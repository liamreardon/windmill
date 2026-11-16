import AVFoundation

public enum RecorderPhase: Sendable, Equatable {
    case idle, ready, recording
    /// A file is being written out; `pressQueued` starts the next one as soon as it is done.
    case finishing(pressQueued: Bool)
}

public enum RecorderEvent: Sendable {
    case sessionStarted, press, release, capReached, background
    /// The file that was finishing, measured, or nil when it was discarded.
    case fileFinished(Segment?)
    case switchCamera, deleteLast, goToEdit
}

public enum RecorderEffect: Sendable, Equatable {
    case startFile(maxDuration: Double), stopFile, append(Segment), switchCamera, deleteLast, stopSession, openEdit
}

/// The recorder's transitions. Any pair not handled here leaves the phase as it is, with no effect, so a camera switch
/// or a delete while a file is finishing does nothing.
public func recorderStep(_ phase: RecorderPhase, _ event: RecorderEvent, _ list: SegmentList) -> (RecorderPhase, [RecorderEffect]) {
    switch (phase, event) {
    case (.idle, .sessionStarted):
        return (.ready, [])
    case (.ready, .press) where list.canRecord:
        return (.recording, [.startFile(maxDuration: list.timeLeft)])
    case (.recording, .release), (.recording, .background):
        return (.finishing(pressQueued: false), [.stopFile])
    case (.recording, .capReached):
        // The output stopped the file itself at maxRecordedDuration.
        return (.finishing(pressQueued: false), [])
    case (.finishing, .press):
        return (.finishing(pressQueued: true), [])
    case (.finishing, .release), (.finishing, .background):
        // A background, a stop or an interruption drops a press that was waiting.
        return (.finishing(pressQueued: false), [])
    case let (.finishing(pressQueued), .fileFinished(segment)):
        var after = list
        var effects: [RecorderEffect] = []
        if let segment, after.append(segment) { effects.append(.append(segment)) }
        guard pressQueued, after.canRecord else { return (.ready, effects) }
        return (.recording, effects + [.startFile(maxDuration: after.timeLeft)])
    case (.ready, .switchCamera):
        return (.ready, [.switchCamera])
    case (.ready, .deleteLast):
        return (.ready, [.deleteLast])
    case (.ready, .goToEdit) where list.total >= Edit.minimumTrim:
        return (.idle, [.stopSession, .openEdit])
    case (.ready, .background):
        return (.idle, [.stopSession])
    default:
        return (phase, [])
    }
}

/// A finished file is kept when the output reports no error, or an error that says the recording still finished
/// (the cap, an interruption, low disk).
public func keepRecordedFile(error: (any Error)?) -> Bool {
    guard let error else { return true }
    return (error as NSError).userInfo[AVErrorRecordingSuccessfullyFinishedKey] as? Bool == true
}
