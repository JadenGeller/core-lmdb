import XCTest
import CoreLMDB

final class TransactionTests: LMDBTestCase {
    func testCommit() throws {
        try withFreshEnvironment { env in
            let db = try env.withTransaction(.write) { txn in
                try Database.open(in: txn)
            }
            
            try env.withTransaction(.write) { txn in
                try db.put("value", atKey: "key", in: txn)
            }
            try env.withTransaction(.read) { txn in
                XCTAssertEqual("value", try db.get(atKey: "key", as: String.self, in: txn)!)
            }
        }
    }
    
    func testRollback() throws {
        try withFreshEnvironment { env in
            let db = try env.withTransaction(.write) { txn in
                try Database.open(in: txn)
            }
            
            try env.withTransaction(.write) { txn in
                try db.put("value1", atKey: "key", in: txn)
            }
            struct RollbackError: Error {}
            do {
                try env.withTransaction(.write) { txn in
                    try db.put("value2", atKey: "key", in: txn)
                    throw RollbackError()
                }
            } catch _ as RollbackError { }
            try env.withTransaction(.read) { txn in
                XCTAssertEqual("value1", try db.get(atKey: "key", as: String.self, in: txn)!)
            }
            
        }
    }
}
