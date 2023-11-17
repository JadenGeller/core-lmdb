import CLMDB

/// Manages a transaction within an LMDB environment.
///
/// Transactions in LMDB can be read-only or read-write and support nested transactions.
///
/// - Warning: Write transactions and their cursors must only be used by a single POSIX thread.
public struct Transaction {
    
    /// The underlying LMDB transaction handle.
    @usableFromInline
    internal var unsafeHandle: OpaquePointer
    
    /// Initializes an existing transaction from the given LMDB transaction handle.
    ///
    /// - Parameter unsafeHandle: An `OpaquePointer` representing the LMDB transaction handle.
    @inlinable @inline(__always)
    internal init(unsafeHandle: OpaquePointer) {
        self.unsafeHandle = unsafeHandle
    }
    
    /// Represents the kind of transaction to be performed.
    public enum Kind: Hashable, Sendable {
        /// A read-only transaction.
        case read
        /// A read-write transaction.
        case write
    }
    
    /// Begins a new transaction within the specified environment.
    ///
    /// - Parameters:
    ///   - kind: The kind of transaction to begin, either `.read` for a read-only transaction or `.write` for a read-write transaction.
    ///   - env: The `Environment` in which to begin the transaction.
    ///   - parent: An optional parent transaction for creating nested transactions. Defaults to `nil`.
    /// - Throws: An `LMDBError` if the transaction cannot be started.
    /// - Returns: A `Transaction` instance representing the new transaction.
    /// - Warning: Write transactions and their cursors must only be used by a single POSIX thread.
    @inlinable
    public static func begin(_ kind: Kind, in env: Environment, nestingWithin parent: Transaction? = nil) throws -> Transaction {
        var handle: OpaquePointer?
        try LMDBError.check(mdb_txn_begin(env.unsafeHandle, parent?.unsafeHandle, (kind == .read) ? UInt32(MDB_RDONLY) : 0, &handle))
        return Transaction(unsafeHandle: handle!)
    }
    
    /// Commits all the operations of a transaction into the database.
    ///
    /// - Throws: An `LMDBError` if committing the transaction fails.
    /// - Warning: The transaction handle is freed after this call and must not be used again.
    @inlinable @inline(__always)
    public func commit() throws {
        try LMDBError.check(mdb_txn_commit(unsafeHandle))
    }
    
    /// Abandons all the operations of the transaction instead of saving them.
    ///
    /// - Warning: The transaction handle is freed after this call and must not be used again.
    @inlinable @inline(__always)
    public func abort() {
        LMDBError.cannotFail(mdb_txn_abort(unsafeHandle))
    }
    
    /// Aborts a read-only transaction, but keeps the handle for later reuse with `renew()`.
    ///
    /// - Precondition: The transaction is read-only.
    /// - Tip: This saves allocation overhead if a new read-only transaction will be started soon.
    @inlinable @inline(__always)
    public func reset() {
        LMDBError.cannotFail(mdb_txn_reset(unsafeHandle))
    }
    
    /// Begins a read-only transaction, reusing a previously reset handle.
    ///
    /// - Precondition: The transaction is read-only and has been reset.
    /// - Throws: An `LMDBError` if renewing the transaction fails.
    @inlinable @inline(__always)
    public func renew() throws {
        try LMDBError.check(mdb_txn_renew(unsafeHandle))
    }
}

extension Environment {
    /// Executes a transactional block of code, committing the transaction if the block succeeds, or aborting if an error is thrown.
    ///
    /// - Parameters:
    ///   - kind: The kind of transaction to begin, either `.read` for a read-only transaction or `.write` for a read-write transaction.
    ///   - block: A closure that performs the work within the transaction. The value it returns is returned by the function.
    /// - Throws: An `LMDBError` if the transaction cannot be started, or any error thrown by the `block`.
    /// - Returns: The value returned by the `block`.
    /// - Warning: Do not manually commit or abort the transaction in the `block`. Use it only to perform operations.
    @inlinable
    public func withTransaction<T>(_ kind: Transaction.Kind, _ block: (Transaction) throws -> T) throws -> T {
        let transaction = try Transaction.begin(kind, in: self)
        do {
            let value = try block(transaction)
            try transaction.commit()
            return value
        } catch {
            transaction.abort()
            throw error
        }
    }
}

extension Transaction {
    /// The environment in which the transaction was created.
    @inlinable @inline(__always)
    public var environment: Environment {
        Environment(unsafeHandle: mdb_txn_env(unsafeHandle)!)
    }
    
    /// The transaction's ID.
    ///
    /// - Note: For a read-only transaction, this corresponds to the snapshot being read.
    ///   Concurrent readers will frequently have the same transaction ID.
    @inlinable @inline(__always)
    public var id: Int {
        mdb_txn_id(unsafeHandle)
    }
}
