import CoreLMDB

// MARK: Decoding

public protocol BoundedByteDecoder: ByteDecoder {
    func scanning(_ buffer: inout UnsafeRawBufferPointer) throws -> UnsafeRawBufferPointer
    func decoding(_ buffer: inout UnsafeRawBufferPointer) throws -> Output
}

public protocol FixedSizeBoundedByteDecoder: BoundedByteDecoder {
    var byteCount: Int { get }
}

extension FixedSizeBoundedByteDecoder {
    @inlinable @inline(__always)
    public func scanning(_ buffer: inout UnsafeRawBufferPointer) throws -> UnsafeRawBufferPointer {
        defer { buffer = .init(rebasing: buffer[byteCount...]) }
        return .init(rebasing: buffer[..<byteCount])
    }
    
    @inlinable @inline(__always)
    public func decoding(_ buffer: inout UnsafeRawBufferPointer) throws -> Output {
        return try decoding(scanning(&buffer))
    }
}

public protocol DynamicSizeBoundedByteDecoder: BoundedByteDecoder { }

extension DynamicSizeBoundedByteDecoder {
    @inlinable @inline(__always)
    public func decoding(_ buffer: UnsafeRawBufferPointer) throws -> Output {
        var buffer = buffer
        defer { assert(buffer.isEmpty) }
        return try decoding(&buffer)
    }
}

// MARK: Encoding

public protocol PrecountingByteEncoder: ByteEncoder {
    func underestimatedByteCount(for input: Input) throws -> Int
}

extension PrecountingByteEncoder {
    public func underestimatedByteCount(for input: Input) -> Int {
        0
    }
}

extension PrecountingByteEncoder where Self: FixedSizeBoundedByteDecoder {
    public func underestimatedByteCount(for input: Input) -> Int {
        byteCount
    }
}
