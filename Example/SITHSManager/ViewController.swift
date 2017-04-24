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
    let dateFormatter = NSDateFormatter()
    var logPath: String!
    var logOutput: NSOutputStream!

    override func viewDidLoad() {
        super.viewDidLoad()

        let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
        let documentsDirectory: NSString = paths[0]
        logPath = documentsDirectory.stringByAppendingPathComponent("log.txt")
        logOutput = NSOutputStream(toFileAtPath: logPath, append: true)
        logOutput.open()

        do {
            let previousLog = try String(contentsOfFile: logPath)
            print(previousLog)
        } catch {
            // Do nothing
        }

        dateFormatter.dateStyle = .NoStyle
        dateFormatter.timeStyle = .MediumStyle

        sithsManager.stateClosure = { [weak self] state in
            guard let `self` = self else {
                return
            }

            self.logMessage("State changed: \(state)")

            switch state {
            case .Unknown:
                self.stateLabel.textColor = UIColor.blackColor()
                self.stateLabel.text = "Unknown"
            case .ReadingFromCard:
                self.stateLabel.textColor = UIColor.blackColor()
                self.stateLabel.text = "Reading From Card..."
            case .Error(let error):
                self.stateLabel.textColor = UIColor.redColor()
                self.stateLabel.text = "Error \(error)"
            case .ReaderDisconnected:
                self.stateLabel.textColor = UIColor.redColor()
                self.stateLabel.text = "Reader Disconnected"
            case .UnknownCardInserted:
                self.stateLabel.textColor = UIColor.redColor()
                self.stateLabel.text = "Unknown Card Inserted"
            case .CardWithoutCertificatesInserted:
                self.stateLabel.textColor = UIColor.redColor()
                self.stateLabel.text = "SITHS Card Without Certificates Inserted"
            case .ReaderConnected:
                self.stateLabel.textColor = UIColor.blueColor()
                self.stateLabel.text = "Reader Connected"
            case .CardInserted(let certificates):
                self.stateLabel.textColor = UIColor.greenColor()

                let strings = certificates.map { certificate in
                    return "• \(certificate.cardNumber) \(certificate.serialString) \(certificate.subject[.CommonName])"
                }

                self.stateLabel.text = "SITHS Card Inserted:\n\(strings.joinWithSeparator("\n"))"
            }
        }

        sithsManager.debugLogClosure = { [weak self] message in
            guard let `self` = self else {
                return
            }

            self.logMessage(message)
        }
    }

    func logMessage(message: String) {
        NSLog("%@", message)

        let timestamp = dateFormatter.stringFromDate(NSDate())
        logTextView.text = "[\(timestamp)] \(message)\n\(logTextView.text)"

        if let logData = "[\(timestamp)] \(message)\n".dataUsingEncoding(NSUTF8StringEncoding) {
            var bytes = [UInt8](count: logData.length, repeatedValue: 0xFF)
            logData.getBytes(&bytes, range: NSRange(location: 0, length: logData.length))

            logOutput.write(bytes, maxLength: logData.length)
        }
    }

    @IBAction func exportButtonPressed(sender: UIButton) {
        self.logOutput.close()

        let url = NSURL(fileURLWithPath: logPath)
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        activityVC.popoverPresentationController?.sourceView = sender
        activityVC.completionWithItemsHandler = { [weak self] _, _, _, _ in
            guard let `self` = self else {
                return
            }
            let _ = try? NSFileManager.defaultManager().removeItemAtPath(self.logPath)
            self.logOutput = NSOutputStream(toFileAtPath: self.logPath, append: true)
            self.logOutput.open()
            self.logTextView.text = ""
        }
        self.presentViewController(activityVC, animated: true, completion: nil)
    }
}
