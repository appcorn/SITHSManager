//
//  ViewController.swift
//  SITHSManager
//
//  Created by Martin Alleus on 04/24/2017.
//  Copyright (c) 2017 Martin Alleus. All rights reserved.
//

import UIKit
import SITHSManager

class ViewController: UIViewController {

    @IBOutlet weak var logTextView: UITextView!
    @IBOutlet weak var stateLabel: UILabel!
    let sithsManager = SITHSManager()
    let dateFormatter = DateFormatter()
    var logPath: URL!
    var logOutput: OutputStream!

    override func viewDidLoad() {
        super.viewDidLoad()

        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = URL(fileURLWithPath: paths[0])
        logPath = documentsDirectory.appendingPathComponent("log.txt")
        logOutput = OutputStream(url: logPath, append: true)
        logOutput.open()

        do {
            let previousLog = try String(contentsOf: logPath)
            print(previousLog)
        } catch {
            // Do nothing
        }

        dateFormatter.dateStyle = .none
        dateFormatter.timeStyle = .medium

        // Add a state change closure, the state can also be read from the `sithsManager.state` property directly
        sithsManager.stateClosure = { [weak self] state in
            self?.log(message: "State changed: \(state)")

            guard let stateLabel = self?.stateLabel else {
                return
            }

            // Switch for the different states
            switch state {
            case .unknown:
                stateLabel.textColor = .black
                stateLabel.text = "Unknown"
            case .readingFromCard:
                stateLabel.textColor = .black
                stateLabel.text = "Reading From Card..."
            case .error(let error):
                stateLabel.textColor = .red
                stateLabel.text = "Error \(error)"
            case .readerDisconnected:
                stateLabel.textColor = .red
                stateLabel.text = "Reader Disconnected"
            case .unknownCardInserted:
                stateLabel.textColor = .red
                stateLabel.text = "Unknown Card Inserted"
            case .cardWithoutCertificatesInserted:
                stateLabel.textColor = .red
                stateLabel.text = "SITHS Card Without Certificates Inserted"
            case .readerConnected:
                stateLabel.textColor = .blue
                stateLabel.text = "Reader Connected"
            case .cardInserted(let certificates):
                // We have a set of at least one SITHS certificate (see the `SITHSCardCertificate` struct for more information)
                let strings = certificates.map { certificate in
                    return "• \(certificate.cardNumber) \(certificate.serialString) \(certificate.subject[.commonName] ?? "[No common name]")"
                }
                
                stateLabel.textColor = .green
                stateLabel.text = "SITHS Card Inserted:\n\(strings.joined(separator: "\n"))"
            }
        }

        sithsManager.debugLogClosure = { [weak self] message in
            guard let `self` = self else {
                return
            }

            self.log(message: message)
        }
    }

    func log(message: String) {
        NSLog("%@", message)

        let timestamp = dateFormatter.string(from: Date())
        logTextView.text = "[\(timestamp)] \(message)\n\(logTextView.text!)"

        if let logData = "[\(timestamp)] \(message)\n".data(using: String.Encoding.utf8) {
            let _ = logData.withUnsafeBytes{ (pointer: UnsafePointer<UInt8>) in
                self.logOutput.write(pointer, maxLength: logData.count)
            }
        }
    }

    @IBAction func exportButtonPressed(_ sender: UIButton) {
        self.logOutput.close()

        let activityVC = UIActivityViewController(activityItems: [logPath], applicationActivities: nil)
        activityVC.popoverPresentationController?.sourceView = sender
        activityVC.completionWithItemsHandler = { [weak self] _, _, _, _ in
            guard let `self` = self else {
                return
            }
            let _ = try? FileManager.default.removeItem(at: self.logPath)
            self.logOutput = OutputStream(url: self.logPath, append: true)
            self.logOutput.open()
            self.logTextView.text = ""
        }
        self.present(activityVC, animated: true, completion: nil)
    }
}
