//
//  DwollaAuthorizationController.h
//  DwollaOAuth
//
//  Created by James Armstead on 6/29/11.
//  Copyright 2011 Dwolla. All rights reserved.
//
//  Largely inspired by LinkedIn OAuth by Sixten Otto <https://github.com/ResultsDirect/LinkedIn-iPhone>
//

#import <UIKit/UIKit.h>
#import "OAuthConsumer.h"
#import "DwollaOAuthEngine.h"

@class DwollaAuthorizationController;

@protocol DwollaAuthorizationControllerDelegate <NSObject>

@optional
- (void)dwollaAuthorizationControllerSucceeded:(DwollaAuthorizationController *)controller;
- (void)dwollaAuthorizationControllerFailed:(DwollaAuthorizationController *)controller;
- (void)dwollaAuthorizationControllerCanceled:(DwollaAuthorizationController *)controller;

@end


@interface DwollaAuthorizationController : UIViewController <UIWebViewDelegate> {
    id<DwollaAuthorizationControllerDelegate> authorizationDelegate;
    DwollaOAuthEngine* dwollaEngine;
	UINavigationBar*  authorizationNavBar;
    UIWebView*        authorizationWebView;
}

@property (nonatomic, assign)   id<DwollaAuthorizationControllerDelegate> delegate;
@property (nonatomic, readonly) DwollaOAuthEngine* engine;
@property (nonatomic, readonly) UINavigationBar* navigationBar;

+ (id)authorizationControllerWithEngine:(DwollaOAuthEngine *)engine delegate:(id<DwollaAuthorizationControllerDelegate>)delegate;

- (id)initWithEngine:(DwollaOAuthEngine *)engine delegate:(id<DwollaAuthorizationControllerDelegate>)delegate;
- (id)initWithConsumerKey:(NSString *)consumerKey 
           consumerSecret:(NSString *)consumerSecret 
                     scope:(NSString *)scope 
                 callback:(NSString *)callback 
                 delegate:(id<DwollaAuthorizationControllerDelegate>)delegate;

- (void) success;
- (void) hideSplash;

@end
