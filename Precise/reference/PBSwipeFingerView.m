//
//  PBSwipeFingerView.m
//  BioPhoto
//
//  Created by Fredrik Rosqvist on 2012-09-21.
//  Copyright (c) 2012 Precise Biometrics AB. All rights reserved.
//

#import "PBSwipeFingerView.h"

@implementation PBSwipeFingerView

@synthesize finger;
@synthesize isAnimating;

static const CGFloat sensorScale = 1.3;
static const CGFloat originalHeight = 240.0;
static const CGFloat originalSensorMargin = sensorScale * 4.0;
static const CGFloat originalFingerMargin = 0.0;

- (void)initializeWithFrame:(CGRect)frame
{
    // Initialization code
    CGFloat scale = frame.size.height / originalHeight;

    UIImage* sensorImage = [UIImage imageNamed:@"practice_sensor.png"];
    CGSize sensorSize = CGSizeMake(sensorScale * scale * (sensorImage.size.width / 2), sensorScale * scale * (sensorImage.size.height / 2));
    
    finger = [[PBBiometryFinger alloc] initWithPosition:PBFingerPositionRightIndex andUserId:1];
    UIImage* fingerImage = [self imageForFinger:finger];
    CGSize fingerSize = CGSizeMake(scale * (fingerImage.size.width / 2), scale * (fingerImage.size.height / 2));
    
    /* Create and add sensor view. */
    sensorImageView = [[UIImageView alloc] initWithFrame:CGRectMake((frame.size.width - sensorSize.width) / 2, (scale * originalSensorMargin), sensorSize.width, sensorSize.height)];
    sensorImageView.image = sensorImage;
    [self addSubview:sensorImageView];
    
    /* Create and add finger view. */
    fingerImageView = [[UIImageView alloc] initWithFrame:CGRectMake((frame.size.width - fingerSize.width) / 2, (scale * originalFingerMargin), fingerSize.width, fingerSize.height)];
    fingerImageView.image = fingerImage;
    [self addSubview:fingerImageView];
    
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
    [finger release];
    [fingerImageView release];
    [sensorImageView release];
    [super dealloc];
}

- (void)startAnimating
{
    isAnimating = YES;
    
    if (! continueAnimation && ! insideAnimation) {
        [self animateHand];
    }
    continueAnimation = YES;
}

- (void)stopAnimating
{
    isAnimating = NO;

    continueAnimation = NO;
}


- (UIImage*)imageForFinger: (PBBiometryFinger*)aFinger
{
    switch (aFinger.position) {
        case PBFingerPositionLeftLittle:
            return [UIImage imageNamed:@"left_little.png"];
        case PBFingerPositionLeftRing:
            return [UIImage imageNamed:@"left_ring.png"];
        case PBFingerPositionLeftMiddle:
            return [UIImage imageNamed:@"left_middle.png"];
        case PBFingerPositionLeftIndex:
            return [UIImage imageNamed:@"left_index.png"];
        case PBFingerPositionLeftThumb:
            return [UIImage imageNamed:@"left_thumb.png"];
        case PBFingerPositionRightLittle:
            return [UIImage imageNamed:@"right_little.png"];
        case PBFingerPositionRightRing:
            return [UIImage imageNamed:@"right_ring.png"];
        case PBFingerPositionRightMiddle:
            return [UIImage imageNamed:@"right_middle.png"];
        case PBFingerPositionRightIndex:
        default:
            return [UIImage imageNamed:@"right_index.png"];
        case PBFingerPositionRightThumb:
            return [UIImage imageNamed:@"right_thumb.png"];
    }
    
}

- (void)setFinger:(PBBiometryFinger *)aFinger
{
    [finger release];
    finger = [aFinger retain];
    fingerImageView.image = [self imageForFinger:aFinger];
}


- (void)animateHand
{
    /* Let the finger swipe for 1 second before fading it out and then letting it fade in
     * in the original position. */
    insideAnimation = YES;
    [UIView animateWithDuration:1 delay:1 options:UIViewAnimationOptionAllowUserInteraction animations:^{
        fingerImageView.transform = CGAffineTransformMakeTranslation(0, 40);
    } completion:^(BOOL finished){
        [UIView animateWithDuration:0.5 delay:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
            fingerImageView.alpha = 0.0;
        } completion:^(BOOL finished){
            if (continueAnimation) {
                fingerImageView.transform = CGAffineTransformMakeTranslation(0, 0);
                [UIView animateWithDuration:0.5 delay:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
                    fingerImageView.alpha = 1.0;
                } completion:^(BOOL finished){
                    if (continueAnimation) {
                        [self animateHand];
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
    [fingerImageView setAlpha:alpha];
    [sensorImageView setAlpha:alpha];
}

@end
