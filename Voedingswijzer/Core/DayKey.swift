import Foundation

/// A calendar day without time or time zone, like the prototype's "yyyy-MM-dd" keys.
struct DayKey: Hashable, Comparable, Codable, Sendable, CustomStringConvertible {
    let year: Int
    let month: Int
    let day: Int

    init(year: Int, month: Int, day: Int) {
        self.year = year
        self.month = month
        self.day = day
    }

    /// The day `date` falls on in `calendar`'s time zone.
    init(_ date: Date, calendar: Calendar = .current) {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        self.init(year: parts.year ?? 1970, month: parts.month ?? 1, day: parts.day ?? 1)
    }

    /// Parses "yyyy-MM-dd".
    init?(_ string: String) {
        let parts = string.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        self.init(year: parts[0], month: parts[1], day: parts[2])
    }

    static func today(calendar: Calendar = .current) -> DayKey {
        DayKey(Date(), calendar: calendar)
    }

    var description: String {
        String(format: "%04d-%02d-%02d", year, month, day)
    }

    /// The day `days` later (or earlier when negative).
    func shifted(by days: Int) -> DayKey {
        let calendar = Self.utcCalendar
        guard let start = calendar.date(from: DateComponents(year: year, month: month, day: day)),
              let shifted = calendar.date(byAdding: .day, value: days, to: start)
        else { return self }
        return DayKey(shifted, calendar: calendar)
    }

    /// Plan weekday with Monday = 0 … Sunday = 6.
    var weekdayIndex: Int {
        let calendar = Self.utcCalendar
        guard let date = calendar.date(from: DateComponents(year: year, month: month, day: day)) else { return 0 }
        // Calendar weekday: Sunday = 1 … Saturday = 7.
        return (calendar.component(.weekday, from: date) + 5) % 7
    }

    static func < (lhs: DayKey, rhs: DayKey) -> Bool {
        (lhs.year, lhs.month, lhs.day) < (rhs.year, rhs.month, rhs.day)
    }

    private static let utcCalendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .current
        return calendar
    }()
}
