import CoreText
import Foundation
import Testing
@testable import WindmillVideo

struct EditTests {
    private func segment(_ seconds: Double) -> Segment {
        Segment(url: URL(filePath: "/clips/\(seconds).mov"), duration: seconds)
    }

    @Test func trimStartsAtFifteenSeconds() throws {
        let edit = try Edit(segments: [segment(10), segment(8)])
        #expect(edit.trim == 0...15)
        #expect(edit.total == 18)
    }

    @Test func tooShortThrows() {
        do {
            _ = try Edit(segments: [segment(0.6)])
            Issue.record("expected sourceTooShort")
        } catch let error as WindmillVideoError {
            guard case .sourceTooShort(let duration, let minimum) = error else {
                Issue.record("wrong case \(error)")
                return
            }
            #expect(duration == 0.6)
            #expect(minimum == 1)
            let text = error.errorDescription ?? ""
            #expect(text.contains("0.6 s"))
            #expect(text.contains("1 s"))
        } catch {
            Issue.record("unexpected \(error)")
        }
    }

    @Test func setTrimClamps() throws {
        var edit = try Edit(segments: [segment(10), segment(8)])
        edit.setTrim(17...20)
        #expect(edit.trim == 17...18)
        edit.setTrim(4...4.2)
        #expect(edit.trim == 4...5)
        edit.setTrim(0...16)
        #expect(edit.trim == 0...15)
    }

    @Test func exportTooLargeTextHasBothSizes() {
        let error = WindmillVideoError.exportTooLarge(bytes: 61_200_000, limit: 52_428_800)
        let text = error.recoverySuggestion ?? ""
        #expect(text.contains("58.4 MB"))
        #expect(text.contains("50 MB"))
        #expect(text.contains("trim"))
    }

    @Test func sizesNearTheBoundStayTrue() {
        let short = WindmillVideoError.sourceTooShort(duration: 0.96, minimum: 1).failureReason ?? ""
        #expect(short.contains("0.9 s"), "\(short)")
        let large = WindmillVideoError.exportTooLarge(bytes: 52_428_801, limit: 52_428_800).failureReason ?? ""
        #expect(large.contains("50.1 MB"), "\(large)")
        let odd = WindmillVideoError.exportTooLarge(bytes: 50_000_001, limit: 50_000_000).failureReason ?? ""
        #expect(odd.contains("limit is 47.6 MB"), "\(odd)")
    }

    @Test func everyCaseHasReasonAndSuggestion() {
        let all: [WindmillVideoError] = [
            .cameraDenied, .microphoneDenied, .cameraUnavailable,
            .sourceTooShort(duration: 0.6, minimum: 1),
            .exportFailed(underlying: CocoaError(.fileWriteUnknown)),
            .exportTooLarge(bytes: 61_200_000, limit: 52_428_800),
        ]
        for error in all {
            #expect(!(error.failureReason ?? "").isEmpty)
            #expect(!(error.recoverySuggestion ?? "").isEmpty)
        }
    }

    @Test func lexendRegisters() {
        Fonts.registerOnce()
        let font = CTFontCreateWithName(Fonts.lexendFamily as CFString, 20, nil)
        let name = CTFontCopyPostScriptName(font) as String
        #expect(name.hasPrefix("Lexend"))
    }
}
