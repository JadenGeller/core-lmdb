import CoreLMDB

public protocol UnsafeMemoryLayoutStorableFloat: BinaryFloatingPoint, UnsafeMemoryLayoutStorable {}
extension Float16: UnsafeMemoryLayoutStorableFloat {}
extension Float32: UnsafeMemoryLayoutStorableFloat {}
extension Float64: UnsafeMemoryLayoutStorableFloat {}

public struct FloatByteCoder<Decoded: UnsafeMemoryLayoutStorableFloat> {
    public init(_ type: Decoded.Type) {}
}

extension FloatByteCoder: FixedSizeBoundedByteDecoder, PrecountingByteEncoder {
    @inlinable @inline(__always)
    public func withEncoding<Result>(of input: Decoded, _ body: (UnsafeRawBufferPointer) throws -> Result) throws -> Result {
        try withUnsafeBytes(of: input, body)
    }

    @inlinable @inline(__always)
    public var byteCount: Int {
        MemoryLayout<Decoded>.size
    }
    
    @inlinable @inline(__always)
    public func decoding(_ buffer: UnsafeRawBufferPointer) throws -> Decoded {
        buffer.loadUnaligned(as: Decoded.self)
    }
}
