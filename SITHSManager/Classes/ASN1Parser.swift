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
    case Universal(typeTag: UniversalTypeTag)
    case Application(number: UInt8)
    case ContextSpecific(number: UInt8)
    case Unknown(rawTypeTag: UInt8)
}

enum UniversalTypeTag: UInt8 {
    case Boolean = 0x01
    case Integer = 0x02
    case BitString = 0x03
    case OctetString = 0x04
    case ObjectIdentifier = 0x06
    case Sequence = 0x30
    case Set = 0x31
    case UTF8String = 0x0C
    case PrintableString = 0x13
    case IA5String = 0x16
    case UTCTime = 0x17
    case NULL = 0x05
}

public indirect enum ElementsOrRawValue: CustomStringConvertible {
    case Elements(elements: [ASN1Element])
    case RawValue(value: NSData)

    init(content: NSData) {
        let parser = ASN1Parser(data: content)

        var elements = [ASN1Element]()
        var foundUnknown = false

        while let parsed = parser.parseElement() {
            switch parsed.element {
            case .Unknown:
                foundUnknown = true
                break
            default:
                elements.append(parsed.element)
            }
        }

        if elements.count == 0 || foundUnknown {
            // Ignore unkown elements when determining element or raw value
            self = .RawValue(value: content)
        } else {
            self = .Elements(elements: elements)
        }
    }

    public var description: String {
        switch self {
        case .Elements(let element):
            return "Element: \(element)"
        case .RawValue(let value):
            return "Raw Value: \(value)"
        }
    }
}

public indirect enum ASN1Element: CustomStringConvertible {
    case Unknown(rawTypeTag: UInt8, value: NSData)
    case Boolean(value: Bool)
    case Integer(value: NSData)
    case BitString(value: ElementsOrRawValue)
    case OctetString(value: ElementsOrRawValue)
    case ObjectIdentifier(value: ASN1ObjectIdentifier)
    case UTF8String(value: String)
    case PrintableString(value: String)
    case IA5String(value: String)
    case UTCTime(value: String)
    case NULL
    case Sequence(elements: [ASN1Element])
    case Set(elements: [ASN1Element])
    case ContextSpecific(number: UInt8, value: ElementsOrRawValue)
    case Application(number: UInt8, value: ElementsOrRawValue)

    init?(typeTag: TypeTag, content: NSData) {
        switch typeTag {
        case .Unknown(let rawTypeTag):
            self = .Unknown(rawTypeTag: rawTypeTag, value: content)

        case .Universal(.Boolean):
            guard let byte = Array(UnsafeBufferPointer(start: UnsafePointer<UInt8>(content.bytes), count: content.length)).first else {
                return nil
            }
            self = .Boolean(value: byte == 0xFF)

        case .Universal(.Integer):
            self = .Integer(value: content)

        case .Universal(.Sequence), .Universal(.Set):
            let parser = ASN1Parser(data: content)

            var elements = [ASN1Element]()

            while let parsed = parser.parseElement() {
                elements.append(parsed.element)
            }

            switch typeTag {
            case .Universal(.Sequence):
                self = .Sequence(elements: elements)
            case .Universal(.Set):
                self = .Set(elements: elements)
            default:
                fatalError()
            }

        case .Universal(.OctetString):
            self = .OctetString(value: ElementsOrRawValue(content: content))

        case .Universal(.BitString):
            self = .BitString(value: ElementsOrRawValue(content: content))

        case .Universal(.ObjectIdentifier):
            let bytes = Array(UnsafeBufferPointer(start: UnsafePointer<UInt8>(content.bytes), count: content.length))
            self = .ObjectIdentifier(value: ASN1ObjectIdentifier(bytes: bytes))

        case .Universal(.PrintableString), .Universal(.IA5String):
            guard let string = String(data: content, encoding: NSASCIIStringEncoding) else {
                return nil
            }

            switch typeTag {
            case .Universal(.PrintableString):
                self = .PrintableString(value: string)
            case .Universal(.IA5String):
                self = .IA5String(value: string)
            default:
                fatalError()
            }

        case .Universal(.UTF8String), .Universal(.UTCTime):
            guard let string = String(data: content, encoding: NSUTF8StringEncoding) else {
                return nil
            }

            switch typeTag {
            case .Universal(.UTF8String):
                self = .UTF8String(value: string)
            case .Universal(.UTCTime):
                self = .UTCTime(value: string)
            default:
                fatalError()
            }

        case .Universal(.NULL):
            self = .NULL

        case .ContextSpecific(let number):
            self = .ContextSpecific(number: number, value: ElementsOrRawValue(content: content))

        case .Application(let number):
            self = .Application(number: number, value: ElementsOrRawValue(content: content))
        }
    }

    public var description: String {
        switch self {
        case .Unknown(let value):
            return "Unknown: \(value)"
        case .Boolean(let value):
            return "Boolean: \(value ? "true" : "false")"
        case .Integer(let value):
            let bytes = Array(UnsafeBufferPointer(start: UnsafePointer<UInt8>(value.bytes), count: value.length))
            var string = "Integer, \(bytes.count * 8) bit: "
            if bytes.count <= 4 {
                // It's 32bit or smaller, print it as an integer value
                string += "\(bytes.intValue()) "
            }
            string += "\(value)"
            return string
        case .BitString(let value):
            return elementListDescription([value], title: "Bit String")
        case .OctetString(let value):
            return elementListDescription([value], title: "Octet String")
        case .ObjectIdentifier(let value):
            return "Object Identifier: \(value)"
        case .UTF8String(let value):
            return "UTF8 String: \(value)"
        case .PrintableString(let value):
            return "Printable String: \(value)"
        case .IA5String(let value):
            return "IA5 String: \(value)"
        case .UTCTime(let value):
            return "UTC Time: \(value)"
        case .NULL:
            return "NULL"
        case .Sequence(let elements):
            return elementListDescription(elements, title: "Sequence")
        case .Set(let elements):
            return elementListDescription(elements, title: "Set")
        case .ContextSpecific(let number, let value):
            switch value {
            case .Elements(let element):
                return elementListDescription([element], title: "[\(number)]")
            case .RawValue(let value):
                return elementListDescription([value], title: "[\(number)]")
            }
        case .Application(let number, let value):
            switch value {
            case .Elements(let element):
                return elementListDescription([element], title: "Application \(number)")
            case .RawValue(let value):
                return elementListDescription([value], title: "Application \(number)")
            }
        }
    }

    private func elementListDescription<T: CustomStringConvertible>(elements: [T], title: String) -> String {
        var string = "\(title) (\(elements.count)): [\n"

        for element in elements {
            let elementDescription = element.description

            for line in elementDescription.componentsSeparatedByString("\n") {
                string += "  \(line)\n"
            }
        }

        string += "]"

        return string
    }
}

class ASN1Parser {
    private struct ASN1ParserConstants {
        static let ElementLongLength: UInt8 = 0b10000000
        static let TypeTagContextSpecific: UInt8 = 0b10000000
        static let TypeTagApplication: UInt8 = 0b01000000
        static let IdentifierNumberBitMask: UInt8 = 0b00011111
    }

    let data: NSData

    var position: Int = 0
    var failed: Bool = false

    init(data: NSData) {
        self.data = data
    }

    func parseElement() -> (element: ASN1Element, data: NSData, cardCertificate: SITHSCardCertificate?)? {
        guard let parsedTypeTag = parseTypeTag() else {
            // Tag parsing failed
            return nil
        }

        let startPosition = position - 1

        guard let parsedLength = parseLength() else {
            // Length parsing failed
            return nil
        }

        guard let readBytes = readBytes(parsedLength) else {
            // Bytes reading failed
            return nil
        }

        let content = NSData(bytes: readBytes, length: parsedLength)

        guard let element = ASN1Element(typeTag: parsedTypeTag, content: content) else {
            // Could not read element
            failed = true
            return nil
        }

        let range = NSRange(location: startPosition, length: position - startPosition)
        let subdata = data.subdataWithRange(range)
        let cardCertificate = SITHSCardCertificate(rootElement: element, derData: subdata)

        return (element: element, data: subdata, cardCertificate: cardCertificate)
    }

    private func parseTypeTag() -> TypeTag? {
        guard let typeTagByte = readBytes(1)?.first else {
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

            return .ContextSpecific(number: number)
        }

        if typeTagByte & ASN1ParserConstants.TypeTagApplication == ASN1ParserConstants.TypeTagApplication {
            // Application, get number and return
            let number = typeTagByte & ASN1ParserConstants.IdentifierNumberBitMask

            return .Application(number: number)
        }

        guard let universalTypeTag = UniversalTypeTag(rawValue: typeTagByte) else {
            // Unknown type tag
            return .Unknown(rawTypeTag: typeTagByte)
        }
        
        return .Universal(typeTag: universalTypeTag)
    }

    private func parseLength() -> Int? {
        guard let firstLengthByte = readBytes(1)?.first else {
            // Not enough bytes to read length
            return nil
        }

        if firstLengthByte & ASN1ParserConstants.ElementLongLength == 0 {
            // Single byte element length
            return Int(firstLengthByte)
        }

        let octets = firstLengthByte ^ ASN1ParserConstants.ElementLongLength

        guard let lengthOctetBytes = readBytes(Int(octets)) else {
            // Not enough bytes to read length
            return nil
        }

        return Int(lengthOctetBytes.uintValue())
    }

    private func readBytes(count: Int) -> [UInt8]? {
        if data.length < position + count {
            // Not enough bytes yet
            return nil
        }

        var bytes = [UInt8](count: count, repeatedValue: 0xFF)
        data.getBytes(&bytes, range: NSRange(location: position, length: count))
        position += count

        return bytes
    }

}
