public enum ProgressCalculator {
    /// Completion percentage rounded to the nearest whole number.
    /// Out-of-range input is clamped, and a course without lessons is 0%.
    public static func percentage(completed: Int, total: Int) -> Int {
        guard total > 0 else { return 0 }
        let clamped = min(max(completed, 0), total)
        return Int((Double(clamped) / Double(total) * 100).rounded())
    }
}
