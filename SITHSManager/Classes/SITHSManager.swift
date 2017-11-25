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

import UIKit
import ExternalAccessory

/**
 The current state of the card reader.

 - Unknown:                         The state of the reader has not yet been determined. This is the initial state.
 - Error:                           An error has occured. The specifics of the error is represented as `SITHSManagerError` in the `error`
                                    associated value.
 - ReaderDisconnected:              There is no card reader connected.
 - ReaderConnected:                 There is a reader connected, but no inserted card.
 - UnknownCardInserted:             There is a smart card inserted to a connected reader, but it does not appear to be a SITHS Card.
 - ReadingFromCard:                 The SITHS Manager is currently reading from an inserted SITHS card, parsing any certificates found.
 - CardWithoutCertificatesInserted: There is a SITHS Card inserted to a connected reader, but the SITHS Manager failed to read any
                                    certificates.
 - CardInserted:                    The reader is connected, and there is a SITHS card, containing at least one certificate, connected. The
                                    parsed certificates are accessed in the `certificates` assoicated value (an array guaranteed to have at
                                    least one element).
 */
public enum SITHSManagerState: Equatable {
    case unknown
    case error(error: SITHSManagerError)
    case readerDisconnected
    case readerConnected
    case unknownCardInserted
    case readingFromCard
    case cardWithoutCertificatesInserted
    case cardInserted(certificates: [SITHSCardCertificate])
}

public func ==(lhs: SITHSManagerState, rhs: SITHSManagerState) -> Bool {
    switch (lhs, rhs) {
    case (.unknown, .unknown),
         (.readerDisconnected, .readerDisconnected),
         (.readerConnected, .readerConnected),
         (.unknownCardInserted, .unknownCardInserted),
         (.readingFromCard, .readingFromCard),
         (.cardWithoutCertificatesInserted, .cardWithoutCertificatesInserted):
        return true
    case let (.error(a), .error(b)):
        return a == b
    case let (.cardInserted(a), .cardInserted(b)):
        return a == b
    case (.unknown, _),
         (.readerDisconnected, _),
         (.readerConnected, _),
         (.unknownCardInserted, _),
         (.readingFromCard, _),
         (.cardWithoutCertificatesInserted, _),
         (.error, _),
         (.cardInserted, _):
        return false
    }
}

/**
 A SITHS Manager error.
 
 - SmartcardError:  An error given by the Precise Biometrics Tactivo SDK. The error code, and descibing message, is sent as associated
                    values.
 - InternalError:   There has been an internal error in the card communication or data parsing. If there is more information, it's contained
                    in the `error` associated value.
 */
public enum SITHSManagerError: Error, Equatable {
    case smartcardError(message: String, code: Int)
    case internalError(error: Error?)
}

public func ==(lhs: SITHSManagerError, rhs: SITHSManagerError) -> Bool {
    switch (lhs, rhs) {
    case let (.smartcardError(messageA, codeA), .smartcardError(messageB, codeB)):
        return messageA == messageB && codeA == codeB
    case (.internalError, .internalError):
        // TODO: This does not properly compare the internal errors
        return false
    case (.smartcardError, _),
         (.internalError, _):
        return false
    }
}

/**
 The `SITHSManager` provides a wrapper around the Precise Biometrics Tactivo SDK. More specifically, this calls combines system
 notifications with the `PBAccessory` and `PBSmartcard` classes to detect and respond to smart card reader and card state changes.

 The class will also communicate with any inserted smart card via APDU messages to fetch the data directory structure and embedded
 certificates. The class uses `ASN1Parser` to parse the SITHS card ASN.1 DER/BER data.
 */
open class SITHSManager {
    fileprivate struct SmartcardManagerConfiguration {
        /// Maximum number of card reader connection retries.
        static let FetchStatusMaxRetries: Int = 5
        /// Card reader connection retry timeout
        static let FetchStatusRetryTimeout: TimeInterval = 0.2
        /// Number of trailing bytes of card file contents that are allowed to be 0xFF until file is considered completely read. Set to nil
        /// to disable this functionality.
        static let ResponseDataTerminatingTrailingFFLimit: Int? = 10
    }

    // Observation and dispatch
    fileprivate var observers: [ObserverProxy] = []
    fileprivate let smartcardQueue: DispatchQueue
    fileprivate var retryingConnection: Bool = false
    fileprivate var applicationInactive: Bool = false

    // Communication objects
    fileprivate let smartcard = PBSmartcard()
    fileprivate let accessory = PBAccessory.sharedClass()

    /// The current state of the SITHS Manager. When changed, the `stateClosure` is called.
    open var state: SITHSManagerState {
        get {
            return internalState
        }
    }

    /**
     The state change obcserver closure block. Will be called every time the state changes. The state can also be read directly from the
     `state` property.
     */
    open var stateClosure: ((SITHSManagerState) -> ())?

    /**
     The debug log closure block. Is called continously during state changes and SITHS card communication, and is quite verbose.
     Note: Since debugging via the console when connected to a card reader is hard, it's adviced to log to screen or file.
     */
    open var debugLogClosure: ((String) -> ())?

    fileprivate var internalState: SITHSManagerState = .unknown {
        didSet {
            if internalState != oldValue {
                DispatchQueue.main.async {
                    self.stateClosure?(self.internalState)
                }
            }
        }
    }

    /**
     Initiates the SmartcardManager.

     - returns: A new SmartcardManager instance. Make sure to store a reference to this instance, since notification state changes will stop
     as soon as this instance is deallocated.
     */
    public init() {
        smartcardQueue = DispatchQueue(label: "Smartcard Queue", attributes: .concurrent)

        // Register for notifications
        observers.append(ObserverProxy(name: .init(rawValue: "PB_CARD_INSERTED"), object: nil, closure: cardInserted))
        observers.append(ObserverProxy(name: .init(rawValue: "PB_CARD_REMOVED"), object: nil, closure: cardRemoved))
        observers.append(ObserverProxy(name: .PBAccessoryDidConnect, object: nil, closure: accessoryConnected))
        observers.append(ObserverProxy(name: .PBAccessoryDidDisconnect, object: nil, closure: accessoryDisconnected))
        observers.append(ObserverProxy(name: .UIApplicationDidBecomeActive, object: nil, closure: applicationDidBecomeActive))
        observers.append(ObserverProxy(name: .UIApplicationWillResignActive, object: nil, closure: applicationWillResignActive))
    }

    fileprivate func applicationDidBecomeActive(notification: Notification) {
        log(message: "Application Did Become Active Notification")
        applicationInactive = false
        smartcardQueue.async {
            self.openSmartcard()
            self.checkSmartcard()
        }
    }

    fileprivate func applicationWillResignActive(notification: Notification) {
        log(message: "Application Will Resign Active Notification")
        applicationInactive = true
        smartcardQueue.async {
            self.closeSmartcard()
        }
    }

    fileprivate func cardInserted(notification: Notification) {
        log(message: "Card Inserted Notification")
        smartcardQueue.async {
            self.checkSmartcard()
        }
    }

    fileprivate func cardRemoved(notification: Notification) {
        log(message: "Card Removed Notification")
        internalState = .readerConnected
    }

    fileprivate func accessoryConnected(notification: Notification) {
        log(message: "Accessory Connected Notification")
        if applicationInactive {
            // Ignore accessory connection state notifications when application is not active.
            return
        }

        smartcardQueue.async {
            self.checkSmartcard()
        }
    }

    fileprivate func accessoryDisconnected(notification: Notification) {
        log(message: "Accessory Disconnected Notification")
        if applicationInactive {
            // Ignore accessory connection state notifications when application is not active.
            return
        }

        internalState = .readerDisconnected
    }

    fileprivate func openSmartcard() {
        let result = smartcard.open()
        log(message: "OpenSmartcard status \(result)")

        guard result == PBSmartcardStatusSuccess else {
            setErrorState(error: getError(status: result))
            return
        }
    }

    fileprivate func checkSmartcard(retryCount: Int = 0) {
        if retryCount == 0 && retryingConnection {
            return
        } else {
            retryingConnection = false
        }

        let status = smartcard.getSlotStatus()
        log(message: "CheckSmartcard status \(status), retry \(retryCount)")

        switch status {
        case PBSmartcardSlotStatusEmpty:
            internalState = .readerConnected
        case PBSmartcardSlotStatusPresent, PBSmartcardSlotStatusPresentConnected:
            let result = smartcard.connect(PBSmartcardProtocolTx)

            log(message: "Connect status \(result)")

            if result == PBSmartcardStatusNoSmartcard {
                internalState = .readerConnected
                return
            } else if result != PBSmartcardStatusSuccess {
                setErrorState(error: getError(status: result))
                return
            }

            var certificates = [SITHSCardCertificate]()

            do {
                log(message: "Selecting EID")

                // Select the SITHS card EID
                let command = SmartcardCommandAPDU(
                    instructionClass: 0x00,
                    instructionCode: 0xA4,
                    instructionParameters: [0x04, 0x00],
                    commandData: Data(bytes: [0xA0, 0x00, 0x00, 0x00, 0x63, 0x50, 0x4B, 0x43, 0x53, 0x2D, 0x31, 0x35]),
                    expectedResponseBytes: nil
                )

                let response = try transmit(command: command)

                log(message: "Got response: \(response)")

                switch response.processingStatus {
                case .successWithResponse:
                    internalState = .readingFromCard

                    // The initial address is the EF.ODF file identifier
                    var identifiers: [[UInt8]] = [[0x50, 0x31]]
                    var readIdentifiers: [[UInt8]] = []

                    while identifiers.count > 0 {
                        let identifier = identifiers.removeFirst()
                        readIdentifiers.append(identifier)

                        log(message: "Read loop iteration, reading from identifier \(identifier.hexString())")

                        let _ = try transmitSelectFileAndGetResponse(identifier: identifier)
                        let efData = try transmitReadBinary()
                        let efParser = ASN1Parser(data: efData)

                        while let parsed = efParser.parseElement() {
                            log(message: "Parsed: \(parsed)")

                            if let foundIdentifier = getCardEFIdentifier(element: parsed.element) {
                                if !identifiers.contains(where: { $0 == foundIdentifier }) && !readIdentifiers.contains(where: { $0 == foundIdentifier }) {
                                    identifiers.append(foundIdentifier)
                                }
                            }

                            if let certificate = parsed.cardCertificate {
                                certificates.append(certificate)
                            }
                        }
                    }
                default:
                    log(message: "Could not correctly set EID, unkown card")
                    internalState = .unknownCardInserted
                    return
                }
            } catch let error as SITHSManagerError {
                setErrorState(error: error)
                return
            } catch {
                setErrorState(error: .internalError(error: error))
                return
            }

            let serialStrings = certificates.map { return $0.serialString }
            log(message: "SITHS Card communication complete, found certificates with serial HEX-strings: \(serialStrings)")

            guard certificates.count > 0 else {
                log(message: "No certificates in response")
                internalState = .cardWithoutCertificatesInserted
                return
            }

            internalState = .cardInserted(certificates: certificates)
        case PBSmartcardSlotStatusUnknown:
            if !(accessory?.isConnected)! {
                internalState = .readerDisconnected
            } else {
                fallthrough
            }
        default:
            if retryCount < SmartcardManagerConfiguration.FetchStatusMaxRetries {
                // Retry connection, do not update state yet
                retryingConnection = true
                smartcardQueue.asyncAfter(deadline: .now() + SmartcardManagerConfiguration.FetchStatusRetryTimeout) {
                    self.checkSmartcard(retryCount: retryCount + 1)
                }
            } else {
                // Max number of retries, set state to unknown
                internalState = .unknown
            }
        }
    }

    fileprivate func getCardEFIdentifier(element: ASN1Element) -> [UInt8]? {
        switch element {
        case .contextSpecific(_, let elementsOrRawValue):
            switch elementsOrRawValue {
            case .elements(let elements):
                switch elements[0] {
                case .sequence(let elements):
                    guard elements.count == 1 else {
                        log(message: "Application Sequence did not contain one value, skip")
                        // Application Sequence did not contain one value, skip
                        break
                    }

                    switch elements[0] {
                    case .octetString(let value):
                        switch value {
                        case .rawValue(let value):
                            guard value.count == 4 else {
                                log(message: "Octet String raw value was not 4 bytes, skip")
                                // Octet String raw value was not 4 bytes, skip
                                break
                            }

                            var bytes = [UInt8](value)

                            guard bytes[0...1] == [0x3F, 0x00] else {
                                log(message: "First bytes was not 3F00, skip")
                                // First bytes was not 3F00, skip
                                break
                            }

                            let identifier = [UInt8](value[2...3])

                            log(message: "Found identifier \(identifier)")

                            return identifier
                        case .elements:
                            log(message: "Sequence Octet String was not raw value, skip")
                            // Sequence Octet String was not raw value, skip
                            break
                        }
                    default:
                        log(message: "Sequence element was not Octet String, skip")
                        // Sequence element was not Octet String, skip
                        break
                    }
                default:
                    log(message: "First Context Specific element is not Sequence, skip")
                    // First Context Specific element is not Sequence, skip
                    break
                }
            case .rawValue:
                log(message: "Context Specific element did not contain parsed elements, skip")
                // Context Specific element did not contain parsed elements, skip
                break
            }

        case .sequence(let elements):
            guard let element = elements[safe: 2] else {
                log(message: "Root Sequence does not have enough elements, skip")
                // Root Sequence does not have enough elements, skip
                break
            }

            switch element {
            case .contextSpecific(number: 1, let value):
                switch value {
                case .elements(let elements):
                    guard let element = elements.first else {
                        log(message: "Context Specific does not have enough elements, skip")
                        // Context Specific does not have enough elements, skip
                        break
                    }

                    switch element {
                    case .sequence(let elements):
                        guard let element = elements.first else {
                            log(message: "First Sequence does not have enough elements, skip")
                            // First Sequence does not have enough elements, skip
                            break
                        }

                        switch element {
                        case .sequence(let elements):
                            guard let element = elements.first else {
                                log(message: "First Sequence does not have enough elements, skip")
                                // First Sequence does not have enough elements, skip
                                break
                            }

                            switch element {
                            case .octetString(let value):
                                switch value {
                                case .rawValue(let value):
                                    guard value.count == 4 else {
                                        log(message: "Octet String raw value was not 4 bytes, skip")
                                        // Octet String raw value was not 4 bytes, skip
                                        break
                                    }

                                    var bytes = [UInt8](value)

                                    guard bytes[0...1] == [0x3F, 0x00] else {
                                        log(message: "First bytes was not 3F00, skip")
                                        // First bytes was not 3F00, skip
                                        break
                                    }
                                    
                                    let identifier = [UInt8](value[2...3])

                                    log(message: "Found identifier \(identifier)")

                                    return identifier
                                default:
                                    log(message: "Sequence Octet String was not raw value, skip")
                                    // Sequence Octet String was not raw value, skip
                                    break
                                }
                            default:
                                log(message: "Sequence element was not Octet String, skip")
                                // Sequence element was not Octet String, skip
                                break
                            }
                        default:
                            log(message: "Sequence element was not Sequence, skip")
                            // Sequence element was not Sequence, skip
                            break
                        }
                    default:
                        log(message: "Context Specific element was not Sequence, skip")
                        // Context Specific element was not Sequence, skip
                        break
                    }
                default:
                    log(message: "Context Specific element did not contain parsed elements, skip")
                    // Context Specific element did not contain parsed elements, skip
                    break
                }
            default:
                log(message: "Root sequence element was not Context Specific, skip")
                // Root sequence element was not Context Specific, skip
                break
            }
        default:
            log(message: "Root element is not Sequence or Context Specific, skip")
            // Root element is not Sequence or Context Specific, skip
            break
        }

        return nil
    }

    fileprivate func transmitSelectFileAndGetResponse(identifier: [UInt8]) throws -> Data {
        // The SELECT FILE command
        let selectFileCommand = SmartcardCommandAPDU(
            instructionClass: 0x00,
            instructionCode: 0xA4,
            instructionParameters: [0x00, 0x00],
            commandData: Data(bytes: identifier),
            expectedResponseBytes: nil
        )

        let selectFileResponse = try transmit(command: selectFileCommand)

        let availableBytes: UInt8

        switch selectFileResponse.processingStatus {
        case .successWithResponse(let internalAvailableBytes):
            availableBytes = internalAvailableBytes
        default:
            throw SITHSManagerError.internalError(error: nil)
        }

        // The GET RESPONSE command
        let getResponseCommand = SmartcardCommandAPDU(
            instructionClass: 0x00,
            instructionCode: 0xC0,
            instructionParameters: [0x00, 0x00],
            commandData: nil,
            expectedResponseBytes: UInt16(availableBytes)
        )

        let getResponseResponse = try transmit(command: getResponseCommand)

        switch getResponseResponse.processingStatus {
        case .success:
            guard let responseData = getResponseResponse.responseData else {
                throw SITHSManagerError.internalError(error: nil)
            }

            return responseData
        default:
            throw SITHSManagerError.internalError(error: nil)
        }
    }

    fileprivate func transmitReadBinary() throws -> Data {
        var dataBuffer = Data()
        var offset: UInt16 = 0
        var chunkSize: UInt16 = 0xFF
        var readingDone = false

        while !readingDone {
            if chunkSize < 0xFF {
                readingDone = true
            }

            let readBinaryCommand = SmartcardCommandAPDU(
                instructionClass: 0x00,
                instructionCode: 0xB0,
                instructionParameters: [
                    UInt8(truncatingBitPattern: offset >> 8),
                    UInt8(truncatingBitPattern: offset)
                ],
                commandData: nil,
                expectedResponseBytes: chunkSize
            )

            let readBinaryResponse = try transmit(command: readBinaryCommand)

            switch readBinaryResponse.processingStatus {
            case .incorrectExpectedResponseBytes(let correctExpectedResponseBytes):
                chunkSize = UInt16(correctExpectedResponseBytes)
            case .success:
                guard let responseData = readBinaryResponse.responseData else {
                    throw SITHSManagerError.internalError(error: nil)
                }

                // Look at the last bytes of the response
                if let limit = SmartcardManagerConfiguration.ResponseDataTerminatingTrailingFFLimit, responseData.count >= limit {
                    var onlyFF = true

                    // Loop through and check for 0xFF
                    for i in responseData.count-limit..<responseData.count {
                        if responseData[i] != 0xFF {
                            onlyFF = false
                            break
                        }
                    }

                    // Last bytes are all 0xFF, assuming file content is finished
                    if onlyFF {
                        readingDone = true
                    }
                }

                offset += UInt16(responseData.count)
                dataBuffer.append(responseData)
            default:
                throw SITHSManagerError.internalError(error: nil)
            }
        }

        return dataBuffer
    }

    fileprivate func transmit(command: SmartcardCommandAPDU) throws -> SmartcardResponseAPDU {
        var mergedCommand = try command.mergedCommand()

        var receivedDataLength: UInt16 = 0xFF

        if let expectedBytes = command.expectedResponseBytes {
            receivedDataLength = expectedBytes + 2
        }

        var receivedData = Data(count: Int(receivedDataLength))

        log(message: "Transmitting \(mergedCommand.count) >>> \(mergedCommand.hexString())")

        let result = receivedData.withUnsafeMutableBytes { (receivedDataPointer: UnsafeMutablePointer<UInt8>) in
            return mergedCommand.withUnsafeMutableBytes { (mergedCommandPointer: UnsafeMutablePointer<UInt8>) in
                return self.smartcard.transmit(mergedCommandPointer,
                                               withCommandLength: UInt16(mergedCommand.count),
                                               andResponseBuffer: receivedDataPointer,
                                               andResponseLength: &receivedDataLength)
            }
        }

        if receivedData.count > Int(receivedDataLength) {
            receivedData.removeSubrange(Int(receivedDataLength)..<receivedData.count)
        }

        log(message: "Received \(receivedDataLength) <<< \(receivedData.hexString())")

        log(message: "Transmit status \(result)")

        guard result == PBSmartcardStatusSuccess else {
            throw getError(status: result)
        }

        let response = try SmartcardResponseAPDU(data: receivedData)

        log(message: "Processed response \(response)")

        return response
    }

    fileprivate func closeSmartcard() {
        let result = smartcard.close()
        log(message: "CloseSmartcard status \(result)")
    }

    fileprivate func getError(status: PBSmartcardStatus) -> SITHSManagerError {
        let message: String
        let code = Int(status.rawValue)

        switch status {
        case PBSmartcardStatusSuccess:
            message = "No error was encountered"
        case PBSmartcardStatusInvalidParameter:
            message = "One or more of the supplied parameters could not be properly interpreted"
        case PBSmartcardStatusSharingViolation:
            message = "The smart card cannot be accessed because of other connections outstanding"
        case PBSmartcardStatusNoSmartcard:
            message = "The operation requires a Smart Card, but no Smart Card is currently in the device"
        case PBSmartcardStatusProtocolMismatch:
            message = "The requested protocols are incompatible with the protocol currently in use with the smart card"
        case PBSmartcardStatusNotReady:
            message = "The reader or smart card is not ready to accept commands"
        case PBSmartcardStatusInvalidValue:
            message = "One or more of the supplied parameters values could not be properly interpreted"
        case PBSmartcardStatusReaderUnavailable:
            message = "The reader is not currently available for use"
        case PBSmartcardStatusUnexpected:
            message = "An unexpected card error has occurred"
        case PBSmartcardStatusUnsupportedCard:
            message = "The reader cannot communicate with the card, due to ATR string configuration conflicts"
        case PBSmartcardStatusUnresponsiveCard:
            message = "The smart card is not responding to a reset"
        case PBSmartcardStatusUnpoweredCard:
            message = "Power has been removed from the smart card, so that further communication is not possible"
        case PBSmartcardStatusResetCard:
            message = "The smart card has been reset, so any shared state information is invalid"
        case PBSmartcardStatusRemovedCard:
            message = "The smart card has been removed, so further communication is not possible"
        case PBSmartcardStatusNotConnected:
            message = "No open connection to the card"
        case PBSmartcardStatusInternalSessionLost:
            message = "An internal session was terminated by iOS"
        case PBSmartcardStatusProtocolNotIncluded:
            message = "All necessary supported protocols are not defined in the plist file"
        case PBSmartcardStatusNotSupported:
            message = "The operation is not supported on your current version of iOS or with the current Tactivo firmware"
        default:
            message = "Undefined error"
        }

        return SITHSManagerError.smartcardError(message: message, code: code)
    }

    fileprivate func setErrorState(error: SITHSManagerError) {
        if applicationInactive {
            // We're suppressing all error states while application is inactive. This will be resolved again when the application enters forground
            // and  a new connection is made (that of course then could result in the same error, and will then be set as state correctly)
            return
        }

        internalState = .error(error: error)
    }

    func log(message: String) {
        DispatchQueue.main.async {
            self.debugLogClosure?(message)
        }
    }
}
