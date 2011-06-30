//
//  DwollaOAuthEngine.h
//  DwollaOAuth
//
//  Created by James Armstead on 6/29/11.
//  Copyright 2011 Dwolla. All rights reserved.
//

@class DwollaOAuthEngine;

#import <Foundation/Foundation.h>
#import "OAuthConsumer.h"

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

+ (id)engineWithConsumerKey:(NSString *)consumerKey consumerSecret:(NSString *)consumerSecret delegate:(id<DwollaOAuthEngineDelegate>)delegate;
- (id)initWithConsumerKey:(NSString *)consumerKey consumerSecret:(NSString *)consumerSecret delegate:(id<DwollaOAuthEngineDelegate>)delegate;

@end
