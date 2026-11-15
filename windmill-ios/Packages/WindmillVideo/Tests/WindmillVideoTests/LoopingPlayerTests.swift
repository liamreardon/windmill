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
        var looped = false, last = 0.0
        let start = ContinuousClock.now
        while !looped, ContinuousClock.now - start < .seconds(5) {
            try await Task.sleep(for: .milliseconds(50))
            let now = looping.player.currentTime().seconds
            looped = looping.player.currentItem !== first || now < last
            last = now
        }
        #expect(looped, "no loop in 5 s")
        #expect(ContinuousClock.now - start >= .milliseconds(900))

        let item = try #require(looping.player.currentItem)
        if looping.loopsBySeeking {
            #expect(item === first)
        } else {
            let compositor = item.videoComposition?.customVideoCompositorClass.map { ObjectIdentifier($0) }
            #expect(compositor == ObjectIdentifier(OverlayCompositor.self))
        }
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
        while !wrapped, ContinuousClock.now - start < .seconds(5) {
            try await Task.sleep(for: .milliseconds(50))
            let now = looping.player.currentTime().seconds
            wrapped = now < last
            last = now
        }
        #expect(wrapped, "the time never went back to the start")
        #expect(looping.player.currentItem === first)
        #expect(looping.player.items().count == 1)
    }

    @Test func releaseEmptiesTheQueue() async throws {
        let looping = LoopingPlayer(url: try await TestClips.solid(.blue))
        // A file loads before the looper queues its copies.
        let start = ContinuousClock.now
        while looping.player.items().isEmpty, ContinuousClock.now - start < .seconds(5) {
            try await Task.sleep(for: .milliseconds(20))
        }
        #expect(!looping.player.items().isEmpty)
        looping.release()
        #expect(looping.player.items().isEmpty)
    }
}
