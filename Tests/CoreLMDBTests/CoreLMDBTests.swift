import XCTest
import System
@testable import CoreLMDB

final class CoreLMDBTests: XCTestCase {
    let path = FilePath(FileManager.default.temporaryDirectory.appendingPathComponent("CoreLMDBTests", isDirectory: true))!

    override func setUp() async throws {
        try! FileManager.default.createDirectory(atPath: path.string, withIntermediateDirectories: false)
    }
    override func tearDown() async throws {
        try! FileManager.default.removeItem(atPath: path.string)
    }
    
    func testCreateNamedDatabase() throws {
        let config = try Environment.Config()
        try config.setMaxDatabases(1)
        let env = try Environment(config: config, path: path)
        let db1 = try env.write {
            try Database.open("test", in: $0)
        }
        try db1.close(in: env)
        _ = try env.read {
            try Database.open("test", in: $0)
        }
    }
    
    func testReadAfterWrite() throws {
        let env = try Environment(path: path)
        let db = try env.read { try Database.open(in: $0) }
        var (key, value) = ("key", "value")
        try env.write {
            try db.withWriter(for: $0) { db in
                try withUnsafeBytes(of: &key) { key in
                    try withUnsafeBytes(of: &value) { value in
                        try db.updateValue(value, forKey: key)
                    }
                    XCTAssertEqual(value, try db[key]!.load(as: String.self))
                }
            }
        }
        try env.read {
            try db.withReader(for: $0) { db in
                try withUnsafeBytes(of: &key) { key in
                    XCTAssertEqual(value, try db[key]!.load(as: String.self))
                }
            }
        }
    }
    
    func testUpdateValue() throws {
        let env = try Environment(path: path)
        let db = try env.read { try Database.open(in: $0) }
        var (key, value, newValue) = ("key", "value", "newValue")
        try env.write {
            try db.withWriter(for: $0) { db in
                try withUnsafeBytes(of: &key) { key in
                    try withUnsafeBytes(of: &value) { value in
                        try db.updateValue(value, forKey: key)
                    }
                    try withUnsafeBytes(of: &newValue) { newValue in
                        try db.updateValue(newValue, forKey: key)
                    }
                    XCTAssertEqual(newValue, try db[key]!.load(as: String.self))
                }
            }
        }
    }

    func testDeleteValue() throws {
        let env = try Environment(path: path)
        let db = try env.read { try Database.open(in: $0) }
        var (key, value) = ("key", "value")
        try env.write {
            try db.withWriter(for: $0) { db in
                try withUnsafeBytes(of: &key) { key in
                    try withUnsafeBytes(of: &value) { value in
                        try db.updateValue(value, forKey: key)
                    }
                    try db.removeValue(forKey: key)
                    XCTAssertNil(try db[key])
                }
            }
        }
    }

    func testNonExistentKey() throws {
        let env = try Environment(path: path)
        let db = try env.read { try Database.open(in: $0) }
        var key = "nonExistentKey"
        try env.read {
            try db.withReader(for: $0) { db in
                try withUnsafeBytes(of: &key) { key in
                    XCTAssertNil(try db[key])
                }
            }
        }
    }

    func testTransactionRollback() throws {
        struct Rollback: Error {}
        let env = try Environment(path: path)
        let db = try env.read { try Database.open(in: $0) }
        var (key, value) = ("key", "value")
        do {
            try env.write {
                try db.withWriter(for: $0) { db in
                    try withUnsafeBytes(of: &key) { key in
                        try withUnsafeBytes(of: &value) { value in
                            try db.updateValue(value, forKey: key)
                        }
                        throw Rollback()
                    }
                }
            }
        } catch _ as Rollback {}
        try env.read {
            try db.withReader(for: $0) { db in
                try withUnsafeBytes(of: &key) { key in
                    XCTAssertNil(try db[key])
                }
            }
        }
    }
}
