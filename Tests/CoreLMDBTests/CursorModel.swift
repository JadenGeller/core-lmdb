//import CoreLMDB
//
//struct  <Store: BidirectionalCollection> where Store.Element: BidirectionalCollection {
//    typealias Key = Store.Index
//    typealias Value = Store.Element.Element
//    
//    var store: Store
//    var focus: (key: Key, value: Value)
//}
//
//extension CursorModel {
//    @discardableResult
//    public mutating func move(to position: Cursor.AbsolutePosition, _ target: Cursor.Target = .key) throws -> (key: Key, value: Value)? {
//        switch (position, target) {
//        case (.first, .key):
//            focus.key = store.startIndex
//            focus.value = store[focus.key].startIndex
//        case (.first, .duplicate):
//            focus.value = store[focus.key].startIndex
//        case (.last, .key):
//            focus.key = store.index(before: store.endIndex)
//            focus.value = store[focus.key].startIndex
//        case (.last, .duplicate):
//            focus.value = store[focus.key].index(before: store[focus.key].endIndex)
//        }
//        guard store.indices.contains(focus.key) else { return nil }
//        let key = store[focus.key]
//        return (key, store[key][focus.value])
//    }
//    
//    @discardableResult
//    public func move(to position: Cursor.RelativePosition, _ target: Cursor.Target? = nil) throws -> (key: Key, value: Value)? {
//        let operation = switch (position, target) {
//        case (.next, nil):
//            MDB_NEXT
//        case (.next, .key):
//            MDB_NEXT_NODUP
//        case (.next, .duplicate):
//            MDB_NEXT_DUP
//        case (.previous, nil):
//            MDB_PREV
//        case (.previous, .key):
//            MDB_PREV_NODUP
//        case (.previous, .duplicate):
//            MDB_PREV_DUP
//        }
//        var key = MDB_val()
//        var value = MDB_val()
//        return try LMDBError.nilIfNotFound {
//            try LMDBError.check(mdb_cursor_get(unsafeHandle, &key, &value, operation))
//            return (.init(key), .init(value))
//        }
//    }
//    
//    /// Moves the cursor to a specified key, with an optional duplicate value, using the specified precision and retrieves the key and value at that position.
//    ///
//    /// - Parameters:
//    ///   - precision: The precision of the move operation, either `.exactly` for an exact match or `.nearby` for the nearest match.
//    ///   - key: The key to move the cursor to, passed as `UnsafeRawBufferPointer`.
//    ///   - value: An optional duplicate value to move the cursor to, passed as `UnsafeRawBufferPointer`. If `nil`, only the key is considered.
//    /// - Returns: A tuple containing the key and value `UnsafeRawBufferPointer` at the cursor's new position, or `nil` if not found.
//    /// - Throws: An `LMDBError` if the operation fails.
//    /// - Warning: The returned buffer pointer is owned by the database and only valid until the next update operation or the end of the transaction. Do not deallocate.
//    @discardableResult @inlinable @inline(__always)
//    public func move(_ precision: Precision, toKey key: UnsafeRawBufferPointer, withDuplicateValue value: UnsafeRawBufferPointer? = nil) throws -> (key: UnsafeRawBufferPointer, value: UnsafeRawBufferPointer)? {
//        let operation: MDB_cursor_op
//        switch (precision, value) {
//        case (.exactly, .none):
//            operation = MDB_SET
//        case (.exactly, .some):
//            operation = MDB_GET_BOTH
//        case (.nearby, .none):
//            operation = MDB_SET_RANGE
//        case (.nearby, .some):
//            operation = MDB_GET_BOTH_RANGE
//        }
//        var key = MDB_val(.init(mutating: key))
//        var value = value.map { MDB_val(.init(mutating: $0)) } ?? .init()
//        return try LMDBError.nilIfNotFound {
//            try LMDBError.check(mdb_cursor_get(unsafeHandle, &key, &value, operation))
//            return (.init(key), .init(value))
//        }
//    }
//}
//
