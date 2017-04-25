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
 * $Date: 2014-10-21 13:22:03 +0200 (Tue, 21 Oct 2014) $ $Rev: 25069 $ 
 *
 */


#import <Foundation/Foundation.h>

/** The type of template. */
typedef enum {
    PBBiometryTemplateUnknown,
    
    /* Standardized template formats. */
    
    /**
     - IMPORTANT NOTE!
     New template type format constants has been added:
     
     * PBBiometryTemplateTypeISO19794_2005
     * PBBiometryTemplateTypeISO19794_2011
     * PBBiometryTemplateTypeISOCompactCard19794_2005
     * PBBiometryTemplateTypeISOCompactCard19794_2011
     * PBBiometryTemplateTypeANSI378_2004
     * PBBiometryTemplateTypeANSI378_2009
     
     The old template format constants; PBBiometryTemplateTypeISO,
     PBBiometryTemplateTypeISOCompactCard and PBBiometryTemplateTypeANSI
     remains for backward compatibility but defaults to the new latest
     formats of the ISO and ANSI template types.
     
     The most common scenario for a iOSToolkit user updating to this release
     is to do nothing. This will simply start using the latest ISO/ANSI
     template formats through the already existing constants
     PBBiometryTemplateTypeISO, PBBiometryTemplateTypeISOCompactCard and
     PBBiometryTemplateTypeANSI.
     
     The only scenario when you would need to use any of the new template
     formats is if you use the extracted templates with a different
     matching algorithm
     
     When updating to this newer version of the iOSToolkit
     and you would like to stick to the old ISO 19794-2:2005 and/or
     ANSI 378:2004 template versions you need to update the templateType
     in PBBiometryEnrollConfig to
     PBBiometryTemplateTypeISO19794_2005,
     PBBiometryTemplateTypeISOCompactCard19794_2005 or
     PBBiometryTemplateTypeANSI378_2004
     
     Also note that once a template is created by the enrollFinger method
     with any of the new format constants the template type is set to either
     PBBiometryTemplateTypeISO,
     PBBiometryTemplateTypeISOCompactCard or
     PBBiometryTemplateTypeANSI
     regardless if using the old ISO/ANSI format constants. This is to ensure 
     future compatibility. This implies that you should NOT probe a created
     template against any of the new ISO/ANSI format constants.
     And, using any of the new format constants in PBBiometryVerifyConfig is 
     not allowed.
      */
    
    /** The ISO 19794-2:2005 Record Format. */
    PBBiometryTemplateTypeISO19794_2005,
    /** The ISO 19794-2:2011 Record Format. */
    PBBiometryTemplateTypeISO19794_2011,
    
    /** The ISO 19794-2:2005 Compact Card Format */
    PBBiometryTemplateTypeISOCompactCard19794_2005,
    /** The ISO 19794-2:2011 Compact Card Format. The default template type
     * used by the internal extractor and verifier. */
    PBBiometryTemplateTypeISOCompactCard19794_2011,

    /** The ANSI-378:2004 Record Format. */
    PBBiometryTemplateTypeANSI378_2004,
    /** The ANSI-378:2009 Record Format. */
    PBBiometryTemplateTypeANSI378_2009,
    
    /** The ISO 19794-2:2011 Record Format. */
    PBBiometryTemplateTypeISO,
    /** The ISO 19794-2:2011 Compact Card Format. */
    PBBiometryTemplateTypeISOCompactCard,
    /** The ANSI-378:2009 Record Format. */
    PBBiometryTemplateTypeANSI,
    
    /* Proprietary template formats. */
    
    /** The Precise BioMatch 3.0 Record Format. Use only if the verification
      * must be done on a smart card with the Precise BioMatch verifier. 
      * The BioMatch 3.0 Record Format consists of 3 formats, one for enrollment
      * , one for verification and one for the header. */
    PBBiometryTemplateTypeBioMatch3Enrollment,
    PBBiometryTemplateTypeBioMatch3Verification,
    PBBiometryTemplateTypeBioMatch3Header
} PBBiometryTemplateType;

/** A biometric (fingerprint) template. A template contains extracted
  * features from the fingerprint, e.g. minutiae points. */
@interface PBBiometryTemplate : NSObject {
	/** The binary data containing the template. */
	uint8_t* data;
	/** The size of the binary data, in bytes. */
	uint16_t dataSize;
    /** The type of template. */
    PBBiometryTemplateType templateType;
}

@property (nonatomic, readonly) uint8_t* data;
@property (nonatomic, readonly) uint16_t dataSize;
@property (nonatomic, readonly) PBBiometryTemplateType templateType;

/** Initiates the template object with template data. The template 
  * type will be set to PBBiometryTemplateTypeISOCompactCard. */
-(id) initWithData : (const uint8_t*)aData 
        andDataSize: (uint16_t)aDataSize; 

/** Initiates the template object with template data and type. */
-(id) initWithData : (const uint8_t*)aData 
        andDataSize: (uint16_t)aDataSize
    andTemplateType: (PBBiometryTemplateType)aTemplateType;

@end
