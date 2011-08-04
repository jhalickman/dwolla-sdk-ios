//
//  DwollaDataFetcher.m
//  DwollaOAuth
//
//  Created by James Armstead on 8/3/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "DwollaDataFetcher.h"
#import "DwollaMutableURLRequest.h"

@implementation DwollaDataFetcher

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)fetchDataWithRequest:(DwollaMutableURLRequest *)aRequest delegate:(id)aDelegate didFinishSelector:(SEL)finishSelector didFailSelector:(SEL)failSelector {
	[request release];
	request = [aRequest retain];
    delegate = aDelegate;
    didFinishSelector = finishSelector;
    didFailSelector = failSelector;
    
    [request prepare];
    
	connection = [[NSURLConnection alloc] initWithRequest:aRequest delegate:self];
}
@end
