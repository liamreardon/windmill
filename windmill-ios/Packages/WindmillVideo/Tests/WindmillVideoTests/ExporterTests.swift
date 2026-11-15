import AVFoundation
import CoreImage
import Foundation
import ImageIO
import Testing
@testable import WindmillVideo

@Suite(.timeLimit(.minutes(5)))
struct ExporterTests {
    private let context = CIContext()
    private let top = TextOverlay(text: "WINDMILL", center: CGPoint(x: 0.5, y: 0.1), height: 0.06)
    private let frame = 1.0 / 30

    private func output(_ ext: String = "mp4") throws -> URL {
        try TestClips.folder().appending(path: "out.\(ext)")
    }

    /// Runs `body` on the file's video track while its asset is alive: a track holds its asset weakly.
    private func video<T>(_ url: URL, _ body: (AVAssetTrack) async throws -> T) async throws -> T {
        let asset = AVURLAsset(url: url)
        let track = try #require(try await asset.loadTracks(withMediaType: .video).first)
        return try await body(track)
    }

    @Test func exportIsH264Mp4WithinOneFrame() async throws {
        let first = try await TestClips.quarters(transform: .rotate90)
        let second = try await TestClips.solid(.blue)
        let composition = try await TestClips.compose([first, second], overlays: [top], context: context)
        let exported = try await Exporter.export(composition, to: try output())

        let (formats, size) = try await video(exported.url) { (try await $0.load(.formatDescriptions), try await $0.load(.naturalSize)) }
        let format = try #require(formats.first)
        #expect(format.mediaSubType.rawValue == kCMVideoCodecType_H264)
        #expect(size == CGSize(width: 1080, height: 1920))
        let seconds = try await AVURLAsset(url: exported.url).load(.duration).seconds
        #expect(abs(seconds - composition.duration.seconds) <= frame + 0.1, "length \(seconds)")
        #expect(exported.url.pathExtension == "mp4")
        #expect(exported.bytes == (try TestClips.fileSize(exported.url)))
        #expect(abs(exported.duration - seconds) < 0.001)
    }

    @Test func audioCoversWholeLength() async throws {
        let withAudio = try await TestClips.solid(.red, audio: .tone(seconds: 1))
        let without = try await TestClips.solid(.blue)
        let composition = try await TestClips.compose([withAudio, without], context: context)
        let exported = try await Exporter.export(composition, to: try output())

        let asset = AVURLAsset(url: exported.url)
        let audio = try #require(try await asset.loadTracks(withMediaType: .audio).first)
        let audioLength = try await audio.load(.timeRange).duration.seconds
        let videoLength = try await video(exported.url) { try await $0.load(.timeRange) }.duration.seconds
        #expect(abs(audioLength - videoLength) <= frame, "audio \(audioLength), video \(videoLength)")
    }

    @Test func exportTooLargeThrowsWithRealSize() async throws {
        let composition = try await TestClips.compose([try await TestClips.quarters(transform: .identity)],
                                                      context: context)
        let url = try output()
        // The export is about 11 KB with Apple's hardware encoder and smaller with CI's software one, so the limit sits
        // far below either.
        do {
            _ = try await Exporter.export(composition, to: url, limit: 1_000)
            Issue.record("expected exportTooLarge")
        } catch WindmillVideoError.exportTooLarge(let bytes, let limit) {
            #expect(bytes == (try TestClips.fileSize(url)))
            #expect(limit == 1_000)
        }
    }

    @Test func thumbnailIsJPEGWithText() async throws {
        let composition = try await TestClips.compose([try await TestClips.solid(.black)], overlays: [top],
                                                      context: context)
        let url = try await Exporter.thumbnail(for: composition, to: try output("jpg"))

        let source = try #require(CGImageSourceCreateWithURL(url as CFURL, nil))
        #expect(CGImageSourceGetType(source) as String? == "public.jpeg")
        let image = try #require(CGImageSourceCreateImageAtIndex(source, 0, nil))
        #expect(image.width == 1080 && image.height == 1920)
        #expect(TestFrame(image).band(y0: 0.05, y1: 0.15, has: .white))
    }

    @Test func longHighFrameRateSourceExportsCapped() async throws {
        let url = try await TestClips.quarters(transform: .identity, size: CGSize(width: 540, height: 960),
                                               duration: 20, fps: 60)
        let composition = try await TestClips.compose([url], context: context)
        let exported = try await Exporter.export(composition, to: try output())

        let seconds = try await AVURLAsset(url: exported.url).load(.duration).seconds
        #expect(abs(seconds - 15) <= frame, "length \(seconds)")
        let rate = try await video(exported.url) { try await $0.load(.nominalFrameRate) }
        #expect(abs(rate - 30) <= 1, "frame rate \(rate)")
    }

    @Test func cancelThrowsCancellation() async throws {
        let url = try await TestClips.quarters(transform: .identity, size: CGSize(width: 540, height: 960),
                                               duration: 20, fps: 60)
        let composition = try await TestClips.compose([url], context: context)
        let out = try output()
        // Cancel once the export reports progress, so it is mid-way on any machine. The stream ends with the export,
        // so an export that fails first shows its own error.
        let (started, signal) = AsyncStream<Void>.makeStream()
        let task = Task {
            defer { signal.finish() }
            return try await Exporter.export(composition, to: out) { if $0 > 0 && $0 < 1 { signal.yield() } }
        }
        for await _ in started { break }
        task.cancel()
        await #expect(throws: CancellationError.self) { try await task.value }
    }

    @Test func sizeIsReadFromTheNewFile() async throws {
        let composition = try await TestClips.compose([try await TestClips.solid(.black)], context: context)
        let url = try output()
        try Data(count: 10).write(to: url)
        #expect(try url.resourceValues(forKeys: [.fileSizeKey]).fileSize == 10)
        let exported = try await Exporter.export(composition, to: url)
        #expect(exported.bytes == (try TestClips.fileSize(URL(filePath: url.path))))
    }

    @Test func hdrDetectedAndConverted() async throws {
        let hlg = try await TestClips.hlg()
        let (written, hdr) = try await video(hlg) {
            (try await $0.load(.formatDescriptions).first.flatMap { $0.extensions[.transferFunction] },
             try await Composer.isHDR($0))
        }
        let input: URL
        if written == .transferFunction(.itu_R_2100_HLG) {
            #expect(hdr)
            input = hlg
        } else {
            print("hdrDetectedAndConverted: this machine wrote no HLG clip (transfer \(String(describing: written))); only the SDR path is checked")
            input = try await TestClips.solid(.red)
            #expect(try await video(input) { try await Composer.isHDR($0) } == false)
        }
        let composition = try await TestClips.compose([input], context: context)
        let exported = try await Exporter.export(composition, to: try output())
        let format = try #require(try await video(exported.url) { try await $0.load(.formatDescriptions) }.first)
        #expect(format.extensions[.transferFunction] == .transferFunction(.itu_R_709_2))
    }
}
