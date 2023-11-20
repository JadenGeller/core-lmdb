public protocol BufferCoderProtocol {
    associatedtype Decoded
    @discardableResult func scanning(partial buffer: inout Slice<UnsafeRawBufferPointer>) throws -> Slice<UnsafeRawBufferPointer>
    func decoding(partial buffer: inout Slice<UnsafeRawBufferPointer>) throws -> Decoded
    func withEncoding<Result>(of decoded: Decoded, _ body: (UnsafeRawBufferPointer) throws -> Result) throws -> Result
    var underestimatedByteCount: Int { get }
}
extension BufferCoderProtocol {
    @inlinable @inline(__always)
    public func decoding(_ buffer: UnsafeRawBufferPointer) throws -> Decoded {
        var buffer = buffer[...]
        defer { assert(buffer.isEmpty) } // FIXME: This behavior is inconsistent with elsewhere
        return try decoding(partial: &buffer)
    }
    @inlinable @inline(__always)
    public var underestimatedByteCount: Int {
        0
    }
}

extension MemoryLayout where T: GuarenteedStableFixedSizeMemoryLayout {
    public struct ContiguousArrayBufferCoder: BufferCoderProtocol {
        public var count: Int
        public init(count: Int) {
            self.count = count
        }
        
        @discardableResult @inlinable @inline(__always)
        public func scanning(partial buffer: inout Slice<UnsafeRawBufferPointer>) throws -> Slice<UnsafeRawBufferPointer> {
            let endIndex = buffer.index(buffer.startIndex, offsetBy: MemoryLayout.size * count)
            defer { buffer = buffer[endIndex...] }
            return buffer[..<endIndex]
        }
        
        @inlinable @inline(__always)
        public func decoding(partial buffer: inout Slice<UnsafeRawBufferPointer>) throws -> ContiguousArray<T> {
            ContiguousArray(try scanning(partial: &buffer).bindMemory(to: T.self))
        }
        
        @inlinable @inline(__always)
        public func withEncoding<Result>(of decoded: ContiguousArray<T>, _ body: (UnsafeRawBufferPointer) throws -> Result) rethrows -> Result {
            try decoded.withUnsafeBytes(body)
        }
        
        @inlinable @inline(__always)
        public var underestimatedByteCount: Int {
            MemoryLayout.size * count
        }
    }
    public struct BufferCoder: BufferCoderProtocol {
        public init() {}
        
        @discardableResult @inlinable @inline(__always)
        public func scanning(partial buffer: inout Slice<UnsafeRawBufferPointer>) throws -> Slice<UnsafeRawBufferPointer> {
            let endIndex = buffer.index(buffer.startIndex, offsetBy: MemoryLayout.size)
            defer { buffer = buffer[endIndex...] }
            return buffer[..<endIndex]
        }
        
        @inlinable @inline(__always)
        public func decoding(partial buffer: inout Slice<UnsafeRawBufferPointer>) throws -> T {
            try scanning(partial: &buffer).loadUnaligned(as: T.self)
        }
        
        @inlinable @inline(__always)
        public func withEncoding<Result>(of decoded: T, _ body: (UnsafeRawBufferPointer) throws -> Result) rethrows -> Result {
            try withUnsafeBytes(of: decoded, body)
        }
        
        @inlinable @inline(__always)
        public var underestimatedByteCount: Int {
            MemoryLayout.size
        }
    }
}

public struct PackedBufferCoder<First: BufferCoderProtocol, Second: BufferCoderProtocol>: BufferCoderProtocol {
    public var first: First
    public var second: Second
    
    @inlinable @inline(__always)
    public init(_ first: First, _ second: Second) {
        self.first = first
        self.second = second
    }
    
    @discardableResult @inlinable @inline(__always)
    public func scanning(partial buffer: inout Slice<UnsafeRawBufferPointer>) throws -> Slice<UnsafeRawBufferPointer> {
        let first = try first.scanning(partial: &buffer)
        let second = try second.scanning(partial: &buffer)
        assert(first.endIndex == second.startIndex) // FIXME: Would be great if protocol was designed so that this weren't necessary
        return .init(base: first.base, bounds: first.startIndex..<second.endIndex)
    }
    
    @inlinable @inline(__always)
    public func decoding(partial buffer: inout Slice<UnsafeRawBufferPointer>) throws -> (First.Decoded, Second.Decoded) {
        (try first.decoding(partial: &buffer), try second.decoding(partial: &buffer))
    }
    
    @inlinable @inline(__always)
    public func withEncoding<Result>(of decoded: (First.Decoded, Second.Decoded), _ body: (UnsafeRawBufferPointer) throws -> Result) throws -> Result {
        var bytes = ContiguousArray<UInt8>()
        bytes.reserveCapacity(first.underestimatedByteCount + second.underestimatedByteCount)
        try first.withEncoding(of: decoded.0) { bytes.append(contentsOf: $0) }
        try second.withEncoding(of: decoded.1) { bytes.append(contentsOf: $0) }
        return try bytes.withUnsafeBytes(body)
    }
}

// FIXME: Can this API be improved to be safer?
// Consumes the entire buffer! Cannot be composed except in the final position
public struct RawBufferRepresentableCoder<Value: RawBufferRepresentable>: BufferCoderProtocol {
    @inlinable @inline(__always)
    public init() {}
    
    @discardableResult @inlinable @inline(__always)
    public func scanning(partial buffer: inout Slice<UnsafeRawBufferPointer>) throws -> Slice<UnsafeRawBufferPointer> {
        defer { buffer = buffer[buffer.endIndex...] }
        return buffer
    }
    
    @inlinable @inline(__always)
    public func decoding(partial buffer: inout Slice<UnsafeRawBufferPointer>) throws -> Value {
        try .init(buffer: UnsafeRawBufferPointer(rebasing: buffer))
    }
    
    @inlinable @inline(__always)
    public func withEncoding<Result>(of decoded: Value, _ body: (UnsafeRawBufferPointer) throws -> Result) throws -> Result {
        try decoded.withUnsafeBytes(body)
    }
}
