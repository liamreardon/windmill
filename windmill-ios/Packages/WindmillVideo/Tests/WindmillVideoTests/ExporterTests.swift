import AVFoundation
import CoreImage
import Foundation
import ImageIO
import Testing
@testable import WindmillVideo

struct ExporterTests {
    // WINDMILL_SOFTWARE_RENDERER=1 is for CI machines whose GPU cannot run Core Image.
    private let context = ProcessInfo.processInfo.environment["WINDMILL_SOFTWARE_RENDERER"] == "1"
        ? CIContext(options: [.useSoftwareRenderer: true]) : CIContext()
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
        do {
            _ = try await Exporter.export(composition, to: url, limit: 10_000)
            Issue.record("expected exportTooLarge")
        } catch WindmillVideoError.exportTooLarge(let bytes, let limit) {
            #expect(bytes == (try TestClips.fileSize(url)))
            #expect(limit == 10_000)
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
        let task = Task { try await Exporter.export(composition, to: out) }
        try await Task.sleep(for: .milliseconds(300))
        task.cancel()
        await #expect(throws: CancellationError.self) { try await task.value }
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
