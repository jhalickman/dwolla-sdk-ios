//
//  DwollaOAuthEngine.h
//  DwollaOAuth
//
//  Created by James Armstead on 6/29/11.
//  Copyright 2011 Dwolla. All rights reserved.
//
//  Largely inspired by LinkedIn OAuth by Sixten Otto <https://github.com/ResultsDirect/LinkedIn-iPhone>
//

@class DwollaOAuthEngine;

#import <Foundation/Foundation.h>
#import "OAuthConsumer.h"
#import "DwollaHTTPURLConnection.h"

extern NSString *const DwollaEngineRequestTokenNotification;
extern NSString *const DwollaEngineAccessTokenNotification;
extern NSString *const DwollaEngineAuthFailureNotification;
extern NSString *const DwollaEngineTokenKey;

@protocol DwollaOAuthEngineDelegate <NSObject>

@optional

- (void)dwollaEngineAccessToken:(DwollaOAuthEngine *)engine setAccessToken:(OAToken *)token;
- (OAToken *)dwollaEngineAccessToken:(DwollaOAuthEngine *)engine;

//- (void)dwollaEngine:(DwollaOAuthEngine *)engine requestSucceeded:(RDLinkedInConnectionID *)identifier withResults:(id)results;
//- (void)dwollaEngine:(DwollaOAuthEngine *)engine requestFailed:(RDLinkedInConnectionID *)identifier withError:(NSError *)error;
@end

@interface DwollaOAuthEngine : NSObject {
    id<DwollaOAuthEngineDelegate> engineDelegate;
    OAConsumer* engineOAuthConsumer;
    OAToken*    engineOAuthRequestToken;
    OAToken*    engineOAuthAccessToken;
    NSString*   engineOAuthVerifier;
    NSMutableDictionary* engineConnections;
}

@property (nonatomic, readonly) BOOL isAuthorized;

+ (id)engineWithConsumerKey:(NSString *)consumerKey 
             consumerSecret:(NSString *)consumerSecret 
                       scope:(NSString *) scope 
                   callback:(NSString *) callback
                   delegate:(id<DwollaOAuthEngineDelegate>)delegate;

- (id)initWithConsumerKey:(NSString *)consumerKey 
           consumerSecret:(NSString *)consumerSecret 
                     scope:(NSString *) scope 
                 callback:(NSString *) callback
                 delegate:(id<DwollaOAuthEngineDelegate>)delegate ;

- (void)requestRequestToken;

- (void)sendTokenRequestWithURL:(NSURL *)url 
                          token:(OAToken *)token
                      onSuccess:(SEL)successSel 
                         onFail:(SEL)failSel;

//- (DwollaConnectionID *)profileForCurrentUser;
@end
