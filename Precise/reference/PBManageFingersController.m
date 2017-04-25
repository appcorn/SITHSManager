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
 *
 * $Date: 2013-05-13 13:16:18 +0200 (Mon, 13 May 2013) $ $Rev: 18140 $ 
 *
 */


#import "PBManageFingersController.h"

#import <QuartzCore/CALayer.h>

@implementation PBManageFingersController

@synthesize verifier;
@synthesize verifyConfig;
@synthesize enrollConfig;
@synthesize verifyAgainstAllFingers;
@synthesize enrollableFingers;
@synthesize database;
@synthesize user;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        /* Set default verifier and config parameters. */
        self->verifier = nil;
        self->verifyConfig = [[PBBiometryVerifyConfig alloc] init];
        self->enrollConfig = [[PBBiometryEnrollConfig alloc] init];
        
        self->verifyAgainstAllFingers = YES;
        
        self->enrollableFingers = nil;
        
        /* Set title in case we are added to a navigation controller. */
        if (self.title == nil) {
            self.title = @"Manage fingers";
        }
        
        /* Set tab bar item in case we are added in a tab bar controller. */
        if (self.tabBarItem.image == nil) {
            UITabBarItem* tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Manage fingers" image:[UIImage imageNamed:@"tab_managefingers.png"] tag:0];
            self.tabBarItem = tabBarItem;
            [tabBarItem release];
        }
        
        self->enrollmentPopoverController = nil;
        self->verificationPopoverController = nil;
    }
    return self;
}

- (void)dealloc
{
    [leftHandImage release];
    [rightHandImage release];
    [leftLittle release];
    [leftRing release];
    [leftMiddle release];
    [leftIndex release];
    [leftThumb release];
    [rightLittle release];
    [rightRing release];
    [rightMiddle release];
    [rightIndex release];
    [rightThumb release];
    [scrollView release];
    [noFingersLabel release];
    [scrollToLeftHandImage release];
    [scrollToRightHandImage release];
    
    [database release];
    [user release];
    [fingerButtons release];
    [enrollableFingers release];
    [verifyConfig release];
    [enrollConfig release];
    
    [enrollmentPopoverController release];
    [verificationPopoverController release];
    
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)applyEnrollableFingers
{
    BOOL defaultValue = (enrollableFingers == nil);
    
    /* Default is YES if enrollableFingers is nil, otherwise NO. */
    leftLittle.enabled = defaultValue;
    leftRing.enabled = defaultValue;
    leftMiddle.enabled = defaultValue;
    leftIndex.enabled = defaultValue;
    leftThumb.enabled = defaultValue;
    rightLittle.enabled = defaultValue;
    rightRing.enabled = defaultValue;
    rightMiddle.enabled = defaultValue;
    rightIndex.enabled = defaultValue;
    rightThumb.enabled = defaultValue;
    
    /* Set to YES for all fingers set as enrollable. */
    for (PBBiometryFinger* finger in enrollableFingers) {
        switch (finger.position) {
            case PBFingerPositionLeftLittle:
                leftLittle.enabled = YES;
                break;
            case PBFingerPositionLeftRing:
                leftRing.enabled = YES;
                break;
            case PBFingerPositionLeftMiddle:
                leftMiddle.enabled = YES;
                break;
            case PBFingerPositionLeftIndex:
                leftIndex.enabled = YES;
                break;
            case PBFingerPositionLeftThumb:
                leftThumb.enabled = YES;
                break;
            case PBFingerPositionRightLittle:
                rightLittle.enabled = YES;
                break;
            case PBFingerPositionRightRing:
                rightRing.enabled = YES;
                break;
            case PBFingerPositionRightMiddle:
                rightMiddle.enabled = YES;
                break;
            case PBFingerPositionRightIndex:
                rightIndex.enabled = YES;
                break;
            case PBFingerPositionRightThumb:
                rightThumb.enabled = YES;
                break;
                
            default:
                break;
        }
    }
    
}

- (void)setButtons: (BOOL)inEditMode
{
    for (NSInteger i = 0; i < 10; i++) {
        UIButton* button = (UIButton*)[fingerButtons objectAtIndex:i];
        PBBiometryFinger* finger = [[PBBiometryFinger alloc] initWithPosition:(i + 1) andUser:user];
        BOOL isEnrolled = [database templateIsEnrolledForFinger:finger];
        [finger release];
        
        /* Set correct button image. */
        if (inEditMode) {
            if (isEnrolled) {
                [button setImage:[UIImage imageNamed:@"key_delete.png"] forState:UIControlStateNormal];                     
            }
            else {
                [button setImage:[UIImage imageNamed:@"key_add.png"] forState:UIControlStateNormal];                     
            }
            button.userInteractionEnabled = YES;
        }
        else {
            if (isEnrolled) {
                [button setImage:[UIImage imageNamed:@"key.png"] forState:UIControlStateNormal];                     
            }
            else {
                [button setImage:nil forState:UIControlStateNormal];                     
            }
            button.userInteractionEnabled = NO;
            
        }
    }
        
    /* Set enrollable fingers. */
    [self applyEnrollableFingers];
}

- (void)scrollLeftAnimated: (BOOL)animated
{
    if (! isAnimatingScroll) {
        [scrollView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:animated];
        isAnimatingScroll = animated;
    }
}

- (void)scrollRightAnimated: (BOOL)animated
{
    if (! isAnimatingScroll) {
        [scrollView scrollRectToVisible:CGRectMake(2*320-1, 0, 1, 1) animated:animated];
        isAnimatingScroll = animated;
    }
}

- (IBAction)scrollLeft
{
    [self scrollLeftAnimated:YES];
}

- (IBAction)scrollRight
{
    [self scrollRightAnimated:YES];
}

- (void)scrollViewDidScroll:(UIScrollView *)aScrollView
{
    CGFloat pageWidth = aScrollView.frame.size.width;
    NSInteger page = floor((aScrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;

    if (page != pageCurrentlyShown) {
        pageCurrentlyShown = page;
        
        if (UIDeviceOrientationIsPortrait([[UIDevice currentDevice] orientation])) {
            /* Save the current hand, but only do this while in portrait since when
             * rotating to landscape we might scroll to x = 0 which should not cause a
             * reset of the current hand. */
            [[NSUserDefaults standardUserDefaults] setBool:(page == 0) forKey:@"PBManageFingersController.startAtLeftHand"];  
        }
    }
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    isAnimatingScroll = NO;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    /* Enable paging. */
    scrollView.pagingEnabled = YES;
        
    /* Remove small hands. */
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        scrollToLeftHandImage.alpha = 0;
        scrollToRightHandImage.alpha = 0;
    }
    
    /* Set content size. */
    CGFloat contentWidth;    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        contentWidth = 2 * 320 + 20;
    }
    else {
        contentWidth = 2 * 320;
    }
    [scrollView setContentSize:CGSizeMake(contentWidth, 1)];
    
    /* Set content size for when placed in a popover. */
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        CGRect frame = self.view.frame;
        
        frame.size.width = 2 * 320;
        self.contentSizeForViewInPopover = frame.size;
    }
    
    /* Create and set edit button. */
    UIBarButtonItem* editButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(editFingers)];
    self.navigationItem.rightBarButtonItem = editButton;
    [editButton release];
    
    fingerButtons = [[NSArray alloc] initWithObjects:rightThumb, rightIndex, rightMiddle, rightRing, rightLittle, leftThumb, leftIndex, leftMiddle, leftRing, leftLittle, nil];
    
    /* Move right hand images to the right side. */
    rightHandImage.transform = CGAffineTransformMake(-1, 0, 0, 1, contentWidth - (2 * rightHandImage.frame.origin.x) - rightHandImage.frame.size.width, 0);
    for (NSInteger i = 0; i < 5; i++) {
        UIButton* button = (UIButton*)[fingerButtons objectAtIndex:i];
        
        button.transform = CGAffineTransformMake(1, 0, 0, 1, contentWidth - (2 * button.frame.origin.x) - button.frame.size.width, 0);        
    }
    scrollToLeftHandImage.transform = CGAffineTransformMake(1, 0, 0, 1, contentWidth - (2 * scrollToLeftHandImage.frame.origin.x) - scrollToLeftHandImage.frame.size.width, 0);
    
    /* Flip scrollToRightImage. */
    scrollToRightHandImage.transform = CGAffineTransformMake(-1, 0, 0, 1, 0, 0);
    
    [self setButtons:NO];
            
    /* Set 'You have no fingers..' label if applicable. */
    [noFingersLabel setHidden:([[database getEnrolledFingers] count] > 0)];    
    
    pageCurrentlyShown = 0;
    
    isAnimatingScroll = NO;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
    
    [self layoutScrollView:duration];
    if (! [[NSUserDefaults standardUserDefaults] boolForKey:@"PBManageFingersController.startAtLeftHand"]) {
        [self scrollRightAnimated:NO];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    /* Do nothing. */
}

/* Layout scrollview based on type of device and device orientation. */
- (void)layoutScrollView: (NSTimeInterval)duration
{
    BOOL isIPad = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
    BOOL inLandscapeMode = (([[UIApplication sharedApplication] statusBarOrientation] == UIInterfaceOrientationLandscapeLeft) || ([[UIApplication sharedApplication] statusBarOrientation] == UIInterfaceOrientationLandscapeRight));
    
    /* Reset transform. */
    scrollView.transform = CGAffineTransformIdentity;
    
    /* Set frame size. */
    CGRect frame = scrollView.frame;  
    if (isIPad) {
        frame.size.width = 2 * 320 + 20; // Adding additional 20 points for more spacing.
    }
    else {
        if (inLandscapeMode) {
            frame.size.width = 2 * 320;
        }
        else {
            frame.size.width = 320;
        }
    }
    scrollView.frame = frame;
    
    /* Apply scaling for iPhone landscape mode. */
    if (!isIPad && inLandscapeMode) {
        CGFloat scale = [UIScreen mainScreen].bounds.size.height / scrollView.frame.size.width;
        scrollView.transform = CGAffineTransformMakeScale(scale, scale);
    }
    
    /* Set frame position. */
    if (isIPad) {
        scrollView.center = self.view.center;
    }
    else {
        frame = scrollView.frame;
        frame.origin.x = 0; 
        frame.origin.y = 0;
        scrollView.frame = frame;
    }
    
    /* Center no fingers label. */
    noFingersLabel.center = self.view.center;

    /* Hide small hands for iPhone landscape mode. */
    if (!isIPad) {
        if (inLandscapeMode) {
            [UIView animateWithDuration:duration animations:^{
                scrollToLeftHandImage.alpha = 0;
                scrollToRightHandImage.alpha = 0;
            }];
        }
        else {
            [UIView animateWithDuration:duration animations:^{
                scrollToLeftHandImage.alpha = 1;
                scrollToRightHandImage.alpha = 1;
            }];
        }
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self layoutScrollView:0.3];
    /* Make sure that the user sees the same hand as the last time. */
    if (! [[NSUserDefaults standardUserDefaults] boolForKey:@"PBManageFingersController.startAtLeftHand"]) {
        [self scrollRightAnimated:NO];
    }
    
    /* Show toolbar if we are used in a navigation controller. */
    [self.navigationController setToolbarHidden:NO];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAllButUpsideDown;
}

- (void)doEditFingers
{
    [self setButtons:YES];
    
    /* Create and set done button. */
    UIBarButtonItem* editButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneEditingFingers)];
    self.navigationItem.rightBarButtonItem = editButton;
    [editButton release];
    
    /* Disable back button, if any. */
    self.navigationItem.hidesBackButton = YES;
    /* Disable tabs, if any. */
    self.tabBarItem.enabled = NO;
    self.tabBarController.tabBar.userInteractionEnabled = NO;
    /* Hide "No fingers registered". */
    [noFingersLabel setHidden:YES];
}

-(NSString*) fingerStringfromFinger: (PBBiometryFinger*) aFinger
{
    switch (aFinger.position) {
        case PBFingerPositionLeftIndex:
            return @"left index";
        case PBFingerPositionLeftLittle:
            return @"left little";
        case PBFingerPositionLeftMiddle:
            return @"left middle";
        case PBFingerPositionLeftRing:
            return @"left ring";
        case PBFingerPositionLeftThumb:
            return @"left thumb";
        case PBFingerPositionRightIndex:
            return @"right index";
        case PBFingerPositionRightLittle:
            return @"right little";
        case PBFingerPositionRightMiddle:
            return @"right middle";
        case PBFingerPositionRightRing:
            return @"right ring";
        case PBFingerPositionRightThumb:
            return @"right thumb";
        default:
            return @"any";
    }
}

- (void)editFingers
{    
    if ([[database getEnrolledFingers] count] > 0) {
        /* Do not allow non-authorized users to edit fingers, verify that this is
         * the enrolled user. */
        [self presentVerificationController];
    }
    else {
        /* No fingers enrolled, continue directly to edit mode. */
        [self doEditFingers];
    }
}

- (void)refreshInMainThread
{
    [self setButtons:NO];
    
    /* Create and set edit button. */
    UIBarButtonItem* editButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(editFingers)];
    self.navigationItem.rightBarButtonItem = editButton;
    [editButton release];
    
    /* Enable back button, if any. */
    self.navigationItem.hidesBackButton = NO;
    /* Enable tab bar, if any. */
    self.tabBarController.tabBar.userInteractionEnabled = YES;
    self.tabBarItem.enabled = YES;
    
    /* Set 'You have no fingers..' label if applicable. */
    [noFingersLabel setHidden:([[database getEnrolledFingers] count] > 0)];    
}

- (void)refresh
{
    [self performSelectorOnMainThread:@selector(refreshInMainThread) withObject:nil waitUntilDone:NO];
}

static PBBiometryFinger* fingerToBeDeleted = nil;

#define ACTION_SHEET_TAG_DELETE_FINGER     1
#define ACTION_SHEET_TAG_CONTINUE          2

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if ((actionSheet == nil) || (actionSheet.tag == ACTION_SHEET_TAG_CONTINUE)) {
        if (buttonIndex == 0) {
            /* The user wants to continue without any registered fingers. */
            [self refresh];
        }
    }
    else if (actionSheet.tag == ACTION_SHEET_TAG_DELETE_FINGER) {
        if (buttonIndex == 0) {
            /* The user wants to delete the finger. */
            [database deleteTemplateForFinger:fingerToBeDeleted];
            
            UIButton* button = (UIButton*)[fingerButtons objectAtIndex:(fingerToBeDeleted.position - 1)];
            [button setImage:[UIImage imageNamed:@"key_add.png"] forState:UIControlStateNormal];
        }
        [fingerToBeDeleted release];
        fingerToBeDeleted = nil;
    }
}

- (IBAction)enrollFinger: (id) sender
{
    UIButton* buttonPressed = (UIButton*) sender;
    PBBiometryFinger* finger = nil;
    
    if (buttonPressed == leftLittle) {
        finger = [[PBBiometryFinger alloc] initWithPosition:PBFingerPositionLeftLittle andUser:user];
    }
    else if (buttonPressed == leftRing) {
        finger = [[PBBiometryFinger alloc] initWithPosition:PBFingerPositionLeftRing andUser:user];    
    }
    else if (buttonPressed == leftMiddle) {
        finger = [[PBBiometryFinger alloc] initWithPosition:PBFingerPositionLeftMiddle andUser:user];    
    }
    else if (buttonPressed == leftIndex) {
        finger = [[PBBiometryFinger alloc] initWithPosition:PBFingerPositionLeftIndex andUser:user];    
    }
    else if (buttonPressed == leftThumb) {
        finger = [[PBBiometryFinger alloc] initWithPosition:PBFingerPositionLeftThumb andUser:user];    
    }
    else if (buttonPressed == rightLittle) {
        finger = [[PBBiometryFinger alloc] initWithPosition:PBFingerPositionRightLittle andUser:user];    
    }
    else if (buttonPressed == rightRing) {
        finger = [[PBBiometryFinger alloc] initWithPosition:PBFingerPositionRightRing andUser:user];    
    }
    else if (buttonPressed == rightMiddle) {
        finger = [[PBBiometryFinger alloc] initWithPosition:PBFingerPositionRightMiddle andUser:user];    
    }
    else if (buttonPressed == rightIndex) {
        finger = [[PBBiometryFinger alloc] initWithPosition:PBFingerPositionRightIndex andUser:user];    
    }
    else if (buttonPressed == rightThumb) {
        finger = [[PBBiometryFinger alloc] initWithPosition:PBFingerPositionRightThumb andUser:user];    
    }
    
    /* Save current hand also when the user is enrolling a finger ensuring that if this is
     * done in landscape mode, when the user returns to portrait mode the hand of the 
     * enrolled finger should be the displayed hand. */
    [[NSUserDefaults standardUserDefaults] setBool:[finger isOnLeftHand] forKey:@"PBManageFingersController.startAtLeftHand"];  
    
    if (finger != nil) {
        if ([database templateIsEnrolledForFinger:finger]) {
            /* Already enrolled, delete. */
            UIActionSheet* actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Delete registered finger" otherButtonTitles:nil];
            
            actionSheet.tag = ACTION_SHEET_TAG_DELETE_FINGER;
            fingerToBeDeleted = finger;
            [finger retain];
            actionSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
            //[actionSheet showFromBarButtonItem:self.navigationItem.rightBarButtonItem animated:YES];
            [actionSheet showFromRect:buttonPressed.frame inView:scrollView animated:YES];
            [actionSheet release];
        }
        else {
            /* Not enrolled, start enrollment. */
            [self presentEnrollmentControllerForFinger:finger];
        }
        [finger release];
    }
}

- (UIButton*)buttonForFinger:(PBBiometryFinger*)finger
{
    switch (finger.position) {
        case PBFingerPositionLeftIndex:
            return leftIndex;
        case PBFingerPositionLeftLittle:
            return leftLittle;
        case PBFingerPositionLeftMiddle:
            return leftMiddle;
        case PBFingerPositionLeftRing:
            return leftRing;
        case PBFingerPositionLeftThumb:
            return leftThumb;
        default:
        case PBFingerPositionRightIndex:
            return rightIndex;
        case PBFingerPositionRightLittle:
            return rightLittle;
        case PBFingerPositionRightMiddle:
            return rightMiddle;
        case PBFingerPositionRightRing:
            return rightRing;
        case PBFingerPositionRightThumb:
            return rightThumb;
    }
}

- (void)presentEnrollmentController:(PBEnrollmentController*)enrollmentController
                          forFinger:(PBBiometryFinger*)finger;
{
    enrollmentController.database = database;
    enrollmentController.finger = finger;
    enrollmentController.delegate = self;
    enrollmentController.config = enrollConfig;
    PBRotationTransparentNavigationController* navController = [[PBRotationTransparentNavigationController alloc] initWithRootViewController:enrollmentController];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        enrollmentPopoverController = [[UIPopoverController alloc] initWithContentViewController:navController];
        
        [enrollmentPopoverController presentPopoverFromRect:[self buttonForFinger:finger].frame inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    }
    else {
        [self presentViewController:navController animated:YES completion:NULL];
    }
    
    [navController release];
}

- (void)presentEnrollmentControllerForFinger:(PBBiometryFinger*)finger
{
    PBEnrollmentController* enrollmentController = [[PBEnrollmentController alloc] initWithNibName:@"PBEnrollmentController" bundle:[NSBundle mainBundle]];
    
    [self presentEnrollmentController:enrollmentController forFinger:finger];
    [enrollmentController release];
}

- (void)presentVerificationController:(PBVerificationController*)verificationController
{
    verificationController.database = database;
    verificationController.fingers = [database getEnrolledFingers];
    verificationController.delegate = self;
    verificationController.message = @"Swipe to unlock edit mode.";
    verificationController.verifier = verifier;
    verificationController.config = verifyConfig;
    verificationController.verifyAgainstAllFingers = verifyAgainstAllFingers;
    PBRotationTransparentNavigationController* navController = [[PBRotationTransparentNavigationController alloc] initWithRootViewController:verificationController];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        verificationPopoverController = [[UIPopoverController alloc] initWithContentViewController:navController];
        
        [verificationPopoverController presentPopoverFromBarButtonItem:self.navigationItem.rightBarButtonItem permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
        /* Do not allow user to tap on toolbar while popover is active. */
        verificationPopoverController.passthroughViews = nil;
    }
    else {
        [self presentViewController:navController animated:YES completion:NULL];
    }
    
    [navController release];
}

- (void)presentVerificationController
{
    PBVerificationController* verificationController = [[PBVerificationController alloc] initWithNibName:@"PBVerificationController" bundle:[NSBundle mainBundle]];
    
    [self presentVerificationController:verificationController];
    [verificationController release];
}

- (void)doneEditingFingers
{
    if ([[database getEnrolledFingers] count] >  0) {
        /* At least one finger is registered, continue. */
        [self actionSheet:nil clickedButtonAtIndex:0];
    }
    else {
        /* No fingers registered, ask user to continue. */
        UIActionSheet* actionSheet = [[UIActionSheet alloc] initWithTitle:@"Continue without any registered fingers?" delegate:self cancelButtonTitle:@"Register fingers" destructiveButtonTitle:@"Continue" otherButtonTitles:nil];
        
        actionSheet.tag = ACTION_SHEET_TAG_CONTINUE;
        actionSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
        [actionSheet showFromBarButtonItem:self.navigationItem.rightBarButtonItem animated:YES];
        [actionSheet release];
    }
}

- (void)enrollmentTemplateEnrolledForFinger:(PBBiometryFinger *)finger
{
    if (finger) {
        UIButton* button = (UIButton*)[fingerButtons objectAtIndex:(finger.position - 1)];

        [button setImage:[UIImage imageNamed:@"key_delete.png"] forState:UIControlStateNormal];
    }

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [enrollmentPopoverController dismissPopoverAnimated:YES];
        [enrollmentPopoverController release];
        enrollmentPopoverController = nil;
    }
    else {
        [self dismissViewControllerAnimated:YES completion:NULL];
    }
}

- (void)verificationVerifiedFinger: (PBBiometryFinger*) finger
{
    if (finger) {
        [self doEditFingers];
    }
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [verificationPopoverController dismissPopoverAnimated:YES];
        [verificationPopoverController release];
        verificationPopoverController = nil;
    }
    else {
        [self dismissViewControllerAnimated:YES completion:NULL];
    }
}

/* DEPRECATED. */
- (id) initWithDatabase: (id<PBBiometryDatabase>) aDatabase
                andUser: (PBBiometryUser*) aUser;
{
    self = [self initWithNibName:@"PBManageFingersController" bundle:[NSBundle mainBundle]];
    if (self) {
        [self setDatabase:aDatabase];
        [self setUser:aUser];
    }
    return self;    
}

@end
