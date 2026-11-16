import AVFoundation
import Foundation
import Testing
@testable import WindmillVideo

struct RecorderMachineTests {
    private func segment(_ seconds: Double) -> Segment {
        Segment(url: URL(fileURLWithPath: "/clips/\(seconds).mov"), duration: seconds)
    }

    private func list(_ durations: Double...) -> SegmentList {
        var list = SegmentList()
        for duration in durations { list.append(segment(duration)) }
        return list
    }

    @Test func segmentUnderHalfSecondRefused() {
        var list = SegmentList()
        let short = list.append(segment(0.4))
        #expect(!short)
        #expect(list.segments.isEmpty)
        let atFloor = list.append(segment(0.5))
        #expect(atFloor)
        #expect(list.total == 0.5)
    }

    @Test func removeLastTakesTheNewest() {
        var clips = list(2, 3)
        let removed = clips.removeLast()
        #expect(removed == segment(3))
        #expect(clips.segments == [segment(2)])
        var empty = SegmentList()
        let none = empty.removeLast()
        #expect(none == nil)
    }

    /// The output can end a clip a frame after its limit, so the list can pass the cap.
    @Test func pastTheCapStopsRecording() {
        let over = list(10, 5.04)
        #expect(over.timeLeft == 0)
        #expect(!over.canRecord)
        #expect(over.marks.last == 1)
        #expect(recorderStep(.ready, .press, over).1.isEmpty)
    }

    @Test func marksAreCumulativeFractions() {
        #expect(list(5, 3).marks == [1.0 / 3, 8.0 / 15])
        #expect(list(5, 3).timeLeft == 7)
    }

    @Test func pressWhileFinishingWaits() {
        let (waiting, none) = recorderStep(.finishing(pressQueued: false), .press, SegmentList())
        #expect(waiting == .finishing(pressQueued: true))
        #expect(none.isEmpty)
        let (phase, effects) = recorderStep(waiting, .fileFinished(segment(2)), SegmentList())
        #expect(phase == .recording)
        #expect(effects == [.append(segment(2)), .startFile(maxDuration: 13)])
    }

    @Test func capDuringRelease() {
        let (finishing, atCap) = recorderStep(.recording, .capReached, list(3))
        #expect(finishing == .finishing(pressQueued: false))
        #expect(atCap.isEmpty)
        let (phase, effects) = recorderStep(finishing, .release, list(3))
        #expect(phase == .finishing(pressQueued: false))
        #expect(!effects.contains(.stopFile))
    }

    @Test func backgroundWhileFinishing() {
        let (phase, effects) = recorderStep(.finishing(pressQueued: false), .background, list(3))
        #expect(phase == .finishing(pressQueued: false))
        #expect(effects.isEmpty)
        let (after, appended) = recorderStep(phase, .fileFinished(segment(2)), list(3))
        #expect(after == .ready)
        #expect(appended == [.append(segment(2))])
    }

    @Test func backgroundDropsQueuedPress() {
        let (phase, effects) = recorderStep(.finishing(pressQueued: true), .background, list(3))
        #expect(phase == .finishing(pressQueued: false))
        #expect(effects.isEmpty)
        let (after, _) = recorderStep(phase, .fileFinished(segment(2)), list(3))
        #expect(after == .ready)
    }

    @Test func switchCameraWhileFinishingIgnored() {
        let (phase, effects) = recorderStep(.finishing(pressQueued: false), .switchCamera, list(3))
        #expect(phase == .finishing(pressQueued: false))
        #expect(effects.isEmpty)
    }

    @Test func pressWithUnderHalfSecondLeftDoesNothing() {
        let full = list(10, 4.6)
        #expect(!full.canRecord)
        let (phase, effects) = recorderStep(.ready, .press, full)
        #expect(phase == .ready)
        #expect(effects.isEmpty)
    }

    @Test func goToEditNeedsOneSecond() {
        let (short, none) = recorderStep(.ready, .goToEdit, list(0.8))
        #expect(short == .ready)
        #expect(none.isEmpty)
        let (phase, effects) = recorderStep(.ready, .goToEdit, list(1.2))
        #expect(phase == .idle)
        #expect(effects == [.stopSession, .openEdit])
    }

    /// Exactly 1 s of clips goes to Edit, and exactly 0.5 s left still records, from ready and from a queued press.
    @Test func limitsAreInclusive() {
        #expect(recorderStep(.ready, .goToEdit, list(1)).0 == .idle)
        let (pressed, started) = recorderStep(.ready, .press, list(14.5))
        #expect(pressed == .recording)
        #expect(started == [.startFile(maxDuration: 0.5)])
        let (queued, effects) = recorderStep(.finishing(pressQueued: true), .fileFinished(segment(4.5)), list(10))
        #expect(queued == .recording)
        #expect(effects == [.append(segment(4.5)), .startFile(maxDuration: 0.5)])
    }

    /// The rest of the table: one row each.
    @Test func everyOtherRow() {
        let rows: [(RecorderPhase, RecorderEvent, SegmentList, RecorderPhase, [RecorderEffect])] = [
            (.idle, .sessionStarted, list(), .ready, []),
            (.ready, .press, list(4), .recording, [.startFile(maxDuration: 11)]),
            (.recording, .release, list(4), .finishing(pressQueued: false), [.stopFile]),
            (.recording, .background, list(4), .finishing(pressQueued: false), [.stopFile]),
            (.finishing(pressQueued: true), .release, list(4), .finishing(pressQueued: false), []),
            (.finishing(pressQueued: true), .fileFinished(nil), list(4), .recording, [.startFile(maxDuration: 11)]),
            (.finishing(pressQueued: true), .fileFinished(segment(1)), list(13.6), .ready, [.append(segment(1))]),
            (.finishing(pressQueued: false), .fileFinished(segment(0.3)), list(4), .ready, []),
            (.ready, .switchCamera, list(4), .ready, [.switchCamera]),
            (.ready, .deleteLast, list(4), .ready, [.deleteLast]),
            (.ready, .background, list(4), .idle, [.stopSession]),
            (.finishing(pressQueued: false), .fileFinished(nil), list(4), .ready, []),
            (.finishing(pressQueued: true), .press, list(4), .finishing(pressQueued: true), []),
        ]
        for (from, event, list, to, effects) in rows {
            let (phase, got) = recorderStep(from, event, list)
            #expect(phase == to, "\(from) on \(event)")
            #expect(got == effects, "\(from) on \(event)")
        }
    }

    /// Every pair the table does not list keeps the phase and has no effect.
    @Test func everyUnlistedPairChangesNothing() {
        func listed(_ phase: RecorderPhase, _ event: RecorderEvent) -> Bool {
            switch (phase, event) {
            case (.idle, .sessionStarted), (.ready, .press), (.ready, .switchCamera), (.ready, .deleteLast), (.ready, .goToEdit),
                 (.ready, .background), (.recording, .release), (.recording, .background), (.recording, .capReached),
                 (.finishing, .press), (.finishing, .release), (.finishing, .background), (.finishing, .fileFinished): true
            default: false
            }
        }
        let phases: [RecorderPhase] = [.idle, .ready, .recording, .finishing(pressQueued: false), .finishing(pressQueued: true)]
        let events: [RecorderEvent] = [.sessionStarted, .press, .release, .capReached, .background, .fileFinished(segment(2)),
                                       .fileFinished(nil), .switchCamera, .deleteLast, .goToEdit]
        var checked = 0
        for phase in phases {
            for event in events where !listed(phase, event) {
                let (after, effects) = recorderStep(phase, event, list(4))
                #expect(after == phase, "\(phase) on \(event)")
                #expect(effects.isEmpty, "\(phase) on \(event)")
                checked += 1
            }
        }
        #expect(checked == 31)
    }

    @Test func keepRule() {
        func error(_ userInfo: [String: Any]) -> NSError {
            NSError(domain: AVFoundationErrorDomain, code: AVError.maximumDurationReached.rawValue, userInfo: userInfo)
        }
        #expect(keepRecordedFile(error: nil))
        #expect(keepRecordedFile(error: error([AVErrorRecordingSuccessfullyFinishedKey: true])))
        #expect(!keepRecordedFile(error: error([AVErrorRecordingSuccessfullyFinishedKey: false])))
        #expect(!keepRecordedFile(error: error([:])))
    }
}
