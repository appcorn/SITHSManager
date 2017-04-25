
 Precise iOS Toolkit - 2.13

 Copyright Precise Biometrics AB
 Date: 2015-10-07
 P/N:  ALA 113 1001

======================================================================
  NEW FEATURES AND FIXED PROBLEMS 2015-10-07 (2.13 version):

API CHANGES
  >>>
   None.
  <<<

iOSLibrary
 - Rebuilt using SDK9 + XCode7.0.1 to have full bitcode version included

====================================================================== 
  NEW FEATURES AND FIXED PROBLEMS 2015-09-18 (2.12 version):

API CHANGES
  >>> 
   None.
  <<< 

iOSLibrary
 - Rebuilt using SDK9 to have bitcode version included

====================================================================== 
  NEW FEATURES AND FIXED PROBLEMS 2015-02-12 (2.11 version):

API CHANGES
  >>>
   PBBiometryGUI.h updated with two new optional methods:
   displayRawImage and displayChosenRawImage
   These methods gives an unprocessed raw image from the sensor.
   More details in PBBiometryGUI.h.
  <<<

iOSLibrary
 - Bug fix for ambiguous type in SCARD_IO_REQUEST (winscard.h)
 - Bug fix for possible crash if calling cancel from within a GUI callback

====================================================================== 
  NEW FEATURES AND FIXED PROBLEMS 2014-10-27 (2.10 version):

API CHANGES
  >>>
   If using any of these template type formats during enrollment:
   PBBiometryTemplateTypeISO, PBBiometryTemplateTypeISOCompactCard or
   PBBiometryTemplateTypeANSI, the templates created will comply to the
   latest standards ISO 19794-4:2011 and ANSI 378:2009, compared to the
   older versions used in previous toolkit versions; ISO 19794:2005 and
   ANSI 378:2004. See PBBioemtryTemplate.h for further details.
  <<<

iOSLibrary
 - Update to use ISO 19794-4:2011 and ANSI 378:2009 template formats as
   default.
 - Bux fix for immediate timout at PBBiometry::enrollFinger: on 64-bit
   devices.
 - Deprecated PBSmartcard::accessoryConnected: and
   PBSmartcard::accessoryDisconnected:. Use regular
   PBAccessoryDidConnectNotification and
   PBAccessoryDidDisconnectNotification instead (see PBAccessory.h)

====================================================================== 
  NEW FEATURES AND FIXED PROBLEMS 2014-05-09 (2.9 version):

iOSLibrary
 - Stability and speed fix for PCSC API when working in multiple
   smart card contexts.
 - Additional logging from PCSC API at log level 'Debug'

====================================================================== 
  NEW FEATURES AND FIXED PROBLEMS 2014-04-10 (2.8 version):

iOSLibrary
 - Improved biometric performance.
 - Added properties to query accessory hardware capabilities.
 - SCardGetStatusChange now sets the SCARD_STATE_CHANGED bit.
 - Support for arm64 instruction set.
 - Added logging capabilities (see PBLibrary.h)
 - Fixed rare deadlock bug that caused SCardConnect/SCardTransmit to 
   return SCARD_E_UNRESPONSIVE_CARD.
 - Minor bug fixes. 
 - armv6 instruction set no longer supported!

iOSReference
 - Fixed bug in PBSmartcardBioManager.m where enrolment data was sent 
   in the FINALIZE command. 

====================================================================== 
  NEW FEATURES AND FIXED PROBLEMS 2014-03-28 (2.7.1 version):

iOSLibrary
 - Rebuilt using XCode 5.1 and iOS SDK 7.1, nothing else changed.

====================================================================== 
  NEW FEATURES AND FIXED PROBLEMS 2013-09-23 (2.7 version):

iOSLibrary
 - SCARD_ATTR_AUTO_POWER_ON will now power on an already inserted 
   card. 
 - Minor bug fixes. 

====================================================================== 
  NEW FEATURES AND FIXED PROBLEMS 2013-07-10 (2.6 version):

iOSLibrary
 - Bug fixes
 - Smart card auto power on supported with new proprietary attribute
   SCARD_ATTR_AUTO_POWER_ON. Auto power on is disabled by default.
 - Removed deprecated PBAccessoryDelegate protocol.

====================================================================== 
  NEW FEATURES AND FIXED PROBLEMS 2013-06-12 (2.5 version):

Sample code is no longer a part of the toolkit. 
Updated sample code can be found on www.idapps.com/developers

iOSLibrary
 - General stability fixes.
 - Improved error handling. 

====================================================================== 
  NEW FEATURES AND FIXED PROBLEMS 2013-04-17 (2.4 version):
 
iOSLibrary
 - Improved stability when moving from/to background
 - SCardGetStatusChange will now populate ATR if card is inserted
   
iOSReference
 - Fix for possible crash when using verification controller on iOS6

====================================================================== 
  NEW FEATURES AND FIXED PROBLEMS 2013-02-07 (2.3 version):
 
iOSLibrary
 - Fixed intermittent deadlock on iOS 6.1.
 - Various stability improvements.
   
====================================================================== 
  NEW FEATURES AND FIXED PROBLEMS 2012-09-24 (2.2 version):
 
iOSLibrary
 - Library compiled with latest iOS SDK (6.0) to support new ARM architecture (arm7s).
   
======================================================================

 NEW FEATURES AND FIXED PROBLEMS 2012-08-21 (2.1 version):
 
 General
 - Minor stability and performance improvements. 

iOSLibrary
Biometry:
 - Fixed crash when matching ANSI templates.

iOSReference:
 - Updated UI for the Manage Fingers controller. Now shows the correct hand when 
   returning to portrait mode after being in landscape mode.
 
======================================================================

 NEW FEATURES AND FIXED PROBLEMS 2012-05-23 (2.0 version):

General
 - API changes. 
 - Added support for playing sounds for different actions, e.g. smartcard 
   inserted or verification failed. Also added support for vibrating when swipe
   error occurs. 
 - Updated projects to support Xcode 4.3.
 - Example code BioSecrets and BioSCReader removed from toolkit 
 - Accessory connect / disconnect messages are coalesced.
 - Added new class PBLibrary
 - iOS 4 no longer supported.
 - Several bug fixes & improvements. 

iOSLibrary
Biometry:
 - Support for Match-on-Card.
 - Support for BioMatch 3.0 template format. 
 - PBBiometry class is now a singleton. Get the object by calling [PBBiometry 
   sharedBiometry].
 - Support for MoC verification added, see new protocol PBBiometryVerifier and 
   new extended verifyFingers method in PBBiometry. 

Smartcard:
 - PBSmartcard should now be thread safe. 
 - Implemented new functions SCardIsValidContext, SCardCancel, SCardSetAttrib 
   and SCardGetAttrib 
 - Deprecated DISABLE_BACKGROUND_MANAGEMENT for use with SCardEstablishContext
 - Background session management is now handled using SCardSetAttrib and
   SCardGetAttrib

Accessory:
 - Deprecated PBAccessoryDelegate protocol and instead added 
   PBAccessoryDidConnectNotification and PBAccessoryDidDisconnectNotification 
   notifications. 

iOSReference
 - Support for BioMatch3 verification, see PBBiomatch3Database and 
   PBBiomatch3Verifier. Also added PBSmartcardBioManager and PBSmartcardIDStore 
   for easy access to BioManager and IDStore.
 - PBVerificationController updated to support MoC, see verifier, config and 
   verifyAgainstAllFingers parameters.
 - PBEnrollmentController updated to support MoC, see config parameter.
 - PBManageFingersController updated to support MoC, see verifier, verifyConfig,
   enrollConfig, verifyAgainstAllFingers and enrollableFingers parameters.
 - PBVerificationController now displays the actual finger that the user has 
   enrolled. If more than one finger is enrolled the last verified finger is 
   shown. 
 - Updated alert texts. 

======================================================================

 NEW FEATURES AND FIXED PROBLEMS 2011-11-25 (1.0 version):

 - First official release.

======================================================================

 SYSTEM REQUIREMENTS:
 
 - Xcode 5
 - iOS 7 or later

======================================================================

 INSTALLATION:

 1. Unzip package to an appropriate location.

======================================================================

 INCLUDED FILES:

 doc
   |- Includes manuals and reference documentation
 include
   |- Includes the external API
 lib
   |- Includes the static library that provides biometric- and smart
   |  card functionality 
 reference
   |- Includes reference implementations that are strongly recommended
      to be utilized by app developers

======================================================================

 IMPORTANT:

 - This delivery may not be redistributed and must be treated as 
   confidential.
 - The fingerprint database implementation included in this toolkit 
   is provided as a reference only.

======================================================================

 DEVELOPER NOTE(S):

 How to build the smart card sample apps:
 --------------------------------
 1. Open the corresponding Xcode workspace.
 2. Build 

 Known limitations:
 ------------------
 - If App1 use the smart card reader while running in the background and App2 
   attempts to access the smart card reader iOS will automatically terminate the
   underlying session for App1 and create a new session for App2. If App1 was 
   running a lengthy card operation while the session was terminated the 
   transmit function will not return an error until the operation times out. The
   actual value of the time out is card dependent and can in some cases be 
   several minutes long. 
   The smart card is always powered off when a session is terminated so App2 
   will not be able to access sensitive information on a smart card that has 
   been "unlocked" by App1. 

 External accessory protocol support:
 ------------------------------------
 In order to use the different external accessory protocols defined for 
 Tactivo those has to be listed for each target:
 "TARGETS" -> "MyTarget" -> "Info" -> "Supported external accessory protocols". 
 Add the following values:
 com.precisebiometrics.ccidbulk
 com.precisebiometrics.ccidinterrupt
 com.precisebiometrics.ccidcontrol
 com.precisebiometrics.sensor

 Note that "Supported external accessory protocols" is probably not 
 defined by default and thus needs to be added before any values can be set.

======================================================================

