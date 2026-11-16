#if os(iOS)
import AVFoundation

/// The audio session while Record is on screen. `enter()` keeps the app's category, mode and options and switches to
/// play and record, so haptics and system sounds still play during a recording; `leave()` puts them back.
@MainActor
public enum CaptureAudioSession {
    private static var stored: (category: AVAudioSession.Category, mode: AVAudioSession.Mode,
                                options: AVAudioSession.CategoryOptions)?

    public static func enter() throws {
        let session = AVAudioSession.sharedInstance()
        if stored == nil { stored = (session.category, session.mode, session.categoryOptions) }
        try session.setCategory(.playAndRecord, mode: .videoRecording, options: [.defaultToSpeaker, .allowBluetoothA2DP])
        try session.setAllowHapticsAndSystemSoundsDuringRecording(true)
        try session.setActive(true)
    }

    /// Call after the recorder has stopped.
    // ponytail: a failed restore is dropped; the app's next enter() keeps whatever is set then.
    public static func leave() {
        guard let stored else { return }
        Self.stored = nil
        try? AVAudioSession.sharedInstance().setCategory(stored.category, mode: stored.mode, options: stored.options)
    }
}
#endif
