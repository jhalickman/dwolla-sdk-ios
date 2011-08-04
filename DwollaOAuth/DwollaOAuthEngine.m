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
#import "DwollaDataFetcher.h"

static NSString *const dwollaAPIBaseURL = @"https://www.dwolla.com/oauth/rest/";
static NSString *const dwollaOAuthURL = @"https://www.dwolla.com/oauth/OAuth.ashx";


NSString *const DwollaEngineRequestTokenNotification = @"DwollaEngineRequestTokenNotification";
NSString *const DwollaEngineAccessTokenNotification  = @"DwollaEngineAccessTokenNotification";
NSString *const DwollaEngineAuthFailureNotification  = @"DwollaEngineAuthFailureNotification";
NSString *const DwollaEngineTokenKey                 = @"DwollaEngineTokenKey";


@interface DwollaOAuthEngine ()

- (DwollaConnectionID *)sendAPIRequestWithURL:(NSURL *)url HTTPMethod:(NSString *)method body:(NSData *)body;
- (void)sendTokenRequestWithURL:(NSURL *)url token:(DwollaToken *)token onSuccess:(SEL)successSel onFail:(SEL)failSel;

@end

@implementation DwollaOAuthEngine

- (void)dealloc {
    engineDelegate = nil;
    [engineOAuthConsumer release];
    [engineOAuthRequestToken release];
    [engineOAuthAccessToken release];
    [engineOAuthVerifier release];
    [engineConnections release];
    [super dealloc];
}

@synthesize verifier = engineOAuthVerifier, consumer = engineOAuthConsumer;

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
        engineOAuthConsumer = [[DwollaConsumer alloc] 
                               initWithKey:consumerKey 
                               secret:consumerSecret 
                               scope:scope 
                               callback:callback];
        engineConnections = [[NSMutableDictionary alloc] init];
        engineOAuthAccessToken = [[[DwollaToken alloc] initWithUserDefaultsUsingServiceProviderName:@"Dwolla" prefix:@"Demo"] autorelease];
    }
    return self;
}


- (void) setTheVerifier:(NSString *)newVerifier
{
    [self setVerifier: newVerifier];
    [engineOAuthRequestToken setVerifier: newVerifier];
}

#pragma mark connection methods

- (NSUInteger)numberOfConnections {
    return [engineConnections count];
}

- (NSArray *)connectionIdentifiers {
    return [engineConnections allKeys];
}

- (void)closeConnection:(DwollaHTTPURLConnection *)connection {
    if( connection ) {
        [connection cancel];
        [engineConnections removeObjectForKey:connection.identifier];
    }
}

- (void)closeConnectionWithID:(DwollaConnectionID *)identifier {
    [self closeConnection:[engineConnections objectForKey:identifier]];
}

- (void)closeAllConnections {
    [[engineConnections allValues] makeObjectsPerformSelector:@selector(cancel)];
    [engineConnections removeAllObjects];
}

#pragma mark authorization methods
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

- (BOOL)hasRequestToken {
	return (engineOAuthRequestToken.key && engineOAuthRequestToken.secret);
}

- (void)requestRequestToken {
	[self sendTokenRequestWithURL:[NSURL URLWithString:dwollaOAuthURL]
                            token:nil 
                        onSuccess:@selector(setRequestTokenFromTicket:data:)
                           onFail:@selector(oauthTicketFailed:data:)];
}

- (void)requestAccessToken {
	[self sendTokenRequestWithURL:[NSURL URLWithString:dwollaOAuthURL]
                            token:engineOAuthRequestToken
                        onSuccess:@selector(setAccessTokenFromTicket:data:)
                           onFail:@selector(oauthTicketFailed:data:)];
}

- (NSURLRequest *)authorizationFormURLRequest {
    NSString* testURL = [NSString stringWithFormat: @"%@?oauth_token=%@", dwollaOAuthURL, engineOAuthRequestToken.key];
	DwollaMutableURLRequest *request = [[[DwollaMutableURLRequest alloc] initWithURL:[NSURL URLWithString:testURL] consumer:nil token:engineOAuthRequestToken realm:nil signatureProvider:nil] autorelease];
    return request;
}

#pragma mark account methods
- (DwollaConnectionID *)accountInformationCurrentUser {
    NSURL* url = [NSURL URLWithString:[dwollaAPIBaseURL stringByAppendingString:@"accountapi/accountinformation"]];
    
    [self sendRequestWithURL: url
                       token:engineOAuthAccessToken 
                      method:@"GET"
                   onSuccess:@selector(getResponse:data:)
                      onFail:@selector(oauthTicketFailed:data:)];
    
    // return [self sendAPIRequestWithURL:url HTTPMethod:@"GET" body:nil];
    return nil;
}
- (void)getResponse:(OAServiceTicket *)ticket data:(NSData *)data 
{
    if (!data) return;
    NSString *dataString = [[[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding] autorelease];
    if (!dataString) return;
}

#pragma mark private

- (DwollaConnectionID *)sendAPIRequestWithURL:(NSURL *)url HTTPMethod:(NSString *)method body:(NSData *)body {
    if( !self.isAuthorized ) return nil;
    //NSLog(@"sending API request to %@", url);
    
	// create and configure the URL request
    DwollaMutableURLRequest* request = [[[DwollaMutableURLRequest alloc] initWithURL:url
                                                                            consumer:engineOAuthConsumer 
                                                                               token:engineOAuthAccessToken 
                                                                               realm:nil
                                                                   signatureProvider:nil] autorelease];
    
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    if( method ) {
        [request setHTTPMethod:method];
    }
    
    [request prepare];
    if( [body length] ) { 
        [request setHTTPBody:body];
    }
    
    // initiate a URL connection with this request
    DwollaHTTPURLConnection* connection = [[[DwollaHTTPURLConnection alloc] initWithRequest:request delegate:self] autorelease];
    
    if( connection ) {
        [engineConnections setObject:connection forKey:connection.identifier];
    }
    
    return connection.identifier;
}

- (void)parseConnectionResponse:(DwollaHTTPURLConnection *)connection {
    //NSLog([NSString stringWithFormat:@"%@",[connection data]]);
}

- (void)sendRequestWithURL:(NSURL *)url 
                     token:(DwollaToken *)token
                    method:(NSString *)method
                 onSuccess:(SEL)successSel 
                    onFail:(SEL)failSel {
    DwollaMutableURLRequest* request = [[[DwollaMutableURLRequest alloc] 
                                         initWithURL:url 
                                         consumer:engineOAuthConsumer 
                                         token:token 
                                         realm:nil 
                                         signatureProvider:nil] autorelease];
	if( !request ) return;
	
    //[request setHTTPMethod:method];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
	[request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    
    DwollaDataFetcher* fetcher = [[[DwollaDataFetcher alloc] init] autorelease];	
    [fetcher fetchDataWithRequest:request delegate:self didFinishSelector:successSel didFailSelector:failSel];
}

- (void)sendTokenRequestWithURL:(NSURL *)url 
                          token:(DwollaToken *)token 
                      onSuccess:(SEL)successSel 
                         onFail:(SEL)failSel {
    DwollaMutableURLRequest* request = [[[DwollaMutableURLRequest alloc] 
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

- (void)oauthTicketFailed:(OAServiceTicket *)ticket data:(NSData *)data {
    [[NSNotificationCenter defaultCenter]
     postNotificationName:DwollaEngineAuthFailureNotification object:self];
}

- (void)setRequestTokenFromTicket:(OAServiceTicket *)ticket data:(NSData *)data {
    if (!ticket.didSucceed || !data) return;
	
	NSString *dataString = [[[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding] autorelease];
	if (!dataString) return;
	
	[engineOAuthRequestToken release];
	engineOAuthRequestToken = [[DwollaToken alloc] initWithHTTPResponseBody:dataString];
    NSLog(@"  request token: %@", engineOAuthRequestToken.key);
	
    //if( rdOAuthVerifier.length ) engineOAuthRequestToken.pin = rdOAuthVerifier;
    
    [[NSNotificationCenter defaultCenter]
     postNotificationName:DwollaEngineRequestTokenNotification object:self
     userInfo:[NSDictionary dictionaryWithObject:engineOAuthRequestToken forKey:DwollaEngineTokenKey]];
}

- (void)setAccessTokenFromTicket:(OAServiceTicket *)ticket data:(NSData *)data {
    //NSLog(@"got access token ticket response: %@ (%lu bytes)", ticket, (unsigned long)[data length]);
	if (!ticket.didSucceed || !data) return;
	
	NSString *dataString = [[[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding] autorelease];
	if (!dataString) return;
    
	if( engineOAuthVerifier.length && [dataString rangeOfString:@"oauth_verifier"].location == NSNotFound ) {
        dataString = [dataString stringByAppendingFormat:@"&oauth_verifier=%@", engineOAuthVerifier];
    }
	
    [engineOAuthAccessToken release];
	engineOAuthAccessToken = [[DwollaToken alloc] initWithHTTPResponseBody:dataString];
    //NSLog(@"  access token set %@", rdOAuthAccessToken.key);
    
	if( [engineDelegate respondsToSelector:@selector(dwollaEngineAccessToken:setAccessToken:)] ) {
        [engineDelegate dwollaEngineAccessToken:self setAccessToken:engineOAuthAccessToken];
    }
    
    // notification of access token
    [[NSNotificationCenter defaultCenter]
     postNotificationName:DwollaEngineAccessTokenNotification object:self
     userInfo:[NSDictionary dictionaryWithObject:engineOAuthAccessToken forKey:DwollaEngineTokenKey]];
}

#pragma mark NSURLConnectionDelegate

- (void)connection:(DwollaHTTPURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    // This method is called when the server has determined that it has enough information to create the NSURLResponse.
    // it can be called multiple times, for example in the case of a redirect, so each time we reset the data.
    [connection resetData];
    
    NSHTTPURLResponse *resp = (NSHTTPURLResponse *)response;
    int statusCode = [resp statusCode];
    
    if( statusCode >= 400 ) {
        // error response; just abort now
        NSError *error = [NSError errorWithDomain:@"HTTP" code:statusCode userInfo:nil];
        if( [engineDelegate respondsToSelector:@selector(dwollaEngine:requestFailed:withError:)] ) {
            [engineDelegate dwollaEngine:self requestFailed:connection.identifier withError:error];
        }
        [self closeConnection:connection];
    }
    else if( statusCode == 204 ) {
        // no content; so skip the parsing, and declare success!
        if( [engineDelegate respondsToSelector:@selector(dwollaEngine:requestSucceeded:withResults:)] ) {
            [engineDelegate dwollaEngine:self requestSucceeded:connection.identifier withResults:nil];
        }
        [self closeConnection:connection];
    }
}


- (void)connection:(DwollaHTTPURLConnection *)connection didReceiveData:(NSData *)data {
    [connection appendData:data];
}


- (void)connection:(DwollaHTTPURLConnection *)connection didFailWithError:(NSError *)error {
	if( [engineDelegate respondsToSelector:@selector(dwollaEngine:requestFailed:withError:)] ) {
		[engineDelegate dwollaEngine:self requestFailed:connection.identifier withError:error];
    }
    
    [self closeConnection:connection];
}


- (void)connectionDidFinishLoading:(DwollaHTTPURLConnection *)connection {
    NSData *receivedData = [connection data];
    if( [receivedData length] ) {
        [self parseConnectionResponse:connection];
    }
    
    // Release the connection.
    [engineConnections removeObjectForKey:[connection identifier]];
}




@end
