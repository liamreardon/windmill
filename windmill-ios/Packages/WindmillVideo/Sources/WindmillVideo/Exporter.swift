import AVFoundation
import ImageIO
import UniformTypeIdentifiers

/// The session's states are made to be read while it exports; the SDK has not marked it Sendable.
private struct Watched: @unchecked Sendable {
    let session: AVAssetExportSession
}

public struct ExportedVideo: Sendable {
    public let url: URL
    public let bytes: Int
    /// Seconds, read back from the file.
    public let duration: Double
}

/// Writes the final MP4 and its thumbnail.
public enum Exporter {
    /// 50 MiB, the same number as the backend's video upload limit.
    public static let maxBytes = 52_428_800

    /// Exports H.264 MP4 at 1080x1920, then reads the file back. Any file already at `url` is replaced, so give
    /// each export its own URL. Throws `exportTooLarge` over `limit` (the file stays at `url`), `CancellationError`
    /// when the task is cancelled, `exportFailed` for anything else.
    public static func export(_ composition: Composition, to url: URL, limit: Int = maxBytes,
                              progress: @escaping @Sendable (Double) -> Void = { _ in }) async throws -> ExportedVideo {
        guard let session = AVAssetExportSession(asset: composition.asset,
                                                 presetName: AVAssetExportPresetHighestQuality) else {
            throw WindmillVideoError.exportFailed(underlying: CocoaError(.featureUnsupported))
        }
        session.videoComposition = composition.videoComposition
        session.audioMix = composition.audioMix
        session.shouldOptimizeForNetworkUse = true
        try? FileManager.default.removeItem(at: url)

        let watched = Watched(session: session)
        let watcher = Task {
            for await state in watched.session.states(updateInterval: 0.1) {
                if case .exporting(let done) = state { progress(done.fractionCompleted) }
            }
        }
        defer { watcher.cancel() }
        return try await WindmillVideoError.wrapping {
            try await session.export(to: url, as: .mp4)
            progress(1)

            // ponytail: MP4 is guaranteed by `as: .mp4`; the read back checks codec and length.
            let asset = AVURLAsset(url: url)
            let duration = try await asset.load(.duration)
            let codec = try await asset.loadTracks(withMediaType: .video).first?.load(.formatDescriptions).first?.mediaSubType
            guard codec?.rawValue == kCMVideoCodecType_H264,
                  abs(duration.seconds - composition.duration.seconds) <= Composer.frameDuration.seconds + 0.1 else {
                throw WindmillVideoError.exportFailed(underlying: CocoaError(.fileReadCorruptFile))
            }
            // Read from the disk: a URL caches resource values, so a file it saw before the export reads the old size.
            let bytes = try FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int ?? 0
            if bytes > limit { throw WindmillVideoError.exportTooLarge(bytes: bytes, limit: limit) }
            return ExportedVideo(url: url, bytes: bytes, duration: duration.seconds)
        }
    }

    /// The first frame, with its text, as a JPEG at quality 0.8.
    public static func thumbnail(for composition: Composition, to url: URL) async throws -> URL {
        try await WindmillVideoError.wrapping { try await writeThumbnail(for: composition, to: url) }
    }

    private static func writeThumbnail(for composition: Composition, to url: URL) async throws -> URL {
        let generator = AVAssetImageGenerator(asset: composition.asset)
        generator.videoComposition = composition.videoComposition
        generator.requestedTimeToleranceBefore = .zero
        generator.requestedTimeToleranceAfter = .zero
        let (image, _) = try await generator.image(at: .zero)
        guard let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.jpeg.identifier as CFString, 1, nil)
        else { throw WindmillVideoError.exportFailed(underlying: CocoaError(.fileWriteUnknown)) }
        CGImageDestinationAddImage(destination, image,
                                   [kCGImageDestinationLossyCompressionQuality: 0.8] as CFDictionary)
        guard CGImageDestinationFinalize(destination) else {
            throw WindmillVideoError.exportFailed(underlying: CocoaError(.fileWriteUnknown))
        }
        return url
    }
}
