import AVFoundation
import CoreImage
import Testing
@testable import WindmillVideo

@Suite(.timeLimit(.minutes(2)))
@MainActor
struct LoopingPlayerTests {
    private let context = CIContext(options: [.useSoftwareRenderer: true])

    @Test func previewItemsKeepOverlayAfterLoop() async throws {
        let overlay = TextOverlay(text: "Loop", center: CGPoint(x: 0.5, y: 0.5), height: 0.06)
        let composition = try await TestClips.compose([try await TestClips.solid(.red)], overlays: [overlay],
                                                      context: context)
        let looping = LoopingPlayer(composition: composition)
        defer { looping.release() }
        let first = try #require(looping.player.currentItem)
        looping.play()

        // A loop shows as a new item (the looper) or as the time going back to the start (seeking).
        // The wait is long because a slow runner may take a while to start the item; a pass ends at the first loop.
        var looped = false, last = 0.0
        let start = ContinuousClock.now
        while !looped, ContinuousClock.now - start < .seconds(30) {
            try await Task.sleep(for: .milliseconds(50))
            let now = looping.player.currentTime().seconds
            looped = looping.player.currentItem !== first || now < last
            last = now
        }
        #expect(looped, "no loop in 30 s")
        #expect(ContinuousClock.now - start >= .seconds(composition.duration.seconds * 0.9))

        #expect(looping.error == nil)
        let item = try #require(looping.player.currentItem)
        if looping.loopsBySeeking { #expect(item === first) }
        #expect(item.videoComposition?.customVideoCompositorClass == OverlayCompositor.self)
    }

    @Test func seekingLoopsTheOriginalItem() async throws {
        let composition = try await TestClips.compose([try await TestClips.solid(.red)], context: context)
        let looping = LoopingPlayer(composition: composition, forceSeeking: true)
        defer { looping.release() }
        #expect(looping.loopsBySeeking)
        let first = try #require(looping.player.currentItem)
        looping.play()

        var wrapped = false, last = 0.0
        let start = ContinuousClock.now
        while !wrapped, ContinuousClock.now - start < .seconds(30) {
            try await Task.sleep(for: .milliseconds(50))
            let now = looping.player.currentTime().seconds
            wrapped = now < last
            last = now
        }
        #expect(wrapped, "the time never went back to the start")
        #expect(ContinuousClock.now - start >= .seconds(composition.duration.seconds * 0.9))
        #expect(looping.player.currentItem === first)
        #expect(looping.player.items().count == 1)
        #expect(first.videoComposition?.customVideoCompositorClass == OverlayCompositor.self)
    }

    @Test func seekingWrapLandsOnTheFirstFrame() async throws {
        // A trim that starts between key frames, where a loose seek lands late.
        let clip = try await TestClips.solid(.red, duration: 3)
        let composition = try await TestClips.compose([clip], trim: 1.3...2.5, context: context)
        let looping = LoopingPlayer(composition: composition, forceSeeking: true)
        defer { looping.release() }
        looping.play()

        var landed: Double?, last = 0.0
        let start = ContinuousClock.now
        while landed == nil, ContinuousClock.now - start < .seconds(30) {
            try await Task.sleep(for: .milliseconds(20))
            let now = looping.player.currentTime().seconds
            if now < last { landed = now }
            last = now
        }
        let time = try #require(landed, "the time never went back")
        #expect(time < 0.15, "the loop restarted at \(time) s")
    }

    @Test func releaseEmptiesTheSeekingQueue() async throws {
        let composition = try await TestClips.compose([try await TestClips.solid(.red)], context: context)
        let looping = LoopingPlayer(composition: composition, forceSeeking: true)
        looping.play()
        try await Task.sleep(for: .milliseconds(300))
        looping.release()
        // Past the clip's end, so the queue has had time to fill again if anything still fed it.
        try await Task.sleep(for: .seconds(composition.duration.seconds + 0.5))
        #expect(looping.player.items().isEmpty)
        #expect(looping.player.currentItem == nil)
    }

    @Test func copiesKeepNeedsTheCompositorOnEveryCopy() async throws {
        let composition = try await TestClips.compose([try await TestClips.solid(.red)], context: context)
        let kept = AVPlayerItem(asset: composition.asset)
        kept.videoComposition = composition.videoComposition
        let dropped = AVPlayerItem(asset: composition.asset)
        let compositor = composition.videoComposition.customVideoCompositorClass
        #expect(LoopingPlayer.copiesKeep(compositor, [kept, kept]))
        #expect(!LoopingPlayer.copiesKeep(compositor, [kept, dropped]))
        #expect(!LoopingPlayer.copiesKeep(compositor, []))
    }

    @Test func releaseEmptiesTheQueue() async throws {
        let looping = LoopingPlayer(url: try await TestClips.solid(.blue))
        // A file loads before the looper queues its copies.
        let start = ContinuousClock.now
        while looping.player.items().isEmpty, ContinuousClock.now - start < .seconds(30) {
            try await Task.sleep(for: .milliseconds(20))
        }
        #expect(!looping.player.items().isEmpty)
        #expect(looping.error == nil)
        looping.release()
        #expect(looping.player.items().isEmpty)
    }

    #if os(macOS)
    /// On macOS the looper keeps the compositor on every copy, so a composition never falls back to seeking.
    @Test func compositionUsesTheLooperOnMacOS() async throws {
        let looping = LoopingPlayer(composition: try await TestClips.compose([try await TestClips.solid(.red)],
                                                                            context: context))
        defer { looping.release() }
        #expect(!looping.loopsBySeeking)
        #expect(looping.player.items().count > 1)
    }
    #endif

    /// A compositor that fails every frame stops the looper and makes the seeking item post a failure.
    @Test(arguments: [false, true]) func failingFramesReportAnError(forceSeeking: Bool) async throws {
        let good = try await TestClips.compose([try await TestClips.solid(.red)], context: context)
        let failing = good.videoComposition.mutableCopy() as! AVMutableVideoComposition
        failing.customVideoCompositorClass = FailingCompositor.self
        let composition = Composition(asset: good.asset, videoComposition: failing, audioMix: nil,
                                      duration: good.duration, fontName: good.fontName, renderSize: good.renderSize)
        let looping = LoopingPlayer(composition: composition, forceSeeking: forceSeeking)
        defer { looping.release() }
        #expect(looping.loopsBySeeking == forceSeeking)
        // With no layer or output to draw into, the player never asks the compositor for a frame.
        let bgra: [String: Any] = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        for item in looping.player.items() { item.add(AVPlayerItemVideoOutput(pixelBufferAttributes: bgra)) }
        looping.play()
        let start = ContinuousClock.now
        while looping.error == nil, ContinuousClock.now - start < .seconds(30) {
            try await Task.sleep(for: .milliseconds(20))
        }
        #expect(looping.error != nil)
    }

    @Test func missingFileReportsAnError() async throws {
        let missing = FileManager.default.temporaryDirectory.appendingPathComponent("missing-\(UUID()).mov")
        let looping = LoopingPlayer(url: missing)
        defer { looping.release() }
        let start = ContinuousClock.now
        while looping.error == nil, ContinuousClock.now - start < .seconds(30) {
            try await Task.sleep(for: .milliseconds(20))
        }
        #expect(looping.error != nil)
    }

    @Test func releaseBeforeLoadStaysEmpty() async throws {
        let url = try await TestClips.solid(.blue)
        let released = LoopingPlayer(url: url), control = LoopingPlayer(url: url)
        defer { control.release() }
        released.release()
        // The control shows when the looper would have queued its copies.
        let start = ContinuousClock.now
        while control.player.items().isEmpty, ContinuousClock.now - start < .seconds(30) {
            try await Task.sleep(for: .milliseconds(20))
        }
        try await Task.sleep(for: .milliseconds(200))
        #expect(!control.player.items().isEmpty)
        #expect(released.player.items().isEmpty)
    }
}

/// Fails every frame, as the overlay compositor does when it gets no pixel buffer.
final class FailingCompositor: NSObject, AVVideoCompositing, @unchecked Sendable {
    let sourcePixelBufferAttributes: [String: any Sendable]? =
        [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
    let requiredPixelBufferAttributesForRenderContext: [String: any Sendable] =
        [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]

    func renderContextChanged(_ newRenderContext: AVVideoCompositionRenderContext) {}

    func startRequest(_ request: AVAsynchronousVideoCompositionRequest) {
        request.finish(with: CocoaError(.fileReadCorruptFile))
    }
}
