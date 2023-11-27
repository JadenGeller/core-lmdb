import CoreLMDB

public protocol ByteCodable {
    associatedtype ByteCoder: CoreLMDB.ByteCoder where ByteCoder.Input == Self, ByteCoder.Output == Self
    static var byteCoder: ByteCoder { get }
}
