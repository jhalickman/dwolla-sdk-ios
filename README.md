Dwolla Grid (OAuth 1) SDK
===========

Simple library for gaining access to the Dwolla OAuth Rest APIs with only a few lines of code, based on the Linked-In SDK(https://github.com/ResultsDirect/LinkedIn-iPhone)!

-------------------------

Documentation & Example Code
===========

Documentation is provided below and an example at https://github.com/Dwolla/Dwolla-Mobile-SDK.
	
### Here is another list of project examples which use the OAuth System. ###
	https://github.com/armsteadj1/DwollaTap

-------------------------

Installation (XCode 4)
===========

1. Download or Use Git Submodule
	1. Adding a git submodule to your project by using `git submodule add git@github.com:Dwolla/dwolla-sdk-ios.git DwollaOAuth`
1. Use the "Add files to "...."" feature in XCode 4 to include the DwollaOAuth submodule folder:
	1. Make sure "Create groups for any folders" is checked.
	
OR

1. Download or Use Git Submodule
	1. Adding a git submodule to your project by using `git submodule add git://github.com/dwolla/dwolla-sdk-ios.git DwollaOAuth`
1. Use the "Add files to "...."" feature in XCode 4 to include each folder in the DwollaOAuth submodule folder:
	1. Make sure "Create groups for any folders" is checked.
	
(I'm not sure which one is the best, if you have a better idea on how to include these let me know)
	
### You should now be able to build successfully ###

-------------------------

Usage
===========

1. The view controller you wish to communicate with the Dwolla SDK will need to implement 2 interfaces:

		"DwollaOAuthEngineDelegate" and "DwollaAuthorizationControllerDelegate"

1. Next you will need to define 2 variables. A ###(DwollaOAuthEngine *)### and a ###(UIViewController *)###. The Engine will hold the Class which holds a majority of the logic for passing data to and from the Dwolla OAuth REST methods. The "UIViewController" is the authorization view that will pop up to do the verification and token processing for the OAuth workflow.

1. Next, you need to implement the functions for both Delegates:

	###DwollaEngineDelegate###

		#Is called  the AccessToken for storing. Tokens can store themselves with "storeInUserDefaultsWithServiceProviderName:prefix:"
		- (void)dwollaEngineAccessToken:(DwollaOAuthEngine *)engine setAccessToken:(DwollaToken *)token 
		
		#Is called when the DwollaEngine needs the AccessToken out of the data store. Tokens can be recalled with: "initWithUserDefaultsUsingServiceProviderName:prefix:"
		- (OAToken *)dwollaEngineAccessToken:(DwollaOAuthEngine *)engine 
		
		#Is called  results from OAuth REST calls. 'results' returns as an NSDictionary with the same structure as the JSON returned from Dwolla.
		- (void)dwollaEngine:(DwollaOAuthEngine *)engine requestSucceeded:(DwollaConnectionID *)identifier withResults:(id)results 
		
		#Is called  the error to you if a problem occured with a Rest call within the Engine.
		- (void)dwollaEngine:(DwollaOAuthEngine *)engine requestFailed:(DwollaConnectionID *)identifier withError:(NSError *)error 

	###DwollaAuthorizationControllerDelegate###

		#Is called if the user is successfully Authorized.
		- (void)dwollaAuthorizationControllerSucceeded:(DwollaAuthorizationController *)controller 
		
		#Is called if the user's authroization Fails.
		- (void)dwollaAuthorizationControllerFailed:(DwollaAuthorizationController *)controller 
		
		#Is called if the user cancels the Authorization.
		- (void)dwollaAuthorizationControllerCanceled:(DwollaAuthorizationController *)controller 

1. Next, you need to allocate your ###DwollaEngine### with your ###Consumer Key,Secret, Scope, and Callback###.
   *NOTE: The callback in this isn't really used, we scrap the URL for the needed results. Would probably be best if was some sort of a "We are logining you in page".*

		dwollaEngine = [[DwollaOAuthEngine 
                     engineWithConsumerKey:@"KEY" 
                     consumerSecret:@"SECRET"
                     scope: @"AccountAPI:AccountInfoFull|AccountAPI:Send|AccountAPI:Contacts|AccountAPI:Transactions|AccountAPI:Balance"
                     callback: @"http://www.<url>.com/" //Needs 'http://' and also trailing '/'
                     delegate:self] retain];  
                     
1. You can try and make API calls through your ###DwollaEngine variable### at this point and it will attempt to grab
the AccessToken using the Delegate function we created. If it can't find an Access Token the funciton you 
called will return 'nil'.

1. To Authorize a user, you just need to call:

		controller = [DwollaAuthorizationController authorizationControllerWithEngine:dwollaEngine delegate:self];
    	if( controller ) {
     		   [self presentModalViewController:controller animated:YES];
   		}
   		
	### This will open up the webview, get all tokens, pass them to the Engine and call your Delegate to save them. ###
	
	### You NOW should be able to make full calls into the Dwolla API using any of the following functions:###
		- (DwollaConnectionID *)accountInformationCurrentUser;
		
		- (DwollaConnectionID *)balanceCurrentUser;
		
		- (DwollaConnectionID *)accountInformationForUser:(NSString *) userIdentifier;
		
		- (DwollaConnectionID *)contactSearch:(NSString *) searchString 
                            withLimit:(NSInteger) limit 
                            withTypes:(NSString *) types;

		- (DwollaConnectionID *)transactionsSince:(NSString *) sinceDate 
                                withLimit:(NSInteger) limit 
                                withTypes:(NSString *) types;

		- (DwollaConnectionID *)sendMoneyWithPin:(NSString *) pin 
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
                                   
POSSIBLE ERRORS RETURNED FROM DWOLLA REST API
==========

		SERVICE_ERROR, 
		INVALID_ACCOUNT_IDENTIFIER, 
		INVALID_ACCOUNT_CREDENTIALS, 
		ACCOUNT_TEMPORARILY_LOCKED, 
		NOTES_TOO_LONG, 
		INVALID_SOURCE_ID, 
		TWITTER_ID_NOT_LINKED, 
		FACEBOOK_ID_NOT_LINKED,
		SOURCE_ID_NOT_REGISTERED, 
		INSUFFICIENT_FUNDS, 
		INVALID_FUNDS_SOURCE, 
		INVALID_DESTINATION_ID, 
		DESTINATION_ID_NOT_REGISTERED, 
		INVALID_DESTINATION_TYPE, 
		INVALID_SINCE_DATE, 
		INVALID_START_DATE, 
		INVALID_END_DATE, 
		INVALID_PHONE_TYPE, 
		INVALID_LATITUDE_LONGITUDE
