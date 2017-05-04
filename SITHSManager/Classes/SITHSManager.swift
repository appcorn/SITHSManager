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
    case Unknown
    case Error(error: SITHSManagerError)
    case ReaderDisconnected
    case ReaderConnected
    case UnknownCardInserted
    case ReadingFromCard
    case CardWithoutCertificatesInserted
    case CardInserted(certificates: [SITHSCardCertificate])
}

public func ==(lhs: SITHSManagerState, rhs: SITHSManagerState) -> Bool {
    switch (lhs, rhs) {
    case (.Unknown, .Unknown),
         (.ReaderDisconnected, .ReaderDisconnected),
         (.ReaderConnected, .ReaderConnected),
         (.UnknownCardInserted, .UnknownCardInserted),
         (.ReadingFromCard, .ReadingFromCard),
         (.CardWithoutCertificatesInserted, .CardWithoutCertificatesInserted):
        return true
    case let (.Error(a), .Error(b)):
        return a == b
    case let (.CardInserted(a), .CardInserted(b)):
        return a == b
    case (.Unknown, _),
         (.ReaderDisconnected, _),
         (.ReaderConnected, _),
         (.UnknownCardInserted, _),
         (.ReadingFromCard, _),
         (.CardWithoutCertificatesInserted, _),
         (.Error, _),
         (.CardInserted, _):
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
public enum SITHSManagerError: ErrorType, Equatable {
    case SmartcardError(message: String, code: Int)
    case InternalError(error: ErrorType?)
}

public func ==(lhs: SITHSManagerError, rhs: SITHSManagerError) -> Bool {
    switch (lhs, rhs) {
    case let (.SmartcardError(messageA, codeA), .SmartcardError(messageB, codeB)):
        return messageA == messageB && codeA == codeB
    case (.InternalError, .InternalError):
        // TODO: This does not properly compare the internal errors
        return false
    case (.SmartcardError, _),
         (.InternalError, _):
        return false
    }
}

/**
 The `SITHSManager` provides a wrapper around the Precise Biometrics Tactivo SDK. More specifically, this calls combines system
 notifications with the `PBAccessory` and `PBSmartcard` classes to detect and respond to smart card reader and card state changes.

 The class will also communicate with any inserted smart card via APDU messages to fetch the data directory structure and embedded
 certificates. The class uses `ASN1Parser` to parse the SITHS card ASN.1 DER/BER data.
 */
public class SITHSManager {
    private struct SmartcardManagerConfiguration {
        /// Maximum number of card reader connection retries.
        static let FetchStatusMaxRetries: Int = 5
        /// Card reader connection retry timeout
        static let FetchStatusRetryTimeout: NSTimeInterval = 0.2
        /// Number of trailing bytes of card file contents that are allowed to be 0xFF until file is considered completely read. Set to nil
        /// to disable this functionality.
        static let ResponseDataTerminatingTrailingFFLimit: Int? = 10
    }

    // Observation and dispatch
    private var observers: [ObserverProxy] = []
    private let smartcardQueue: dispatch_queue_t
    private var retryingConnection: Bool = false
    private var applicationInactive: Bool = false

    // Communication objects
    private let smartcard = PBSmartcard()
    private let accessory = PBAccessory.sharedClass()

    /// The current state of the SITHS Manager. When changed, the `stateClosure` is called.
    public var state: SITHSManagerState {
        get {
            return internalState
        }
    }

    /**
     The state change obcserver closure block. Will be called every time the state changes. The state can also be read directly from the
     `state` property.
     */
    public var stateClosure: ((SITHSManagerState) -> ())?

    /**
     The debug log closure block. Is called continously during state changes and SITHS card communication, and is quite verbose.
     Note: Since debugging via the console when connected to a card reader is hard, it's adviced to log to screen or file.
     */
    public var debugLogClosure: ((String) -> ())?

    private var internalState: SITHSManagerState = .Unknown {
        didSet {
            if internalState != oldValue {
                dispatch_async(dispatch_get_main_queue()) {
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
        smartcardQueue = dispatch_queue_create("Smartcard Queue", DISPATCH_QUEUE_CONCURRENT)

        // Register for notifications
        observers.append(ObserverProxy(name: "PB_CARD_INSERTED", object: nil, closure: cardInserted))
        observers.append(ObserverProxy(name: "PB_CARD_REMOVED", object: nil, closure: cardRemoved))
        observers.append(ObserverProxy(name: PBAccessoryDidConnectNotification, object: nil, closure: accessoryConnected))
        observers.append(ObserverProxy(name: PBAccessoryDidDisconnectNotification, object: nil, closure: accessoryDisconnected))
        observers.append(ObserverProxy(name: UIApplicationDidBecomeActiveNotification, object: nil, closure: applicationDidBecomeActive))
        observers.append(ObserverProxy(name: UIApplicationWillResignActiveNotification, object: nil, closure: applicationWillResignActive))
    }

    private func applicationDidBecomeActive(notification: NSNotification) {
        log("Application Did Become Active Notification")
        applicationInactive = false
        dispatch_async(smartcardQueue) {
            self.openSmartcard()
            self.checkSmartcard()
        }
    }

    private func applicationWillResignActive(notification: NSNotification) {
        log("Application Will Resign Active Notification")
        applicationInactive = true
        dispatch_async(smartcardQueue) {
            self.closeSmartcard()
        }
    }

    private func cardInserted(notification: NSNotification) {
        log("Card Inserted Notification")
        dispatch_async(smartcardQueue) {
            self.checkSmartcard()
        }
    }

    private func cardRemoved(notification: NSNotification) {
        log("Card Removed Notification")
        internalState = .ReaderConnected
    }

    private func accessoryConnected(notification: NSNotification) {
        log("Accessory Connected Notification")
        if applicationInactive {
            // Ignore accessory connection state notifications when application is not active.
            return
        }

        dispatch_async(smartcardQueue) {
            self.checkSmartcard()
        }
    }

    private func accessoryDisconnected(notification: NSNotification) {
        log("Accessory Disconnected Notification")
        if applicationInactive {
            // Ignore accessory connection state notifications when application is not active.
            return
        }

        internalState = .ReaderDisconnected
    }

    private func openSmartcard() {
        let result = smartcard.open()
        log("OpenSmartcard status \(result)")

        guard result == PBSmartcardStatusSuccess else {
            setErrorState(getError(result))
            return
        }
    }

    private func checkSmartcard(retryCount: Int = 0) {
        if retryCount == 0 && retryingConnection {
            return
        } else {
            retryingConnection = false
        }

        let status = smartcard.getSlotStatus()
        log("CheckSmartcard status \(status), retry \(retryCount)")

        switch status {
        case PBSmartcardSlotStatusEmpty:
            internalState = .ReaderConnected
        case PBSmartcardSlotStatusPresent, PBSmartcardSlotStatusPresentConnected:
            let result = smartcard.connect(PBSmartcardProtocolTx)

            log("Connect status \(result)")

            if result == PBSmartcardStatusNoSmartcard {
                internalState = .ReaderConnected
                return
            } else if result != PBSmartcardStatusSuccess {
                setErrorState(getError(result))
                return
            }

            var certificates = [SITHSCardCertificate]()

            do {
                log("Selecting EID")

                // Select the SITHS card EID
                let command = SmartcardCommandAPDU(
                    instructionClass: 0x00,
                    instructionCode: 0xA4,
                    instructionParameters: [0x04, 0x00],
                    commandData: [0xA0, 0x00, 0x00, 0x00, 0x63, 0x50, 0x4B, 0x43, 0x53, 0x2D, 0x31, 0x35],
                    expectedResponseBytes: nil
                )

                let response = try transmitCommand(command)

                log("Got response: \(response)")

                switch response.processingStatus {
                case .successWithResponse:
                    internalState = .ReadingFromCard

                    // The initial address is the EF.ODF file identifier
                    var identifiers = [[UInt8(0x50), UInt8(0x31)]]
                    var readIdentifiers = [[UInt8]]()

                    while identifiers.count > 0 {
                        let identifier = identifiers.removeFirst()
                        readIdentifiers.append(identifier)

                        log("Read loop iteration, reading from identifier \(identifier.hexString())")

                        let _ = try transmitSelectFileAndGetResponse(identifier)
                        let efData = try transmitReadBinary()
                        let efParser = ASN1Parser(data: efData)

                        while let parsed = efParser.parseElement() {
                            log("Pasred: \(parsed)")

                            if let foundIdentifier = getCardEFIdentifier(parsed.element) {
                                if !identifiers.contains({ $0 == foundIdentifier }) && !readIdentifiers.contains({ $0 == foundIdentifier }) {
                                    identifiers.append(foundIdentifier)
                                }
                            }

                            if let certificate = parsed.cardCertificate {
                                certificates.append(certificate)
                            }
                        }
                    }
                default:
                    log("Could not correctly set EID, unkown card")
                    internalState = .UnknownCardInserted
                    return
                }
            } catch let error as SITHSManagerError {
                setErrorState(error)
                return
            } catch {
                setErrorState(.InternalError(error: error))
                return
            }

            let serialStrings = certificates.map { return $0.serialString }
            log("SITHS Card communication complete, found certificates with serial HEX-strings: \(serialStrings)")

            guard certificates.count > 0 else {
                log("No certificates in response")
                internalState = .CardWithoutCertificatesInserted
                return
            }

            internalState = .CardInserted(certificates: certificates)
        case PBSmartcardSlotStatusUnknown:
            if !accessory.connected {
                internalState = .ReaderDisconnected
            } else {
                fallthrough
            }
        default:
            if retryCount < SmartcardManagerConfiguration.FetchStatusMaxRetries {
                // Retry connection, do not update state yet
                retryingConnection = true
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(SmartcardManagerConfiguration.FetchStatusRetryTimeout * Double(NSEC_PER_SEC))), smartcardQueue) {
                    self.checkSmartcard(retryCount + 1)
                }
            } else {
                // Max number of retries, set state to unknown
                internalState = .Unknown
            }
        }
    }

    private func getCardEFIdentifier(element: ASN1Element) -> [UInt8]? {
        switch element {
        case .ContextSpecific(_, let elementsOrRawValue):
            switch elementsOrRawValue {
            case .Elements(let elements):
                switch elements[0] {
                case .Sequence(let elements):
                    guard elements.count == 1 else {
                        log("Application Sequence did not contain one value, skip")
                        // Application Sequence did not contain one value, skip
                        break
                    }

                    switch elements[0] {
                    case .OctetString(let value):
                        switch value {
                        case .RawValue(let value):
                            guard value.length == 4 else {
                                log("Octet String raw value was not 4 bytes, skip")
                                // Octet String raw value was not 4 bytes, skip
                                break
                            }

                            var bytes = [UInt8](count: value.length, repeatedValue: 0xFF)
                            value.getBytes(&bytes, length: value.length)

                            guard bytes[0...1] == [0x3F, 0x00] else {
                                log("First bytes was not 3F00, skip")
                                // First bytes was not 3F00, skip
                                break
                            }

                            let identifier = Array(bytes[2...3])

                            log("Found identifier \(identifier)")

                            return identifier
                        case .Elements:
                            log("Sequence Octet String was not raw value, skip")
                            // Sequence Octet String was not raw value, skip
                            break
                        }
                    default:
                        log("Sequence element was not Octet String, skip")
                        // Sequence element was not Octet String, skip
                        break
                    }
                default:
                    log("First Context Specific element is not Sequence, skip")
                    // First Context Specific element is not Sequence, skip
                    break
                }
            case .RawValue:
                log("Context Specific element did not contain parsed elements, skip")
                // Context Specific element did not contain parsed elements, skip
                break
            }

        case .Sequence(let elements):
            guard let element = elements[safe: 2] else {
                log("Root Sequence does not have enough elements, skip")
                // Root Sequence does not have enough elements, skip
                break
            }

            switch element {
            case .ContextSpecific(number: 1, let value):
                switch value {
                case .Elements(let elements):
                    guard let element = elements.first else {
                        log("Context Specific does not have enough elements, skip")
                        // Context Specific does not have enough elements, skip
                        break
                    }

                    switch element {
                    case .Sequence(let elements):
                        guard let element = elements.first else {
                            log("First Sequence does not have enough elements, skip")
                            // First Sequence does not have enough elements, skip
                            break
                        }

                        switch element {
                        case .Sequence(let elements):
                            guard let element = elements.first else {
                                log("First Sequence does not have enough elements, skip")
                                // First Sequence does not have enough elements, skip
                                break
                            }

                            switch element {
                            case .OctetString(let value):
                                switch value {
                                case .RawValue(let value):
                                    guard value.length == 4 else {
                                        log("Octet String raw value was not 4 bytes, skip")
                                        // Octet String raw value was not 4 bytes, skip
                                        break
                                    }

                                    var bytes = [UInt8](count: value.length, repeatedValue: 0xFF)
                                    value.getBytes(&bytes, length: value.length)

                                    guard bytes[0...1] == [0x3F, 0x00] else {
                                        log("First bytes was not 3F00, skip")
                                        // First bytes was not 3F00, skip
                                        break
                                    }
                                    
                                    let identifier = Array(bytes[2...3])

                                    log("Found identifier \(identifier)")

                                    return identifier
                                default:
                                    log("Sequence Octet String was not raw value, skip")
                                    // Sequence Octet String was not raw value, skip
                                    break
                                }
                            default:
                                log("Sequence element was not Octet String, skip")
                                // Sequence element was not Octet String, skip
                                break
                            }
                        default:
                            log("Sequence element was not Sequence, skip")
                            // Sequence element was not Sequence, skip
                            break
                        }
                    default:
                        log("Context Specific element was not Sequence, skip")
                        // Context Specific element was not Sequence, skip
                        break
                    }
                default:
                    log("Context Specific element did not contain parsed elements, skip")
                    // Context Specific element did not contain parsed elements, skip
                    break
                }
            default:
                log("Root sequence element was not Context Specific, skip")
                // Root sequence element was not Context Specific, skip
                break
            }
        default:
            log("Root element is not Sequence or Context Specific, skip")
            // Root element is not Sequence or Context Specific, skip
            break
        }

        return nil
    }

    private func transmitSelectFileAndGetResponse(identifier: [UInt8]) throws -> NSData {
        // The SELECT FILE command
        let selectFileCommand = SmartcardCommandAPDU(
            instructionClass: 0x00,
            instructionCode: 0xA4,
            instructionParameters: [0x00, 0x00],
            commandData: identifier,
            expectedResponseBytes: nil
        )

        let selectFileResponse = try transmitCommand(selectFileCommand)

        let availableBytes: UInt8

        switch selectFileResponse.processingStatus {
        case .successWithResponse(let internalAvailableBytes):
            availableBytes = internalAvailableBytes
        default:
            throw SITHSManagerError.InternalError(error: nil)
        }

        // The GET RESPONSE command
        let getResponseCommand = SmartcardCommandAPDU(
            instructionClass: 0x00,
            instructionCode: 0xC0,
            instructionParameters: [0x00, 0x00],
            commandData: nil,
            expectedResponseBytes: UInt16(availableBytes)
        )

        let getResponseResponse = try transmitCommand(getResponseCommand)

        switch getResponseResponse.processingStatus {
        case .success:
            guard let responseData = getResponseResponse.responseData else {
                throw SITHSManagerError.InternalError(error: nil)
            }

            return responseData
        default:
            throw SITHSManagerError.InternalError(error: nil)
        }
    }

    private func transmitReadBinary() throws -> NSData {
        let dataBuffer = NSMutableData()
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

            let readBinaryResponse = try transmitCommand(readBinaryCommand)

            switch readBinaryResponse.processingStatus {
            case .incorrectExpectedResponseBytes(let correctExpectedResponseBytes):
                chunkSize = UInt16(correctExpectedResponseBytes)
            case .success:
                guard let responseData = readBinaryResponse.responseData else {
                    throw SITHSManagerError.InternalError(error: nil)
                }

                // Look at the last bytes of the response
                if let limit = SmartcardManagerConfiguration.ResponseDataTerminatingTrailingFFLimit where responseData.length >= limit {
                    let bytes =  UnsafePointer<UInt8>(responseData.bytes)
                    var onlyFF = true

                    // Loop through and check for 0xFF
                    for i in responseData.length-limit..<responseData.length {
                        if bytes[i] != 0xFF {
                            onlyFF = false
                            break
                        }
                    }

                    // Last bytes are all 0xFF, assuming file content is finished
                    if onlyFF {
                        readingDone = true
                    }
                }

                offset += UInt16(responseData.length)
                dataBuffer.appendData(responseData)
            default:
                throw SITHSManagerError.InternalError(error: nil)
            }
        }

        return dataBuffer
    }

    private func transmitCommand(command: SmartcardCommandAPDU) throws -> SmartcardResponseAPDU {
        let mergedCommand = try command.mergedCommand()

        var received_data_length: UInt16 = 0xFF

        if let expectedBytes = command.expectedResponseBytes {
            received_data_length = expectedBytes + 2
        }

        let received_data = UnsafeMutablePointer<UInt8>.alloc(Int(received_data_length))

        log("Transmitting \(mergedCommand.count) >>> \(mergedCommand.hexString())")

        let result = smartcard.transmit(UnsafeMutablePointer(mergedCommand),
                                        withCommandLength: UInt16(mergedCommand.count),
                                        andResponseBuffer: received_data,
                                        andResponseLength: &received_data_length)

        let bytes = received_data.valueArray(count: Int(received_data_length))

        log("Received \(received_data_length) <<< \(bytes.hexString())")

        log("Transmit status \(result)")

        guard result == PBSmartcardStatusSuccess else {
            throw getError(result)
        }

        let response = try SmartcardResponseAPDU(bytes: bytes)

        log("Processed response \(response)")

        return response
    }

    private func closeSmartcard() {
        let result = smartcard.close()
        log("CloseSmartcard status \(result)")
    }

    private func getError(status: PBSmartcardStatus) -> SITHSManagerError {
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

        return SITHSManagerError.SmartcardError(message: message, code: code)
    }

    private func setErrorState(error: SITHSManagerError) {
        if applicationInactive {
            // We're suppressing all error states while application is inactive. This will be resolved again when the application enters forground
            // and  a new connection is made (that of course then could result in the same error, and will then be set as state correctly)
            return
        }

        internalState = .Error(error: error)
    }

    func log(message: String) {
        dispatch_async(dispatch_get_main_queue()) {
            self.debugLogClosure?(message)
        }
    }
}
