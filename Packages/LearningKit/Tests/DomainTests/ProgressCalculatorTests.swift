import Testing
@testable import Domain

@Suite("Progress calculation")
struct ProgressCalculatorTests {
    @Test("Rounds to the nearest whole percent", arguments: [
        (completed: 0, total: 20, expected: 0),
        (completed: 13, total: 20, expected: 65),
        (completed: 6, total: 16, expected: 38),
        (completed: 7, total: 28, expected: 25),
        (completed: 1, total: 3, expected: 33),
        (completed: 2, total: 3, expected: 67),
        (completed: 20, total: 20, expected: 100),
    ])
    func percentage(completed: Int, total: Int, expected: Int) {
        #expect(ProgressCalculator.percentage(completed: completed, total: total) == expected)
    }

    @Test("A course without lessons is 0%, never a division by zero")
    func emptyCourse() {
        #expect(ProgressCalculator.percentage(completed: 0, total: 0) == 0)
    }

    @Test("Out-of-range input is clamped to 0...100")
    func clamping() {
        #expect(ProgressCalculator.percentage(completed: -3, total: 10) == 0)
        #expect(ProgressCalculator.percentage(completed: 15, total: 10) == 100)
    }
}
