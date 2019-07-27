typealias Byte = UInt64

extension Byte {
    private static let bytesInKByte: UInt64 = 1024
    private static let kByteInMByte: UInt64 = 1024

    static let kByte = bytesInKByte
    static let mByte = kByteInMByte * kByte
}
