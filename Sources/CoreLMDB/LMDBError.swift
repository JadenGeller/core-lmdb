import CLMDB
import Foundation

/// Represents an error that can occur when interacting with the LMDB database.
public struct LMDBError: Swift.Error, Equatable {
    /// The error code returned by the LMDB function.
    @usableFromInline 
    internal var code: Int32
    
    /// Initializes a new error with the given return code if does not represent success.
    /// - Precondition: The `returnCode` is less than or equal to 0.
    /// - Parameter returnCode: The error code returned by an LMDB function.
    @inlinable @inline(__always)
    internal init?(returnCode: Int32) {
        guard returnCode != MDB_SUCCESS else { return nil }
        precondition(returnCode < 0)
        self.code = returnCode
    }
    
    /// Checks the return code from an LMDB function and throws an `LMDBError` if it indicates an error.
    /// - Parameter returnCode: The error code returned by an LMDB function.
    /// - Throws: An `LMDBError` if the return code indicates an error.
    @inlinable @inline(__always)
    internal static func check(_ returnCode: Int32) throws {
        if let posixCode = POSIXErrorCode(rawValue: returnCode) {
            throw POSIXError(posixCode)
        } else if let lmdbError = LMDBError(returnCode: returnCode) {
            throw lmdbError
        }
    }
    
    /// Static assertion that a CLMDB function does not return an error code.
    ///
    /// - Parameter void: An expression that does not evaluate to a return code.
    @inlinable @inline(__always)
    internal static func cannotFail(_ void: Void) { }
}

extension LMDBError {
    
    /// Key/data pair already exists.
    @inlinable @inline(__always)
    public static var keyExist: LMDBError { LMDBError(returnCode: MDB_KEYEXIST)! }
    
    /// Key/data pair not found (EOF).
    @inlinable @inline(__always)
    public static var notFound: LMDBError { LMDBError(returnCode: MDB_NOTFOUND)! }
    
    /// Requested page not found - this usually indicates corruption.
    @inlinable @inline(__always)
    public static var pageNotFound: LMDBError { LMDBError(returnCode: MDB_PAGE_NOTFOUND)! }
    
    /// Located page was wrong type.
    @inlinable @inline(__always)
    public static var corrupted: LMDBError { LMDBError(returnCode: MDB_CORRUPTED)! }
    
    /// Update of meta page failed or environment had fatal error.
    @inlinable @inline(__always)
    public static var panic: LMDBError { LMDBError(returnCode: MDB_PANIC)! }
    
    /// Environment version mismatch.
    @inlinable @inline(__always)
    public static var versionMismatch: LMDBError { LMDBError(returnCode: MDB_VERSION_MISMATCH)! }
    
    /// File is not a valid LMDB file.
    @inlinable @inline(__always)
    public static var invalid: LMDBError { LMDBError(returnCode: MDB_INVALID)! }
    
    /// Environment mapsize reached.
    @inlinable @inline(__always)
    public static var mapFull: LMDBError { LMDBError(returnCode: MDB_MAP_FULL)! }
    
    /// Environment maxdbs reached.
    @inlinable @inline(__always)
    public static var dbsFull: LMDBError { LMDBError(returnCode: MDB_DBS_FULL)! }
    
    /// Environment maxreaders reached.
    @inlinable @inline(__always)
    public static var readersFull: LMDBError { LMDBError(returnCode: MDB_READERS_FULL)! }
    
    /// Too many TLS keys in use - Windows only.
    @inlinable @inline(__always)
    public static var tlsFull: LMDBError { LMDBError(returnCode: MDB_TLS_FULL)! }
    
    /// Txn has too many dirty pages.
    @inlinable @inline(__always)
    public static var txnFull: LMDBError { LMDBError(returnCode: MDB_TXN_FULL)! }
    
    /// Cursor stack too deep - internal error.
    @inlinable @inline(__always)
    public static var cursorFull: LMDBError { LMDBError(returnCode: MDB_CURSOR_FULL)! }
    
    /// Page has not enough space - internal error.
    @inlinable @inline(__always)
    public static var pageFull: LMDBError { LMDBError(returnCode: MDB_PAGE_FULL)! }
    
    /// Database contents grew beyond environment mapsize.
    @inlinable @inline(__always)
    public static var mapResized: LMDBError { LMDBError(returnCode: MDB_MAP_RESIZED)! }
    
    /// Operation and DB incompatible, or DB type changed.
    @inlinable @inline(__always)
    public static var incompatible: LMDBError { LMDBError(returnCode: MDB_INCOMPATIBLE)! }
    
    /// Invalid reuse of reader locktable slot.
    @inlinable @inline(__always)
    public static var badRSlot: LMDBError { LMDBError(returnCode: MDB_BAD_RSLOT)! }
    
    /// Transaction must abort, has a child, or is invalid.
    @inlinable @inline(__always)
    public static var badTxn: LMDBError { LMDBError(returnCode: MDB_BAD_TXN)! }
    
    /// Unsupported size of key/DB name/data, or wrong DUPFIXED size.
    @inlinable @inline(__always)
    public static var badValSize: LMDBError { LMDBError(returnCode: MDB_BAD_VALSIZE)! }
    
    /// The specified DBI was changed unexpectedly.
    @inlinable @inline(__always)
    public static var badDbi: LMDBError { LMDBError(returnCode: MDB_BAD_DBI)! }
}

extension LMDBError: CustomStringConvertible {
    
    /// A human-readable description of the error.
    @inlinable @inline(__always)
    public var description: String {
        precondition(code != MDB_SUCCESS)
        return String(cString: mdb_strerror(code)!)
    }
}

extension LMDBError {
    /// Performs an operation, catching `LMDBError.notFound` and returning `nil` instead.
    ///
    /// - Parameter block: The operation to perform,
    @inlinable @inline(__always)
    internal static func nilIfNotFound<Result>(_ block: () throws -> Result) rethrows -> Result? {
        do {
            return try block()
        } catch let error as LMDBError where error == .notFound {
            return nil
        }
    }
}
