//
//  DwollaMutableURLRequest.m
//  DwollaOAuth
//
//  Created by James Armstead on 7/27/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "DwollaMutableURLRequest.h"

@interface DwollaMutableURLRequest (Private)
- (void)_generateTimestamp;
- (void)_generateNonce;
- (NSString *)_signatureBaseString;
@end

@implementation DwollaMutableURLRequest

- (id)initWithURL:(NSURL *)aUrl
		 consumer:(OAConsumer *)aConsumer
			token:(OAToken *)aToken
            realm:(NSString *)aRealm
signatureProvider:(id<OASignatureProviding>)aProvider  {
    
    if ((self = [super initWithURL:aUrl
                       cachePolicy:NSURLRequestReloadIgnoringCacheData
                   timeoutInterval:10.0])) {
        
		consumer = [aConsumer retain];
		
		// empty token for Unauthorized Request Token transaction
		if (aToken == nil) {
			token = [[OAToken alloc] init];
		} else {
			token = [aToken retain];
		}
		
		if (aRealm == nil) {
			realm = @"";
		} else {
			realm = [aRealm copy];
		}
        
		// default to HMAC-SHA1
		if (aProvider == nil) {
			signatureProvider = [[OAHMAC_SHA1SignatureProvider alloc] init];
		} else {
			signatureProvider = [aProvider retain];
		}
        
		[self _generateTimestamp];
		[self _generateNonce];
	}
    
    return self;
}

// Setting a timestamp and nonce to known
// values can be helpful for testing
- (id)initWithURL:(NSURL *)aUrl
		 consumer:(OAConsumer *)aConsumer
			token:(OAToken *)aToken
            realm:(NSString *)aRealm
signatureProvider:(id<OASignatureProviding>)aProvider
            nonce:(NSString *)aNonce
        timestamp:(NSString *)aTimestamp{
    
    [self initWithURL:aUrl
             consumer:aConsumer
                token:aToken
                realm:aRealm
    signatureProvider:aProvider];
    
    nonce = [aNonce copy];
    timestamp = [aTimestamp copy];
    
    return self;
}

- (void)prepare {
    // sign
	//NSLog(@"Base string is: %@", [self _signatureBaseString]);
    
    DwollaConsumer* dwollaConsumer = (DwollaConsumer *) consumer;
    
    NSString *consumerSecret = (NSString *) CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef) dwollaConsumer.secret, NULL, CFSTR(":/?#[]@!$&’()*+,;="), kCFStringEncodingUTF8);
    NSString *tokenSecret = (NSString *) CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef) [token.secret  stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding], NULL, CFSTR(":/?#[]@!$&’()*+,;="), kCFStringEncodingUTF8);
    
    signature = [signatureProvider signClearText:[self _signatureBaseString]
                                      withSecret:[NSString stringWithFormat:@"%@&%@",
                                                  consumerSecret,
                                                  tokenSecret ? tokenSecret : @""]];
    
    // set OAuth headers
	NSMutableArray *chunks = [[NSMutableArray alloc] init];
    
    
    //if([[[token parameters] objectForKey:@"oauth_verifier"] length] == 0) {
    if([[token key] length] == 0) {
        [chunks addObject:[NSString stringWithFormat:@"oauth_callback=\"%@\"", [dwollaConsumer.callback encodedURLParameterString]]]; 
    }
    
	[chunks addObject:[NSString stringWithFormat:@"oauth_consumer_key=\"%@\"", [dwollaConsumer.key encodedURLParameterString]]];
    
	NSDictionary *tokenParameters = [token parameters];
	for (NSString *k in tokenParameters) {
		[chunks addObject:[NSString stringWithFormat:@"%@=\"%@\"", k, [[[tokenParameters objectForKey:k] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding] encodedURLParameterString]]];
	}
    [chunks addObject:[NSString stringWithFormat:@"oauth_nonce=\"%@\"", [nonce encodedURLParameterString]]];
	[chunks addObject:[NSString stringWithFormat:@"oauth_signature_method=\"%@\"", [[signatureProvider name] encodedURLParameterString]]];
	[chunks addObject:[NSString stringWithFormat:@"oauth_signature=\"%@\"", [signature encodedURLParameterString]]];
    [chunks	addObject:@"oauth_version=\"1.0\""];
	[chunks addObject:[NSString stringWithFormat:@"oauth_timestamp=\"%@\"", timestamp]];
    
//    NSLog([NSString stringWithFormat:@"Token secret: %@", tokenSecret]);
//    NSLog([NSString stringWithFormat:@"Token key: %@", [token.key  stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]);
//    NSLog([NSString stringWithFormat:@"Timestamp: %@", [timestamp  stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]);
//    NSLog([NSString stringWithFormat:@"Nonce: %@", [nonce  stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]);
//    NSLog([NSString stringWithFormat:@"Signature: %@", [signature  stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]);
    
	NSString *oauthHeader = [NSString stringWithFormat:@"OAuth %@", [chunks componentsJoinedByString:@","]];
	[chunks release];
    
    [self setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [self setValue:oauthHeader forHTTPHeaderField:@"Authorization"];
    
    if([[[token parameters] objectForKey:@"oauth_verifier"] length] == 0) {
        NSString *scope = [NSString stringWithFormat:@"scope=%@", [dwollaConsumer.scope encodedURLParameterString]];
        
        [self setHTTPBody:[[[NSString alloc] initWithString: scope] 
                           dataUsingEncoding: NSASCIIStringEncoding]];
    }
}

- (void)_generateTimestamp {
	[timestamp release];
    timestamp = [[NSString alloc]initWithFormat:@"%d", time(NULL)];
}

- (void)_generateNonce {
    CFUUIDRef theUUID = CFUUIDCreate(NULL);
    CFStringRef string = CFUUIDCreateString(NULL, theUUID);
    NSMakeCollectable(theUUID);
	if (nonce) {
		CFRelease(nonce);
	}
    nonce = (NSString *)string;
}

- (NSString *)_signatureBaseString {
    DwollaConsumer* dwollaConsumer = (DwollaConsumer *) consumer;
    
    // OAuth Spec, Section 9.1.1 "Normalize Request Parameters"
    // build a sorted array of both request parameters and OAuth header parameters
	NSDictionary *tokenParameters = [token parameters];
	// 6 being the number of OAuth params in the Signature Base String
	NSArray *parameters = [self parameters];
	NSMutableArray *parameterPairs = [[NSMutableArray alloc] initWithCapacity:(5 + [parameters count] + [tokenParameters count])];
    
	OARequestParameter *parameter;
    
    if([[[token parameters] objectForKey:@"oauth_verifier"] length] == 0) {
        
    }
    
    if([[token key] length] == 0) {
        parameter = [[OARequestParameter alloc] initWithName:@"oauth_callback" value:dwollaConsumer.callback];
        [parameterPairs addObject:[parameter URLEncodedNameValuePair]];
        [parameter release];
        
        parameter = [[OARequestParameter alloc] initWithName:@"scope" value:dwollaConsumer.scope] ;
        [parameterPairs addObject:[parameter URLEncodedNameValuePair]];
        [parameter release];
    }
	parameter = [[OARequestParameter alloc] initWithName:@"oauth_consumer_key" value:dwollaConsumer.key];
    [parameterPairs addObject:[parameter URLEncodedNameValuePair]];
	[parameter release];
    parameter = [[OARequestParameter alloc] initWithName:@"oauth_nonce" value:nonce];
    [parameterPairs addObject:[parameter URLEncodedNameValuePair]];
	[parameter release];
	parameter = [[OARequestParameter alloc] initWithName:@"oauth_signature_method" value:[signatureProvider name]];
    [parameterPairs addObject:[parameter URLEncodedNameValuePair]];
	[parameter release];
	parameter = [[OARequestParameter alloc] initWithName:@"oauth_timestamp" value:timestamp];
    [parameterPairs addObject:[parameter URLEncodedNameValuePair]];
	[parameter release];
	parameter = [[OARequestParameter alloc] initWithName:@"oauth_version" value:@"1.0"] ;
    [parameterPairs addObject:[parameter URLEncodedNameValuePair]];
	[parameter release];
	
    
	for(NSString *k in tokenParameters) {
		[parameterPairs addObject:[[OARequestParameter requestParameter:k value:[[tokenParameters objectForKey:k] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] URLEncodedNameValuePair]];
	}
    
	if (![[self valueForHTTPHeaderField:@"Content-Type"] hasPrefix:@"multipart/form-data"]) {
		for (OARequestParameter *param in parameters) {
			[parameterPairs addObject:[param URLEncodedNameValuePair]];
		}
	}
    
    // Oauth Spec, Section 3.4.1.3.2 "Parameters Normalization"
    NSArray *sortedPairs = [parameterPairs sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        NSArray *nameAndValue1 = [obj1 componentsSeparatedByString:@"="];
        NSArray *nameAndValue2 = [obj2 componentsSeparatedByString:@"="];
        
        NSString *name1 = [nameAndValue1 objectAtIndex:0];
        NSString *name2 = [nameAndValue2 objectAtIndex:0];
        
        NSComparisonResult comparisonResult = [name1 compare:name2];
        if (comparisonResult == NSOrderedSame) {
            NSString *value1 = [nameAndValue1 objectAtIndex:1];
            NSString *value2 = [nameAndValue2 objectAtIndex:1];
            
            comparisonResult = [value1 compare:value2];
        }
        
        return comparisonResult;
    }];
    
    NSString *normalizedRequestParameters = [sortedPairs componentsJoinedByString:@"&"];
    [parameterPairs release];
	//	NSLog(@"Normalized: %@", normalizedRequestParameters);
    // OAuth Spec, Section 9.1.2 "Concatenate Request Elements"
    return [NSString stringWithFormat:@"%@&%@&%@",
            [self HTTPMethod],
            [[[self URL] URLStringWithoutQuery] encodedURLParameterString],
            [normalizedRequestParameters encodedURLString]];
}

- (void) dealloc
{
    consumer = nil;
    token = nil;
    signatureProvider = nil;
    timestamp = nil;
    nonce = nil;
	[super dealloc];
}

@end
