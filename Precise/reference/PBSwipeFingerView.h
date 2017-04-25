//
//  PBSwipeFingerView.h
//  BioPhoto
//
//  Created by Fredrik Rosqvist on 2012-09-21.
//  Copyright (c) 2012 Precise Biometrics AB. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PBBiometryFinger.h"

/** A view that animates a swiping finger above a sensor. */
@interface PBSwipeFingerView : UIView {
    /* The finger to be swiped. Default a finger with PBFingerPositionRightIndex. */
    PBBiometryFinger* finger;
    
    UIImageView* fingerImageView;
    UIImageView* sensorImageView;
    
    BOOL isAnimating;
    
    BOOL continueAnimation;
    BOOL insideAnimation;
}

@property (nonatomic, retain) PBBiometryFinger* finger;
@property (nonatomic, readonly) BOOL isAnimating;

- (void)startAnimating;
- (void)stopAnimating;

@end
