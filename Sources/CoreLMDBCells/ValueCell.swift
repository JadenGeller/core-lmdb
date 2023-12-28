import CoreLMDB

public struct SingleValueCell<ValueCoder: ByteCoder> {
    @usableFromInline
    internal var transaction: Transaction
    
    @usableFromInline
    internal var database: Database<RawByteCoder, ValueCoder>
    
    @usableFromInline
    internal var key: ContiguousArray<UInt8>
    
    @inlinable @inline(__always)
    public init<KeyCoder: ByteEncoder>(atKey key: KeyCoder.Input, for database: Database<KeyCoder, ValueCoder>, in transaction: Transaction) throws {
        self.transaction = transaction
        self.database = database.rebind(to: .init(keyCoder: .init(), valueCoder: database.schema.valueCoder))
        self.key = try database.schema.keyCoder.withEncoding(of: key, ContiguousArray.init)
    }
    
    @inlinable @inline(__always)
    public func get() throws -> ValueCoder.Output? {
        try database.get(atKey: key, in: transaction)
    }

    @inlinable @inline(__always)
    public func put(_ value: ValueCoder.Input) throws {
        try database.put(value, atKey: key, precondition: nil, in: transaction)
    }
    
    @inlinable @inline(__always)
    public func delete() throws {
        try database.delete(atKey: key, in: transaction)
    }
}

public typealias RawSingleValueCell = SingleValueCell<RawByteCoder>

extension SingleValueCell {
    public func rebind<NewValueCoder: ByteCoder>(to valueCoder: NewValueCoder) -> SingleValueCell<NewValueCoder> {
        // cannot fail since RawByteCoder does not fail
        try! .init(atKey: key, for: database.rebind(to: .init(keyCoder: RawByteCoder(), valueCoder: valueCoder)), in: transaction)
    }
}
