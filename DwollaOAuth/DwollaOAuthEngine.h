//
//  DwollaOAuthEngine.h
//  DwollaOAuth
//
//  Created by James Armstead on 6/29/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OAuthConsumer.h"

@protocol DwollaOAuthEngineDelegate <NSObject>

@optional

- (void)dwollaEngineAccessToken:(DwollaOAuthEngine *)engine setAccessToken:(OAToken *)token;
- (OAToken *)dwollaEngineAccessToken:(DwollaOAuthEngine *)engine;

//- (void)dwollaEngine:(DwollaOAuthEngine *)engine requestSucceeded:(RDLinkedInConnectionID *)identifier withResults:(id)results;
//- (void)dwollaEngine:(DwollaOAuthEngine *)engine requestFailed:(RDLinkedInConnectionID *)identifier withError:(NSError *)error;

@end

@end

@interface DwollaOAuthEngine : NSObject {
    
}

@end
