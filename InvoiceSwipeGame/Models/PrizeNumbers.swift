import Foundation

struct PrizeNumbers {
    let special: String   // 特別獎 – 全 8 碼
    let grand: String     // 特獎   – 全 8 碼
    let first1: String    // 頭獎①  – 全 8 碼
    let first2: String    // 頭獎②  – 全 8 碼
    let first3: String    // 頭獎③  – 全 8 碼

    /// 三組頭獎集合，方便遍歷對獎
    var firsts: [String] { [first1, first2, first3] }

    static var placeholder: PrizeNumbers {
        PrizeNumbers(
            special: "--------",
            grand:   "--------",
            first1:  "--------",
            first2:  "--------",
            first3:  "--------"
        )
    }
}
