//
//  DwollaConsumer.h
//  DwollaOAuth
//
//  Created by James Armstead on 7/27/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "OAConsumer.h"

@interface DwollaConsumer : OAConsumer{
@protected
    NSString *scope;
    NSString *callback;
}
@property(copy, readwrite) NSString *scope;
@property(copy, readwrite) NSString *callback;

- (id)initWithKey:(const NSString *)aKey 
           secret:(const NSString *)aSecret 
            scope:(NSString *) aScope 
         callback:(NSString *) aCallback;

- (BOOL)isEqualToConsumer:(OAConsumer *)aConsumer;
- (NSString *) strippedCallback;

@end
