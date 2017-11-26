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

struct KeyUsage: OptionSet {
    let rawValue: UInt8

    static let DigitalSignature = KeyUsage(rawValue: 0b10000000)
    static let NonRepudiation   = KeyUsage(rawValue: 0b01000000)
    static let KeyEncipherment  = KeyUsage(rawValue: 0b00100000)
    static let DataEncipherment = KeyUsage(rawValue: 0b00010000)
    static let KeyAgreement     = KeyUsage(rawValue: 0b00001000)
    static let KeyCertSign      = KeyUsage(rawValue: 0b00000100)
    static let CrlSign          = KeyUsage(rawValue: 0b00000010)
}

public enum ASN1ObjectIdentifier: Hashable {
    case undefined(data: Data)
    case sha1WithRSAEncryption
    case countryName
    case organizationName
    case commonName
    case surname
    case givenName
    case serialNumber
    case title
    case keyUsage
    case subjectDirectoryAttributes
    case cardNumber

    init(data: Data) {
        let bytes = [UInt8](data)

        if bytes == [0x2A, 0x86, 0x48, 0x86, 0xF7, 0x0D, 0x01, 0x01, 0x05] { // 1.2.840.113549.1.1.5
            self = .sha1WithRSAEncryption
        } else if bytes == [0x55, 0x04, 0x06] { // 2.5.4.6
            self = .countryName
        } else if bytes == [0x55, 0x04, 0x0A] { // 2.5.4.10
            self = .organizationName
        } else if bytes == [0x55, 0x04, 0x03] { // 2.5.4.3
            self = .commonName
        } else if bytes == [0x55, 0x04, 0x04] { // 2.5.4.4
            self = .surname
        } else if bytes == [0x55, 0x04, 0x2A] { // 2.5.4.42
            self = .givenName
        } else if bytes == [0x55, 0x04, 0x05] { // 2.5.4.5
            self = .serialNumber
        } else if bytes == [0x55, 0x04, 0x0C] { // 2.5.4.12
            self = .title
        } else if bytes == [0x55, 0x1D, 0x0F] { // 2.5.29.15
            self = .keyUsage
        } else if bytes == [0x55, 0x1D, 0x09] { // 2.5.29.9
            self = .subjectDirectoryAttributes
        } else if bytes == [0x2A, 0x85, 0x70, 0x22, 0x02, 0x01] { // 1.2.752.34.2.1
            self = .cardNumber
        } else {
            self = .undefined(data: data)
        }
    }

    public var hashValue: Int {
        return "\(self)".hashValue
    }
}

public func ==(lhs: ASN1ObjectIdentifier, rhs: ASN1ObjectIdentifier) -> Bool {
    return lhs.hashValue == rhs.hashValue
}

/**
 The `SITHSCardCertificate` struct represents a parsed SITHS authentication certificate. When initialized with a ASN.1 root element, the
 element is transversed to verify that it's containing a certificate with all the required information.
 */
public struct SITHSCardCertificate: CustomStringConvertible, Equatable {

    /// The root ASN.1 element of the certificate. Can be used to extract information from the raw data.
    public let rootElement: ASN1Element

    /// The raw DER data that was parsed to result in the certificate.
    public let derData: Data

    /// The SITHS card number as an unformatted string, for example "9752278900000000000"
    public let cardNumber: String

    /// The serial raw X.509 serial number data. By specification, this data represents a signed integer of maximum 20 bytes.
    /// NOTE: This is not to be confused with the HSAID ("SE000000000000-0000"), that is found on the subject OID .SerialNumber.
    public let serialNumber: Data

    /// The `serialNumber` value represented as a uppercase HEX string without byte separators, example: "63D0DAC6F31D6BE4C68658C487863CC0"
    /// NOTE: This is not to be confused with the HSAID ("SE000000000000-0000"), that is found on the subject OID .SerialNumber.
    public let serialString: String

    /**
     All the X.509 subject string fields contained in the certificate. Usually, these card holder subject OIDs are present in a SITHS card:

     - .Surname:            The surename, example: "Alléus"
     - .GivenName:          The given name, example: "Martin Nils"
     - .Title:              The title, example: "CTO"
     - .CountryName:        The country name string, example: "se"
     - .OrganizationName:   The organization name, example: "Appcorn AB"
     - .CommonName:         The common name for the card holder, example: "Martin Alléus"
     - .SerialNumber:       The card HSAID, in its proper form, example: "SE000000000000-0000"
     */
    public let subject: [ASN1ObjectIdentifier: String]

    /// Initializes a new certificate struct by parsing the provided DER data
    ///
    /// - Parameter derData: The raw DER data to parse.
    /// - Returns: A `SITHSCardCertificate` instance, if the parsing was succesfull, and the root ASN.1 element contained sufficent
    ///            details.
    public init?(derData: Data) {
        let parser = ASN1Parser(data: derData)

        guard let rootElement = parser.parseElement(), let certificate = rootElement.cardCertificate else {
            // DER data could not be parsed to an ASN1 Element
            return nil
        }

        self = certificate
    }

    /// Initializes a new certificate struct by analyzing pre-parsed DER data. This is useful when a single ASN. 1parser is used to parse
    /// multiple root elements in a single byte stream.
    ///
    /// - Parameter rootElement: A parsed ASN.1 element of the certificate data contained in the `derData` parameter.
    /// - Parameter derData: The raw DER data to parse.
    /// - Returns: A `SITHSCardCertificate` instance, if the root ASN.1 element contained sufficent details.
    public init?(rootElement: ASN1Element, derData: Data) {
        self.rootElement = rootElement
        self.derData = derData

        switch rootElement {
        case .sequence(let elements):
            guard elements.count >= 1 else {
                // Root sequence does not have enough elements, fail
                return nil
            }

            switch elements[0] {
            case .sequence(let elements):
                guard elements.count >= 8 else {
                    // Not enough elements in certificate Sequence, fail
                    return nil
                }

                switch elements[1] {
                case .integer(let value):
                    serialNumber = value

                    let strippedValue = value.count > 16 ? value.subdata(in: value.count-16..<value.count) : value
                    serialString = strippedValue.hexString(byteSeparator: false)

                default:
                    // Serial number was not Integer, fail
                    return nil
                }

                var subject = [ASN1ObjectIdentifier: String]()

                switch elements[5] {
                case .sequence(let subjectElements):
                    for subjectElement in subjectElements {
                        switch subjectElement {
                        case .set(let subjectItemElements):
                            guard subjectItemElements.count >= 1 else {
                                // Subject item did not contain enough elements, skip
                                continue
                            }

                            switch subjectItemElements[0] {
                            case .sequence(let subjectItemSequenceElements):
                                guard subjectItemSequenceElements.count >= 2 else {
                                    // Subject item Sequence did not contain enough elements, skip
                                    continue
                                }

                                let objectIdentifier: ASN1ObjectIdentifier

                                switch subjectItemSequenceElements[0] {
                                case .objectIdentifier(let value):
                                    objectIdentifier = value
                                default:
                                    // First subject item Sequence element was not Object Identifier, skip
                                    continue
                                }

                                switch subjectItemSequenceElements[1] {
                                case .utf8String(let value):
                                    subject[objectIdentifier] = value
                                case .printableString(let value):
                                    subject[objectIdentifier] = value
                                default:
                                    // TODO: Support for more subject types, somtime in the future
                                    // Subject item Sequence element was not a String type, skip
                                    continue
                                }
                            default:
                                // Subject item Set element was not Sequence, skip
                                continue
                            }
                        default:
                            // Subject item was not Sequence, skip
                            continue
                        }
                    }
                default:
                    // Subject name element was not Sequence, fail
                    return nil
                }

                self.subject = subject

                var cardNumber: String?
                var keyUsage: KeyUsage?

                for element in elements[7..<elements.count] {
                    // Go through optional certificate Sequence elements and look for Context Specific [3]
                    switch element {
                    case .contextSpecific(number: 3, let value):
                        switch value {
                        case .elements(let elements):
                            switch elements[0] {
                            case .sequence(let elements):
                                for element in elements {
                                    switch element {
                                    case .sequence(let elements):
                                        guard elements.count >= 2 else {
                                            // Context Specific [3] item Sequence did not contain enough elements, skip
                                            continue
                                        }

                                        switch elements[0] {
                                        case .objectIdentifier(.keyUsage):
                                            switch elements[2] {
                                            case .octetString(let value):
                                                switch value {
                                                case .elements(let elements):
                                                    switch elements[0] {
                                                    case .bitString(let value):
                                                        switch value {
                                                        case .rawValue(let value):
                                                            guard value.count == 2 else {
                                                                // Key usage is not 2 bytes, skip
                                                                continue
                                                            }

                                                            keyUsage = KeyUsage(rawValue: value[1])
                                                        default:
                                                            // Octet String Bit String element was not raw value, skip
                                                            continue
                                                        }
                                                    default:
                                                        // Parsed Key Usage Sequence Octet String element was not Bit String, skip
                                                        continue
                                                    }
                                                default:
                                                    // Key Usage Sequence Octet String was not a parsed element, skip
                                                    continue
                                                }
                                            default:
                                                // Key Usage Sequence item was not Octet String, skip
                                                continue
                                            }
                                        case .objectIdentifier(.cardNumber):
                                            switch elements[1] {
                                            case .octetString(let value):
                                                switch value {
                                                case .elements(let elements):
                                                    switch elements[0] {
                                                    case .printableString(let value):
                                                        cardNumber = value
                                                    default:
                                                        // Parsed Card Number Sequence Octet String element was not Printable String, skip
                                                        continue
                                                    }
                                                default:
                                                    // Card Number Sequence Octet String was not a parsed element, skip
                                                    continue
                                                }
                                            default:
                                                // Card Number Sequence item was not Octet String, skip
                                                continue
                                            }
                                        default:
                                            // Context Specific [3] item Sequence first element was not Card Number or Key Usage Object Identifier, skip
                                            continue
                                        }
                                    default:
                                        // Context Specific [3] item element was not Sequence, skip
                                        continue
                                    }
                                }
                            default:
                                // Context Specific [3] element was not Sequence, skip
                                continue
                            }
                        default:
                            // Context Specific [3] did not contain a parsed element, skip
                            continue
                        }
                    default:
                        // Element not Context Specific [3], skip
                        continue
                    }
                }

                guard let unwrappedKeyUsage = keyUsage else {
                    // No key usage found, fail
                    return nil
                }

                if unwrappedKeyUsage != [KeyUsage.DigitalSignature, KeyUsage.KeyEncipherment] {
                    // Only let through ceriticates with these specific key usages
                    return nil
                }

                guard let unwrappedCardNumber = cardNumber else {
                    // No card number found, fail
                    return nil
                }

                self.cardNumber = unwrappedCardNumber

            default:
                // First element in root sequence is not a Sequence, fail
                return nil
            }
        default:
            // Root element is not Sequence, fail
            return nil
        }

        // Everything passed, we're good!
    }

    public var description: String {
        return "SITHSManager.SITHSCardCertificate serialString: \(serialString), serialNumber: \(serialNumber), cardNumber: \(cardNumber), subject: \(subject)"
    }
}

public func ==(lhs: SITHSCardCertificate, rhs: SITHSCardCertificate) -> Bool {
    return lhs.derData == rhs.derData
}
