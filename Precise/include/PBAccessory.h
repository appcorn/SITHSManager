/*
 * Copyright (c) 2011 - 2013, Precise Biometrics AB
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. Neither the name of the Precise Biometrics AB nor the names of its
 *    contributors may be used to endorse or promote products derived from
 *    this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
 * COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
 * OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED
 * AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
 * THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
 * DAMAGE.
 *
 *
 * $Date: 2014-02-11 12:01:54 +0100 (Tue, 11 Feb 2014) $ $Rev: 21575 $ 
 *
 */
 
#import <Foundation/Foundation.h>

#import <ExternalAccessory/ExternalAccessory.h>


/* The PBAccessory class delivers specific notifications for when the Tactivo gets connected
 * and is ready for communication and when it gets disconnected. For more detailed information 
 * about accessory connections, use EAAccessoryDidConnectNotification (EAC) and 
 * EAAccessoryDidDisconnectNotification (EAD) notifications. Note that an EAC notification is 
 * received directly after the device is inserted into the Tactivo, but that the associated 
 * accessory does not contain the Tactivo protocol strings. When the Tactivo is authenticated 
 * after 1-2 seconds an EAD notification is sent, immediately followed by a new EAC. This new 
 * EAC will then have an associated accessory containing the correct Tactivo protocol strings, 
 * meaning that the Tactivo is now ready for communication. Also note that if the Tactivo is 
 * removed from the device before the authentication is completed, no EAC with an associated 
 * accessory with the Tactivo protocol strings will be sent. */


/** The notification sent when Tactivo is connected and ready for communication. Note that 
  * Tactivo is not ready for communication until iOS has authenticated it, which may take 
  * 1-2 seconds from that when the device is inserted into the Tactivo. */
extern NSString *const PBAccessoryDidConnectNotification;
/** The notification sent when Tactivo gets disconnected. */
extern NSString *const PBAccessoryDidDisconnectNotification;


/** Class that handles communication with the Tactivo accessory that
  * is not biometry or smartcard related. 
  * 
  * PBAccessory generates the following notifications:
  *     PBAccessoryDidConnectNotification
  *     PBAccessoryDidDisconnectNotification
  * The application can register for these notifications by adding itself as an observer on the
  * NSNotificationCenter object:
  *     [[NSNotificationCenter defaultCenter] addObserver:myObject selector:@selector(mySelector:) name:PBAccessoryDidConnectNotification object:[PBAccessory sharedClass]];
  */
@interface PBAccessory : NSObject {
    /** Tells if the accessory is connected or not. */
    BOOL connected;
    /** Notification queue. */
    NSMutableArray* notificationQueue;
    /** Semaphore used by the notification handler. */
    dispatch_semaphore_t notificationSemaphore;
}

@property (nonatomic, readonly, getter = isConnected) BOOL connected;

/** Returns YES if the connected accessory, if any, features a contact smart card reader.
 *
 * @return YES if the connected accessory has a contact smart card reader, or NO if no accessory is connected or does not support a contact smart card reader.
 */
@property (nonatomic, readonly) BOOL hasSmartCardReader;

/** Returns YES if the connected accessory, if any, features a fingerprint sensor.
 *
 * @return YES if the connected accessory has a fingerprint sensor, or NO if no accessory is connected or does not support a fingerprint sensor.
 */
@property (nonatomic, readonly) BOOL hasFingerprintSensor ;


@property (nonatomic, readonly) NSString* modelNumber;

@property (nonatomic, readonly) NSString*  hardwareRevision;

/* Class method for receiving the singleton object. */
+ (PBAccessory*) sharedClass;

/** Returns the EAAccessory object for the connected accessory, if any. 
  * 
  * @return the connected accessory, or nil if no accessory is connected.
  */
- (EAAccessory*)getAccessory;



@end