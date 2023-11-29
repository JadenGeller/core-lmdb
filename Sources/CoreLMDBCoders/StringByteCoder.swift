import CoreLMDB

public struct StringByteCoder {
    public init() {}
}

extension StringByteCoder: PrecountingByteEncoder {
    @inlinable @inline(__always)
    public func withEncoding<Result>(of input: String, _ body: (UnsafeRawBufferPointer) throws -> Result) throws -> Result {
        var input = input
        return try input.withUTF8 { try body(UnsafeRawBufferPointer($0)) }
    }
    
    @inlinable @inline(__always)
    public func underestimatedByteCount(for input: String) -> Int {
        input.utf8.count
    }
}

extension StringByteCoder: ByteDecoder {
    @inlinable @inline(__always)
    public func decoding(_ buffer: UnsafeRawBufferPointer) -> String {
        String(decoding: buffer, as: UTF8.self)
    }
}
