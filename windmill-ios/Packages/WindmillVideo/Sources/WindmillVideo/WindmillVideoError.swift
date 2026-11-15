import Foundation

public enum WindmillVideoError: Error, LocalizedError {
    case cameraDenied
    case microphoneDenied
    case cameraUnavailable
    case sourceTooShort(duration: Double, minimum: Double)
    case exportFailed(underlying: any Error)
    case exportTooLarge(bytes: Int, limit: Int)

    public var errorDescription: String? { failureReason }

    public var failureReason: String? {
        switch self {
        case .cameraDenied: "Windmill can't use the camera."
        case .microphoneDenied: "Windmill can't use the microphone, so clips record without sound."
        case .cameraUnavailable: "This device has no camera Windmill can use."
        case .sourceTooShort(let duration, let minimum):
            "This video is \(Self.seconds(duration, rounded: .down)); Windmill needs at least \(Self.seconds(minimum, rounded: .up))."
        case .exportFailed(let underlying): "The video couldn't be exported: \(underlying.localizedDescription)"
        case .exportTooLarge(let bytes, let limit):
            "The exported video is \(Self.megabytes(bytes, rounded: .up)); the limit is \(Self.megabytes(limit, rounded: .down))."
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .cameraDenied: "Turn on Camera for Windmill in Settings, or pick a video from Photos."
        case .microphoneDenied: "Turn on Microphone for Windmill in Settings."
        case .cameraUnavailable: "Pick a video from Photos instead."
        case .sourceTooShort(_, let minimum): "Record or pick a video of at least \(Self.seconds(minimum, rounded: .up))."
        case .exportFailed: "Try again. If it keeps failing, pick another video."
        case .exportTooLarge(let bytes, let limit):
            "Use a shorter trim: this video is \(Self.megabytes(bytes, rounded: .up)) and the limit is \(Self.megabytes(limit, rounded: .down))."
        }
    }

    /// "0.6 s", "1 s". A size and its bound round away from each other, so 0.96 s never reads as 1 s and a file one
    /// byte over the limit never reads as the same size.
    static func seconds(_ value: Double, rounded rule: FloatingPointRoundingRule = .toNearestOrAwayFromZero) -> String {
        oneDecimal(value, rule) + " s"
    }

    /// Binary megabytes: "58.4 MB", "50 MB".
    static func megabytes(_ bytes: Int, rounded rule: FloatingPointRoundingRule = .toNearestOrAwayFromZero) -> String {
        oneDecimal(Double(bytes) / 1_048_576, rule) + " MB"
    }

    /// Runs `body`; `WindmillVideoError` and `CancellationError` pass through, anything else becomes `exportFailed`.
    static func wrapping<T>(_ body: () async throws -> T) async throws -> T {
        do {
            return try await body()
        } catch let error as WindmillVideoError {
            throw error
        } catch let error as CancellationError {
            throw error
        } catch {
            throw WindmillVideoError.exportFailed(underlying: error)
        }
    }

    private static func oneDecimal(_ value: Double, _ rule: FloatingPointRoundingRule) -> String {
        let text = String(format: "%.1f", (value * 10).rounded(rule) / 10)
        return text.hasSuffix(".0") ? String(text.dropLast(2)) : text
    }
}
