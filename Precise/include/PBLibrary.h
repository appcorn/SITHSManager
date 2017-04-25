/*
 * Copyright (c) 2011 - 2012, Precise Biometrics AB
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
 * $Date: 2014-10-27 13:56:25 +0100 (Mon, 27 Oct 2014) $ $Rev: 25122 $ 
 *
 */
 
#import <Foundation/Foundation.h>

/* Library log levels.
 * A step in log level will also incorporate previous steps as well.
 * For example, choosing level 'Info' will automatically include log levels
 * 'Warn' and 'Error'.
 */
typedef enum
{
    /* Logging is turned off (default value) */
    Off,
    /* Critical error messages are logged */
    Error,
    /* Warning messages are logged */
    Warn,
    /* Informational messages are logged */
    Info,
    /* Debug messages are logged */
    Debug,
    /* Verbose logging is enabled */
    Verbose
} PBLogLevel;

/** Class that handles toolkit/library functionality that is not
  * accessory, biometry or smartcard related. 
  *
  */
@interface PBLibrary : NSObject {
    NSString* version;
}
/** The version of the static library. */
@property (nonatomic, readonly, retain) NSString* version;

/* Used to enable/set/get the current library log level.
 * Logging is always switched off by default but can be turned on at runtime
 * to get diagnostic information also after the app has been deployed.
 * Logging messages are sent to the XCode console output, Apple System Log and
 * stored as a log file in the consuming app sandbox at:
 * ./Library/Caches/Logs/PreciseBiometricsiOSLibrary.log. The max size of the 
 * log file is 1 MB.
 * An additional new file is created with filename
 * PreciseBiometricsiOSLibrary <n>.log for each fresh start of the app or if
 * the log file size exceeds 1 MB.
 * Note that logging adds some minimal processing and memory overhead.
 * The 'Verbose' log setting include information that may be sensitive to the 
 * application such as APDU traces. This setting should not be used unless
 * absolutely required (or during development/troubleshooting).
 */
@property (nonatomic, assign)PBLogLevel logLevel;

/** Class method for receiving the singleton object. */
+ (PBLibrary*) sharedClass;

@end