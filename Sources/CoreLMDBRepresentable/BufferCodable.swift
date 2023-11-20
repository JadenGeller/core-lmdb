public protocol BufferCodable: RawBufferRepresentable {
    associatedtype BufferCoder: BufferCoderProtocol where BufferCoder.Decoded == Self
    static var bufferCoder: BufferCoder { get }
}

extension BufferCodable {
    @inlinable @inline(__always)
    public init(buffer: UnsafeRawBufferPointer) throws {
        self = try Self.bufferCoder.decoding(buffer)
    }
    
    @inlinable @inline(__always)
    public func withUnsafeBytes<R>(_ body: (UnsafeRawBufferPointer) throws -> R) throws -> R {
        try Self.bufferCoder.withEncoding(of: self, body)
    }
}
