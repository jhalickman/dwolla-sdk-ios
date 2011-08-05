//
//  DwollaOAuthEngine.h
//  DwollaOAuth
//
//  Created by James Armstead on 6/29/11.
//  Copyright 2011 Dwolla. All rights reserved.
//
//  Largely inspired by LinkedIn OAuth by Sixten Otto <https://github.com/ResultsDirect/LinkedIn-iPhone>
//

@class DwollaOAuthEngine;

#import <Foundation/Foundation.h>
#import "OAuthConsumer.h"
#import "DwollaHTTPURLConnection.h"
#import "DwollaToken.h"
#import "DwollaMutableURLRequest.h"
#import "DwollaConsumer.h"

extern NSString *const DwollaEngineRequestTokenNotification;
extern NSString *const DwollaEngineAccessTokenNotification;
extern NSString *const DwollaEngineAuthFailureNotification;
extern NSString *const DwollaEngineTokenKey;

@protocol DwollaOAuthEngineDelegate <NSObject>

@optional

- (void)dwollaEngineAccessToken:(DwollaOAuthEngine *)engine setAccessToken:(DwollaToken *)token;
- (DwollaToken *)dwollaEngineAccessToken:(DwollaOAuthEngine *)engine;

- (void)dwollaEngine:(DwollaOAuthEngine *)engine requestSucceeded:(DwollaConnectionID *)identifier withResults:(id)results;
- (void)dwollaEngine:(DwollaOAuthEngine *)engine requestFailed:(DwollaConnectionID *)identifier withError:(NSError *)error;
@end

@interface DwollaOAuthEngine : NSObject {
    id<DwollaOAuthEngineDelegate> engineDelegate;
    DwollaConsumer* engineOAuthConsumer;
    DwollaToken*    engineOAuthRequestToken;
    DwollaToken*    engineOAuthAccessToken;
    NSString*   engineOAuthVerifier;
    NSMutableDictionary* engineConnections;
}

@property (nonatomic, readonly) DwollaConsumer *consumer;
@property (nonatomic, readonly) BOOL isAuthorized;
@property (nonatomic, readonly) BOOL hasRequestToken;
@property (nonatomic, retain) NSString* verifier;

+ (id)engineWithConsumerKey:(NSString *)consumerKey 
             consumerSecret:(NSString *)consumerSecret 
                      scope:(NSString *) scope 
                   callback:(NSString *) callback
                   delegate:(id<DwollaOAuthEngineDelegate>)delegate;

- (id)initWithConsumerKey:(NSString *)consumerKey 
           consumerSecret:(NSString *)consumerSecret 
                    scope:(NSString *) scope 
                 callback:(NSString *) callback
                 delegate:(id<DwollaOAuthEngineDelegate>)delegate ;

- (void)sendRequestWithURL:(NSURL *)url 
                     token:(DwollaToken *)token
                    method:(NSString *)method
                 onSuccess:(SEL)successSel 
                    onFail:(SEL)failSel;

- (void)requestRequestToken;
- (void)requestAccessToken;

- (NSUInteger)numberOfConnections;
- (NSArray *)connectionIdentifiers;
- (void)closeConnectionWithID:(DwollaConnectionID *)identifier;
- (void)closeAllConnections;

- (NSURLRequest *)authorizationFormURLRequest;

- (void) setTheVerifier:(NSString *)newVerifier;
- (void)parseConnectionResponse:(DwollaHTTPURLConnection *)connection;
- (DwollaConnectionID *)accountInformationCurrentUser;
- (DwollaConnectionID *)balanceCurrentUser;
- (DwollaConnectionID *)accountInformationForUser:(NSString *) userIdentifier;
- (DwollaConnectionID *)contactSearch:(NSString *) searchString 
                            withLimit:(NSInteger) limit 
                            withTypes:(NSString *) types;

- (DwollaConnectionID *)transactionsSince:(NSString *) sinceDate 
                                withLimit:(NSInteger) limit 
                                withTypes:(NSString *) types;

- (DwollaConnectionID *)sendMoney:(NSString *) pin 
                withDestinationId:(NSString *) destinationId 
                       withAmount:(NSDecimalNumber *) amount 
                        withNotes:(NSString *) note 
              withDestinationType:(NSString *) type 
                   withAssumeCost:(BOOL) assumeCost 
                  withFundsSource:(NSString *) fundSource;

- (DwollaConnectionID *)nearbySearchWithLongitude:(NSString *) longitude 
                                     withLatitude:(NSString *) latitude 
                                        withLimit:(NSInteger) limit
                                        withRange:(NSInteger) range;

//- (DwollaConnectionID *)statsForCurrentUserWithTypes:(NSString *) types 
//                                       withStartDate:(NSString *) startDate 
//                                         withEndDate:(NSString *) endDate;

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
                                   withDOB:(NSString *) dob;
@end
