import CoreLMDB

public struct VectorByteCoder<ElementCoder: FixedSizeBoundedByteDecoder & ByteEncoder>: FixedSizeBoundedByteDecoder, PrecountingByteEncoder {
    var elementCoder: ElementCoder
    var count: Int
    
    public var byteCount: Int {
        count * elementCoder.byteCount
    }
    
    public func decoding(_ buffer: UnsafeRawBufferPointer) throws -> [ElementCoder.Output] {
        var buffer = buffer
        var elements: [ElementCoder.Output] = []
        for _ in 0..<count {
            elements.append(try elementCoder.decoding(&buffer))
        }
        return elements
    }
    
    public func withEncoding<Result>(of input: [ElementCoder.Input], _ body: (UnsafeRawBufferPointer) throws -> Result) throws -> Result {
        var bytes = ContiguousArray<UInt8>()
        bytes.reserveCapacity(byteCount)
        for element in input {
            try elementCoder.withEncoding(of: element) {
                bytes.append(contentsOf: $0)
            }
        }
        return try bytes.withUnsafeBytes(body)
    }
}
