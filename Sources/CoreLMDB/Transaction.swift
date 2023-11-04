import CLMDB

public enum Transaction {
    public struct Read: ~Copyable, Sendable {
        internal var txn: OpaquePointer
        
        deinit {
            LMDBError.cannotFail(mdb_txn_abort(txn))
        }
    }
    public struct Write: ~Copyable {
        internal var txn: OpaquePointer
        
        public let threadID: ThreadID = .current
        @inlinable public func assertThread() {
            assert(threadID == .current, "WriteTransaction must be used from same thread that created it")
        }

        deinit {
            assertThread()
            LMDBError.cannotFail(mdb_txn_abort(txn))
        }
    }
}

extension Transaction.Read {
    public init(in environment: borrowing Environment) throws {
        var txn: OpaquePointer?
        try LMDBError.check(mdb_txn_begin(environment.env, nil, UInt32(MDB_RDONLY), &txn))
        self.txn = txn!
    }
    
    public consuming func commit() throws {
        let txn = txn
        discard self
        try LMDBError.check(mdb_txn_commit(txn))
    }
    
    public consuming func abort() {
        LMDBError.cannotFail(mdb_txn_abort(txn))
        discard self
    }
}

extension Transaction.Write {
    public init(in environment: borrowing Environment) throws {
        var txn: OpaquePointer?
        try LMDBError.check(mdb_txn_begin(environment.env, nil, 0, &txn))
        self.txn = txn!
    }
    
    public consuming func commit() throws {
        assertThread()
        let txn = txn
        discard self
        try LMDBError.check(mdb_txn_commit(txn))
    }
    
    public consuming func abort() {
        assertThread()
        LMDBError.cannotFail(mdb_txn_abort(txn))
        discard self
    }
}

extension Transaction {
    public struct Reset: ~Copyable {
        fileprivate var txn: OpaquePointer
        
        public consuming func renew() throws -> Transaction.Read {
            let txn = txn
            discard self
            return try Transaction.Read(renewing: txn)
        }
        
        deinit {
            LMDBError.cannotFail(mdb_txn_abort(txn))
        }
    }
}
extension Transaction.Read {
    public consuming func reset() -> Transaction.Reset {
        LMDBError.cannotFail(mdb_txn_reset(txn))
        return .init(txn: txn)
    }
    fileprivate init(renewing txn: OpaquePointer) throws {
        self.txn = txn
        try LMDBError.check(mdb_txn_renew(txn))
    }
}

extension Environment {
    public func read<Result>(_ runInTransaction: (borrowing Transaction.Read) throws -> Result) throws -> Result {
        let transaction = try Transaction.Read(in: self)
        do {
            let result = try runInTransaction(transaction)
            try transaction.commit()
            return result
        } catch let error {
            throw error
        }
    }
    public func read<Result>(_ runInTransaction: (borrowing Transaction.Read) async throws -> Result) async throws -> Result {
        let transaction = try Transaction.Read(in: self)
        do {
            let result = try await runInTransaction(transaction)
            try transaction.commit()
            return result
        } catch let error {
            throw error
        }
    }
    public func write<Result>(_ runInTransaction: (borrowing Transaction.Write) throws -> Result) throws -> Result {
        let transaction = try Transaction.Write(in: self)
        do {
            let result = try runInTransaction(transaction)
            try transaction.commit()
            return result
        } catch let error {
            throw error
        }
    }
}
