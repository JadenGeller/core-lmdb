import XCTest
import System
import CoreLMDB
import CoreLMDBCollections

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

final class EnvironmentTests: XCTestCase {
    func testWhatever() throws {
        try withFreshPath { path in
            try withEnvironment(at: path) { env in
                let db = try env.withTransaction(.write) { txn in
                    try DurableSortedDictionary<String, Int32>.Database.open(in: txn)
                }
                try env.withTransaction(.write) { txn in
                    var dict = DurableSortedDictionary(database: db, in: txn)
                    
                    dict["jaden"] = 10
                    dict["sawyer", default: 3] += 1
                    
                    dict.merge([("jaden", 5)], uniquingKeysWith: *)
                    dict["sawyer"] = nil

                    for (key, value) in dict {
                        print(key, value)
                    }
                }
            }
        }
    }
}
