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
static NSString *const dwollaOAuthAuthorizeURL    = @"https://www.dwolla.com/oauth/OAuth.ashx";

NSString *const DwollaEngineRequestTokenNotification = @"DwollaEngineRequestTokenNotification";
NSString *const DwollaEngineAccessTokenNotification  = @"DwollaEngineAccessTokenNotification";
NSString *const DwollaEngineAuthFailureNotification  = @"DwollaEngineAuthFailureNotification";
NSString *const DwollaEngineTokenKey                 = @"DwollaEngineTokenKey";

@implementation DwollaOAuthEngine


    + (id)engineWithConsumerKey:(NSString *)consumerKey 
                 consumerSecret:(NSString *)consumerSecret 
                           scope:(NSString *)scope 
                       callback:(NSString *)callback 
                       delegate:(id<DwollaOAuthEngineDelegate>)delegate {
        
        return [[[self alloc] initWithConsumerKey:consumerKey 
                                   consumerSecret:consumerSecret 
                                             scope:scope 
                                         callback:callback 
                                         delegate:delegate] autorelease];
        
    }

    - (id)initWithConsumerKey:(NSString *)consumerKey 
               consumerSecret:(NSString *)consumerSecret 
                         scope:(NSString *)scope 
                     callback:(NSString *)callback 
                     delegate:(id<DwollaOAuthEngineDelegate>)delegate {
        if( self == [super init] ) {
            engineDelegate = delegate;
            engineOAuthConsumer = [[OAConsumer alloc] 
                                   initWithKey:consumerKey 
                                   secret:consumerSecret 
                                   scope:scope 
                                   callback:callback];
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


- (void)sendTokenRequestWithURL:(NSURL *)url 
                          token:(OAToken *)token 
                      onSuccess:(SEL)successSel 
                         onFail:(SEL)failSel {
    OAMutableURLRequest* request = [[[OAMutableURLRequest alloc] 
                                     initWithURL:url 
                                     consumer:engineOAuthConsumer 
                                     token:token 
                                     realm:nil 
                                     signatureProvider:nil] autorelease];
	if( !request ) return;
	
    [request setHTTPMethod:@"POST"];
	//if( engineOAuthVerifier.length ) token.pin = engineOAuthVerifier;
	
    OADataFetcher* fetcher = [[[OADataFetcher alloc] init] autorelease];	
    [fetcher fetchDataWithRequest:request delegate:self didFinishSelector:successSel didFailSelector:failSel];
}

//RESPONSES
- (void)setRequestTokenFromTicket:(OAServiceTicket *)ticket data:(NSData *)data {
    if (!ticket.didSucceed || !data) return;
	
	NSString *dataString = [[[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding] autorelease];
	if (!dataString) return;
	
	[engineOAuthRequestToken release];
	engineOAuthRequestToken = [[OAToken alloc] initWithHTTPResponseBody:dataString];
    NSLog(@"  request token: %@", engineOAuthRequestToken.key);
	
    //if( rdOAuthVerifier.length ) engineOAuthRequestToken.pin = rdOAuthVerifier;
    
    [[NSNotificationCenter defaultCenter]
     postNotificationName:DwollaEngineRequestTokenNotification object:self
     userInfo:[NSDictionary dictionaryWithObject:engineOAuthRequestToken forKey:DwollaEngineTokenKey]];
}

- (void)oauthTicketFailed:(OAServiceTicket *)ticket data:(NSData *)data {
    [[NSNotificationCenter defaultCenter]
     postNotificationName:DwollaEngineAuthFailureNotification object:self];
}

//HELPERS
- (BOOL)hasRequestToken {
	return (engineOAuthRequestToken.key && engineOAuthRequestToken.secret);
}
- (NSURLRequest *)authorizationFormURLRequest {
    NSString* testURL = [NSString stringWithFormat: @"%@?oauth_token=%@", dwollaOAuthAuthorizeURL, engineOAuthRequestToken.key];
	OAMutableURLRequest *request = [[[OAMutableURLRequest alloc] initWithURL:[NSURL URLWithString:testURL] consumer:nil token:engineOAuthRequestToken realm:nil signatureProvider:nil] autorelease];
    return request;
}

@end
