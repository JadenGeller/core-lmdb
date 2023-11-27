import CoreLMDB
import CoreLMDBRepresentable

// TODO: Is there any way this could be copy-on-write? It would need to reference the environment
public struct DurableSortedDictionary<Key: ByteCodable, Value: ByteCodable> {
    public typealias Database = CoreLMDB.Database<Key.ByteCoder, Value.ByteCoder>
    
    internal var database: Database
    internal var transaction: Transaction
    
    public init(for database: Database, in transaction: Transaction) {
        self.database = database
        self.transaction = transaction
    }
}

extension DurableSortedDictionary {
    public subscript(key: Key) -> Value? {
        get {
            try! database.get(atKey: key, in: transaction)
        }
        set {
            if let newValue {
                try! database.put(newValue, atKey: key, overwrite: true, in: transaction)
            } else {
                try! transaction.withCursor(for: database) { cursor in
                    if try cursor.get(atKey: key, precision: .exactly) != nil {
                        try cursor.delete()
                    }
                }
            }
        }
    }
    
    public subscript(key: Key, default defaultValue: @autoclosure () -> Value) -> Value {
        get {
            self[key] ?? defaultValue()
        }
        set {
            self[key] = newValue
        }
    }
}

extension DurableSortedDictionary: BidirectionalCollection {
    public typealias Index = DatabaseIndex<Key, Value>
    public typealias Element = (key: Key, value: Value)

    public var startIndex: Index {
        let index = Index(for: database, in: transaction)
        assert(try! index.move(to: .first) != nil)
        return index
    }
    
    public var endIndex: Index {
        let index = Index(for: database, in: transaction)
        index.moveToEnd()
        return index
    }

    public func index(forKey key: Key) -> Index? {
        let index = Index(for: database, in: transaction)
        guard try! index.move(.exactly, toKey: key) != nil else { return nil }
        return index
    }
    
    public subscript(index: Index) -> Element {
        guard !index.isEnd else { index.preconditionFailure() }
        return index.item
    }
    
    public func formIndex(after i: inout Index) {
        try! i.move(to: .next)
    }
    
    public func formIndex(before i: inout Index) {
        try! i.move(to: .previous)
    }
    
    public func index(after i: Index) -> Index {
        var newIndex = Index(for: database, in: transaction)
        try! newIndex.cursor.get(atKey: i.item.key, precision: .exactly)
        formIndex(after: &newIndex)
        return newIndex
    }
    
    public func index(before i: Index) -> Index {
        var newIndex = Index(for: database, in: transaction)
        try! newIndex.cursor.get(atKey: i.item.key, precision: .exactly)
        formIndex(before: &newIndex)
        return newIndex
    }
}

// TODO: Implement `keys` and `values`

extension DurableSortedDictionary {
    public mutating func updateValue(_ value: Value, forKey key: Key) -> Value? {
        try! transaction.withCursor(for: database) { cursor in
            defer { try! cursor.put(value, atKey: key) }
            return try! cursor.get(atKey: key, precision: .exactly)?.value
        }
    }

    public mutating func merge<S>(_ other: S, uniquingKeysWith combine: (Value, Value) throws -> Value) rethrows where S : Sequence, S.Element == (Key, Value) {
        for (key, newValue) in other {
            if let existingValue = self[key] {
                self[key] = try combine(existingValue, newValue)
            } else {
                self[key] = newValue
            }
        }
    }
}

extension DurableSortedDictionary {
    @discardableResult
    public mutating func removeValue(forKey key: Key) -> Value? {
        defer { self[key] = nil }
        return self[key]
    }
    
    @discardableResult
    public mutating func remove(at index: Index) -> Element {
        defer { try! index.cursor.delete() }
        return self[index]
    }

    public mutating func removeAll() {
        try! database.drop(close: false, in: transaction)
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
    public func withDurableSortedDictionary<Key: ByteCodable, Value: ByteCodable, Result>(
        as type: (Key.Type, Value.Type),
        for database: Database<Key.ByteCoder, Value.ByteCoder>,
        _ block: (inout DurableSortedDictionary<Key, Value>) throws -> Result
    ) throws -> Result {
        var dict = DurableSortedDictionary<Key, Value>(for: database, in: self)
        return try block(&dict)
    }
}
