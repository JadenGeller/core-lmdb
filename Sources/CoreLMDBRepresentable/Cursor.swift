import CoreLMDB

extension Cursor {
    @inlinable @inline(__always)
    public func move<Key: RawBufferRepresentable, Value: RawBufferRepresentable>(
        to position: AbsolutePosition,
        _ target: Target = .key,
        as type: (Key.Type, Value.Type)
    ) throws -> (key: Key, value: Value)? {
        guard let (key, value) = try move(to: position, target) else { return nil }
        return try (Key(buffer: key), Value(buffer: value))
    }
    
    @inlinable @inline(__always)
    public func move<Key: RawBufferRepresentable, Value: RawBufferRepresentable>(
        to position: RelativePosition,
        _ target: Target? = nil,
        as type: (Key.Type, Value.Type)
    ) throws -> (key: Key, value: Value)? {
        guard let (key, value) = try move(to: position, target) else { return nil }
        return try (Key(buffer: key), Value(buffer: value))
    }
    
    @inlinable @inline(__always)
    public func move<Key: RawBufferRepresentable, Value: RawBufferRepresentable>(
        _ precision: Precision,
        toKey key: Key,
        withDuplicateValue value: Value? = nil,
        as type: (Key.Type, Value.Type)
    ) throws -> (key: Key, value: Value)? {
        try key.withUnsafeBytes { key in
            try value.withUnsafeBytesOrNil { value in
                guard let (key, value) = try move(precision, toKey: key, withDuplicateValue: value) else { return nil }
                return try (Key(buffer: key), Value(buffer: value))
            }
        }
    }
}

extension Cursor {
    @inlinable @inline(__always)
    public func get<Key: RawBufferRepresentable, Value: RawBufferRepresentable>(as type: (Key.Type, Value.Type)) throws -> (key: Key, value: Value)? {
        guard let (key, value) = try get() else { return nil }
        return try (Key(buffer: key), Value(buffer: value))
    }
    
    @inlinable @inline(__always)
    public func put<Key: RawBufferRepresentable, Value: RawBufferRepresentable>(key: Key, value: Value, overwrite: Bool = true) throws {
        try key.withUnsafeBytes { key in
            try value.withUnsafeBytes { value in
                try put(key: key, value: value, overwrite: overwrite)
            }
        }
    }
}

// MARK: Utils

extension Optional where Wrapped: RawBufferRepresentable {
    @inlinable @inline(__always)
    internal func withUnsafeBytesOrNil<Result>(_ body: (UnsafeRawBufferPointer?) throws -> Result) rethrows -> Result {
        switch self {
        case .some(let wrapped):
            try wrapped.withUnsafeBytes { buffer in
                try body(buffer)
            }
        case .none:
            try body(nil)
        }
    }
}
