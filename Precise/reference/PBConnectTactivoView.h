//
//  PBConnectTactivoView.h
//  BioPhoto
//
//  Created by Fredrik Rosqvist on 2012-10-03.
//  Copyright (c) 2012 Precise Biometrics AB. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PBConnectTactivoView : UIView {
    
    UIImageView* tactivoTopImageView;
    UIImageView* tactivoBottomImageView;
    UIImageView* iphoneImageView;
    
    BOOL isAnimating;
    
    BOOL continueAnimation;
    BOOL insideAnimation;
    
}

@property (nonatomic, readonly) BOOL isAnimating;

- (void)startAnimating;
- (void)stopAnimating;

@end
