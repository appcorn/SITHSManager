//
//  Written by Martin Alléus, Appcorn AB, martin@appcorn.se
//
//  Copyright 2017 Svensk e-identitet AB
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the
//  "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish,
//  distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject
//  to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
//  MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR
//  ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH
//  THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

import Foundation

extension Sequence where Iterator.Element == UInt8 {
    /// Creates and returns a HEX string representation of the data in the byte array.
    ///
    /// - Parameter byteSeparator: If set to true (the default value), the bytes will be separated with a space.
    /// - Returns: An upper case HEX string represent of the byte array, for exampel "6D 61 72 74 69 6E" or "6D617274696E"
    func hexString(byteSeparator: Bool = true) -> String {
        var hexString = [String]()

        for byte in self {
            hexString.append(String(format: "%02X", byte))
        }

        return hexString.joined(separator: byteSeparator ? " " : "")
    }
}

extension Data {
    /// Creates and returns a HEX string representation of the data.
    ///
    /// - Parameter byteSeparator: If set to true (the default value), the bytes will be separated with a space.
    /// - Returns: An upper case HEX string represent of the data, for exampel "6D 61 72 74 69 6E" or "6D617274696E"
    func hexString(byteSeparator: Bool = true) -> String {
        var hexString = [String]()

        for i in 0..<count {
            hexString.append(String(format: "%02X", self[i]))
        }

        return hexString.joined(separator: byteSeparator ? " " : "")
    }

    /// Converts the byte array to a big endian signed integer. Note that byte arrays larger than 4 bytes will be truncated.
    ///
    /// - Returns: The big endian signed integer representation of up to 4 bytes in the byte array.
    func intValue() -> Int {
        var data = self

        switch count {
        case 0:
            return 0
        case 1:
            return Int(data[0])
        case 2:
            let value = data.withUnsafeBytes { (pointer: UnsafePointer<Int16>) in
                return pointer.pointee
            }
            return Int(Int16(bigEndian: value))
        case 3:
            // Only three bytes, add 0x00 padding to result in four bytes and continue to next case
            data =  Data(bytes: [0x00]) + data
            fallthrough
        case 4..<Int.max:
            let value = data.withUnsafeBytes { (pointer: UnsafePointer<Int32>) in
                return pointer.pointee
            }
            return Int(Int32(bigEndian: value))
        default:
            fatalError()
        }
    }

    /// Converts the byte array to a big endian unsigned integer. Note that byte arrays larger than 4 bytes will be truncated.
    ///
    /// - Returns: The big endian unsigned integer representation of up to 4 bytes in the byte array.
    func uintValue() -> UInt {
        var data = self

        switch count {
        case 0:
            return 0
        case 1:
            return UInt(data[0])
        case 2:
            let value = data.withUnsafeBytes { (pointer: UnsafePointer<UInt16>) in
                return pointer.pointee
            }
            return UInt(UInt16(bigEndian: value))
        case 3:
            // Only three bytes, add 0x00 padding to result in four bytes and continue to next case
            data =  Data(bytes: [0x00]) + data
            fallthrough
        case 4..<Int.max:
            let value = data.withUnsafeBytes { (pointer: UnsafePointer<UInt32>) in
                return pointer.pointee
            }
            return UInt(UInt32(bigEndian: value))
        default:
            fatalError()
        }
    }
}

extension Collection {
    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Generator.Element? {
        return index <= endIndex ? self[index] : nil
    }
}

extension UnsafeMutablePointer {
    /// Creates an array containing the values at the pointer.
    ///
    /// - Parameter count: Number of bytes to read from the pointer.
    /// - Returns: An array, conatining the bytes of data at the pointer.
    func valueArray(count: Int) -> [Pointee] {
        let buffer = UnsafeBufferPointer(start: self, count: count)
        return Array(buffer)
    }
}
