import Foundation

/// Stable FNV-1a hashing for seeds and persistence keys. Swift's `Hasher` is
/// intentionally random between launches, so it must not drive level layouts.
enum StableSeed {
    static func make(_ text: String) -> UInt64 {
        text.utf8.reduce(1_469_598_103_934_665_603) { value, byte in
            (value ^ UInt64(byte)) &* 1_099_511_628_211
        }
    }
}
