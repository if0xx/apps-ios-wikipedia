//  Created by Monte Hurd on 12/16/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#include "SectionEditorViewController.h"
#include "MWPageTitle.h"

typedef enum {
    DISCOVERY_METHOD_SEARCH = 0,
    DISCOVERY_METHOD_RANDOM = 1,
    DISCOVERY_METHOD_LINK = 2
} ArticleDiscoveryMethod;

@interface CenterNavController : UINavigationController <UINavigationControllerDelegate>

@property (nonatomic, readonly) BOOL isEditorOnNavstack;
@property (nonatomic, readonly) SectionEditorViewController *editor;

-(void)loadArticleWithTitle: (MWPageTitle *)title
                     domain: (NSString *)domain
                   animated: (BOOL)animated
            discoveryMethod: (ArticleDiscoveryMethod)discoveryMethod
          invalidatingCache: (BOOL)invalidateCache;

-(void) promptFirstTimeZeroOnWithTitleIfAppropriate:(NSString *) title;
-(void) promptZeroOff;

-(ArticleDiscoveryMethod)getDiscoveryMethodForString:(NSString *)string;
-(NSString *)getStringForDiscoveryMethod:(ArticleDiscoveryMethod)method;

@property (nonatomic) BOOL isTransitioningBetweenViewControllers;

@end

//TODO: maybe use currentTopMenuTextFieldText instead of currentSearchString?
