//
//  DwollaOAuthEngine.m
//  DwollaOAuth
//
//  Created by James Armstead on 6/29/11.
//  Copyright 2011 Dwolla. All rights reserved.
//

#import "DwollaOAuthEngine.h"


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
@end
