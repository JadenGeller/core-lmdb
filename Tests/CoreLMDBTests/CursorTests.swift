import XCTest
import CoreLMDB
import CoreLMDBRepresentable


//struct Spec {
////    @inlinable @inline(__always)
////    public func move<Key: RawBufferRepresentable, Value: RawBufferRepresentable>(
////        to position: AbsolutePosition,
////        _ target: Target = .key,
////        as type: (Key.Type, Value.Type)
////    ) throws -> (key: Key, value: Value)? {
////        guard let (key, value) = try move(to: position, target) else { return nil }
////        return try (Key(buffer: key), Value(buffer: value))
////    }
////
//    
//    
//}
//
//// Int: Int
//
//// next
//// - no duplicates
////   - key += 1, unless it is the max, then we're done
//// - duplicates
////   - value += 1, unless it is the max, then we're done
//
//func runCursorTest(
//    _ expected: (key: String, value: String)?,
//    _ block: (Cursor) throws -> (key: String, value: String)?,
//    file: StaticString = #filePath,
//    line: UInt = #line
//) throws {
//    try withFreshWriteTransaction { txn in
//        let db = try txn.createSampleDatabase(with: [
//            "cat": "meow",
//            "crow": "caw",
//            "dog": "bark",
//            "pig": "oink",
//        ])
//        try txn.withCursor(for: db) { cursor in
//            try assertCursor(expected, { try block(cursor) }, file: file, line: line)
//        }
//    }
//}
//
//final class CursorTests: LMDBTestCase {
//    
//    func testDuplicateHandling() throws {
//        try withFreshEnvironment { env in
//            let config = Database.Config(sortOrder: .standard, duplicateHandling: nil)
//            try env.withTransaction(.write) { txn in
//                let db = try Database.open(config: config, in: txn)
//                let key = "key".data(using: .utf8)!
//                let value1 = "value1".data(using: .utf8)!
//                let value2 = "value2".data(using: .utf8)!
//                
//                try key.withUnsafeBytes { keyBuffer in
//                    try value1.withUnsafeBytes { valueBuffer in
//                        try db.put(valueBuffer, atKey: keyBuffer, in: txn)
//                    }
//                    try value2.withUnsafeBytes { valueBuffer in
//                        try db.put(valueBuffer, atKey: keyBuffer, in: txn)
//                    }
//                }
//                
//                try txn.withCursor(for: db) { cursor in
//                    let (firstKey, firstValue) = try cursor.move(to: .first)!
//                    XCTAssertEqual(key, Data(firstKey))
//                    XCTAssertEqual(value1, Data(firstValue))
//                    
//                    let (nextKey, nextValue) = try cursor.move(to: .next, .duplicate)!
//                    XCTAssertEqual(key, Data(nextKey))
//                    XCTAssertEqual(value2, Data(nextValue))
//                    
//                    let dupCount = try cursor.duplicateCount
//                    XCTAssertEqual(dupCount, 2)
//                }
//            }
//        }
//    }
//}
//
//    func testMoveToFirstEntry() throws {
//        try runCursorTest(("cat", "meow")) {
//            try $0.move(to: .first, as: $1)!
//        }
//    }
//
//    func testMoveToNextEntry() throws {
//        try runCursorTest(("crow", "caw")) {
//            _ = try $0.move(to: .first)
//            return try $0.move(to: .next, as: $1)!
//        }
//    }
//
//    func testMoveToLastEntry() throws {
//        try runCursorTest(("pig", "oink")) {
//            try $0.move(to: .last, as: $1)!
//        }
//    }
//
//    func testMovePastLastEntry() throws {
//        try runCursorTest(nil as (String, String)?) {
//            _ = try $0.move(to: .last, as: )
//            return try $0.move(to: .next)
//        }
//    }
//
//    func testMoveExactlyToKnownKey() throws {
//        try runCursorTest(("dog", "bark")) {
//            try $0.move(.exactly, toKey: "dog", as: $1)!
//        }
//    }
//
//    func testMoveToNearbyKey() throws {
//        try runCursorTest(("pig", "oink")) {
//            try $0.move(.nearby, toKey: "fox", as: $1)!
//        }
//    }
//
//    func testMoveToPreviousEntry() throws {
//        try runCursorTest(("crow", "caw")) {
//            _ = try $0.move(.exactly, toKey: "dog")
//            return try $0.move(to: .previous, as: $1)!
//        }
//    }
//
//    // Additional tests based on the new behavior scenarios
//
//    func testMoveToNextAfterMovingPastEnd() throws {
//        try runCursorTest(nil) {
//            _ = try $0.move(to: .last)
//            _ = try $0.move(to: .next)
//            return try $0.move(to: .next)
//        }
//    }
//
//    func testMoveToPreviousAfterMovingBeforeFirst() throws {
//        try runCursorTest(nil) {
//            _ = try $0.move(to: .first)
//            _ = try $0.move(to: .previous)
//            return try $0.move(to: .previous)
//        }
//    }
//
//    func testMoveExactlyToNonExistentKey() throws {
//        try runCursorTest(nil) {
//            return try $0.move(.exactly, toKey: "nonexistent", as: $1)
//        }
//    }
//
//    // ... Add more tests as needed for each behavior scenario
//    
//    // Note: Insert data into the database is a placeholder for the actual data insertion logic.
//    // You would need to implement that part similarly to how it's done in the original testMoveOperations function.
//        
//    func testMoveOperations() throws {
//        try withFreshEnvironment { env in
//            try env.withTransaction(.write) { txn in
//                let db = try txn.createSampleDatabase(with: sampleData)
//                                
//                try txn.withCursor(for: db) { cursor in
//                    try assertCursor(("cat", "meow")) {
//                        try cursor.move(to: .first, as: $0)!
//                    }
//                    try assertCursor(("crow", "caw")) {
//                        try cursor.move(to: .next, as: $0)!
//                    }
//                    try assertCursor(("pig", "oink")) {
//                        try cursor.move(to: .last, as: $0)!
//                    }
//                    XCTAssertNil(try cursor.move(to: .next))
//                    try assertCursor(("dog", "bark")) {
//                        try cursor.move(.exactly, toKey: "dog", as: $0)!
//                    }
//                    try assertCursor(("crow", "caw")) {
//                        try cursor.move(to: .previous, as: $0)!
//                    }
//                    try assertCursor(("pig", "oink")) {
//                        try cursor.move(.nearby, toKey: "fox", as: $0)!
//                    }
//                }
//            }
//        }
//    }
//    
//    func testMoveOperationsWithDuplicates() throws {
//        try withFreshEnvironment { env in
//            let config = Database.Config(duplicateHandling: .init())
//            try env.withTransaction(.write) { txn in
//                let db = try Database.open(config: config, in: txn)
//                
//                let data = [
//                    "animal": ["cat", "dog", "crow"],
//                    "fruit": ["apple", "banana", "orange", "cherry"]
//                ]
//                for (key, values) in data {
//                    let key = key.data(using: .utf8)!
//                    for value in values {
//                        let value = value.data(using: .utf8)!
//                        try key.withUnsafeBytes { keyBuffer in
//                            try value.withUnsafeBytes { valueBuffer in
//                                try db.put(valueBuffer, atKey: keyBuffer, in: txn)
//                            }
//                        }
//                    }
//                }
//                
//                try txn.withCursor(for: db) { cursor in
//                    do {
//                        let (key, value) = try cursor.move(to: .first)!
//                        XCTAssertEqual("animal", String(data: Data(key), encoding: .utf8))
//                        XCTAssertEqual("cat", String(data: Data(value), encoding: .utf8))
//                    }
//                    do {
//                        let (key, value) = try cursor.move(to: .next, .duplicate)!
//                        XCTAssertEqual("animal", String(data: Data(key), encoding: .utf8))
//                        XCTAssertEqual("crow", String(data: Data(value), encoding: .utf8))
//                    }
//                    do {
//                        var (key, value) = try cursor.move(to: .next, .duplicate)!
//                        XCTAssertEqual("animal", String(data: Data(key), encoding: .utf8))
//                        XCTAssertEqual("dog", String(data: Data(value), encoding: .utf8))
//                        XCTAssertNil(try cursor.move(to: .next, .duplicate))
//                        (key, value) = try cursor.get()!
//                        XCTAssertEqual("animal", String(data: Data(key), encoding: .utf8))
//                        XCTAssertEqual("dog", String(data: Data(value), encoding: .utf8))
//                    }
//                    do {
//                        let (key, value) = try cursor.move(to: .previous)!
//                        XCTAssertEqual("animal", String(data: Data(key), encoding: .utf8))
//                        XCTAssertEqual("crow", String(data: Data(value), encoding: .utf8))
//                    }
////                    
////                    do {
////                        let key = "fruit".data(using: .utf8)!
////                        let value = "banana".data(using: .utf8)!
////                        try key.withUnsafeBytes { keyBuffer in
////                            try value.withUnsafeBytes { valueBuffer in
////                                let (key, value) = try cursor.move(.exactly, toKey: keyBuffer, withDuplicateValue: valueBuffer)!
////                                XCTAssertEqual("fruit", String(data: Data(key), encoding: .utf8))
////                                XCTAssertEqual("banana", String(data: Data(value), encoding: .utf8))
////                            }
////                        }
////                    }
////                    do {
////                        let (key, value) = try cursor.move(to: .previous, .duplicate)!
////                        XCTAssertEqual("fruit", String(data: Data(key), encoding: .utf8))
////                        XCTAssertEqual("apple", String(data: Data(value), encoding: .utf8))
////                    }
////                    do {
////                        var (key, value) = try cursor.move(to: .last, .duplicate)!
////                        XCTAssertEqual("", String(data: Data(key), encoding: .utf8))
////                        XCTAssertEqual("orange", String(data: Data(value), encoding: .utf8))
////                        (key, value) = try cursor.get()!
////                        XCTAssertEqual("fruit", String(data: Data(key), encoding: .utf8))
////                        XCTAssertEqual("orange", String(data: Data(value), encoding: .utf8))
////                    }
////                    do {
////                        let (key, value) = try cursor.move(to: .previous, .key)!
////                        XCTAssertEqual("animal", String(data: Data(key), encoding: .utf8))
////                        XCTAssertEqual("crow", String(data: Data(value), encoding: .utf8))
////                    }
//                    
//                    // Move to the next key (which is a duplicate) and verify
////                    let (_, secondValue) = try cursor.move(to: .next, .duplicate)
////                    XCTAssertEqual("dog", String(data: Data(secondValue), encoding: .utf8))
////                    
////                    // Move to the next key (which is the same duplicate) and verify
////                    let (_, thirdValue) = try cursor.move(to: .next, .duplicate)
////                    XCTAssertEqual("dog", String(data: Data(thirdValue), encoding: .utf8))
////                    
////                    // Move to the next key (which is a new key) and verify
////                    let (fourthKey, fourthValue) = try cursor.move(to: .next)
////                    XCTAssertEqual("fruit", String(data: Data(fourthKey), encoding: .utf8))
////                    XCTAssertEqual("apple", String(data: Data(fourthValue), encoding: .utf8))
////                    
////                    // Move to the last key and verify
////                    let (lastKey, lastValue) = try cursor.move(to: .last)
////                    XCTAssertEqual("fruit", String(data: Data(lastKey), encoding: .utf8))
////                    XCTAssertEqual("cherry", String(data: Data(lastValue), encoding: .utf8))
////                    
////                    // Move to the previous key (which is a duplicate) and verify
////                    let (_, prevValue) = try cursor.move(to: .previous, .duplicate)
////                    XCTAssertEqual("banana", String(data: Data(prevValue), encoding: .utf8))
////                    
////                    // Move to the first duplicate of the 'banana' key and verify
////                    let (_, firstDupValue) = try cursor.move(to: .first, .duplicate)
////                    XCTAssertEqual("banana", String(data: Data(firstDupValue), encoding: .utf8))
////                    
////                    // Verify the duplicate count for the 'banana' key
////                    let dupCount = try cursor.duplicateCount
////                    XCTAssertEqual(dupCount, 2)
////                    
////                    // Move to a specific key with precision exactly and verify
////                    let specificKey = "fruit".data(using: .utf8)!
////                    try specificKey.withUnsafeBytes { keyBuffer in
////                        let (specificKey, specificValue) = try cursor.move(.exactly, toKey: keyBuffer)
////                        XCTAssertEqual("fruit", String(data: Data(specificKey), encoding: .utf8))
////                        XCTAssertEqual("apple", String(data: Data(specificValue), encoding: .utf8))
////                    }
////                    
////                    // Move to a specific key with precision nearby and verify
////                    let nearbyKey = "garden".data(using: .utf8)!
////                    try nearbyKey.withUnsafeBytes { keyBuffer in
////                        let (nearbyKey, nearbyValue) = try cursor.move(.nearby, toKey: keyBuffer)
////                        XCTAssertEqual("fruit", String(data: Data(nearbyKey), encoding: .utf8))
////                        XCTAssertEqual("cherry", String(data: Data(nearbyValue), encoding: .utf8))
////                    }
//                }
//            }
//        }
//    }
//}
