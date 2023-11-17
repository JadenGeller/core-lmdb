import CLMDB

/// The statistics of either a database or an environment.
public struct Statistics {
    /// The underlying `MDB_stat` structure from the LMDB C library.
    @usableFromInline
    internal var base: MDB_stat
    
    /// Initializes a new `Statistics` instance with the given `MDB_stat` structure.
    ///
    /// - Parameter base: The `MDB_stat` structure containing the database statistics.
    @inlinable @inline(__always)
    internal init(base: MDB_stat) {
        self.base = base
    }
    
    /// The size of a database page in bytes.
    ///
    /// - Note: This value is consistent across all databases in the environment.
    @inlinable @inline(__always)
    public var pageSize: UInt32 {
        base.ms_psize
    }
    
    /// The depth (height) of the B-tree structure of the database.
    @inlinable @inline(__always)
    public var treeDepth: UInt32 {
        base.ms_depth
    }
    
    /// The number of internal (non-leaf) pages in the B-tree.
    @inlinable @inline(__always)
    public var branchPageCount: Int {
        base.ms_branch_pages
    }
    
    /// The number of leaf pages in the B-tree.
    @inlinable @inline(__always)
    public var leafPageCount: Int {
        base.ms_leaf_pages
    }
    
    /// The number of overflow pages in the database.
    ///
    /// - Tip: Overflow pages are used to store data that does not fit within the regular page size.
    @inlinable @inline(__always)
    public var overflowPageCount: Int {
        base.ms_overflow_pages
    }
    
    /// The total number of data items stored in the database.
    @inlinable @inline(__always)
    public var dataItemCount: Int {
        base.ms_entries
    }
}

extension Environment {
    /// Retrieves the statistics for the database environment.
    ///
    /// - Throws: An `LMDBError` if the operation fails.
    /// - Returns: A `Statistics` object containing the database environment statistics.
    @inlinable @inline(__always)
    public var statistics: Statistics {
        get throws {
            var base: MDB_stat = .init()
            try LMDBError.check(mdb_env_stat(unsafeHandle, &base))
            return .init(base: base)
        }
    }
}

extension Database {
    /// Retrieves the statistics for a specific database.
    ///
    /// - Parameter transaction: The `Transaction` within which to retrieve the statistics.
    /// - Throws: An `LMDBError` if the operation fails.
    /// - Returns: A `Statistics` object containing the database statistics.
    @inlinable @inline(__always)
    public func statistics(in transaction: Transaction) throws -> Statistics {
        var base: MDB_stat = .init()
        try LMDBError.check(mdb_stat(transaction.unsafeHandle, unsafeHandle, &base))
        return .init(base: base)
    }
}
