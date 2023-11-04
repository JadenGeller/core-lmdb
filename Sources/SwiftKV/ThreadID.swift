import Darwin

public struct ThreadID: Equatable, Sendable {
    public var value: UInt64
    @inlinable public init(value: UInt64) {
        self.value = value
    }
    
    @inlinable static var current: Self {
        var value: UInt64 = 0
        pthread_threadid_np(pthread_self(), &value)
        return .init(value: value)
    }
}
