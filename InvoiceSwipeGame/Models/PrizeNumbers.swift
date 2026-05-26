import Foundation

struct PrizeNumbers {
    let special: String   // 特別獎 – 全 8 碼
    let grand: String     // 特獎   – 全 8 碼
    let first: String     // 頭獎   – 全 8 碼

    static var placeholder: PrizeNumbers {
        PrizeNumbers(special: "--------", grand: "--------", first: "--------")
    }

    /// Trailing 3/4/5/6/7 digits derived from first prize (for HUD display)
    var sixthSuffix:  String { String(first.suffix(3)) }
    var fifthSuffix:  String { String(first.suffix(4)) }
    var fourthSuffix: String { String(first.suffix(5)) }
}
