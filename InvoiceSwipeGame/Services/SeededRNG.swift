import Foundation

/// Mulberry32 – deterministic, portable seeded PRNG
struct SeededRNG {
    private var state: UInt32

    init(seed: UInt32) { state = seed }

    /// Returns a value in [0, 1)
    mutating func next() -> Double {
        state = state &+ 0x6D2B79F5
        var t = state ^ (state >> 15)
        t = t &* (state | 1)
        t ^= t &+ (t ^ (t >> 7)) &* (state | 61)
        return Double((t ^ (t >> 14)) & 0xFFFF_FFFF) / 4_294_967_296.0
    }

    mutating func nextInt(_ range: ClosedRange<Int>) -> Int {
        let span = range.upperBound - range.lowerBound + 1
        return range.lowerBound + Int(next() * Double(span))
    }

    mutating func nextElement<C: Collection>(_ col: C) -> C.Element {
        precondition(!col.isEmpty, "SeededRNG.nextElement: collection must not be empty")
        let idx = nextInt(0...col.count - 1)
        return col[col.index(col.startIndex, offsetBy: idx)]
    }

    /// Seeded from today's date  (YYYYMMDD as UInt32)
    static func dailySeed() -> UInt32 {
        let c = Calendar.current
        let d = Date()
        let y = c.component(.year,  from: d)
        let m = c.component(.month, from: d)
        let day = c.component(.day, from: d)
        return UInt32(y * 10_000 + m * 100 + day)
    }
}
