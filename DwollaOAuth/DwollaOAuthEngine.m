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
#import "SBJson.h"
#import "DwollaXMLReader.h"

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
	if( [engineOAuthAccessToken isValid] ) return YES;
	
	// check for cached creds
    if( [engineDelegate respondsToSelector:@selector(dwollaEngineAccessToken:)] ) {
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
    
    return [self sendAPIRequestWithURL:url HTTPMethod:@"GET" body:nil];
}

- (DwollaConnectionID *)balanceCurrentUser {
    NSURL* url = [NSURL URLWithString:[dwollaAPIBaseURL stringByAppendingString:@"accountapi/balance"]];
    
    return [self sendAPIRequestWithURL:url HTTPMethod:@"GET" body:nil];
}

- (DwollaConnectionID *)accountInformationForUser:(NSString *) userIdentifier {
    NSURL* url = [NSURL URLWithString:[dwollaAPIBaseURL stringByAppendingString:[NSString stringWithFormat:@"accountapi/accountinformation/%@", userIdentifier]]];
    
    return [self sendAPIRequestWithURL:url HTTPMethod:@"GET" body:nil];
}

- (DwollaConnectionID *)contactSearch:(NSString *) searchString withLimit:(NSInteger) limit withTypes:(NSString *) types {
    
    NSMutableArray* parameters = [[NSMutableArray alloc] init];
    
    if (searchString != nil) {
        [parameters addObject:[NSString stringWithFormat:@"search=%@",searchString]];
    }
    if (limit > 0) {
        [parameters addObject:[NSString stringWithFormat:@"limit=%@", [NSString stringWithFormat:@"%d", limit]]];
    }
    if (types != nil) {
        [parameters addObject:[NSString stringWithFormat:@"types=%@",types]];
    }
    
    NSString* parameterString = @"";
    
    if ([parameters count] > 0) {
        parameterString = [NSString stringWithFormat:@"?%@", [parameters componentsJoinedByString:@"&"]];
    }
    
    NSURL* url = [NSURL URLWithString:[dwollaAPIBaseURL stringByAppendingString:[NSString stringWithFormat:@"accountapi/contacts%@", parameterString]]];
        
    return [self sendAPIRequestWithURL:url HTTPMethod:@"GET" body:nil];
}

- (DwollaConnectionID *)nearbySearchWithLongitude:(NSString *) longitude 
                                     withLatitude:(NSString *) latitude 
                                        withLimit:(NSInteger) limit
                                        withRange:(NSInteger) range {
    NSURL* url = [NSURL URLWithString:[dwollaAPIBaseURL stringByAppendingString:[NSString stringWithFormat:@"accountapi/nearby?latitude=%@&longitude=%@&range=%@&limit=%@", latitude, longitude, [NSString stringWithFormat:@"%d", range], [NSString stringWithFormat:@"%d", limit]]]];
    
    return [self sendAPIRequestWithURL:url HTTPMethod:@"GET" body:nil];
}

//- (DwollaConnectionID *)statsForCurrentUserWithTypes:(NSString *) types 
//                                       withStartDate:(NSString *) startDate 
//                                         withEndDate:(NSString *) endDate {
//    NSURL* url = [NSURL URLWithString:[dwollaAPIBaseURL stringByAppendingString:[NSString stringWithFormat:@"accountapi/stats?types=%@&startDate=%@&endDate=%@", types, startDate, endDate]]];
//    
//    return [self sendAPIRequestWithURL:url HTTPMethod:@"GET" body:nil];
//}

- (DwollaConnectionID *) registerWithEmail:(NSString *) email 
                              withPassword:(NSString *) password
                             withFirstName:(NSString *) firstName 
                              withLastName:(NSString *) lastName 
                                  withType:(NSString *) accountType 
                          withOrganization:(NSString *) organization 
                                   withEIN:(NSString *) ein 
                               withAddress:(NSString *) address 
                            withAddressTwo:(NSString *) address2 
                                  withCity:(NSString *) city 
                                 withState:(NSString *) state 
                                   withZip:(NSString *) zip 
                                 withPhone:(NSString *) phone 
                              withPhoneTwo:(NSString *) phone2
                                   withPIN:(NSString *) pin 
                                   withDOB:(NSString *) dob {
    NSURL* url = [NSURL URLWithString:[dwollaAPIBaseURL stringByAppendingString:@"accountapi/register"]];
    
    NSString* json = [NSString stringWithFormat:@"{\"Email\":\"%@\", \"{Password\":\"%@\", \"FirstName\":%@, \"LastName\":\"%@\", \"AccountType\":\"%@\", \"Organization\":\"%@\", \"EIN\":\"%@\", \"Address\":\"%@\", \"Address2\":\"%@\", \"City\":\"%@\", \"State\":\"%@\", \"Phone\":\"%@\", \"Phone2\":\"%@\", \"PIN\":\"%@\", \"DOB\":\"%@\"}", email, password, firstName, lastName, accountType, organization, ein, address, address2, city, state, zip, phone, phone2, pin, dob];
    
    NSData* body = [json dataUsingEncoding:NSUTF8StringEncoding];
    
    return [self sendAPIRequestWithURL:url HTTPMethod:@"POST" body:body];
}

- (DwollaConnectionID *)transactionsSince:(NSString *) sinceDate withLimit:(NSInteger) limit withTypes:(NSString *) types {
    NSMutableArray* parameters = [[NSMutableArray alloc] init];
    
    if (sinceDate != nil) {
        [parameters addObject:[NSString stringWithFormat:@"sincedate=%@",sinceDate]];
    }
    if (limit > 0) {
        [parameters addObject:[NSString stringWithFormat:@"limit=%@", [NSString stringWithFormat:@"%d", limit]]];
    }
    if (types != nil) {
        [parameters addObject:[NSString stringWithFormat:@"types=%@",types]];
    }
    
    NSString* parameterString = @"";
    
    if ([parameters count] > 0) {
        parameterString = [NSString stringWithFormat:@"?%@", [parameters componentsJoinedByString:@"&"]];
    }
    
    NSURL* url = [NSURL URLWithString:[dwollaAPIBaseURL stringByAppendingString:[NSString stringWithFormat:@"accountapi/transactions%@", parameterString]]];
    
    return [self sendAPIRequestWithURL:url HTTPMethod:@"GET" body:nil];
}

- (DwollaConnectionID *)sendMoneyWithPin:(NSString *) pin 
                withDestinationId:(NSString *) destinationId 
                       withAmount:(NSDecimalNumber *) amount 
                        withNotes:(NSString *) note 
              withDestinationType:(NSString *) type 
                   withAssumeCost:(BOOL) assumeCost 
                  withFundsSource:(NSString *) fundSource
{
    NSURL* url = [NSURL URLWithString:[dwollaAPIBaseURL stringByAppendingString:@"accountapi/send"]];
    
    NSString* json = [NSString stringWithFormat:@"{\"pin\":\"%@\", \"destinationId\":\"%@\", \"amount\":%@, \"notes\":\"%@\", \"destinationType\":\"%@\", \"assumeCosts\":\"%@\", \"fundsSource\":\"%@\"}", pin, destinationId, amount, note, type, (assumeCost ? @"true" : @"false"), fundSource];
    NSData* body = [json dataUsingEncoding:NSUTF8StringEncoding];
    
    return [self sendAPIRequestWithURL:url HTTPMethod:@"POST" body:body];
}

- (DwollaConnectionID *)sendMoneyWithPin:(NSString *) pin 
                       withDestinationId:(NSString *) destinationId 
                              withAmount:(NSDecimalNumber *) amount 
                               withNotes:(NSString *) note 
                     withDestinationType:(NSString *) type 
                          withAssumeCost:(BOOL) assumeCost 
                         withFundsSource:(NSString *) fundSource
                         withFacilitatorAmount:(NSDecimalNumber *) facilitatorAmount
{
    NSURL* url = [NSURL URLWithString:[dwollaAPIBaseURL stringByAppendingString:@"accountapi/send"]];
    
    NSString* json = [NSString stringWithFormat:@"{\"pin\":\"%@\", \"destinationId\":\"%@\", \"amount\":%@, \"notes\":\"%@\", \"destinationType\":\"%@\", \"assumeCosts\":\"%@\", \"fundsSource\":\"%@\", \"facilitatorAmount\":\"%@\"}", pin, destinationId, amount, note, type, (assumeCost ? @"true" : @"false"), fundSource, facilitatorAmount];
    NSData* body = [json dataUsingEncoding:NSUTF8StringEncoding];
    
    return [self sendAPIRequestWithURL:url HTTPMethod:@"POST" body:body];
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
    statusCode = [resp statusCode];
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
    NSDictionary *result = nil;
    
    if( statusCode >= 400 ) {
        if( [receivedData length] ) {
            result = [self parseConnectionError:connection];
        }
        // error response; just abort now
        NSError *error = [NSError errorWithDomain:[result objectForKey:@"error"] code:statusCode userInfo:nil];
        if( [engineDelegate respondsToSelector:@selector(dwollaEngine:requestFailed:withError:)] ) {
            [engineDelegate dwollaEngine:self requestFailed:connection.identifier withError:error];
        }
    } else {
        if( [receivedData length] ) {
            result = [self parseConnectionResponse:connection];
        }
        
         [engineDelegate dwollaEngine:self requestSucceeded:connection.identifier withResults:result];
    }
    
    // Release the connection.
    [engineConnections removeObjectForKey:[connection identifier]];
}

- (NSDictionary *)parseConnectionResponse:(DwollaHTTPURLConnection *)connection {
    NSString *dataString = [[[NSString alloc] initWithData: [connection data] encoding: NSUTF8StringEncoding] autorelease];
    NSDictionary *result = (NSDictionary *) [[SBJsonParser new] objectWithString:dataString error:NULL];
    
    return result;
}

- (NSDictionary *)parseConnectionError:(DwollaHTTPURLConnection *)connection {
    NSString *dataString = [[[NSString alloc] initWithData: [connection data] encoding: NSUTF8StringEncoding] autorelease];
    
    NSError *parseError = nil;
    NSDictionary *error = [XMLReader dictionaryForXMLString:dataString error:&parseError];
    NSDictionary *result = [NSDictionary dictionaryWithObject:[[[[error objectForKey:@"Fault"] objectForKey:@"Detail"] objectForKey:@"string"] objectForKey:@"text"] forKey:@"error"];
    
    return result;
}
@end
