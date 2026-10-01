import Foundation

/// All Tasks is a filter, not a stored category. Work, Personal, and custom names are categories.
public enum CategoryFilterLabel: Sendable {
    public static let allTasks = "All Tasks"

    public static func title(selectedName: String?) -> String {
        guard let name = selectedName?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty else {
            return allTasks
        }
        return name
    }
}
