import Foundation

public protocol RawBufferRepresentable {
    init(buffer: UnsafeRawBufferPointer) throws
    func withUnsafeBytes<R>(_ body: (UnsafeRawBufferPointer) throws -> R) rethrows -> R
}

extension Data: RawBufferRepresentable {
    @inlinable @inline(__always)
    public init(buffer: UnsafeRawBufferPointer) throws {
        guard let bytes = buffer.baseAddress else { self.init(); return }
        self.init(bytes: bytes, count: buffer.count)
    }
}

extension String: RawBufferRepresentable {
    public init(buffer: UnsafeRawBufferPointer) throws {
        self.init(decoding: buffer, as: UTF8.self)
    }

    public func withUnsafeBytes<R>(_ body: (UnsafeRawBufferPointer) throws -> R) rethrows -> R {
        try data(using: .utf8)!.withUnsafeBytes(body)
    }
}
