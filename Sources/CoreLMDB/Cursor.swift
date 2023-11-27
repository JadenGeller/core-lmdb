import CLMDB

/// A cursor for navigating through a database.
public struct Cursor<KeyCoder: ByteCoder, ValueCoder: ByteCoder> {
    /// The type of database with `Schema` compatible with this cursor.
    public typealias Database = CoreLMDB.Database<KeyCoder, ValueCoder>
    
    /// The underlying LMDB cursor handle.
    @usableFromInline
    internal var unsafeHandle: OpaquePointer?
    
    /// The `Schema` to use to encode and decode keys and values in the Database.
    public let schema: Database.Schema

    /// Creates a cursor for a given transaction and database.
    ///
    /// - Parameters:
    ///   - database: The database for which to create the cursor.
    ///   - schema: The `Schema` to use to encode and decode keys and values.
    ///   - transaction: The transaction within which to create the cursor.
    ///
    /// - Throws: An `LMDBError` if the cursor could not be created.
    /// - Note: Cursor must not be used when its database handle is closed, nor when its transaction has ended, except with `renew()`.
    ///   If in a write transaction, the cursor may be closed before the transaction ends, but it will otherwise be closed automatically.
    ///   If in a read transaction, the cursor must be closed explicitly, but it doesn't need to be closed before the transaction ends.
    @inlinable @inline(__always)
    public init(for database: Database, in transaction: Transaction) throws {
        var cursor: OpaquePointer?
        try LMDBError.check(mdb_cursor_open(transaction.unsafeHandle, database.unsafeHandle, &cursor))
        self.unsafeHandle = cursor
        self.schema = database.schema
    }
    
    /// Closes the cursor.
    ///
    /// - Precondition: The cursor's transaction must still be live if it is a write-transaction.
    /// - Note: If in a write transaction, the cursor may be closed before the transaction ends, but it will otherwise be closed automatically.
    ///   If in a read transaction, the cursor must be closed explicitly, but it doesn't need to be closed before the transaction ends.
    @inlinable @inline(__always)
    public func close() {
        mdb_cursor_close(unsafeHandle)
    }
    
    /// Renews a cursor for use with a new transaction.
    ///
    /// - Parameter transaction: The new transaction handle.
    /// - Throws: An `LMDBError` if the cursor could not be renewed.
    /// - Precondition: The cursor's transaction is read-only.
    @inlinable @inline(__always)
    public func renew(for transaction: Transaction) throws {
        try LMDBError.check(mdb_cursor_renew(transaction.unsafeHandle, unsafeHandle))
    }
}

extension Cursor {
    /// The transaction associated with the cursor.
    @inlinable @inline(__always)
    public var transaction: Transaction {
        Transaction(unsafeHandle: mdb_cursor_txn(unsafeHandle))
    }
    
    /// The database associated with the cursor.
    @inlinable @inline(__always)
    public var database: Database {
        Database(unsafeHandle: mdb_cursor_dbi(unsafeHandle), schema: schema)
    }
}

// TODO: Provide methods to read key without value by passing `nil` for value?

extension Cursor {
    /// Moves the cursor to an absolute position within the database and retrieves the key and value at that position.
    ///
    /// - Parameters:
    ///   - position: The absolute position to move the cursor to.
    ///   - target: The target of the move operation, either a key or a duplicate value of the current key. Defaults to `.key`.
    /// - Returns: A  pair containing the key and value at the cursor's new position, or `nil` if not found.
    /// - Throws: An `LMDBError` if the operation fails.
    /// - Warning: The returned buffer pointer is owned by the database and only valid until the next update operation or the end of the transaction. Do not deallocate.
    ///   You usually don't need to worry about this, unless you're using a decoder like `RawByteCoder` that exposes the buffer.
    /// - Note: If `target` is `.value`, the `key` returned will not be valid—only the `value` will be. If you need the key as well, use `get()`.
    @discardableResult @inlinable @inline(__always) @_specialize(where KeyCoder == RawByteCoder, ValueCoder == RawByteCoder)
    public func get(_ position: AbsoluteCursorPosition, target: CursorTarget = .key) throws -> (key: KeyCoder.Output, value: ValueCoder.Output)? {
        let operation = switch (position, target) {
        case (.first, .key):   MDB_FIRST
        case (.first, .value): MDB_FIRST_DUP
        case (.last, .key):    MDB_LAST
        case (.last, .value):  MDB_LAST_DUP
        }
        var key = MDB_val()
        var value = MDB_val()
        return try LMDBError.nilIfNotFound {
            try LMDBError.check(mdb_cursor_get(unsafeHandle, &key, &value, operation))
            return try (
                key: schema.keyCoder.decoding(.init(key)),
                value: schema.valueCoder.decoding(.init(value))
            )
        }
    }
    
    /// Moves the cursor to a relative position from its current location within the database and retrieves the key and value at that position.
    ///
    /// - Parameters:
    ///   - position: The relative position to move the cursor to.
    ///   - target: An optional target of the move operation, which can be `.key` or `.value`. If `nil`, the cursor moves to the next or previous entry without considering duplicates.
    /// - Returns: A pair containing the key and value at the cursor's new position, or `nil` if not found.
    /// - Throws: An `LMDBError` if the operation fails.
    /// - Warning: The returned buffer pointer is owned by the database and only valid until the next update operation or the end of the transaction. Do not deallocate.
    ///   You usually don't need to worry about this, unless you're using a decoder like `RawByteCoder` that exposes the buffer.
    @discardableResult @inlinable @inline(__always) @_specialize(where KeyCoder == RawByteCoder, ValueCoder == RawByteCoder)
    public func get(_ position: RelativeCursorPosition, target: CursorTarget? = nil) throws -> (key: KeyCoder.Output, value: ValueCoder.Output)? {
        let operation = switch (position, target) {
        case (.next, nil):        MDB_NEXT
        case (.next, .key):       MDB_NEXT_NODUP
        case (.next, .value):     MDB_NEXT_DUP
        case (.previous, nil):    MDB_PREV
        case (.previous, .key):   MDB_PREV_NODUP
        case (.previous, .value): MDB_PREV_DUP
        }
        var key = MDB_val()
        var value = MDB_val()
        return try LMDBError.nilIfNotFound {
            try LMDBError.check(mdb_cursor_get(unsafeHandle, &key, &value, operation))
            return try (
                key: schema.keyCoder.decoding(.init(key)),
                value: schema.valueCoder.decoding(.init(value))
            )
        }
    }
    
    /// Moves the cursor to a specified key, with an optional duplicate value, using the specified precision and retrieves the key and value at that position.
    ///
    /// - Parameters:
    ///   - key: The key to move the cursor to.
    ///   - value: An optional duplicate value to move the cursor to. If `nil`, only the key is considered.
    ///   - precision: The precision of the move operation, either `.exactly` for an exact match or `.nearby` for the nearest match.
    /// - Returns: A pair containing the key and value at the cursor's new position, or `nil` if not found.
    /// - Throws: An `LMDBError` if the operation fails.
    /// - Warning: The returned buffer pointer is owned by the database and only valid until the next update operation or the end of the transaction. Do not deallocate.
    ///   You usually don't need to worry about this, unless you're using a decoder like `RawByteCoder` that exposes the buffer.
    /// - Note: The `value` is ingnored if precision is `exactly` and the database doesn't have duplicate values.
    @discardableResult @inlinable @inline(__always) @_specialize(where KeyCoder == RawByteCoder, ValueCoder == RawByteCoder)
    public func get(atKey key: KeyCoder.Input, value: ValueCoder.Input? = nil, precision: CursorPrecision = .exactly) throws -> (key: KeyCoder.Output, value: ValueCoder.Output)? {
        // FIXME: Clarify behavior if value is specified for non-DUPSORT database
        let operation = switch (precision, value) {
        case (.exactly, .none): MDB_SET_KEY
        case (.exactly, .some): MDB_GET_BOTH
        case (.nearby, .none):  MDB_SET_RANGE
        case (.nearby, .some):  MDB_GET_BOTH_RANGE
        }
        return try schema.keyCoder.withEncoding(of: key) { key in
            try schema.valueCoder.withEncodingOrNil(of: value) { value in
                var key = MDB_val(.init(mutating: key))
                var value = value.map { MDB_val(.init(mutating: $0)) } ?? .init()
                return try LMDBError.nilIfNotFound {
                    try LMDBError.check(mdb_cursor_get(unsafeHandle, &key, &value, operation))
                    return try (
                        key: schema.keyCoder.decoding(.init(key)),
                        value: schema.valueCoder.decoding(.init(value))
                    )
                }
            }
        }
    }
}
    
extension Cursor {
    /// Retrieves a key/data pair into the database at the cursor's current position.
    ///
    /// - Returns: A pair containing the key and value at the cursor's current position, or `nil` if not found.
    /// - Throws: An `LMDBError` if the operation fails.
    /// - Warning: The returned buffer pointer is owned by the database and only valid until the next update operation or the end of the transaction. Do not deallocate.
    ///   You usually don't need to worry about this, unless you're using a decoder like `RawByteCoder` that exposes the buffer.
    @inlinable @inline(__always) @_specialize(where KeyCoder == RawByteCoder, ValueCoder == RawByteCoder)
    public func get() throws -> (key: KeyCoder.Output, value: ValueCoder.Output)? {
        var key = MDB_val()
        var value = MDB_val()
        return try LMDBError.nilIfNotFound {
            try LMDBError.check(mdb_cursor_get(unsafeHandle, &key, &value, MDB_GET_CURRENT))
            return try (
                key: schema.keyCoder.decoding(.init(key)),
                value: schema.valueCoder.decoding(.init(value))
            )
        }
    }
    
    /// Stores a key/data pair into the database, updating the cursor's position.
    ///
    /// - Parameters:
    ///   - key: The key under which to store the data.
    ///   - value: The data to store.
    ///   - overwrite: A Boolean value that determines whether to overwrite an existing value for a key. Defaults to `true`.
    /// - Throws: An `LMDBError` if the operation fails.
    /// - Precondition: The cursor's transaction must be a write transaction.
    @inlinable @inline(__always) @_specialize(where KeyCoder == RawByteCoder, ValueCoder == RawByteCoder)
    public func put(_ value: ValueCoder.Input, atKey key: KeyCoder.Input, overwrite: Bool = true) throws {
        try schema.keyCoder.withEncoding(of: key) { key in
            try schema.valueCoder.withEncoding(of: value) { value in
                var key = MDB_val(.init(mutating: key))
                var value = MDB_val(.init(mutating: value))
                try LMDBError.check(mdb_cursor_put(unsafeHandle, &key, &value, overwrite ? 0 : UInt32(MDB_NOOVERWRITE)))
            }
        }
    }
    
    
    /// Deletes data at the cursor's current position.
    ///
    /// - Parameters:
    ///   - target: If multiple values are set for the given key, you can either delete a single `value` or the entire `key`, deleting all values.
    /// - Throws: An `LMDBError` if the operation fails.
    /// - Precondition: The transaction must be a write transaction.
    /// - Note: If the key does not exist in the database, the function will throw `LMDBError.notFound`.
    @inlinable @inline(__always)
    public func delete(target: CursorTarget = .value) throws {
        try LMDBError.check(mdb_cursor_del(unsafeHandle, UInt32(target == .key ? MDB_NODUPDATA : 0)))
    }
}

extension Cursor {
    /// The number of duplicate values stored at the cursor's current key.
    @inlinable @inline(__always)
    public var duplicateCount: Int {
        get throws {
            var count = -1
            try LMDBError.check(mdb_cursor_count(unsafeHandle, &count))
            return count
        }
    }
}

extension Transaction {
    /// Executes a block of code with a cursor, closing the cursor once the block returns.
    ///
    /// - Parameters:
    ///   - database: The database for which to create the cursor.
    ///   - block: A closure that performs the work with the cursor. The value it returns is returned by the function.
    /// - Throws: An `LMDBError` if the cursor cannot be created, or any error thrown by the `block`.
    /// - Returns: The value returned by the `block`.
    @inlinable
    public func withCursor<T, KeyCoder: ByteCoder, ValueCoder: ByteCoder>(
        for database: Database<KeyCoder, ValueCoder>,
        _ block: (Cursor<KeyCoder, ValueCoder>) throws -> T
    ) throws -> T {
        let cursor = try Cursor<KeyCoder, ValueCoder>(for: database, in: self)
        defer { cursor.close() }
        return try block(cursor)
    }
}

extension Cursor: Equatable {
    public static func ==(lhs: Cursor, rhs: Cursor) -> Bool {
        lhs.unsafeHandle == rhs.unsafeHandle
    }
}
