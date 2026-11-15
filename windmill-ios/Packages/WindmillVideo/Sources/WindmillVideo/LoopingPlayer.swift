import AVFoundation
#if os(iOS)
import SwiftUI
import UIKit
#endif

/// Plays a file or a composition over and over. Make one per screen and call `release()` when the screen goes away,
/// so the decoders are freed; a released player does not play again.
@MainActor
public final class LoopingPlayer {
    public let player = AVQueuePlayer()
    /// True when the looper's copies of the item dropped the video composition, so the player loops by seeking to zero
    /// on one item instead.
    public private(set) var loopsBySeeking = false
    private var looper: AVPlayerLooper?
    private var endObserver: (any NSObjectProtocol)?

    public init(url: URL) {
        looper = AVPlayerLooper(player: player, templateItem: AVPlayerItem(url: url))
    }

    public convenience init(composition: Composition) {
        self.init(composition: composition, forceSeeking: false)
    }

    /// `forceSeeking` lets the tests run the seeking path, which the looper on macOS never needs.
    init(composition: Composition, forceSeeking: Bool) {
        let item = AVPlayerItem(asset: composition.asset)
        item.videoComposition = composition.videoComposition
        item.audioMix = composition.audioMix
        let looper = AVPlayerLooper(player: player, templateItem: item)
        // A composition's copies exist as soon as the looper does.
        if !forceSeeking, Self.copiesKeep(composition.videoComposition.customVideoCompositorClass, looper.loopingPlayerItems) {
            self.looper = looper
            return
        }
        looper.disableLooping()
        player.removeAllItems()
        loopsBySeeking = true
        player.actionAtItemEnd = .none
        player.insert(item, after: nil)
        endObserver = NotificationCenter.default.addObserver(
            forName: AVPlayerItem.didPlayToEndTimeNotification, object: item, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.player.seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero) }
        }
    }

    /// True when every copy plays through `compositor`; an empty list counts as dropped, not kept.
    static func copiesKeep(_ compositor: AnyClass?, _ copies: [AVPlayerItem]) -> Bool {
        !copies.isEmpty && copies.allSatisfy { $0.videoComposition?.customVideoCompositorClass == compositor }
    }

    /// Why nothing plays, such as a file that is gone; nil while the item loads or plays.
    // ponytail: read on demand; a screen that has to react to it can observe the item's status.
    public var error: (any Error)? { looper?.error ?? player.error ?? player.currentItem?.error }

    public func play() { player.play() }

    public func pause() { player.pause() }

    /// Stops looping and removes every item, which frees their decoders.
    public func release() {
        looper?.disableLooping()
        looper = nil
        if let endObserver { NotificationCenter.default.removeObserver(endObserver) }
        endObserver = nil
        player.pause()
        player.removeAllItems()
    }
}

#if os(iOS)
/// The player's video, filling the view and cropping the overflow.
public struct LoopingVideoView: UIViewRepresentable {
    private let player: LoopingPlayer

    public init(player: LoopingPlayer) {
        self.player = player
    }

    public func makeUIView(context: Context) -> PlayerView {
        let view = PlayerView()
        view.clipsToBounds = true
        view.playerLayer.videoGravity = .resizeAspectFill
        view.playerLayer.player = player.player
        return view
    }

    public func updateUIView(_ view: PlayerView, context: Context) {
        if view.playerLayer.player !== player.player { view.playerLayer.player = player.player }
    }

    public final class PlayerView: UIView {
        override public class var layerClass: AnyClass { AVPlayerLayer.self }
        var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
    }
}
#endif
