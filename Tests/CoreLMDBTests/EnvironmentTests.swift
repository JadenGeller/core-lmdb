import XCTest
import CoreLMDB

final class EnvironmentTests: LMDBTestCase {
    func testFilesCreated() throws {
        try withFreshPath { path in
            let env = try Environment()
            try env.open(path: path)
            XCTAssert(FileManager.default.fileExists(atPath: path.appending("data.mdb").string))
            XCTAssert(FileManager.default.fileExists(atPath: path.appending("lock.mdb").string))
            env.close()
            XCTAssert(FileManager.default.fileExists(atPath: path.appending("data.mdb").string))
            XCTAssert(FileManager.default.fileExists(atPath: path.appending("lock.mdb").string))
        }
    }
}
