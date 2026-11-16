// The camera recorder. iOS only, so the package still builds on macOS.
#if os(iOS)
import AVFoundation
import UIKit
import WindmillVideo

public enum CaptureAccess: Sendable { case unknown, authorized, denied, unavailable }

/// What the record screen draws.
public struct RecorderSnapshot: Sendable {
    public var phase = RecorderPhase.idle
    public var list = SegmentList()
    /// The recorded time, the file being written included, as a fraction of the cap.
    public var progress = 0.0
    public var access = CaptureAccess.unknown
    /// True once a microphone is in the session; clips have no sound otherwise.
    public var microphoneOn = false
    public var position = AVCaptureDevice.Position.back
    public var torchAvailable = false
    public var torchOn = false
    public var zoom = 1.0
    /// True from a clip that the cap ended until the next one starts, for the cap haptic.
    public var endedAtCap = false
}

/// Hold to record over one `AVCaptureMovieFileOutput`, a new file per clip in `draftFolder`. The transitions are
/// `recorderStep`; this class runs its effects.
///
/// `@unchecked Sendable`: every property is read and written on `queue` only. The public methods, the file output's
/// delegate and the notifications all hop onto it.
public final class Recorder: NSObject, @unchecked Sendable {
    public let session = AVCaptureSession()

    private var continuation: AsyncStream<RecorderSnapshot>.Continuation?
    private let queue = DispatchQueue(label: "windmill.recorder")
    private let output = AVCaptureMovieFileOutput()
    private let draftFolder: URL
    private var state = RecorderSnapshot()
    private var camera: AVCaptureDeviceInput?
    private var configured = false
    /// The clips the last `goToEdit` handed over, until it returns them.
    private var handedOver: [Segment]?
    private var progressTimer: (any DispatchSourceTimer)?
    /// The length of the file being written, kept until the clip is in the list, so the ring holds still on a release.
    private var writing = 0.0
    private var observers: [any NSObjectProtocol] = []
    /// True between `start()` and `stop()` or the hand over to Edit; the camera comes back after the background only then.
    private var wanted = false
    private var inBackground = false

    public init(draftFolder: URL) {
        self.draftFolder = draftFolder
        super.init()
        session.automaticallyConfiguresApplicationAudioSession = false
        observe()
    }

    deinit {
        for observer in observers { NotificationCenter.default.removeObserver(observer) }
        continuation?.finish()
    }

    /// A new stream of snapshots, the current one first, then the newest after every change. One reader at a time: a new
    /// call ends the stream before it, so Record can read again after Back from Edit.
    public func updates() -> AsyncStream<RecorderSnapshot> {
        let (stream, continuation) = AsyncStream.makeStream(of: RecorderSnapshot.self, bufferingPolicy: .bufferingNewest(1))
        queue.async {
            self.continuation?.finish()
            self.continuation = continuation
            self.publish()
        }
        return stream
    }

    public func start() {
        queue.async {
            self.wanted = true
            try? FileManager.default.createDirectory(at: self.draftFolder, withIntermediateDirectories: true)
            self.startSession()
        }
    }

    /// Ends any clip and stops the camera. Returns once the session has stopped, so the audio session can be put back;
    /// a clip that was still being written reaches the list in a later snapshot.
    public func stop() async {
        await withCheckedContinuation { (done: CheckedContinuation<Void, Never>) in
            queue.async {
                self.wanted = false
                self.step(.background)
                self.stopCamera()
                self.publish()
                done.resume()
            }
        }
    }

    /// Does nothing while the camera is stopped or interrupted: there is nothing to record.
    public func press() {
        queue.async {
            guard self.wanted, !self.inBackground, self.session.isRunning, !self.session.isInterrupted else { return }
            self.step(.press)
        }
    }

    public func release() { queue.async { self.step(.release) } }
    public func switchCamera() { queue.async { self.step(.switchCamera) } }
    public func deleteLast() { queue.async { self.step(.deleteLast) } }

    /// Stops the camera and returns the clips for Edit. Nil, with nothing changed, unless the recorder is ready with 1 s of
    /// clips or more.
    public func goToEdit() async -> [Segment]? {
        await withCheckedContinuation { (done: CheckedContinuation<[Segment]?, Never>) in
            queue.async {
                self.step(.goToEdit)
                done.resume(returning: self.handedOver)
                self.handedOver = nil
            }
        }
    }

    public func setTorch(_ on: Bool) {
        queue.async {
            guard let device = self.camera?.device, device.hasTorch, (try? device.lockForConfiguration()) != nil else { return }
            device.torchMode = on ? .on : .off
            device.unlockForConfiguration()
            // The torch stays off when the phone is too hot for it.
            self.state.torchOn = device.torchMode == .on
            self.publish()
        }
    }

    /// `factor` is the camera's zoom factor, 1 for no zoom, clamped to what the camera allows and at most 8.
    public func setZoom(_ factor: Double) {
        queue.async {
            guard factor.isFinite, let device = self.camera?.device, (try? device.lockForConfiguration()) != nil else { return }
            let zoom = min(max(CGFloat(factor), device.minAvailableVideoZoomFactor), min(device.maxAvailableVideoZoomFactor, 8))
            device.videoZoomFactor = zoom
            device.unlockForConfiguration()
            self.state.zoom = Double(zoom)
            self.publish()
        }
    }

    // MARK: On the queue

    private func startSession() {
        guard wanted, !inBackground, state.phase == .idle else { return }
        guard AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: state.position) != nil else {
            state.access = .unavailable
            return publish()
        }
        requestAccess(.video) { camera in
            guard camera else {
                self.state.access = .denied
                return self.publish()
            }
            self.requestAccess(.audio) { microphone in
                self.state.access = self.configure(microphone: microphone) ? .authorized : .unavailable
                guard self.state.access == .authorized, self.wanted, !self.inBackground, self.state.phase == .idle else {
                    return self.publish()
                }
                self.session.startRunning()
                // Not running means an interruption, whose end calls this again, or a runtime error, which `recover` takes.
                guard self.session.isRunning else { return self.publish() }
                self.step(.sessionStarted)
            }
        }
    }

    /// Calls `then` on the queue, asking first when the user has not been asked yet.
    private func requestAccess(_ type: AVMediaType, then: @escaping @Sendable (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: type) {
        case .authorized: then(true)
        case .notDetermined: AVCaptureDevice.requestAccess(for: type) { granted in self.queue.async { then(granted) } }
        default: then(false)
        }
    }

    /// Adds what the session is missing: the camera, the microphone when allowed, the file output. Returns whether the
    /// camera and the output are in; when they are not, the next start tries again.
    private func configure(microphone: Bool) -> Bool {
        guard !configured else { return true }
        session.beginConfiguration()
        if session.canSetSessionPreset(.hd1920x1080) { session.sessionPreset = .hd1920x1080 }
        if camera == nil, let input = Self.input(state.position), session.canAddInput(input) {
            session.addInput(input)
            camera = input
        }
        if microphone, !state.microphoneOn, let device = AVCaptureDevice.default(for: .audio),
           let input = try? AVCaptureDeviceInput(device: device), session.canAddInput(input) {
            session.addInput(input)
            state.microphoneOn = true
        }
        if !session.outputs.contains(output), session.canAddOutput(output) { session.addOutput(output) }
        session.commitConfiguration()
        configured = camera != nil && session.outputs.contains(output)
        if configured { setUpConnection() }
        return configured
    }

    private static func input(_ position: AVCaptureDevice.Position) -> AVCaptureDeviceInput? {
        AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position)
            .flatMap { try? AVCaptureDeviceInput(device: $0) }
    }

    /// Portrait, and the front camera mirrored in the file itself, so a segment needs no mirror flag.
    private func setUpConnection() {
        if let connection = output.connection(with: .video) {
            if connection.isVideoRotationAngleSupported(90) { connection.videoRotationAngle = 90 }
            if connection.isVideoMirroringSupported {
                connection.automaticallyAdjustsVideoMirroring = false
                connection.isVideoMirrored = state.position == .front
            }
        }
        state.torchAvailable = camera?.device.hasTorch ?? false
        state.torchOn = false
        state.zoom = 1
    }

    /// Stops the session and turns the torch off, so it is not back on when the camera starts again.
    private func stopCamera() {
        session.stopRunning()
        if let device = camera?.device, device.torchMode == .on, (try? device.lockForConfiguration()) != nil {
            device.torchMode = .off
            device.unlockForConfiguration()
        }
        state.torchOn = false
    }

    private func step(_ event: RecorderEvent) {
        let (phase, effects) = recorderStep(state.phase, event, state.list)
        state.phase = phase
        for effect in effects { apply(effect) }
        // A background or stop that came while a file was finishing takes effect once it is done. A start() that came
        // after such a stop found the phase still finishing and did nothing, so the camera starts again here.
        if phase == .ready, !wanted || inBackground || (!session.isRunning && !session.isInterrupted) {
            step(.background)
            return startSession()
        }
        publish()
    }

    private func apply(_ effect: RecorderEffect) {
        switch effect {
        case .startFile(let maxDuration):
            // With no active connection startRecording raises an exception. The camera stopped after a press was queued:
            // no file, so back to ready.
            guard output.connection(with: .video)?.isActive == true else {
                return queue.async {
                    self.step(.release)
                    self.step(.fileFinished(nil))
                }
            }
            state.endedAtCap = false
            output.maxRecordedDuration = CMTime(seconds: maxDuration, preferredTimescale: 600)
            output.startRecording(to: draftFolder.appendingPathComponent("clip-\(UUID().uuidString).mov"), recordingDelegate: self)
            startProgressTimer()
        case .stopFile:
            output.stopRecording()
        case .append(let segment):
            state.list.append(segment)
        case .switchCamera:
            flipCamera()
        case .deleteLast:
            if let segment = state.list.removeLast() { try? FileManager.default.removeItem(at: segment.url) }
        case .stopSession:
            stopCamera()
        case .openEdit:
            wanted = false
            handedOver = state.list.segments
        }
    }

    private func flipCamera() {
        let position: AVCaptureDevice.Position = state.position == .back ? .front : .back
        guard let input = Self.input(position) else { return }
        session.beginConfiguration()
        if let camera { session.removeInput(camera) }
        guard session.canAddInput(input) else {
            if let camera { session.addInput(camera) }
            return session.commitConfiguration()
        }
        session.addInput(input)
        session.commitConfiguration()
        camera = input
        state.position = position
        setUpConnection()
    }

    private func startProgressTimer() {
        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now(), repeating: .milliseconds(33))
        timer.setEventHandler { [weak self] in self?.publish() }
        timer.resume()
        progressTimer = timer
    }

    private func publish() {
        if output.isRecording, output.recordedDuration.seconds.isFinite { writing = output.recordedDuration.seconds }
        state.progress = min(1, (state.list.total + writing) / SegmentList.cap)
        continuation?.yield(state)
    }

    /// A runtime error stopped the session. After a media services reset the camera starts again; any other error
    /// shows as unavailable until the next `start()`.
    private func recover(reset: Bool) {
        step(.background)
        if reset { return startSession() }
        state.access = .unavailable
        publish()
    }

    private func observe() {
        let center = NotificationCenter.default
        func watch(_ name: Notification.Name, _ object: AnyObject?, _ action: @escaping @Sendable (Recorder) -> Void)
            -> any NSObjectProtocol {
            center.addObserver(forName: name, object: object, queue: nil) { [weak self] _ in
                guard let self else { return }
                self.queue.async { action(self) }
            }
        }
        observers = [
            watch(UIApplication.didEnterBackgroundNotification, nil) { recorder in
                recorder.inBackground = true
                recorder.step(.background)
            },
            // Not willEnterForeground: the app is still in the background when that one is posted.
            watch(UIApplication.didBecomeActiveNotification, nil) { recorder in
                recorder.inBackground = false
                recorder.startSession()
            },
            // An interruption (a call, Siri, another app taking the camera) ends the clip and keeps it. The session is
            // left running, so it carries on by itself when the interruption ends.
            watch(AVCaptureSession.wasInterruptedNotification, session) { recorder in recorder.step(.release) },
            // For a start() made during the interruption, which is still idle.
            watch(AVCaptureSession.interruptionEndedNotification, session) { recorder in recorder.startSession() },
            center.addObserver(forName: AVCaptureSession.runtimeErrorNotification, object: session, queue: nil) { [weak self] note in
                let reset = (note.userInfo?[AVCaptureSessionErrorKey] as? AVError)?.code == .mediaServicesWereReset
                guard let self else { return }
                self.queue.async { self.recover(reset: reset) }
            },
        ]
    }
}

extension Recorder: AVCaptureFileOutputRecordingDelegate {
    public func fileOutput(
        _ output: AVCaptureFileOutput, didFinishRecordingTo url: URL, from connections: [AVCaptureConnection],
        error: (any Error)?
    ) {
        let keep = keepRecordedFile(error: error)
        let atCap = (error as NSError?)?.code == AVError.maximumDurationReached.rawValue
        queue.async {
            self.progressTimer?.cancel()
            self.progressTimer = nil
            // The output stopped by itself, at the cap or on a failure, while the button was still held.
            if self.state.phase == .recording {
                self.state.endedAtCap = atCap
                self.step(atCap ? .capReached : .background)
            }
        }
        Task {
            let segment: Segment? = if keep { try? await Segment.measured(url) } else { nil }
            self.queue.async {
                let kept = segment.flatMap { $0.duration >= SegmentList.floor ? $0 : nil }
                if kept == nil { try? FileManager.default.removeItem(at: url) }
                self.writing = 0
                self.step(.fileFinished(kept))
            }
        }
    }
}
#endif
