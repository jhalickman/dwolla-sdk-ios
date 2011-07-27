//
//  OAToken.m
//  OAuthConsumer
//
//  Created by Jon Crosby on 10/19/07.
//  Copyright 2007 Kaboomerang LLC. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.


#import "NSString+URLEncoding.h"
#import "DwollaToken.h"

@interface DwollaToken (Private)

+ (NSString *)settingsKey:(const NSString *)name provider:(const NSString *)provider prefix:(const NSString *)prefix;
+ (id)loadSetting:(const NSString *)name provider:(const NSString *)provider prefix:(const NSString *)prefix;
+ (void)saveSetting:(NSString *)name object:(id)object provider:(const NSString *)provider prefix:(const NSString *)prefix;
+ (NSNumber *)durationWithString:(NSString *)aDuration;
+ (NSDictionary *)attributesWithString:(NSString *)theAttributes;

@end

@implementation DwollaToken

#pragma mark init

- (id)initWithCoder:(NSCoder *)aDecoder {
	OAToken *t = [self initWithKey:[aDecoder decodeObjectForKey:@"key"]
							secret:[aDecoder decodeObjectForKey:@"secret"]
						   session:[aDecoder decodeObjectForKey:@"session"]
						  duration:[aDecoder decodeObjectForKey:@"duration"]
						attributes:[aDecoder decodeObjectForKey:@"attributes"]
						   created:[aDecoder decodeObjectForKey:@"created"]
						 renewable:[aDecoder decodeBoolForKey:@"renewable"]];
	[t setVerifier:[aDecoder decodeObjectForKey:@"verifier"]];
	return t;
}

#pragma mark dealloc

- (void)dealloc {
    self.key = nil;
    self.secret = nil;
	self.session = nil;
    self.duration = nil;
    self.verifier = nil;
    self.attributes = nil;
	[super dealloc];
}

#pragma mark settings

- (BOOL)isValid {
	return (key != nil && ![key isEqualToString:@""] && secret != nil && ![secret isEqualToString:@""]);
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
	[aCoder encodeObject:[self key] forKey:@"key"];
	[aCoder encodeObject:[self secret] forKey:@"secret"];
	[aCoder encodeObject:[self session] forKey:@"session"];
	[aCoder encodeObject:[self duration] forKey:@"duration"];
	[aCoder encodeObject:[self attributes] forKey:@"attributes"];
	[aCoder encodeBool:renewable forKey:@"renewable"];
	[aCoder encodeObject:[self verifier] forKey:@"verifier"];
}

- (NSDictionary *)parameters
{
	NSMutableDictionary *params = [[[NSMutableDictionary alloc] init] autorelease];
    
	if (key) {
		[params setObject:key forKey:@"oauth_token"];
		if ([self isForRenewal]) {
			[params setObject:session forKey:@"oauth_session_handle"];
		}
	} else {
		if (duration) {
			[params setObject:[duration stringValue] forKey: @"oauth_token_duration"];
		}
		if ([attributes count]) {
			[params setObject:[self attributeString] forKey:@"oauth_token_attributes"];
		}
	}
	if (self.verifier) {
		[params setObject:self.verifier forKey:@"oauth_verifier"];
	}
	return params;
}
@end
