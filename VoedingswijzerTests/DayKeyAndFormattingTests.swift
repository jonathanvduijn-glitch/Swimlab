import Foundation
import Testing
@testable import Voedingswijzer

@Suite("Day keys")
struct DayKeyTests {
    @Test func weekdayStartsOnMonday() {
        #expect(DayKey(year: 2026, month: 10, day: 5).weekdayIndex == 0)
        #expect(DayKey(year: 2026, month: 10, day: 3).weekdayIndex == 5)
        #expect(DayKey(year: 2026, month: 10, day: 4).weekdayIndex == 6)
    }

    @Test func shifting() {
        let day = DayKey(year: 2026, month: 3, day: 1)
        #expect(day.shifted(by: -1) == DayKey(year: 2026, month: 2, day: 28))
        #expect(DayKey(year: 2024, month: 3, day: 1).shifted(by: -1) == DayKey(year: 2024, month: 2, day: 29))
        #expect(DayKey(year: 2026, month: 12, day: 31).shifted(by: 1) == DayKey(year: 2027, month: 1, day: 1))
        // Across the end of daylight saving time.
        #expect(DayKey(year: 2026, month: 10, day: 25).shifted(by: 1) == DayKey(year: 2026, month: 10, day: 26))
    }

    @Test func stringRoundTrip() {
        #expect(DayKey(year: 2026, month: 9, day: 7).description == "2026-09-07")
        #expect(DayKey("2026-09-07") == DayKey(year: 2026, month: 9, day: 7))
        #expect(DayKey("geen datum") == nil)
    }

    @Test func fromDateUsesCalendarTimeZone() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "Europe/Amsterdam"))
        // 23:30 UTC on 4 Oct is already 5 Oct in Amsterdam.
        let date = try #require(ISO8601DateFormatter().date(from: "2026-10-04T23:30:00Z"))
        #expect(DayKey(date, calendar: calendar) == Fixtures.monday)
    }
}

@Suite("Formatting")
struct FormattingTests {
    @Test func jsRoundRoundsHalvesUp() {
        #expect(jsRound(2.5) == 3)
        #expect(jsRound(-2.5) == -2)
        #expect(jsRound(275.5) == 276)
        #expect(jsRound(2.4999) == 2)
    }

    @Test(arguments: [
        (2600.0, 0, "2.600"),
        (782, 0, "782"),
        (0.7109, 1, "0,7"),
        (1.2564, 1, "1,3"),
        (2.0, 1, "2"),
        (1234567, 0, "1.234.567"),
        (-936, 0, "-936"),
        (662.85, 0, "663"),
        (-0.4, 0, "0"), // the prototype shows "-0" here; a display glitch, not a rule
        (12.25, 2, "12,25"),
        (0.05, 1, "0,1"),
    ])
    func dutchNumbers(value: Double, digits: Int, expected: String) {
        #expect(DutchNumber.format(value, digits: digits) == expected)
    }
}
