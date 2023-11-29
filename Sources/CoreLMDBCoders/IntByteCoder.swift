import CoreLMDB
import CoreFoundation

public protocol UnsafeMemoryLayoutStorableInteger: FixedWidthInteger, UnsafeMemoryLayoutStorable {}
extension Int8: UnsafeMemoryLayoutStorableInteger {}
extension Int16: UnsafeMemoryLayoutStorableInteger {}
extension Int32: UnsafeMemoryLayoutStorableInteger {}
extension Int64: UnsafeMemoryLayoutStorableInteger {}
extension UInt8: UnsafeMemoryLayoutStorableInteger {}
extension UInt16: UnsafeMemoryLayoutStorableInteger {}
extension UInt32: UnsafeMemoryLayoutStorableInteger {}
extension UInt64: UnsafeMemoryLayoutStorableInteger {}

public struct IntByteCoder<Decoded: UnsafeMemoryLayoutStorableInteger> {
    public enum Endianness {
        case little
        case big
    }
    public var endianness: Endianness
    
    public init(_ type: Decoded.Type, endianness: Endianness) {
        self.endianness = endianness
    }
}
extension IntByteCoder.Endianness {
    @inlinable @inline(__always)
    internal func transform(_ value: Decoded) -> Decoded {
        switch self {
        case .little: value.littleEndian
        case .big: value.bigEndian
        }
    }
    
    @inlinable @inline(__always)
    var isPlatformByteOrder: Bool {
        transform(1) == 1
    }
}

extension IntByteCoder: PrecountingByteEncoder, FixedSizeBoundedByteDecoder {
    @inlinable @inline(__always)
    public func withEncoding<Result>(of input: Decoded, _ body: (UnsafeRawBufferPointer) throws -> Result) throws -> Result {
        try withUnsafeBytes(of: endianness.transform(input), body)
    }

    @inlinable @inline(__always)
    public var byteCount: Int {
        MemoryLayout<Decoded>.size
    }
    
    @inlinable @inline(__always)
    public func decoding(_ buffer: UnsafeRawBufferPointer) throws -> Decoded {
        endianness.transform(buffer.loadUnaligned(as: Decoded.self))
    }
}
