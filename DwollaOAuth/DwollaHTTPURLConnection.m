//
//  DwollaHTTPURLConnection.m
//  DwollaOAuth
//
//  Created by James Armstead on 6/29/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "DwollaHTTPURLConnection.h"
#import "NSString+UUID.h"


@implementation DwollaHTTPURLConnection

@synthesize request = dwollaRequest;

- (id)initWithRequest:(NSURLRequest *)request delegate:(id)delegate {
    if( self == [super initWithRequest:request delegate:delegate] ) {
        dwollaRequest = [request retain];
        dwollaData = [[NSMutableData alloc] init];
    }
    return self;
}

- (void)dealloc {
    [dwollaRequest release];
    [dwollaData release];
    [dwollaIdentifier release];
    [super dealloc];
}

- (DwollaConnectionID *)identifier {
    if( !dwollaIdentifier ) {
        dwollaIdentifier = [[NSString stringWithNewUUID] retain];
    }
    return dwollaIdentifier;
}

- (NSData *)data {
    return dwollaData;
}

- (void)appendData:(NSData *)data {
    [dwollaData appendData:data];
}

- (void)resetData {
    [dwollaData setLength:0];
}

@end

