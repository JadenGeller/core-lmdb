import CLMDB
import Foundation

public struct Database {
    internal var dbi: MDB_dbi
    
    private static func `open`(_ name: String? = nil, in txn: OpaquePointer, flags: UInt32) throws -> MDB_dbi {
        func openWithName(_ name: UnsafePointer<CChar>?) throws -> MDB_dbi {
            var dbi = MDB_dbi()
            try LMDBError.check(mdb_dbi_open(txn, name, flags, &dbi))
            return dbi
        }
        if let name {
            return try name.withCString(openWithName)
        } else {
            return try openWithName(nil)
        }
    }
    public static func `open`(_ name: String? = nil, in transaction: borrowing Transaction.Read) throws -> Database {
        .init(dbi: try open(name, in: transaction.txn, flags: 0))
    }
    public static func `open`(_ name: String? = nil, in transaction: borrowing Transaction.Write, createIfNotFound: Bool = true) throws -> Database {
        .init(dbi: try open(name, in: transaction.txn, flags: createIfNotFound ? UInt32(MDB_CREATE) : 0))
    }
    
    public consuming func close(in environment: borrowing Environment) throws {
        LMDBError.cannotFail(mdb_dbi_close(environment.env, dbi))
    }
}

extension Database {
    public struct Reader: ~Copyable {
        fileprivate var txn: OpaquePointer
        fileprivate var dbi: MDB_dbi
    }
    public func withReader<Result>(for transaction: borrowing Transaction.Read, _ transact: (borrowing Reader) throws -> Result) rethrows -> Result {
        try transact(Reader(txn: transaction.txn, dbi: dbi))
    }
    public func withReader<Result>(for transaction: borrowing Transaction.Write, _ transact: (borrowing Reader) throws -> Result) rethrows -> Result {
        try transact(Reader(txn: transaction.txn, dbi: dbi))
    }
}

extension Database {
    public struct Writer: ~Copyable {
        fileprivate var txn: OpaquePointer
        fileprivate var dbi: MDB_dbi

        fileprivate func withReader<Result>(_ transact: (borrowing Reader) throws -> Result) rethrows -> Result {
            try transact(Database.Reader(txn: txn, dbi: dbi))
        }
    }
    public func withWriter<Result>(for transaction: borrowing Transaction.Write, _ transact: (borrowing Writer) throws -> Result) rethrows -> Result {
        try transact(Writer(txn: transaction.txn, dbi: dbi))
    }
}

extension Database.Reader {
    public subscript(_ key: UnsafeRawBufferPointer) -> UnsafeRawBufferPointer? {
        get throws {
            var key = MDB_val(.init(mutating: key))
            var data = MDB_val()
            do {
                try LMDBError.check(mdb_get(txn, dbi, &key, &data))
                return .init(data)
            } catch let error as LMDBError {
                if error.returnCode == MDB_NOTFOUND {
                    return nil
                }
                throw error
            }
        }
    }
}

extension Database.Writer {
    public subscript(_ key: UnsafeRawBufferPointer) -> UnsafeMutableRawBufferPointer? {
        get throws { try withReader { try $0[key].map({ .init(mutating: $0) }) }}
    }
    
    public func updateValue(_ data: UnsafeRawBufferPointer, forKey key: UnsafeRawBufferPointer) throws {
        var key = MDB_val(.init(mutating: key))
        var data = MDB_val(.init(mutating: data))
        try LMDBError.check(mdb_put(txn, dbi, &key, &data, 0))
    }
    
    public func removeValue(forKey key: UnsafeRawBufferPointer) throws {
        var key = MDB_val(.init(mutating: key))
        try LMDBError.check(mdb_del(txn, dbi, &key, nil))
    }
    
    public func removeAll() throws {
        try LMDBError.check(mdb_drop(txn, dbi, 0))
    }
}

extension MDB_val {
    fileprivate init(_ buffer: UnsafeMutableRawBufferPointer) {
        self.init(mv_size: buffer.count, mv_data: buffer.baseAddress)
    }
}
extension UnsafeRawBufferPointer {
    fileprivate init(_ val: MDB_val) {
        self.init(start: val.mv_data, count: val.mv_size)
    }
}
