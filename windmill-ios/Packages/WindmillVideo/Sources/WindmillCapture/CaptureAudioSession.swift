#if os(iOS)
import AVFoundation

/// The audio session while Record is on screen. `enter()` keeps the app's category, mode and options and switches to
/// play and record, so haptics and system sounds still play during a recording; `leave()` puts them back.
@MainActor
public enum CaptureAudioSession {
    private static var stored: (category: AVAudioSession.Category, mode: AVAudioSession.Mode,
                                options: AVAudioSession.CategoryOptions)?

    /// On a throw (during a call, for one) the app's category is already back, so there is nothing to leave.
    public static func enter() throws {
        let session = AVAudioSession.sharedInstance()
        if stored == nil { stored = (session.category, session.mode, session.categoryOptions) }
        do {
            try session.setCategory(.playAndRecord, mode: .videoRecording, options: [.defaultToSpeaker, .allowBluetoothA2DP])
            try session.setAllowHapticsAndSystemSoundsDuringRecording(true)
            try session.setActive(true)
        } catch {
            leave()
            throw error
        }
    }

    /// Call after the recorder has stopped. Lets audio that Record stopped, such as music in another app, carry on.
    // ponytail: a failed restore is dropped; the app's next enter() keeps whatever is set then.
    public static func leave() {
        guard let stored else { return }
        Self.stored = nil
        let session = AVAudioSession.sharedInstance()
        try? session.setActive(false, options: .notifyOthersOnDeactivation)
        try? session.setCategory(stored.category, mode: stored.mode, options: stored.options)
    }
}
#endif
