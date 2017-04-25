//
//  PBConnectTactivoView.m
//  BioPhoto
//
//  Created by Fredrik Rosqvist on 2012-10-03.
//  Copyright (c) 2012 Precise Biometrics AB. All rights reserved.
//

#import "PBConnectTactivoView.h"

@implementation PBConnectTactivoView

@synthesize isAnimating;

- (void)initializeWithFrame:(CGRect)frame
{
    // Initialization code
    UIImage* image = [UIImage imageNamed:@"connect_tactivo_bottom.png"];
    
    /* Compute image frame and center. */
    CGRect imageFrame = frame;
    imageFrame.size.width = image.size.width * imageFrame.size.height / image.size.height;
    CGPoint imageCenter = CGPointMake(frame.size.width / 2, frame.size.height / 2);
    
    /* Create and add image views. */
    tactivoBottomImageView = [[UIImageView alloc] initWithFrame:imageFrame];
    tactivoBottomImageView.image = image;
    [self addSubview:tactivoBottomImageView];
    tactivoBottomImageView.center = imageCenter;
    
    tactivoTopImageView = [[UIImageView alloc] initWithFrame:imageFrame];
    tactivoTopImageView.image = [UIImage imageNamed:@"connect_tactivo_top.png"];;
    [self addSubview:tactivoTopImageView];
    tactivoTopImageView.center = imageCenter;
    
    iphoneImageView = [[UIImageView alloc] initWithFrame:imageFrame];
    iphoneImageView.image = [UIImage imageNamed:@"connect_tactivo_iphone.png"];;
    [self addSubview:iphoneImageView];
    iphoneImageView.center = imageCenter;
    
    
    isAnimating = NO;
    
    insideAnimation = NO;
    continueAnimation = NO;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initializeWithFrame:self.frame];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self initializeWithFrame:frame];
    }
    return self;
}

- (void)dealloc
{
    [tactivoBottomImageView release];
    [tactivoTopImageView release];
    [iphoneImageView release];
    [super dealloc];
}

- (void)startAnimating
{
    tactivoTopImageView.hidden = YES;
    isAnimating = YES;
    
    if (! continueAnimation && ! insideAnimation) {
        [self animateConnection];
    }
    continueAnimation = YES;
}

- (void)stopAnimating
{
    isAnimating = NO;
    
    continueAnimation = NO;
}

- (void)animateConnection
{
    insideAnimation = YES;
    [UIView animateWithDuration:0.5 delay:1 options:0 animations:^{
        tactivoTopImageView.alpha = 0;
        iphoneImageView.alpha = 0;
    } completion:^(BOOL finished){
        tactivoTopImageView.transform = CGAffineTransformMakeTranslation(0, -(self.frame.size.height / 3));
        iphoneImageView.transform = CGAffineTransformMakeTranslation(0, -(self.frame.size.height / 3));
        [UIView animateWithDuration:0.5 delay:0.5 options:0 animations:^{
            tactivoTopImageView.alpha = 1;
            iphoneImageView.alpha = 1;
        } completion:^(BOOL finished){
            if (continueAnimation) {
                [UIView animateWithDuration:1.0 delay:0 options:0 animations:^{
                    tactivoTopImageView.transform = CGAffineTransformIdentity;
                    iphoneImageView.transform = CGAffineTransformIdentity;
                } completion:^(BOOL finished) {
                    if (continueAnimation) {
                        [self animateConnection];
                    }
                    else {
                        insideAnimation = NO;
                    }
                }];
            }
            else {
                insideAnimation = NO;
            }
        }];
    }];
}

- (void)setAlpha:(CGFloat)alpha
{
    [super setAlpha:alpha];
    [tactivoBottomImageView setAlpha:alpha];
    [tactivoTopImageView setAlpha:alpha];
    [iphoneImageView setAlpha:alpha];
}

@end
