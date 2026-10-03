import Foundation

/// Rounds like JavaScript's `Math.round`: halves round towards +∞ (so -2.5 → -2).
/// The prototype's formulas depend on this, so all Core rounding goes through here.
func jsRound(_ value: Double) -> Double {
    (value + 0.5).rounded(.down)
}

/// Formats numbers the way the prototype's `fmt()` does with `nl-NL`:
/// thousands separator ".", decimal comma, at most `digits` decimals, no trailing zeros.
enum DutchNumber {
    static func format(_ value: Double, digits: Int = 0) -> String {
        let scale = pow(10, Double(digits))
        let rounded = jsRound(value * scale) / scale
        let negative = rounded < 0
        let magnitude = abs(rounded)

        let integerPart = magnitude.rounded(.down)
        var fraction = ""
        if digits > 0 {
            let fractionDigits = Int(jsRound((magnitude - integerPart) * scale))
            fraction = String(fractionDigits)
            fraction = String(repeating: "0", count: max(0, digits - fraction.count)) + fraction
            while fraction.hasSuffix("0") { fraction.removeLast() }
        }

        var digitsText = String(Int(integerPart))
        var grouped = ""
        while digitsText.count > 3 {
            grouped = "." + String(digitsText.suffix(3)) + grouped
            digitsText.removeLast(3)
        }
        grouped = digitsText + grouped

        let sign = negative && (integerPart > 0 || !fraction.isEmpty) ? "-" : ""
        return sign + grouped + (fraction.isEmpty ? "" : "," + fraction)
    }
}
