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

enum SmartcardCommandError: ErrorType {
    case CommandDataTooLarge
    case ResponseTooSmall
}

struct SmartcardCommandAPDU {
    let instructionClass: UInt8
    let instructionCode: UInt8
    let instructionParameters: [UInt8]
    let commandData: [UInt8]?
    let expectedResponseBytes: UInt16?

    func mergedCommand() throws -> [UInt8] {
        var returnCommand = [UInt8]()

        returnCommand.append(instructionClass)
        returnCommand.append(instructionCode)
        returnCommand.appendContentsOf(instructionParameters)

        var commandDataPresent: Bool

        if let commandData = commandData {
            commandDataPresent = true

            if commandData.count <= Int(UInt8.max) {
                returnCommand.append(UInt8(commandData.count))
            } else if commandData.count <= Int(UInt16.max) {
                returnCommand.append(0x00)

                let length = UInt16(commandData.count)
                returnCommand.append(UInt8(truncatingBitPattern: length >> 8))
                returnCommand.append(UInt8(truncatingBitPattern: length))
            } else {
                throw SmartcardCommandError.CommandDataTooLarge
            }

            returnCommand.appendContentsOf(commandData)
        } else {
            commandDataPresent = false
        }

        if let expectedResponseBytes = expectedResponseBytes {
            if expectedResponseBytes <= UInt16(UInt8.max) {
                returnCommand.append(UInt8(expectedResponseBytes))
            } else {
                if commandDataPresent {
                    returnCommand.append(0x00)
                }

                returnCommand.append(UInt8(truncatingBitPattern: expectedResponseBytes >> 8))
                returnCommand.append(UInt8(truncatingBitPattern: expectedResponseBytes))
            }
        }

        return returnCommand
    }
}

enum ProcessingStatus {
    case success
    case successWithResponse(availableBytes: UInt8)
    case incorrectExpectedResponseBytes(correctExpectedResponseBytes: UInt8)
    case fileNotFound
    case incorrectInstructionParameters
    case unknown(statusCode: [UInt8])

    init(bytes: [UInt8]) {
        if bytes == [0x90, 0x00] {
            self = .success
        } else if bytes == [0x6a, 0x82] {
            self = .fileNotFound
        } else if bytes == [0x6a, 0x86] {
            self = .incorrectInstructionParameters
        } else if bytes[0] == 0x61 {
            self = .successWithResponse(availableBytes: bytes[1])
        } else if bytes[0] == 0x6c {
            self = .incorrectExpectedResponseBytes(correctExpectedResponseBytes: bytes[1])
        } else {
            self = .unknown(statusCode: bytes)
        }
    }
}

struct SmartcardResponseAPDU: CustomStringConvertible {
    let responseData: NSData?
    let processingStatus: ProcessingStatus

    init(bytes: [UInt8]) throws {
        guard bytes.count >= 2 else {
            throw SmartcardCommandError.ResponseTooSmall
        }

        processingStatus = ProcessingStatus(bytes: Array(bytes[bytes.count-2..<bytes.count]))

        if bytes.count > 2 {
            let pointer = UnsafePointer<UInt8>(bytes)
            responseData = NSData(bytes: pointer, length: bytes.count - 2)
        } else {
            responseData = nil
        }
    }

    var description: String {
        return "<SmartcardResponseAPDU> processingStatus: \(processingStatus) responseData: \(responseData?.hexString() ?? "<Empty>")"
    }
}
