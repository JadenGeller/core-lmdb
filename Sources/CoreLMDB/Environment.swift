import CLMDB
import System

/// Manages access to an LMDB database environment.
///
/// This environment acts as a container for one or more named databases, coordinating transactions and access within a
/// single shared-memory map and disk file. It must be configured and opened before use.
///
/// - Warning: This type represents a low-level handle to an LMDB environment. Improper use can invalidate the handle,
/// leading to undefined behavior and potential crashes. Always ensure that the environment is properly managed
/// and remains valid throughout its lifecycle.
public struct Environment {
    
    /// The underlying LMDB environment handle.
    @usableFromInline 
    internal var unsafeHandle: OpaquePointer
    
    /// Initializes an existing environment from the given LMDB environment handle.
    ///
    /// - Parameter unsafeHandle: An `OpaquePointer` representing the LMDB environment handle.
    @inlinable @inline(__always)
    internal init(unsafeHandle: OpaquePointer) {
        self.unsafeHandle = unsafeHandle
    }
    
    /// Initializes a new LMDB environment handle.
    ///
    /// After initialization, configure the handle with `setMapSize(_:)`, `setMaxReaders(_:)`, and `setMaxDBs(_:)`
    /// before opening it with `open(path:mode:)` to make it ready for use.
    ///
    /// - Throws: An `LMDBError` if unable to create the environment handle.
    @inlinable @inline(__always)
    public init() throws {
        var handle: OpaquePointer?
        try LMDBError.check(mdb_env_create(&handle))
        self.unsafeHandle = handle!
    }

    /// Opens an LMDB environment with the specified path and file permissions.
    ///
    /// - Parameters:
    ///   - path: The `FilePath` representing the directory in which the database files reside.
    ///   - mode: The file permissions to set on created files and semaphores.
    ///
    /// - Throws: An `LMDBError` if opening the environment fails.
    /// - Note: If this function fails, you must call `close()` to discard environment handle.
    @inlinable
    public func open(path: FilePath, mode: FilePermissions = [.ownerReadWrite, .groupReadWrite, .otherRead]) throws {
        try path.withPlatformString { cPath in
            try LMDBError.check(mdb_env_open(unsafeHandle, cPath, UInt32(MDB_NOTLS), mode.rawValue))
        }
    }

    /// Closes the LMDB environment and releases the memory map.
    ///
    /// - Warning: This function must be called from a single thread. Using any environment-related
    ///   handles after calling this function will result in a segmentation fault (`SIGSEGV`).
    /// - Precondition: All transactions, databases, and cursors associated with the environment
    ///   must be closed before invoking this method.
    /// - Note: The environment handle is freed. Do not use it after this method is called.
    @inlinable @inline(__always)
    public func close() {
        LMDBError.cannotFail(mdb_env_close(unsafeHandle))
    }
}

extension Environment {
    
    /// Configures the memory map size for the environment.
    ///
    /// The size should be a multiple of the OS page size and as large as possible to accommodate future growth of the database.
    /// The new size takes effect immediately for the current process but will not be persisted to any others until a write transaction has been committed.
    ///
    /// - Precondition: Invoke this method after creating the environment and before its first use, or when there are no active transactions.
    /// - Parameter newValue: The size in bytes for the memory map.
    /// - Throws: An `LMDBError` if the operation fails.
    /// - Note: Any attempt to set a size smaller than the space already consumed by the environment will result in the size being set to the current size of the used space.
    @inlinable @inline(__always)
    public func setMapSize(_ newValue: Int) throws {
        try LMDBError.check(mdb_env_set_mapsize(unsafeHandle, newValue))
    }
    
    /// Sets the maximum number of reader slots in the environment's lock table.
    ///
    /// - Precondition: Invoke this method after creating the environment and before its first use.
    /// - Parameter newValue: The maximum number of reader slots.
    /// - Throws: An `LMDBError` if the operation fails.
    /// - Tip: Default is 126 slots. Increase if expecting many concurrent readers.
    @inlinable @inline(__always)
    public func setMaxReaders(_ newValue: UInt32) throws {
        try LMDBError.check(mdb_env_set_maxreaders(unsafeHandle, newValue))
    }

    /// Sets the maximum number of named databases for the environment.
    ///
    /// - Precondition: Invoke this method after creating the environment and before its first use.
    /// - Parameter newValue: The maximum number of databases.
    /// - Throws: An `LMDBError` if the operation fails.
    /// - Note: A moderate number of databases are inexpensive, but a very large number can be costly in terms of resources and
    ///   performance due to the linear search required for each database open.
    @inlinable @inline(__always)
    public func setMaxDBs(_ newValue: UInt32) throws {
        try LMDBError.check(mdb_env_set_maxdbs(unsafeHandle, newValue))
    }
}

extension Environment {
    /// The maximum size of keys supported.
    ///
    /// - Note: If data is written to a database that allows duplicate values, those values are limited to this same size too.
    @inlinable @inline(__always)
    public var maxKeySize: Int32 {
        mdb_env_get_maxkeysize(unsafeHandle)
    }
}

extension Environment {
    /// Check for stale entries in the reader lock table.
    ///
    /// - Returns: The number of stale slots that were cleared.
    @discardableResult @inlinable @inline(__always)
    public func checkReaders() throws -> Int32 {
        var dead: Int32 = -1
        mdb_reader_check(unsafeHandle, &dead)
        return dead
    }
}

extension Environment: Equatable {
    public static func ==(lhs: Environment, rhs: Environment) -> Bool {
        lhs.unsafeHandle == rhs.unsafeHandle
    }
}
