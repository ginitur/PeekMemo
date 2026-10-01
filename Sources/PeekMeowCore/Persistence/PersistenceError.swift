import Foundation

public enum PersistenceError: Error, Equatable, Sendable, CustomStringConvertible {
    case databaseUnavailable(String)
    case notFound(UUID)
    case noteCannotHaveSubtask
    case cannotNestSubtask
    case notesAreNotCompletable
    case corruptIdentifier(String)

    public var description: String {
        switch self {
        case .databaseUnavailable(let message):
            "database unavailable: \(message)"
        case .notFound(let id):
            "memo item not found: \(id)"
        case .noteCannotHaveSubtask:
            "a note cannot have a subtask"
        case .cannotNestSubtask:
            "a subtask cannot contain another subtask"
        case .notesAreNotCompletable:
            "a note has no completion state"
        case .corruptIdentifier(let raw):
            "corrupt identifier: \(raw)"
        }
    }
}
