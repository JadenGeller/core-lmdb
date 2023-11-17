// https://github.com/apple/swift/blob/3bd764d70b01a9a8770117b70285e83903c801d3/docs/ABI/TypeLayout.rst
public protocol GuarenteedStableFixedSizeMemoryLayout: RawBufferRepresentable { }
extension GuarenteedStableFixedSizeMemoryLayout {
    public init(buffer: UnsafeRawBufferPointer) throws {
        self = buffer.loadUnaligned(as: Self.self)
    }
    public func withUnsafeBytes<R>(_ body: (UnsafeRawBufferPointer) throws -> R) rethrows -> R {
        try Swift.withUnsafeBytes(of: self, body)
    }
}

extension Int8: GuarenteedStableFixedSizeMemoryLayout { }
extension Int16: GuarenteedStableFixedSizeMemoryLayout { }
extension Int32: GuarenteedStableFixedSizeMemoryLayout { }
extension Int64: GuarenteedStableFixedSizeMemoryLayout { }
extension UInt8: GuarenteedStableFixedSizeMemoryLayout { }
extension UInt16: GuarenteedStableFixedSizeMemoryLayout { }
extension UInt32: GuarenteedStableFixedSizeMemoryLayout { }
extension UInt64: GuarenteedStableFixedSizeMemoryLayout { }
extension Float16: GuarenteedStableFixedSizeMemoryLayout { }
extension Float32: GuarenteedStableFixedSizeMemoryLayout { }
extension Float64: GuarenteedStableFixedSizeMemoryLayout { }

extension ContiguousArray: RawBufferRepresentable where Element: GuarenteedStableFixedSizeMemoryLayout {
    public init(buffer: UnsafeRawBufferPointer) throws {
        self.init(buffer.bindMemory(to: Element.self))
    }
}
