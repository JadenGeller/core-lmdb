import CLMDB

public struct Statistics {
    fileprivate var stat: MDB_stat
    
    public var pageSize: UInt32 {
        stat.ms_psize
    }
    
    public var treeDepth: UInt32 {
        stat.ms_depth
    }
    
    public var branchPageCount: Int {
        stat.ms_branch_pages
    }
    
    public var leafPageCount: Int {
        stat.ms_leaf_pages
    }
    
    public var overflowPageCount: Int {
        stat.ms_overflow_pages
    }
    
    public var dataItemCount: Int {
        stat.ms_entries
    }
}

extension Environment {
    var statistics: Statistics {
        get throws {
            var stat: MDB_stat = .init()
            try LMDBError.check(mdb_env_stat(env, &stat))
            return .init(stat: stat)
        }
    }
}

extension Database {
    func statistics(in transaction: borrowing Transaction.Read) throws -> Statistics {
        var stat: MDB_stat = .init()
        try LMDBError.check(mdb_stat(transaction.txn, dbi, &stat))
        return .init(stat: stat)
    }
}
