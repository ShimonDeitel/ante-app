import Foundation

enum Money {
    static func format(cents: Int) -> String {
        let value = Double(cents) / 100
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        // Pin the locale: on non-US devices "US$5" reads like a foreign
        // charge; the app is USD-only so always render plain "$5".
        formatter.locale = Locale(identifier: "en_US")
        formatter.maximumFractionDigits = value.truncatingRemainder(dividingBy: 1) == 0 ? 0 : 2
        return formatter.string(from: NSNumber(value: value)) ?? "$\(value)"
    }
}
