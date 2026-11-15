import Testing
@testable import WindmillVideo

struct LimitsTests {
    @Test func maxBytes() {
        #expect(Exporter.maxBytes == 52_428_800)
    }
}
