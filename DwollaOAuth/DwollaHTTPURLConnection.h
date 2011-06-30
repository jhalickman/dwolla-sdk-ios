//
//  DwollaHTTPURLConnection.h
//  DwollaOAuth
//
//  Created by James Armstead on 6/29/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#define DwollaConnectionID NSString


@interface DwollaHTTPURLConnection : NSURLConnection {
    NSURLRequest*           dwollaRequest;
    NSMutableData*          dwollaData;
    DwollaConnectionID* dwollaIdentifier;
}

@property (nonatomic, readonly) DwollaConnectionID* identifier;
@property (nonatomic, readonly) NSURLRequest* request;

- (NSData *)data;
- (void)appendData:(NSData *)data;
- (void)resetData;

@end
