import CoreLMDB
import CoreLMDBRepresentable

public final class DatabaseIndex {
    @usableFromInline
    internal let cursor: Cursor
    
    // FIXME: Is it worth opening a cursor for `endIndex`?
    @usableFromInline
    internal var isEnd: Bool
    
    internal init(for database: Database, in transaction: Transaction) {
        self.cursor = try! Cursor(for: database, in: transaction)
        self.isEnd = false
    }
    
    deinit {
        cursor.close()
    }
}

extension DatabaseIndex {
    @inlinable @inline(__always)
    internal func preconditionFailure() -> Never {
        Swift.preconditionFailure("Attempting to access Dictionary elements using an invalid index")
    }
    
    internal var item: Cursor.DataItem {
        guard let item = try! cursor.get() else { preconditionFailure() }
        return item
    }
}
 
extension DatabaseIndex: Comparable {
    internal static func assertCompatible(_ lhs: DatabaseIndex, _ rhs: DatabaseIndex) {
        assert(lhs.cursor.database == rhs.cursor.database, "invalid comparison between indices of separate database")
        assert(lhs.cursor.transaction == rhs.cursor.transaction, "invalid comparison between indices of separate transaction")
    }
    
    public static func keyOrdering(of lhs: DatabaseIndex, _ rhs: DatabaseIndex) -> Database.Ordering {
        assertCompatible(lhs, rhs)
        let (database, transaction) = (lhs.cursor.database, lhs.cursor.transaction)
        return database.keyOrdering(of: lhs.item.key, rhs.item.key, in: transaction)
    }
    
    public static func ==(lhs: DatabaseIndex, rhs: DatabaseIndex) -> Bool {
        switch (lhs.isEnd, rhs.isEnd) {
        case (true, true):
            true
        case (true, false), (false, true):
            false
        case (false, false):
            keyOrdering(of: lhs, rhs) == .equal
        }
    }
    
    public static func <(lhs: DatabaseIndex, rhs: DatabaseIndex) -> Bool {
        switch (lhs.isEnd, rhs.isEnd) {
        case (true, _):
            false
        case (false, true):
            true
        case (false, false):
            keyOrdering(of: lhs, rhs) == .ascending
        }
    }
}

extension DatabaseIndex {
    public func moveToEnd() {
        isEnd = true
    }
    
    @discardableResult @inlinable @inline(__always)
    public func move(to position: Cursor.AbsolutePosition, _ target: Cursor.Target = .key) throws -> Cursor.DataItem? {
        isEnd = false
        return try cursor.move(to: position, target)
    }

    @discardableResult @inlinable @inline(__always)
    public func move(to position: Cursor.RelativePosition, _ target: Cursor.Target? = nil) throws -> Cursor.DataItem? {
        switch (isEnd, position) {
        case (true, .previous):
            return try cursor.move(to: .last)
        case (true, .next):
            preconditionFailure()
        case (false, .previous):
            return try cursor.move(to: position, target)
        case (false, .next):
            if let result = try cursor.move(to: position, target) { return result }
            isEnd = true
            return nil
        }
    }
    
    @discardableResult @inlinable @inline(__always)
    public func move<Key: RawBufferRepresentable>(_ precision: Cursor.Precision, toKey key: Key) throws -> Cursor.DataItem? {
        if let result = try cursor.move(precision, toKey: key) { return result }
        isEnd = true
        return nil
    }
}
