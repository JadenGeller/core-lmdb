import XCTest
import System
import CoreLMDB
import CoreLMDBRepresentable

// TODO: Delete
class LMDBTestCase: XCTestCase {
}

func withFreshPath(_ block: (FilePath) throws -> Void) throws {
    let path = FilePath(root: .init(FileManager.default.temporaryDirectory.path), components: "CoreLMDBTests")
    if FileManager.default.fileExists(atPath: path.string) {
        try FileManager.default.removeItem(atPath: path.string)
    }
    try FileManager.default.createDirectory(atPath: path.string, withIntermediateDirectories: false)
    try block(path)
    try FileManager.default.removeItem(atPath: path.string)
}

func withEnvironment(at path: FilePath, _ block: (Environment) throws -> Void, setup: (Environment) throws -> Void = { _ in }) throws {
    let env = try Environment()
    try setup(env)
    try env.open(path: path)
    try block(env)
    env.close()

}

func withFreshEnvironment(_ block: (Environment) throws -> Void, setup: (Environment) throws -> Void = { _ in }) throws {
    try withFreshPath { path in
        try withEnvironment(at: path) {
            try block($0)
        } setup: {
            try setup($0)
        }
    }
}

func withFreshWriteTransaction(_ block: (Transaction) throws -> Void) throws {
    try withFreshEnvironment { env in
        try env.withTransaction(.write) { txn in
            try block(txn)
        }
    }
}

func assertCursor<Key: RawBufferRepresentable & Equatable, Value: RawBufferRepresentable & Equatable>(
    _ expected: (key: Key, value: Value)?,
    _ block: ((Key.Type, Value.Type)) throws -> (key: Key, value: Value)?,
    file: StaticString = #filePath,
    line: UInt = #line
) rethrows {
    let actual = try block((Key.self, Value.self))
    XCTAssertEqual(expected?.key, actual?.key, file: file, line: line)
    XCTAssertEqual(expected?.value, actual?.value, file: file, line: line)
}

extension Transaction {
    func createSampleDatabase<Key: RawBufferRepresentable & Hashable, Value: RawBufferRepresentable>(with sampleData: [Key: Value]) throws -> Database {
        let db = try Database.open(in: self)
        for (key, value) in sampleData {
            try db.put(value, atKey: key, in: self)
        }
        return db
    }
}
