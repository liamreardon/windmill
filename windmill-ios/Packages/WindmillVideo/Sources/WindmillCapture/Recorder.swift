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
    public var microphoneOn = false
    public var position = AVCaptureDevice.Position.back
    public var torchAvailable = false
    public var torchOn = false
    public var zoom = 1.0
    /// The clips to edit, set when the recorder hands over to Edit and cleared by the next `start()`.
    public var handoff: [Segment]?
}

/// Hold to record over one `AVCaptureMovieFileOutput`, a new file per clip in `draftFolder`. The transitions are
/// `recorderStep`; this class runs its effects.
///
/// `@unchecked Sendable`: every property is read and written on `queue` only. The public methods, the file output's
/// delegate and the notifications all hop onto it.
public final class Recorder: NSObject, @unchecked Sendable {
    public let session = AVCaptureSession()
    /// The newest snapshot after every change. One reader.
    public let updates: AsyncStream<RecorderSnapshot>

    private let continuation: AsyncStream<RecorderSnapshot>.Continuation
    private let queue = DispatchQueue(label: "windmill.recorder")
    private let output = AVCaptureMovieFileOutput()
    private let draftFolder: URL
    private var state = RecorderSnapshot()
    private var camera: AVCaptureDeviceInput?
    private var configured = false
    private var progressTimer: (any DispatchSourceTimer)?
    private var observers: [any NSObjectProtocol] = []
    /// True between `start()` and `stop()` or the hand over to Edit; the camera comes back after the background or an
    /// interruption only then.
    private var wanted = false
    private var inBackground = false

    public init(draftFolder: URL) {
        self.draftFolder = draftFolder
        (updates, continuation) = AsyncStream.makeStream(bufferingPolicy: .bufferingNewest(1))
        super.init()
        session.automaticallyConfiguresApplicationAudioSession = false
        observe()
    }

    deinit {
        for observer in observers { NotificationCenter.default.removeObserver(observer) }
        continuation.finish()
    }

    public func start() {
        queue.async {
            self.wanted = true
            self.state.handoff = nil
            self.startSession()
        }
    }

    /// Ends any clip and stops the camera. Returns once the session has stopped, so the audio session can be put back.
    public func stop() async {
        await withCheckedContinuation { (done: CheckedContinuation<Void, Never>) in
            queue.async {
                self.wanted = false
                self.step(.background)
                self.session.stopRunning()
                done.resume()
            }
        }
    }

    public func press() { queue.async { self.step(.press) } }
    public func release() { queue.async { self.step(.release) } }
    public func switchCamera() { queue.async { self.step(.switchCamera) } }
    public func deleteLast() { queue.async { self.step(.deleteLast) } }
    public func goToEdit() { queue.async { self.step(.goToEdit) } }

    public func setTorch(_ on: Bool) {
        queue.async {
            guard let device = self.camera?.device, device.hasTorch, (try? device.lockForConfiguration()) != nil else { return }
            device.torchMode = on ? .on : .off
            device.unlockForConfiguration()
            self.state.torchOn = on
            self.publish()
        }
    }

    /// `factor` is the camera's zoom factor, 1 for no zoom, clamped to what the camera allows and at most 8.
    public func setZoom(_ factor: Double) {
        queue.async {
            guard let device = self.camera?.device, (try? device.lockForConfiguration()) != nil else { return }
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
                self.state.access = .authorized
                self.state.microphoneOn = microphone
                self.configure(microphone: microphone)
                guard self.wanted, !self.inBackground, self.state.phase == .idle else { return self.publish() }
                self.session.startRunning()
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

    private func configure(microphone: Bool) {
        guard !configured else { return }
        configured = true
        session.beginConfiguration()
        if session.canSetSessionPreset(.hd1920x1080) { session.sessionPreset = .hd1920x1080 }
        if let input = Self.input(state.position), session.canAddInput(input) {
            session.addInput(input)
            camera = input
        }
        if microphone, let device = AVCaptureDevice.default(for: .audio), let input = try? AVCaptureDeviceInput(device: device),
           session.canAddInput(input) {
            session.addInput(input)
        }
        if session.canAddOutput(output) { session.addOutput(output) }
        session.commitConfiguration()
        setUpConnection()
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

    private func step(_ event: RecorderEvent) {
        let (phase, effects) = recorderStep(state.phase, event, state.list)
        state.phase = phase
        for effect in effects { apply(effect) }
        // A background or stop that came while a file was finishing takes effect once it is done.
        if phase == .ready, !wanted || inBackground { return step(.background) }
        publish()
    }

    private func apply(_ effect: RecorderEffect) {
        switch effect {
        case .startFile(let maxDuration):
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
            session.stopRunning()
        case .openEdit:
            wanted = false
            state.handoff = state.list.segments
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
        let current = output.isRecording ? output.recordedDuration.seconds : 0
        state.progress = min(1, (state.list.total + (current.isFinite ? current : 0)) / SegmentList.cap)
        continuation.yield(state)
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
            watch(UIApplication.willEnterForegroundNotification, nil) { recorder in
                recorder.inBackground = false
                recorder.startSession()
            },
            // An interruption (a call, another app taking the camera) ends the clip and keeps it, as the background does.
            watch(AVCaptureSession.wasInterruptedNotification, session) { recorder in recorder.step(.background) },
            watch(AVCaptureSession.interruptionEndedNotification, session) { recorder in recorder.startSession() },
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
            if self.state.phase == .recording { self.step(atCap ? .capReached : .background) }
        }
        Task {
            let segment: Segment? = if keep { try? await Segment.measured(url) } else { nil }
            self.queue.async {
                let kept = segment.flatMap { $0.duration >= SegmentList.floor ? $0 : nil }
                if kept == nil { try? FileManager.default.removeItem(at: url) }
                self.step(.fileFinished(kept))
            }
        }
    }
}
#endif
