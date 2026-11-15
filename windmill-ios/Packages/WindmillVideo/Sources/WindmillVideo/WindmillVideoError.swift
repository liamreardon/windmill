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
            "This video is \(Self.seconds(duration)); Windmill needs at least \(Self.seconds(minimum))."
        case .exportFailed(let underlying): "The video couldn't be exported: \(underlying.localizedDescription)"
        case .exportTooLarge(let bytes, let limit):
            "The exported video is \(Self.megabytes(bytes)); the limit is \(Self.megabytes(limit))."
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .cameraDenied: "Turn on Camera for Windmill in Settings, or pick a video from Photos."
        case .microphoneDenied: "Turn on Microphone for Windmill in Settings."
        case .cameraUnavailable: "Pick a video from Photos instead."
        case .sourceTooShort(_, let minimum): "Record or pick a video of at least \(Self.seconds(minimum))."
        case .exportFailed: "Try again. If it keeps failing, pick another video."
        case .exportTooLarge(let bytes, let limit):
            "Use a shorter trim: this video is \(Self.megabytes(bytes)) and the limit is \(Self.megabytes(limit))."
        }
    }

    /// "0.6 s", "1 s".
    static func seconds(_ value: Double) -> String { oneDecimal(value) + " s" }

    /// Binary megabytes: "58.4 MB", "50 MB".
    static func megabytes(_ bytes: Int) -> String { oneDecimal(Double(bytes) / 1_048_576) + " MB" }

    private static func oneDecimal(_ value: Double) -> String {
        let text = String(format: "%.1f", value)
        return text.hasSuffix(".0") ? String(text.dropLast(2)) : text
    }
}
