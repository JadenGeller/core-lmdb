import CLMDB

/// Represents the configuration for a database within an LMDB environment.
public struct DatabaseConfig: Hashable, Sendable {
    /// Represents the sort order for keys and duplicate values in the database.
    public enum SortOrder: Hashable, Sendable {
        /// Sorted in standard lexicographic order.
        case standard
        
        /// Sorted in reverse lexicographic order.
        case reverse
        
        /// Sorted as binary integers in native byte order.
        ///
        /// - Note: Keys must all be the same size.
        case integer
    }
    
    /// Represents the configuration for handling duplicate keys in the database.
    public struct DuplicateHandling: Hashable, Sendable {
        /// The sort order for duplicate values.
        public var sortOrder: SortOrder
        
        /// Indicates whether all duplicate values have the same size, allowing for further optimizations in storage and retrieval.
        ///
        /// - Tip: If true, cursor operations may be used to retrieve multiple items at once.
        public var fixedSize: Bool
        
        /// Initializes a new configuration for handling duplicate keys.
        /// - Parameters:
        ///   - sortOrder: The sort order for duplicate values.
        ///   - fixedSize: A Boolean value indicating whether all duplicate values have the same size.
        @inlinable @inline(__always)
        public init(sortOrder: SortOrder = .standard, fixedSize: Bool = false) {
            self.sortOrder = sortOrder
            self.fixedSize = fixedSize
        }
    }
    
    /// The sort order for keys in the database.
    public var sortOrder: SortOrder
    /// The configuration for handling duplicate keys, if duplicates are allowed.
    ///
    /// - Note: If duplicates are allowed, the maximum data size is limited to the maximum key size.
    public var duplicateHandling: DuplicateHandling?
    
    /// Initializes a new database configuration with the specified key sorting and duplicate handling options.
    /// - Parameters:
    ///   - sortOrder: The sort order for keys in the database.
    ///   - duplicateConfiguration: An optional configuration for handling duplicate keys.
    /// - Throws: An error if an invalid configuration is provided.
    @inlinable @inline(__always)
    public init(sortOrder: SortOrder = .standard, duplicateHandling: DuplicateHandling? = nil) {
        self.sortOrder = sortOrder
        self.duplicateHandling = duplicateHandling
    }
}

extension DatabaseConfig.SortOrder {
    @inlinable @inline(__always)
    internal var rawKeyValue: Int32 {
        switch self {
        case .reverse:
            return MDB_REVERSEKEY
        case .integer:
            return MDB_INTEGERKEY
        case .standard:
            return 0
        }
    }
    
    @inlinable @inline(__always)
    internal init(rawKeyValue: Int32) {
        if rawKeyValue & MDB_REVERSEKEY != 0 {
            self = .reverse
        } else if rawKeyValue & MDB_INTEGERKEY != 0 {
            self = .integer
        } else {
            self = .standard
        }
    }

    @inlinable @inline(__always)
    internal var rawDupValue: Int32 {
        switch self {
        case .reverse:
            return MDB_REVERSEDUP
        case .integer:
            return MDB_INTEGERDUP
        case .standard:
            return 0
        }
    }

    @inlinable @inline(__always)
    internal init(rawDupValue: Int32) {
        if rawDupValue & MDB_REVERSEDUP != 0 {
            self = .reverse
        } else if rawDupValue & MDB_INTEGERDUP != 0 {
            self = .integer
        } else {
            self = .standard
        }
    }
}

extension DatabaseConfig.DuplicateHandling {
    @inlinable @inline(__always)
    internal var rawValue: Int32 {
        MDB_DUPSORT | sortOrder.rawDupValue | (fixedSize ? MDB_DUPFIXED : 0)
    }

    @inlinable @inline(__always)
    internal init?(rawValue: Int32) {
        guard rawValue & MDB_DUPSORT != 0 else { return nil }
        self.init(
            sortOrder: DatabaseConfig.SortOrder(rawDupValue: rawValue),
            fixedSize: rawValue & MDB_DUPFIXED != 0
        )
    }
}

extension DatabaseConfig: RawRepresentable {
    @inlinable @inline(__always)
    public var rawValue: Int32 {
        sortOrder.rawKeyValue | (duplicateHandling?.rawValue ?? 0)
    }

    @inlinable @inline(__always)
    public init(rawValue: Int32) {
        self.init(
            sortOrder: .init(rawKeyValue: rawValue),
            duplicateHandling: .init(rawValue: rawValue)
        )
    }
}
