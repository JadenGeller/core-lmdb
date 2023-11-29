import CoreLMDB

public struct TupleByteCoder<First, Second> {
    public var first: First
    public var second: Second
    
    public init(_ first: First, _ second: Second) {
        self.first = first
        self.second = second
    }
}

extension TupleByteCoder: ByteDecoder where First: BoundedByteDecoder, Second: ByteDecoder {
    public func decoding(_ buffer: UnsafeRawBufferPointer) throws -> (First.Output, Second.Output) {
        var buffer = buffer
        return (try first.decoding(&buffer), try second.decoding(buffer))
    }
}

extension TupleByteCoder: ByteEncoder where First: ByteEncoder, Second: ByteEncoder {
    public func withEncoding<Result>(of input: (First.Input, Second.Input), _ body: (UnsafeRawBufferPointer) throws -> Result) throws -> Result {
        var bytes = ContiguousArray<UInt8>()
        try first.withEncoding(of: input.0) { bytes.append(contentsOf: $0) }
        try second.withEncoding(of: input.1) { bytes.append(contentsOf: $0) }
        return try bytes.withUnsafeBytes(body)
    }
}

extension TupleByteCoder: PrecountingByteEncoder where First: PrecountingByteEncoder, Second: PrecountingByteEncoder {
    public func withEncoding<Result>(of input: (First.Input, Second.Input), _ body: (UnsafeRawBufferPointer) throws -> Result) throws -> Result {
        var bytes = ContiguousArray<UInt8>()
        bytes.reserveCapacity(underestimatedByteCount(for: input))
        try first.withEncoding(of: input.0) { bytes.append(contentsOf: $0) }
        try second.withEncoding(of: input.1) { bytes.append(contentsOf: $0) }
        return try bytes.withUnsafeBytes(body)
    }
    
    public func underestimatedByteCount(for input: (First.Input, Second.Input)) -> Int {
        first.underestimatedByteCount(for: input.0) + second.underestimatedByteCount(for: input.1)
    }
}
