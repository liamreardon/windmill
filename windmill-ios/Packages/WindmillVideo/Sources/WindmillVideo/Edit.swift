import CoreGraphics
import Foundation

/// One recorded clip, or the one video picked from Photos.
public struct Segment: Sendable, Hashable {
    public let url: URL
    /// Seconds, measured on the finished file.
    public let duration: Double

    public init(url: URL, duration: Double) {
        self.url = url
        self.duration = duration
    }
}

public struct OverlayColor: Sendable, Hashable {
    public var red, green, blue, alpha: Double

    public init(red: Double, green: Double, blue: Double, alpha: Double = 1) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }

    public static let white = OverlayColor(red: 1, green: 1, blue: 1)
}

/// Text laid over the video, set in Lexend.
// ponytail: no start and end times in Stage 0; every overlay spans the trimmed clip. The Text timing row adds them.
public struct TextOverlay: Sendable, Hashable, Identifiable {
    public var id: UUID
    public var text: String
    /// The text's centre as a fraction of the frame, origin top left.
    public var center: CGPoint
    /// The line height as a fraction of the frame height.
    public var height: Double
    public var color: OverlayColor

    public init(id: UUID = UUID(), text: String, center: CGPoint, height: Double, color: OverlayColor = .white) {
        self.id = id
        self.text = text
        self.center = center
        self.height = height
        self.color = color
    }
}

/// The segments in order, a trim on their joined timeline, and the text overlays.
public struct Edit: Sendable, Hashable {
    public static let minimumTrim = 1.0
    public static let cap = 15.0

    public let segments: [Segment]
    /// Seconds on the joined timeline.
    public private(set) var trim: ClosedRange<Double>
    public var overlays: [TextOverlay] = []

    public var total: Double { segments.reduce(0) { $0 + $1.duration } }

    /// Throws `WindmillVideoError.sourceTooShort` under 1 second. The trim starts as the first 15 seconds.
    public init(segments: [Segment]) throws {
        let total = segments.reduce(0) { $0 + $1.duration }
        guard total >= Self.minimumTrim else {
            throw WindmillVideoError.sourceTooShort(duration: total, minimum: Self.minimumTrim)
        }
        self.segments = segments
        self.trim = 0...min(total, Self.cap)
    }

    /// Clamps to the clips and to a length of 1 to 15 seconds.
    public mutating func setTrim(_ range: ClosedRange<Double>) {
        var lower = max(0, range.lowerBound)
        var upper = min(total, range.upperBound)
        if upper - lower > Self.cap { upper = lower + Self.cap }
        if upper - lower < Self.minimumTrim {
            upper = min(total, lower + Self.minimumTrim)
            lower = max(0, upper - Self.minimumTrim)
        }
        trim = lower...upper
    }
}
