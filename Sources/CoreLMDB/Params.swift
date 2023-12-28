import CLMDB

public enum PutPrecondition {
    case uniqueKey
    case uniqueKeyValue
    
    @inlinable
    internal var rawValue: UInt32 {
        switch self {
        case .uniqueKey: UInt32(MDB_NOOVERWRITE)
        case .uniqueKeyValue: UInt32(MDB_NODUPDATA)
        }
    }
}

/// Represents the absolute position to which a cursor can move.
public enum AbsoluteCursorPosition {
    /// Moves the cursor to the first key or first duplicate of the current key, depending on `Target`.
    /// - Note: If moving to `Target.value`, only the `value` returned will be valid, not the `key`.
    case first
    
    /// Moves the cursor to the last key or last duplicate of the current key, depending on `Target`.
    /// - Note: If moving to `Target.value`, only the `value` returned will be valid, not the `key`.
    case last
}

/// Represents the relative position to which a cursor can move.
public enum RelativeCursorPosition {
    /// Moves the cursor to the next key or duplicate of the current key, depending on `Target`.
    /// If `Target` is not specified, moves to next duplicate if available, otherwise next key.
    case next
    
    /// Moves the cursor to the previous key or duplicate of the current key, depending on `Target`.
    /// If `Target` is not specified, moves to next duplicate if available, otherwise next key.
    /// - Note: If moving to `Target.key`, the value will be the first duplicate value for that key, not the last.
    case previous
}

/// Represents the target of a cursor move operation.
public enum CursorTarget {
    /// Targets unique keys in the database.
    /// In move operations, directs the cursor to unique keys, bypassing any duplicates.
    /// - Note: If the key has duplicate values, moving a `RelativePosition`—both `.next` and `.previous`
    ///   will always move to the first duplicate value for that key.
    case key
    
    /// Targets duplicate values under the current key.
    /// In move operations, directs the cursor through duplicates of the current key.
    /// - Note: If moving to `AbsolutePosition.first` or `AbsolutePosition.last`,
    /// only the `value` returned will be valid, not the `key`.
    case value
}

/// Represents the precision of a cursor move operation.
public enum CursorPrecision {
    /// The exact key or key-value pair.
    /// The cursor will move to the exact key or key-value pair if it exists in the database.
    case exactly
    
    /// The nearest key or key-value pair if an exact match is not found.
    /// The cursor will move to the nearest key or key-value pair that is greater than or equal to the specified key or key-value pair.
    case nearby
}
