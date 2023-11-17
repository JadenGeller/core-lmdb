import XCTest
import CoreLMDB
import CoreLMDBRepresentable

final class DatabaseTests: LMDBTestCase {
    func testOpen() throws {
        try withFreshPath { path in
            try withEnvironment(at: path) {
                XCTAssertNoThrow(try $0.withTransaction(.write) {
                    _ = try Database.open(in: $0)
                })
                XCTAssertThrowsError(try $0.withTransaction(.write) {
                    try Database.open("test1", in: $0)
                })
            }
            try withEnvironment(at: path) {
                XCTAssertThrowsError(try $0.withTransaction(.read) {
                    try Database.open("test1", in: $0)
                })
                XCTAssertNoThrow(try $0.withTransaction(.write) {
                    try Database.open("test1", in: $0)
                })
                XCTAssertNoThrow(try $0.withTransaction(.write) {
                    try Database.open("test1", in: $0)
                })
                XCTAssertNoThrow(try $0.withTransaction(.write) {
                    try Database.open("test2", in: $0)
                })
                XCTAssertThrowsError(try $0.withTransaction(.write) {
                    try Database.open("test3", in: $0)
                })
                XCTAssertNoThrow(try $0.withTransaction(.read) {
                    try Database.open("test2", in: $0)
                })
            } setup: {
                try $0.setMaxDBs(2)
            }
        }
    }
    
    func testConfig() throws {
        func assertConfig(_ config: Database.Config, file: StaticString = #filePath, line: UInt = #line) throws {
            try withFreshEnvironment { env in
                try env.withTransaction(.write) {
                    XCTAssertEqual(config, try Database.open(config: config, in: $0).config(in: $0), file: file, line: line)
                }
            }
        }
        let sortOrders:  [Database.Config.SortOrder] = [.standard, .reverse, .integer]
        for sortOrder in sortOrders {
            try assertConfig(.init(sortOrder: sortOrder, duplicateHandling: nil))
            for dupSortOrder in sortOrders {
                try assertConfig(.init(sortOrder: sortOrder, duplicateHandling: .init(sortOrder: dupSortOrder, fixedSize: false)))
                try assertConfig(.init(sortOrder: sortOrder, duplicateHandling: .init(sortOrder: dupSortOrder, fixedSize: true)))
            }
        }
    }
        
    func testOperations() throws {
        try withFreshEnvironment { env in
            try env.withTransaction(.write) { txn in
                let db = try Database.open(in: txn)
                
                try db.put("value", atKey: "key", in: txn)
                XCTAssertEqual("value", try db.get(atKey: "key", as: String.self, in: txn)!)

                XCTAssertThrowsError(try db.put("newValue", atKey: "key", overwrite: false, in: txn))
                XCTAssertEqual("value", try db.get(atKey: "key", as: String.self, in: txn)!)

                try db.delete(atKey: "key", in: txn)
                XCTAssertNil(try db.get(atKey: "key", as: String.self, in: txn))
                try db.put("newValue", atKey: "key", overwrite: false, in: txn)
                XCTAssertEqual("newValue", try db.get(atKey: "key", as: String.self, in: txn)!)

                try db.put("value", atKey: "key", in: txn)
                XCTAssertEqual("value", try db.get(atKey: "key", as: String.self, in: txn)!)
            }
        }
    }
}
