/// The pair of `ByteCoder` to use to encode and decode keys and values.
public struct DatabaseSchema<KeyCoder: ByteEncoder, ValueCoder: ByteCoder> {
    /// The `ByteCoder` to use to encode and decode keys.
    public var keyCoder: KeyCoder
    
    /// The `ByteCoder` to use to encode and decode values.
    public var valueCoder: ValueCoder
    
    public init(keyCoder: KeyCoder, valueCoder: ValueCoder) {
        self.keyCoder = keyCoder
        self.valueCoder = valueCoder
    }
}

public typealias ByteCoder
    = ByteEncoder
    & ByteDecoder

public protocol ByteDecoder {
    associatedtype Output
    func decoding(_ buffer: UnsafeRawBufferPointer) throws -> Output
}

public protocol ByteEncoder {
    associatedtype Input
    func withEncoding<Result>(of input: Input, _ body: (UnsafeRawBufferPointer) throws -> Result) throws -> Result
}

extension ByteEncoder {
    @inlinable @inline(__always)
    internal func withEncodingOrNil<Result>(of input: Input?, _ body: (UnsafeRawBufferPointer?) throws -> Result) throws -> Result {
        guard let input else { return try body(nil) }
        return try withEncoding(of: input, body)
    }
}

public struct RawByteCoder {
    @inlinable @inline(__always)
    public init() {}
}

extension RawByteCoder: ByteEncoder {
    @inlinable @inline(__always)
    public func withEncoding<Result>(of input: ContiguousArray<UInt8>, _ body: (UnsafeRawBufferPointer) throws -> Result) throws -> Result {
        try input.withUnsafeBytes(body)
    }
}

extension RawByteCoder: ByteDecoder {
    @inlinable @inline(__always)
    public func decoding(_ buffer: UnsafeRawBufferPointer) -> ContiguousArray<UInt8> {
        .init(buffer)
    }
}

public struct RawBytePointerCoder {
    @inlinable @inline(__always)
    public init() {}
}

extension RawBytePointerCoder: ByteEncoder {
    @inlinable @inline(__always)
    public func withEncoding<Result>(of input: UnsafeRawBufferPointer, _ body: (UnsafeRawBufferPointer) throws -> Result) throws -> Result {
        try body(input)
    }
}

extension RawBytePointerCoder: ByteDecoder {
    @inlinable @inline(__always)
    public func decoding(_ buffer: UnsafeRawBufferPointer) -> UnsafeRawBufferPointer {
        buffer
    }
}
