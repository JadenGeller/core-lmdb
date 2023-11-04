import CLMDB

public struct LMDBError: Swift.Error {
    public var returnCode: Int32
    
    @inlinable internal init?(returnCode: Int32) {
        guard returnCode != MDB_SUCCESS else { return nil }
        self.returnCode = returnCode
    }
    
    @inlinable internal static func check(_ returnCode: Int32) throws {
        if let error = Self(returnCode: returnCode) {
            throw error
        }
    }
    
    @inlinable internal static func cannotFail(_ void: Void) { }
}
