import AVFoundation
import CoreImage
import Foundation
import Testing
@testable import WindmillVideo

struct ComposerTests {
    private let context = CIContext(options: [.useSoftwareRenderer: true])

    private func compose(_ urls: [URL], trim: ClosedRange<Double>? = nil,
                         overlays: [TextOverlay] = []) async throws -> Composition {
        try await TestClips.compose(urls, trim: trim, overlays: overlays, context: context)
    }

    private func frame(_ composition: Composition, at seconds: Double) async throws -> TestFrame {
        try await TestClips.frame(at: seconds, in: composition.asset, videoComposition: composition.videoComposition)
    }

    private func expectQuarters(_ frame: TestFrame, _ label: String, sourceLocation: SourceLocation = #_sourceLocation) {
        let expected: [(Double, Double, RGB)] = [(0.25, 0.25, .red), (0.75, 0.25, .green),
                                                 (0.25, 0.75, .blue), (0.75, 0.75, .yellow)]
        for (x, y, color) in expected {
            let got = frame.pixel(x: x, y: y)
            #expect(got.near(color), "\(label): at (\(x), \(y)) expected \(color), got \(got)",
                    sourceLocation: sourceLocation)
        }
    }

    @Test(arguments: ClipTransform.allCases)
    func quartersUprightUnderEachTransform(_ transform: ClipTransform) async throws {
        let composition = try await compose([try await TestClips.quarters(transform: transform)])
        let frame = try await frame(composition, at: 0.5)
        #expect(frame.width == 1080 && frame.height == 1920)
        expectQuarters(frame, "\(transform)")
    }

    @Test func landscapeIsCroppedToCover() async throws {
        let url = try await TestClips.quarters(transform: .identity, size: CGSize(width: 1920, height: 1080))
        let composition = try await compose([url])
        #expect(composition.renderSize == CGSize(width: 1080, height: 1920))
        let frame = try await frame(composition, at: 0.5)
        #expect(frame.width == 1080 && frame.height == 1920)
        #expect(frame.pixel(x: 0.25, y: 0.25).near(.red), "got \(frame.pixel(x: 0.25, y: 0.25))")
        #expect(frame.pixel(x: 0.75, y: 0.75).near(.yellow), "got \(frame.pixel(x: 0.75, y: 0.75))")
    }

    @Test func upsideDownAndMixedSizes() async throws {
        let first = try await TestClips.quarters(transform: .rotate180)
        let second = try await TestClips.quarters(transform: .identity, size: CGSize(width: 720, height: 1280))
        let composition = try await compose([first, second])
        for seconds in [0.5, 1.5] {
            let frame = try await frame(composition, at: seconds)
            expectQuarters(frame, "\(seconds) s")
            #expect(frame.pixel(x: 0.02, y: 0.02).near(.red), "edge at \(seconds) s: \(frame.pixel(x: 0.02, y: 0.02))")
        }
    }

    @Test func textAtTopLandsAtTop() async throws {
        let overlay = TextOverlay(text: "WINDMILL", center: CGPoint(x: 0.5, y: 0.1), height: 0.06, color: .white)
        let composition = try await compose([try await TestClips.solid(.black)], overlays: [overlay])
        let frame = try await frame(composition, at: 0.5)
        #expect(frame.band(y0: 0.05, y1: 0.15, has: .white))
        #expect(!frame.band(y0: 0.5, y1: 1.0, has: .white))
    }

    @Test func trimStartingInsideSecondSegment() async throws {
        let red = try await TestClips.solid(.red, duration: 2)
        let blue = try await TestClips.solid(.blue, duration: 2, audio: .tone(seconds: 2))
        let composition = try await compose([red, blue], trim: 2.5...3.5)
        #expect(abs(composition.duration.seconds - 1) <= 1.0 / 30, "duration \(composition.duration.seconds)")
        let pixel = try await frame(composition, at: 0).pixel(x: 0.5, y: 0.5)
        #expect(pixel.near(.blue), "got \(pixel)")
        // A solid clip looks the same from any start, so check where in the source the cut begins.
        for type in [AVMediaType.video, .audio] {
            let segment = try #require(composition.asset.tracks(withMediaType: type).first?.segments.first { !$0.isEmpty })
            #expect(abs(segment.timeMapping.source.start.seconds - 0.5) < 0.001,
                    "\(type.rawValue) starts at \(segment.timeMapping.source.start.seconds) s in the source")
        }
    }

    @Test func editAndCompositionAgreeWhenAudioOutlastsVideo() async throws {
        let red = try await TestClips.solid(.red, duration: 1, audio: .tone(seconds: 1.5))
        let blue = try await TestClips.solid(.blue, duration: 2)
        var edit = try Edit(segments: [try await Segment.measured(red), try await Segment.measured(blue)])
        edit.setTrim(2.5...3.5)
        let composition = try await Composer.make(edit, context: context)
        let length = edit.trim.upperBound - edit.trim.lowerBound
        #expect(abs(composition.duration.seconds - length) <= 1.0 / 30,
                "edit \(length) s, composition \(composition.duration.seconds) s")
    }

    @Test func segmentAfterTheTrimIsNotOpened() async throws {
        let red = try await TestClips.solid(.red, duration: 2)
        let broken = try TestClips.folder().appending(path: "broken.mov")
        try Data("not a movie".utf8).write(to: broken)
        var edit = try Edit(segments: [try await Segment.measured(red), Segment(url: broken, duration: 2)])
        edit.setTrim(0...1.5)
        let composition = try await Composer.make(edit, context: context)
        #expect(abs(composition.duration.seconds - 1.5) <= 1.0 / 30, "duration \(composition.duration.seconds)")
    }

    @Test func longTextStaysInsideTheFrame() throws {
        let size = Composer.renderSize
        let long = TextOverlay(text: String(repeating: "WINDMILL ", count: 300), center: CGPoint(x: 0.5, y: 0.5),
                               height: 0.06)
        let image = try #require(Composer.textImage([long], renderSize: size))
        #expect(image.extent == CGRect(origin: .zero, size: size), "extent \(image.extent)")
        let empty = TextOverlay(text: "W", center: CGPoint(x: 0.5, y: 0.5), height: 0)
        #expect(Composer.textImage([empty], renderSize: size) == nil)
    }

    @Test(.timeLimit(.minutes(1))) func longClipWithAudioWrites() async throws {
        let asset = AVURLAsset(url: try await TestClips.solid(.red, duration: 4, audio: .tone(seconds: 4)))
        let audio = try #require(try await asset.loadTracks(withMediaType: .audio).first)
        #expect(try await audio.load(.timeRange).duration.seconds > 3.9)
    }

    @Test func silenceOutlastsTheCap() async throws {
        let url = try #require(Composer.silenceURL)
        #expect(try await AVURLAsset(url: url).load(.duration).seconds > Edit.cap)
    }

    @Test func audioFollowsEachSegment() async throws {
        let first = try await TestClips.solid(.red, audio: .tone(seconds: 1))
        let second = try await TestClips.solid(.green, audio: .tone(seconds: 0.9))
        let third = try await TestClips.solid(.blue)
        let composition = try await compose([first, second, third])
        let audio = try #require(composition.asset.tracks(withMediaType: .audio).first)
        let video = try #require(composition.asset.tracks(withMediaType: .video).first)
        let starts = audio.segments.filter { !$0.isEmpty }.map(\.timeMapping.target.start)
        for second in 0...2 {
            #expect(starts.contains(CMTime(value: CMTimeValue(second), timescale: 1)),
                    "no audio segment starts at \(second) s: \(starts.map(\.seconds))")
        }
        #expect(audio.timeRange.end == video.timeRange.end,
                "audio ends \(audio.timeRange.end.seconds), video \(video.timeRange.end.seconds)")
    }

    @Test func rendererResolvedLexend() async throws {
        let composition = try await compose([try await TestClips.solid(.black)])
        #expect(composition.fontName.hasPrefix("Lexend"), "got \(composition.fontName)")
    }

    @Test func sdrClipIsNotHDR() async throws {
        let asset = AVURLAsset(url: try await TestClips.solid(.red))
        let track = try #require(try await asset.loadTracks(withMediaType: .video).first)
        #expect(try await Composer.isHDR(track) == false)
    }
}
