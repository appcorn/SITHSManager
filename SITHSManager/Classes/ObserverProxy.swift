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

/**
 Simple Proxy class to enable closure based NSNotificaionCenter observers.
 */
class ObserverProxy {
    let closure: (Notification) -> ();

    /**
     Creates and registers an observer for the provided parameters.

     - parameter name:    The `NSNotificationCenter` notification name to observe.
     - parameter object:  The `NSNotificationCenter` sender object to observe, can be nil.
     - parameter closure: The closure block to execute when the notification is sent by `NSNotificationCenter` This closure should take a
     `NSNotification` as parameter.

     - returns: The registered observer proxy. Note that the caller of this init method is responsibe for storing the observer proxy. When
     the object is deinited, the observation is removed from `NSNotificationCenter`
     */
    init(name: NSNotification.Name, object: AnyObject?, closure: @escaping (Notification) -> ()) {
        self.closure = closure

        NotificationCenter.default.addObserver(self, selector: #selector(self.handler), name: name, object: object);
    }

    deinit {
        stop()
    }

    /**
     Manually removes the observer from `NSNotificationCenter`
     */
    func stop() {
        NotificationCenter.default.removeObserver(self);
    }

    dynamic func handler(notification: Notification) {
        closure(notification);
    }
}
