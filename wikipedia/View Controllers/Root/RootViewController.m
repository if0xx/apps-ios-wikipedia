//  Created by Monte Hurd on 5/15/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "RootViewController.h"
#import "TopMenuViewController.h"
#import "BottomMenuViewController.h"
#import "WebViewController.h"
#import "UINavigationController+SearchNavStack.h"
#import "TopMenuContainerView.h"
#import "UIViewController+StatusBarHeight.h"
#import "Defines.h"
#import "ModalMenuAndContentViewController.h"
#import "UIViewController+ModalPresent.h"
#import "OnboardingViewController.h"

@interface RootViewController (){
    
}

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *centerContainerTopConstraint;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topContainerHeightConstraint;

@property (strong, nonatomic) UIViewController *topVC;

@end

@implementation RootViewController

-(void)constrainTopContainerHeight
{
    CGFloat topMenuHeight = TOP_MENU_INITIAL_HEIGHT;
    
    // iOS 7 needs to have room for a view behind the top status bar.
    if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1) {
        if(![self prefersStatusBarHiddenForViewController:self.topVC]){
            topMenuHeight += [self getStatusBarHeight];
        }
    }

    self.topContainerHeightConstraint.constant = topMenuHeight;
}

-(void)setTopMenuHidden:(BOOL)topMenuHidden
{
    if (self.topMenuHidden == topMenuHidden) return;

    _topMenuHidden = topMenuHidden;

    // Fade out the top menu when it is hidden.
    CGFloat alpha = topMenuHidden ? 0.0 : 1.0;

    // Note: don't fade out the navBarContainer or the line at its bottom gets hidden!
    //self.topMenuViewController.navBarContainer.alpha = alpha;
    
    for (UIView *v in self.topMenuViewController.navBarContainer.subviews) {
        v.alpha = alpha;
    }
    
    [self.view setNeedsUpdateConstraints];
}

- (UIStatusBarStyle) preferredStatusBarStyle {
    return (self.topMenuViewController.navBarStyle == NAVBAR_STYLE_NIGHT) ? UIStatusBarStyleLightContent : UIStatusBarStyleDefault;
}

- (UIViewController *)childViewControllerForStatusBarStyle
{
    return self.topVC;
}

- (UIViewController *)childViewControllerForStatusBarHidden
{
    return self.topVC;
}

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    [self animateStatusBarHeightChangesForViewController:viewController then:^{
        [self.centerNavController pushViewController:viewController animated:animated];
    }];
}

- (UIViewController *)popViewControllerAnimated:(BOOL)animated
{
    NSInteger index = self.centerNavController.viewControllers.count - 2;
    if (index < 0) return nil;
    id vcBeneath = self.centerNavController.viewControllers[index];
    
    [self animateStatusBarHeightChangesForViewController:vcBeneath then:^{
        [self.centerNavController popViewControllerAnimated:animated];
    }];
    return vcBeneath;
}

- (void)popToViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    [self animateStatusBarHeightChangesForViewController:viewController then:^{
        [self.centerNavController popToViewController:viewController animated:animated];
    }];
}

- (void)popToRootViewControllerAnimated:(BOOL)animated
{
    [self animateStatusBarHeightChangesForViewController:self.centerNavController.viewControllers.firstObject then:^{
        [self.centerNavController popToViewController:self.centerNavController.viewControllers.firstObject animated:animated];
    }];
}

-(BOOL)shouldHideTopNavIfNecessaryForViewController:(UIViewController *)vc
{
    BOOL hideTopNav = NO;
    if ([vc respondsToSelector:NSSelectorFromString(@"prefersTopNavigationHidden")]) {
        SEL selector = NSSelectorFromString(@"prefersTopNavigationHidden");
        if ([vc respondsToSelector:selector]) {
            NSInvocation *invocation =
            [NSInvocation invocationWithMethodSignature: [[vc class] instanceMethodSignatureForSelector:selector]];
            [invocation setSelector:selector];
            [invocation setTarget:vc];
            [invocation invoke];
            BOOL prefersTopNavigationHidden;
            [invocation getReturnValue:&prefersTopNavigationHidden];
            hideTopNav = (BOOL)prefersTopNavigationHidden;
        }
    }else{
        hideTopNav = NO;
    }
    
    return hideTopNav;
}

// A view controller can set navBarMode so its preference will be taken in to
// account when animating the transition.
-(BOOL)preferredNavBarModeForViewController:(UIViewController *)vc
{
    NavBarMode mode = NAVBAR_MODE_UNKNOWN;
    if ([vc respondsToSelector:NSSelectorFromString(@"navBarMode")]) {
        SEL selector = NSSelectorFromString(@"navBarMode");
        if ([vc respondsToSelector:selector]) {
            NSInvocation *invocation =
            [NSInvocation invocationWithMethodSignature: [[vc class] instanceMethodSignatureForSelector:selector]];
            [invocation setSelector:selector];
            [invocation setTarget:vc];
            [invocation invoke];
            NavBarMode preferredMode;
            [invocation getReturnValue:&preferredMode];
            mode = (NavBarMode)preferredMode;
        }
    }
    
    return mode;
}

-(BOOL)prefersStatusBarHiddenForViewController:(UIViewController *)vc
{
    BOOL prefersHidden = NO;
    if ([vc respondsToSelector:NSSelectorFromString(@"prefersStatusBarHidden")]) {
        SEL selector = NSSelectorFromString(@"prefersStatusBarHidden");
        if ([vc respondsToSelector:selector]) {
            NSInvocation *invocation =
            [NSInvocation invocationWithMethodSignature: [[vc class] instanceMethodSignatureForSelector:selector]];
            [invocation setSelector:selector];
            [invocation setTarget:vc];
            [invocation invoke];
            BOOL prefersStatusBarHidden;
            [invocation getReturnValue:&prefersStatusBarHidden];
            prefersHidden = (BOOL)prefersStatusBarHidden;
        }
    }else{
        prefersHidden = NO;
    }
    return prefersHidden;
}

-(void)animateStatusBarHeightChangesForViewController: (UIViewController *)vc
                                                 then: (void (^)(void))block
{
    // Animates changes to the top menu to adjust room for the status bar based on the
    // wishes of the view controller being presented.
    CGFloat duration = 0.15;

    NavBarMode preferredMode = [self preferredNavBarModeForViewController:vc];
    BOOL prefersStatusBarHidden = [self prefersStatusBarHiddenForViewController:vc];
    
    self.topVC = vc;

    if (preferredMode != NAVBAR_MODE_UNKNOWN) {
        // Reminder: don't do this as part of the animation block below. The changes to the nav
        // buttons positions need to not be animated!
        self.topMenuViewController.navBarMode = preferredMode;

        // Prevent the nav bar buttons from moving around as part of the view push/pop.
        [self.view.superview layoutIfNeeded];
    }

    [UIView animateWithDuration:duration delay:0.0f options:UIViewAnimationOptionBeginFromCurrentState animations:^{

        self.topMenuHidden = [self shouldHideTopNavIfNecessaryForViewController:vc];

        // Allow the top menu to adjust its views' heights based on whether the
        // top view controller wants the status bar shown or not.
        self.topMenuViewController.statusBarHidden = prefersStatusBarHidden;//self.topVC.prefersStatusBarHidden;
        
        [self.view setNeedsUpdateConstraints];
        
        // Update status bar according to topVC's wishes.
        if ([self respondsToSelector:@selector(setNeedsStatusBarAppearanceUpdate)]) {
            [self setNeedsStatusBarAppearanceUpdate];
        }
        
        [self.view.superview layoutIfNeeded];
    } completion:^(BOOL done){
        block();
    }];
}

-(void)updateTopMenuVisibilityConstraint
{
    // Hides the top menu by raising the center container's top - since the top menu sits on
    // top of the center container the top menue gets pushed up offscreen. Shows the top menu
    // by lowering the center container.

    CGFloat topMenuVisibleHeight = TOP_MENU_INITIAL_HEIGHT;
    CGFloat statusBarHeight = (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1) ? [self getStatusBarHeight] : 0;
    
    if ([self prefersStatusBarHiddenForViewController:self.topVC]) statusBarHeight = 0;
    
    CGFloat topMenuHeight = self.topMenuHidden ? statusBarHeight : (topMenuVisibleHeight + statusBarHeight);
    
    self.centerContainerTopConstraint.constant = topMenuHeight;
}

-(void)animateTopAndBottomMenuHidden:(BOOL)hidden
{
    // Don't toggle if hidden state isn't different or if it's already toggling.
    if ((self.topMenuHidden == hidden) || self.isAnimatingTopAndBottomMenuHidden) return;

    self.isAnimatingTopAndBottomMenuHidden = YES;
    
    // Queue it up so web view doesn't get blanked out.
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{

        [UIView animateWithDuration:0.12f delay:0.0f options:UIViewAnimationOptionBeginFromCurrentState animations:^{
            
            self.topMenuHidden = hidden;

            WebViewController *webVC = [NAV searchNavStackForViewControllerOfClass:[WebViewController class]];
            webVC.bottomMenuHidden = self.topMenuHidden;
            
            [webVC.view setNeedsUpdateConstraints];
            
            [self.view setNeedsUpdateConstraints];
            //[self.view.superview layoutSubviews];
            
            [self.view.superview layoutIfNeeded];
            
        } completion:^(BOOL done){
            self.isAnimatingTopAndBottomMenuHidden = NO;
        }];
        
    }];
}

-(void)updateViewConstraints
{
    [self constrainTopContainerHeight];

    [self updateTopMenuVisibilityConstraint];

    [super updateViewConstraints];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	if ([segue.identifier isEqualToString: @"TopMenuViewController_embed"]) {
		self.topMenuViewController = (TopMenuViewController *) [segue destinationViewController];
	}else if ([segue.identifier isEqualToString: @"CenterNavController_embed"]) {
		self.centerNavController = (CenterNavController *) [segue destinationViewController];
    }
}

-(void)togglePrimaryMenu
{
    if (
        self.presentedViewController.isBeingPresented
        ||
        self.presentedViewController.isBeingDismissed
        )
    {
        return;
    }

    if ([self.presentedViewController isMemberOfClass:[ModalMenuAndContentViewController class]]) {
        [self dismissViewControllerAnimated:YES completion:^{}];
    }else{
        [self performModalSequeWithID: @"modal_segue_show_primary_menu"
                      transitionStyle: UIModalTransitionStyleCrossDissolve
                                block: nil];
    }
}

@end
