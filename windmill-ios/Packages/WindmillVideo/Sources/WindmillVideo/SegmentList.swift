/// The clips recorded so far, in order, under the 15 second cap.
public struct SegmentList: Sendable, Hashable {
    public static let cap = 15.0
    /// The shortest clip kept, and the least time left that still lets the record button start one.
    public static let floor = 0.5

    public private(set) var segments: [Segment] = []

    public init() {}

    /// Adds `segment` unless it is under the floor; returns whether it was added.
    @discardableResult
    public mutating func append(_ segment: Segment) -> Bool {
        guard segment.duration >= Self.floor else { return false }
        segments.append(segment)
        return true
    }

    public mutating func removeLast() -> Segment? { segments.popLast() }

    public var total: Double { segments.reduce(0) { $0 + $1.duration } }

    public var timeLeft: Double { max(0, Self.cap - total) }

    public var canRecord: Bool { timeLeft >= Self.floor }

    /// Where each clip ends, as a fraction of the cap, for the marks on the record ring.
    public var marks: [Double] {
        var end = 0.0
        return segments.map { segment in
            end += segment.duration
            return end / Self.cap
        }
    }
}
