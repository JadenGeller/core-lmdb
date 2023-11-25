//import CoreLMDB
//
//extension Cursor.DataItem {
//    public func key<Key: RawBufferRepresentable>(as type: Key.Type) throws -> Key {
//        try Key(buffer: key)
//    }
//    public func value<Value: RawBufferRepresentable>(as type: Value.Type) throws -> Value {
//        try Value(buffer: value)
//    }
//}
//
//extension Cursor {
//    @discardableResult @inlinable @inline(__always)
//    public func move<Key: RawBufferRepresentable>(
//        _ precision: Precision,
//        toKey key: Key
//    ) throws -> DataItem? {
//        try key.withUnsafeBytes { key in
//            try move(precision, toKey: key)
//        }
//    }
//    
//    @discardableResult @inlinable @inline(__always)
//    public func move<Key: RawBufferRepresentable, Value: RawBufferRepresentable>(
//        _ precision: Precision,
//        toKey key: Key,
//        withDuplicateValue value: Value
//    ) throws -> DataItem? {
//        try key.withUnsafeBytes { key in
//            try value.withUnsafeBytes { value in
//                try move(precision, toKey: key, withDuplicateValue: value)
//            }
//        }
//    }
//
//}
//
//extension Cursor {
//    @inlinable @inline(__always)
//    public func put<Key: RawBufferRepresentable, Value: RawBufferRepresentable>(_ value: Value, atKey key: Key, overwrite: Bool = true) throws {
//        try key.withUnsafeBytes { key in
//            try value.withUnsafeBytes { value in
//                try put(value, atKey: key, overwrite: overwrite)
//            }
//        }
//    }
//}
