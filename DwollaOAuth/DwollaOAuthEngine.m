//
//  DwollaOAuthEngine.m
//  DwollaOAuth
//
//  Created by James Armstead on 6/29/11.
//  Copyright 2011 Dwolla. All rights reserved.
//
//  Largely inspired by LinkedIn OAuth by Sixten Otto <https://github.com/ResultsDirect/LinkedIn-iPhone>
//

#import "DwollaOAuthEngine.h"

static NSString *const dwollaAPIBaseURL           = @"https://www.dwolla.com/oauth/OAuth.ashx";
static NSString *const dwollaOAuthRequestTokenURL = @"https://www.dwolla.com/oauth/OAuth.ashx";
//static NSString *const dwollaOAuthAccessTokenURL  = @"https://api.linkedin.com/uas/oauth/accessToken";
//static NSString *const dwollaOAuthAuthorizeURL    = @"https://www.linkedin.com/uas/oauth/authorize";

NSString *const DwollaEngineRequestTokenNotification = @"DwollaEngineRequestTokenNotification";
NSString *const DwollaEngineAccessTokenNotification  = @"DwollaEngineAccessTokenNotification";
NSString *const DwollaEngineAuthFailureNotification  = @"DwollaEngineAuthFailureNotification";
NSString *const DwollaEngineTokenKey                 = @"DwollaEngineTokenKey";

@implementation DwollaOAuthEngine


    + (id)engineWithConsumerKey:(NSString *)consumerKey consumerSecret:(NSString *)consumerSecret delegate:(id<DwollaOAuthEngineDelegate>)delegate {
        return [[[self alloc] initWithConsumerKey:consumerKey consumerSecret:consumerSecret delegate:delegate] autorelease];
    }

    - (id)initWithConsumerKey:(NSString *)consumerKey consumerSecret:(NSString *)consumerSecret delegate:(id<DwollaOAuthEngineDelegate>)delegate {
        if( self == [super init] ) {
            engineDelegate = delegate;
            engineOAuthConsumer = [[OAConsumer alloc] initWithKey:consumerKey secret:consumerSecret];
            engineConnections = [[NSMutableDictionary alloc] init];
        }
        return self;
    }

//AUTHORIZATION
- (BOOL)isAuthorized {
	if( engineOAuthAccessToken.key && engineOAuthAccessToken.secret ) return YES;
	
	// check for cached creds
    if( [engineDelegate respondsToSelector:@selector(linkedInEngineAccessToken:)] ) {
        [engineOAuthAccessToken release];
        engineOAuthAccessToken = [[engineDelegate dwollaEngineAccessToken:self] retain];
        if( engineOAuthAccessToken.key && engineOAuthAccessToken.secret ) return YES;
    }
	
    // no valid access token found
	[engineOAuthAccessToken release];
	engineOAuthAccessToken = nil;
	return NO;
}

//REQUESTS
- (void)requestRequestToken {
	[self sendTokenRequestWithURL:[NSURL URLWithString:dwollaOAuthRequestTokenURL]
                            token:nil
                        onSuccess:@selector(setRequestTokenFromTicket:data:)
                           onFail:@selector(oauthTicketFailed:data:)];
}


- (void)sendTokenRequestWithURL:(NSURL *)url token:(OAToken *)token onSuccess:(SEL)successSel onFail:(SEL)failSel {
    OAMutableURLRequest* request = [[[OAMutableURLRequest alloc] initWithURL:url consumer:engineOAuthConsumer token:token realm:nil signatureProvider:nil] autorelease];
	if( !request ) return;
	
    [request setHTTPMethod:@"POST"];
	//if( engineOAuthVerifier.length ) token.pin = engineOAuthVerifier;
	
    OADataFetcher* fetcher = [[[OADataFetcher alloc] init] autorelease];	
    [fetcher fetchDataWithRequest:request delegate:self didFinishSelector:successSel didFailSelector:failSel];
}
@end
