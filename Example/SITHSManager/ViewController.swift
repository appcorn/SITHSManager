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

        sithsManager.stateClosure = { [weak self] state in
            guard let `self` = self else {
                return
            }

            self.log(message: "State changed: \(state)")

            switch state {
            case .unknown:
                self.stateLabel.textColor = .black
                self.stateLabel.text = "Unknown"
            case .readingFromCard:
                self.stateLabel.textColor = .black
                self.stateLabel.text = "Reading From Card..."
            case .error(let error):
                self.stateLabel.textColor = .red
                self.stateLabel.text = "Error \(error)"
            case .readerDisconnected:
                self.stateLabel.textColor = .red
                self.stateLabel.text = "Reader Disconnected"
            case .unknownCardInserted:
                self.stateLabel.textColor = .red
                self.stateLabel.text = "Unknown Card Inserted"
            case .cardWithoutCertificatesInserted:
                self.stateLabel.textColor = .red
                self.stateLabel.text = "SITHS Card Without Certificates Inserted"
            case .readerConnected:
                self.stateLabel.textColor = .blue
                self.stateLabel.text = "Reader Connected"
            case .cardInserted(let certificates):
                self.stateLabel.textColor = .green

                let strings = certificates.map { certificate in
                    return "• \(certificate.cardNumber) \(certificate.serialString) \(certificate.subject[.commonName] ?? "[No common name]")"
                }

                self.stateLabel.text = "SITHS Card Inserted:\n\(strings.joined(separator: "\n"))"
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
