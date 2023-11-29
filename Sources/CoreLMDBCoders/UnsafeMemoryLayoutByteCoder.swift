import CoreLMDB

public protocol UnsafeMemoryLayoutStorable {}

public struct UnsafeMemoryLayoutByteCoder<Element: UnsafeMemoryLayoutStorable>: FixedSizeBoundedByteDecoder, PrecountingByteEncoder {
    var count: Int
    
    public init(count: Int) {
        self.count = count
    }
    
    public var byteCount: Int {
        count * MemoryLayout<Element>.size
    }
    
    public func decoding(_ buffer: UnsafeRawBufferPointer) throws -> [Element] {
        Array(buffer.bindMemory(to: Element.self))
    }
    
    public func withEncoding<Result>(of input: [Element], _ body: (UnsafeRawBufferPointer) throws -> Result) throws -> Result {
        try input.withUnsafeBytes(body)
    }
}
