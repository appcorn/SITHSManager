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

enum TypeTag {
    case universal(typeTag: UniversalTypeTag)
    case application(number: UInt8)
    case contextSpecific(number: UInt8)
    case unknown(rawTypeTag: UInt8)
}

enum UniversalTypeTag: UInt8 {
    case boolean = 0x01
    case integer = 0x02
    case bitString = 0x03
    case octetString = 0x04
    case objectIdentifier = 0x06
    case sequence = 0x30
    case set = 0x31
    case utf8String = 0x0C
    case printableString = 0x13
    case ia5String = 0x16
    case utcTime = 0x17
    case null = 0x05
}

public indirect enum ElementsOrRawValue: CustomStringConvertible {
    case elements(elements: [ASN1Element])
    case rawValue(value: Data)

    init(content: Data) {
        let parser = ASN1Parser(data: content)

        var elements = [ASN1Element]()
        var foundUnknown = false

        while let parsed = parser.parseElement() {
            switch parsed.element {
            case .unknown:
                foundUnknown = true
                break
            default:
                elements.append(parsed.element)
            }
        }

        if elements.count == 0 || foundUnknown {
            // Ignore unkown elements when determining element or raw value
            self = .rawValue(value: content)
        } else {
            self = .elements(elements: elements)
        }
    }

    public var description: String {
        switch self {
        case .elements(let element):
            return "Element: \(element)"
        case .rawValue(let value):
            return "Raw Value: \(value)"
        }
    }
}

public indirect enum ASN1Element: CustomStringConvertible {
    case unknown(rawTypeTag: UInt8, value: Data)
    case boolean(value: Bool)
    case integer(value: Data)
    case bitString(value: ElementsOrRawValue)
    case octetString(value: ElementsOrRawValue)
    case objectIdentifier(value: ASN1ObjectIdentifier)
    case utf8String(value: String)
    case printableString(value: String)
    case ia5String(value: String)
    case utcTime(value: String)
    case null
    case sequence(elements: [ASN1Element])
    case set(elements: [ASN1Element])
    case contextSpecific(number: UInt8, value: ElementsOrRawValue)
    case application(number: UInt8, value: ElementsOrRawValue)

    init?(typeTag: TypeTag, content: Data) {
        switch typeTag {
        case .unknown(let rawTypeTag):
            self = .unknown(rawTypeTag: rawTypeTag, value: content)

        case .universal(.boolean):
            guard let byte = content[safe: 0] else {
                return nil
            }
            self = .boolean(value: byte == 0xFF)

        case .universal(.integer):
            self = .integer(value: content)

        case .universal(.sequence), .universal(.set):
            let parser = ASN1Parser(data: content)

            var elements = [ASN1Element]()

            while let parsed = parser.parseElement() {
                elements.append(parsed.element)
            }

            switch typeTag {
            case .universal(.sequence):
                self = .sequence(elements: elements)
            case .universal(.set):
                self = .set(elements: elements)
            default:
                fatalError()
            }

        case .universal(.octetString):
            self = .octetString(value: ElementsOrRawValue(content: content))

        case .universal(.bitString):
            self = .bitString(value: ElementsOrRawValue(content: content))

        case .universal(.objectIdentifier):
            self = .objectIdentifier(value: ASN1ObjectIdentifier(data: content))

        case .universal(.printableString), .universal(.ia5String):
            guard let string = String(data: content, encoding: .ascii) else {
                return nil
            }

            switch typeTag {
            case .universal(.printableString):
                self = .printableString(value: string)
            case .universal(.ia5String):
                self = .ia5String(value: string)
            default:
                fatalError()
            }

        case .universal(.utf8String), .universal(.utcTime):
            guard let string = String(data: content, encoding: .utf8) else {
                return nil
            }

            switch typeTag {
            case .universal(.utf8String):
                self = .utf8String(value: string)
            case .universal(.utcTime):
                self = .utcTime(value: string)
            default:
                fatalError()
            }

        case .universal(.null):
            self = .null

        case .contextSpecific(let number):
            self = .contextSpecific(number: number, value: ElementsOrRawValue(content: content))

        case .application(let number):
            self = .application(number: number, value: ElementsOrRawValue(content: content))
        }
    }

    public var description: String {
        switch self {
        case .unknown(let value):
            return "Unknown: \(value)"
        case .boolean(let value):
            return "Boolean: \(value ? "true" : "false")"
        case .integer(let value):
            var string = "Integer, \(value.count * 8) bit: "
            if value.count <= 4 {
                // It's 32bit or smaller, print it as an integer value
                string += "\(value.intValue()) "
            }
            string += "\(value)"
            return string
        case .bitString(let value):
            return elementListDescription(elements: [value], title: "Bit String")
        case .octetString(let value):
            return elementListDescription(elements: [value], title: "Octet String")
        case .objectIdentifier(let value):
            return "Object Identifier: \(value)"
        case .utf8String(let value):
            return "UTF8 String: \(value)"
        case .printableString(let value):
            return "Printable String: \(value)"
        case .ia5String(let value):
            return "IA5 String: \(value)"
        case .utcTime(let value):
            return "UTC Time: \(value)"
        case .null:
            return "NULL"
        case .sequence(let elements):
            return elementListDescription(elements: elements, title: "Sequence")
        case .set(let elements):
            return elementListDescription(elements: elements, title: "Set")
        case .contextSpecific(let number, let value):
            switch value {
            case .elements(let element):
                return elementListDescription(elements: [element], title: "[\(number)]")
            case .rawValue(let value):
                return elementListDescription(elements: [value], title: "[\(number)]")
            }
        case .application(let number, let value):
            switch value {
            case .elements(let element):
                return elementListDescription(elements: [element], title: "Application \(number)")
            case .rawValue(let value):
                return elementListDescription(elements: [value], title: "Application \(number)")
            }
        }
    }

    fileprivate func elementListDescription<T: CustomStringConvertible>(elements: [T], title: String) -> String {
        var string = "\(title) (\(elements.count)): [\n"

        for element in elements {
            let elementDescription = element.description

            for line in elementDescription.components(separatedBy: "\n") {
                string += "  \(line)\n"
            }
        }

        string += "]"

        return string
    }
}

public class ASN1Parser {
    fileprivate struct ASN1ParserConstants {
        static let ElementLongLength: UInt8 = 0b10000000
        static let TypeTagContextSpecific: UInt8 = 0b10000000
        static let TypeTagApplication: UInt8 = 0b01000000
        static let IdentifierNumberBitMask: UInt8 = 0b00011111
    }

    let data: Data

    var position: Int = 0
    var failed: Bool = false

    init(data: Data) {
        self.data = data
    }

    func parseElement() -> (element: ASN1Element, data: Data, cardCertificate: SITHSCardCertificate?)? {
        guard let parsedTypeTag = parseTypeTag() else {
            // Tag parsing failed
            return nil
        }

        let startPosition = position - 1

        guard let parsedLength = parseLength() else {
            // Length parsing failed
            return nil
        }

        guard let readBytes = readBytes(count: parsedLength) else {
            // Bytes reading failed
            return nil
        }

        guard let element = ASN1Element(typeTag: parsedTypeTag, content: readBytes) else {
            // Could not read element
            failed = true
            return nil
        }

        let subdata = data.subdata(in: startPosition..<position)
        let cardCertificate = SITHSCardCertificate(rootElement: element, derData: subdata)

        return (element: element, data: subdata, cardCertificate: cardCertificate)
    }

    fileprivate func parseTypeTag() -> TypeTag? {
        guard let typeTagByte = readBytes(count: 1)?.first else {
            // Not enough bytes to read tag
            return nil
        }

        if typeTagByte == 0xFF {
            failed = true
            return nil
        }

        if typeTagByte & ASN1ParserConstants.TypeTagContextSpecific == ASN1ParserConstants.TypeTagContextSpecific {
            // Context specific, get number and return
            let number = typeTagByte & ASN1ParserConstants.IdentifierNumberBitMask

            return .contextSpecific(number: number)
        }

        if typeTagByte & ASN1ParserConstants.TypeTagApplication == ASN1ParserConstants.TypeTagApplication {
            // Application, get number and return
            let number = typeTagByte & ASN1ParserConstants.IdentifierNumberBitMask

            return .application(number: number)
        }

        guard let universalTypeTag = UniversalTypeTag(rawValue: typeTagByte) else {
            // Unknown type tag
            return .unknown(rawTypeTag: typeTagByte)
        }
        
        return .universal(typeTag: universalTypeTag)
    }

    fileprivate func parseLength() -> Int? {
        guard let firstLengthByte = readBytes(count: 1)?.first else {
            // Not enough bytes to read length
            return nil
        }

        if firstLengthByte & ASN1ParserConstants.ElementLongLength == 0 {
            // Single byte element length
            return Int(firstLengthByte)
        }

        let octets = firstLengthByte ^ ASN1ParserConstants.ElementLongLength

        guard let lengthOctetBytes = readBytes(count: Int(octets)) else {
            // Not enough bytes to read length
            return nil
        }

        return Int(lengthOctetBytes.uintValue())
    }

    fileprivate func readBytes(count: Int) -> Data? {
        if data.count < position + count {
            // Not enough bytes yet
            return nil
        }

        let read = data.subdata(in: position..<position+count)
        position += count

        return read
    }

}
