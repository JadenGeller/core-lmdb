import CoreLMDB

// MARK: Input

public struct MapInputByteCoder<Base: ByteEncoder, Input>: ByteEncoder {
    var base: Base
    var transform: (Input) throws -> Base.Input
    
    public init(_ base: Base, _ transform: @escaping (Input) throws -> Base.Input) {
        self.base = base
        self.transform = transform
    }

    public func withEncoding<Result>(of input: Input, _ body: (UnsafeRawBufferPointer) throws -> Result) throws -> Result {
        try base.withEncoding(of: try transform(input), body)
    }
}
extension MapInputByteCoder: PrecountingByteEncoder where Base: PrecountingByteEncoder {
    public func underestimatedByteCount(for input: Input) throws -> Int {
        try base.underestimatedByteCount(for: try transform(input))
    }
}

extension MapInputByteCoder: ByteDecoder where Base: ByteDecoder {
    public typealias Output = Base.Output
    
    public func decoding(_ buffer: UnsafeRawBufferPointer) throws -> Base.Output {
        try base.decoding(buffer)
    }
}

extension MapInputByteCoder: BoundedByteDecoder where Base: BoundedByteDecoder {
    public func scanning(_ buffer: inout UnsafeRawBufferPointer) throws -> UnsafeRawBufferPointer {
        try base.scanning(&buffer)
    }
    
    public func decoding(_ buffer: inout UnsafeRawBufferPointer) throws -> Base.Output {
        try base.decoding(&buffer)
    }
}

extension MapInputByteCoder: FixedSizeBoundedByteDecoder where Base: FixedSizeBoundedByteDecoder {
    public var byteCount: Int {
        base.byteCount
    }
}

// MARK: Output

public struct MapOutputByteCoder<Base: ByteDecoder, Output>: ByteDecoder {
    var base: Base
    var transform: (Base.Output) throws -> Output
    
    public init(_ base: Base, _ transform: @escaping (Base.Output) throws -> Output) {
        self.base = base
        self.transform = transform
    }

    public func decoding(_ buffer: UnsafeRawBufferPointer) throws -> Output {
        try transform(try base.decoding(buffer))
    }
}

extension MapOutputByteCoder: BoundedByteDecoder where Base: BoundedByteDecoder {
    public func scanning(_ buffer: inout UnsafeRawBufferPointer) throws -> UnsafeRawBufferPointer {
        try base.scanning(&buffer)
    }
    
    public func decoding(_ buffer: inout UnsafeRawBufferPointer) throws -> Output {
        try transform(try base.decoding(&buffer))
    }
}

extension MapOutputByteCoder: FixedSizeBoundedByteDecoder where Base: FixedSizeBoundedByteDecoder {
    public var byteCount: Int {
        base.byteCount
    }
}
