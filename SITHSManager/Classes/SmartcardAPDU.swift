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

enum SmartcardCommandError: Error {
    case commandDataTooLarge
    case responseTooSmall
}

struct SmartcardCommandAPDU {
    let instructionClass: UInt8
    let instructionCode: UInt8
    let instructionParameters: [UInt8]
    let commandData: Data?
    let expectedResponseBytes: UInt16?

    func mergedCommand() throws -> Data {
        var returnCommand = Data()

        returnCommand.append(instructionClass)
        returnCommand.append(instructionCode)
        returnCommand.append(contentsOf: instructionParameters)

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
                throw SmartcardCommandError.commandDataTooLarge
            }

            returnCommand.append(contentsOf: commandData)
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

    init(data: Data) {
        let bytes = [UInt8](data)

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
    let responseData: Data?
    let processingStatus: ProcessingStatus

    init(data: Data) throws {
        guard data.count >= 2 else {
            throw SmartcardCommandError.responseTooSmall
        }

        processingStatus = ProcessingStatus(data: data.subdata(in: data.count-2..<data.count))

        if data.count > 2 {
            responseData = data.subdata(in: 0..<data.count-2)
        } else {
            responseData = nil
        }
    }

    var description: String {
        return "<SmartcardResponseAPDU> processingStatus: \(processingStatus) responseData: \(responseData?.hexString() ?? "<Empty>")"
    }
}
