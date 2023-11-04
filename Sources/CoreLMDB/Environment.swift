import CLMDB
import Foundation
import System

public struct Environment: ~Copyable {
    internal let env: OpaquePointer
    public init(config: consuming Config, path: FilePath, mode: FilePermissions = [.ownerReadWrite, .groupReadWrite, .otherRead]) throws {
        env = config.takeUnsafeEnv()
        try path.withPlatformString { path in
            try LMDBError.check(mdb_env_open(env, path, UInt32(MDB_NOTLS), mode.rawValue))
        }
    }
    public init(path: FilePath, mode: FilePermissions = [.ownerReadWrite, .groupReadWrite, .otherRead]) throws {
        try self.init(config: .init(), path: path, mode: mode)
    }
    
    deinit {
        LMDBError.cannotFail(mdb_env_close(env))
    }
}

extension Environment {
    public struct Config: ~Copyable {
        let env: OpaquePointer
        public init() throws {
            var env: OpaquePointer?
            try LMDBError.check(mdb_env_create(&env))
            self.env = env!
        }
        
        public func setMapSize(_ newValue: Int) throws {
            try LMDBError.check(mdb_env_set_mapsize(env, newValue))
        }
        
        public func setMaxReaders(_ newValue: UInt32) throws {
            try LMDBError.check(mdb_env_set_maxreaders(env, newValue))
        }

        public func setMaxDatabases(_ newValue: UInt32) throws {
            try LMDBError.check(mdb_env_set_maxdbs(env, newValue))
        }
        
        fileprivate consuming func takeUnsafeEnv() -> OpaquePointer {
            let env = env
            discard self
            return env
        }
        
        deinit {
            LMDBError.cannotFail(mdb_env_close(env))
        }
    }
}

extension Environment {
    public var info: Info {
        get throws {
            try .init(env: env)
        }
    }
    
    public struct Info {
        private let info: MDB_envinfo
        
        fileprivate init(env: OpaquePointer) throws {
            var info: MDB_envinfo = .init()
            try LMDBError.check(mdb_env_info(env, &info))
            self.info = info
        }
        
        public var mapSize: Int {
            info.me_mapsize
        }
        
        public var maxReaders: UInt32 {
            info.me_maxreaders
        }
        
        public var numReaders: UInt32 {
            info.me_numreaders
        }
        
        public var lastPageID: Int {
            info.me_last_pgno
        }
        
        public var lastTransactionID: Int {
            info.me_last_txnid
        }
    }
}
