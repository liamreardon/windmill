import AVFoundation
import CoreImage
import CoreText
import ImageIO

/// What the player and the exporter both use: the joined, trimmed clips and the compositor that draws them.
/// Unchecked because every member is an immutable copy that is never changed after `Composer.make`.
public struct Composition: @unchecked Sendable {
    public let asset: AVComposition
    public let videoComposition: AVVideoComposition
    public let audioMix: AVAudioMix?
    public let duration: CMTime
    /// The PostScript name of the font the text is drawn with.
    public let fontName: String
    public let renderSize: CGSize
}

public enum Composer {
    public static let renderSize = CGSize(width: 1080, height: 1920)
    public static let frameDuration = CMTime(value: 1, timescale: 30)

    // ponytail: one context for every composition; CIContext is thread safe.
    private static let sharedContext = CIContext()

    /// Joins the segments, keeps only the trim, and sets up the compositor for orientation, the cover crop and text.
    public static func make(_ edit: Edit, context: CIContext? = nil) async throws -> Composition {
        guard let silenceURL = Bundle.module.url(forResource: "silence-48k", withExtension: "m4a") else {
            throw WindmillVideoError.exportFailed(underlying: CocoaError(.fileReadNoSuchFile))
        }
        // A track holds its asset weakly, so the asset is kept until the last insert.
        let silenceAsset = AVURLAsset(url: silenceURL)
        defer { withExtendedLifetime(silenceAsset) {} }
        let composition = AVMutableComposition()
        guard let videoOut = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid),
              let audioOut = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid),
              let silence = try await silenceAsset.loadTracks(withMediaType: .audio).first
        else { throw WindmillVideoError.exportFailed(underlying: CocoaError(.fileReadCorruptFile)) }

        let font = Fonts.lexend(size: 1)
        let text = textImage(edit.overlays, renderSize: renderSize)
        let context = context ?? sharedContext
        let trimStart = time(edit.trim.lowerBound), trimEnd = time(edit.trim.upperBound)

        var instructions: [SegmentInstruction] = []
        var joined = CMTime.zero
        for segment in edit.segments {
            let asset = AVURLAsset(url: segment.url)
            guard let video = try await asset.loadTracks(withMediaType: .video).first else {
                throw WindmillVideoError.exportFailed(underlying: CocoaError(.fileReadCorruptFile))
            }
            let (range, transform, natural) = try await video.load(.timeRange, .preferredTransform, .naturalSize)
            let start = joined
            joined = start + range.duration
            let lower = max(start, trimStart), upper = min(joined, trimEnd)
            guard lower < upper else { continue }

            let source = CMTimeRange(start: range.start + (lower - start), end: range.start + (upper - start))
            let at = lower - trimStart
            try videoOut.insertTimeRange(source, of: video, at: at)

            // Audio clamped to this segment's video; gaps before and after get silence.
            var audioEnd = at
            if let audio = try await asset.loadTracks(withMediaType: .audio).first {
                let clamped = try await audio.load(.timeRange).intersection(source)
                if clamped.duration > .zero {
                    let audioAt = at + (clamped.start - source.start)
                    try fillSilence(audioOut, silence, from: audioEnd, to: audioAt)
                    try audioOut.insertTimeRange(clamped, of: audio, at: audioAt)
                    audioEnd = audioAt + clamped.duration
                }
            }
            try fillSilence(audioOut, silence, from: audioEnd, to: at + source.duration)

            instructions.append(SegmentInstruction(
                timeRange: CMTimeRange(start: at, duration: source.duration), trackID: videoOut.trackID,
                orientation: orientation(transform), naturalSize: natural, text: text, context: context))
        }

        let videoComposition = AVMutableVideoComposition()
        videoComposition.customVideoCompositorClass = OverlayCompositor.self
        videoComposition.renderSize = renderSize
        videoComposition.frameDuration = frameDuration
        videoComposition.instructions = instructions
        videoComposition.colorPrimaries = AVVideoColorPrimaries_ITU_R_709_2
        videoComposition.colorTransferFunction = AVVideoTransferFunction_ITU_R_709_2
        videoComposition.colorYCbCrMatrix = AVVideoYCbCrMatrix_ITU_R_709_2

        return Composition(
            asset: composition.copy() as! AVComposition,
            videoComposition: videoComposition.copy() as! AVVideoComposition,
            audioMix: nil, duration: videoOut.timeRange.duration,
            fontName: CTFontCopyPostScriptName(font) as String, renderSize: renderSize)
    }

    /// True for HLG and PQ video.
    public static func isHDR(_ track: AVAssetTrack) async throws -> Bool {
        try await track.load(.mediaCharacteristics).contains(.containsHDRVideo)
    }

    // MARK: helpers

    private static func time(_ seconds: Double) -> CMTime {
        CMTime(seconds: seconds, preferredTimescale: 600)
    }

    // ponytail: the silent file is 16 s and a segment is at most 15 s, so one insert always covers a gap.
    private static func fillSilence(_ track: AVMutableCompositionTrack, _ silence: AVAssetTrack,
                                    from start: CMTime, to end: CMTime) throws {
        guard end > start else { return }
        try track.insertTimeRange(CMTimeRange(start: .zero, duration: end - start), of: silence, at: start)
    }

    /// The display orientation a phone's preferred transform stands for.
    // ponytail: only right angles and flips; any other transform draws the frame as stored.
    static func orientation(_ t: CGAffineTransform) -> CGImagePropertyOrientation {
        switch (t.a.rounded(), t.b.rounded(), t.c.rounded(), t.d.rounded()) {
        case (0, 1, -1, 0): .right
        case (-1, 0, 0, -1): .down
        case (0, -1, 1, 0): .left
        case (-1, 0, 0, 1): .upMirrored
        case (1, 0, 0, -1): .downMirrored
        case (0, 1, 1, 0): .leftMirrored
        case (0, -1, -1, 0): .rightMirrored
        default: .up
        }
    }

    /// Every overlay drawn once with Core Text, placed in a frame of `renderSize` (Core Image's origin is bottom left).
    static func textImage(_ overlays: [TextOverlay], renderSize: CGSize) -> CIImage? {
        var result: CIImage?
        for overlay in overlays where !overlay.text.isEmpty {
            let font = Fonts.lexend(size: overlay.height * renderSize.height)
            let color = CGColor(srgbRed: overlay.color.red, green: overlay.color.green, blue: overlay.color.blue,
                                alpha: overlay.color.alpha)
            let attributes: [NSAttributedString.Key: Any] = [
                NSAttributedString.Key(kCTFontAttributeName as String): font,
                NSAttributedString.Key(kCTForegroundColorAttributeName as String): color,
            ]
            let line = CTLineCreateWithAttributedString(NSAttributedString(string: overlay.text, attributes: attributes))
            var ascent: CGFloat = 0, descent: CGFloat = 0
            let width = ceil(CTLineGetTypographicBounds(line, &ascent, &descent, nil))
            let height = ceil(ascent + descent)
            guard width > 0, height > 0,
                  let space = CGColorSpace(name: CGColorSpace.sRGB),
                  let cg = CGContext(data: nil, width: Int(width), height: Int(height), bitsPerComponent: 8,
                                     bytesPerRow: 0, space: space,
                                     bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
            else { continue }
            cg.textPosition = CGPoint(x: 0, y: descent)
            CTLineDraw(line, cg)
            guard let image = cg.makeImage() else { continue }
            let x = overlay.center.x * renderSize.width - width / 2
            let y = (1 - overlay.center.y) * renderSize.height - height / 2
            let placed = CIImage(cgImage: image).transformed(by: CGAffineTransform(translationX: x, y: y))
            result = result.map { placed.composited(over: $0) } ?? placed
        }
        return result
    }
}
