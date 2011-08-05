Dwolla Grid (OAuth 1) SDK
===========

Simple library for gaining access to the Dwolla OAuth Rest APIs with only a few lines of code, based on the Linked-In SDK(https://github.com/ResultsDirect/LinkedIn-iPhone)!

-------------------------

Documentation & Example Code
===========

Documentation is provided below and an example at https://github.com/dwolla/DwollaOAuthDemo.

-------------------------

Installation (XCode 4)
===========

1. Download or Use Git Submodule
	1. Adding a git submodule to your project by using `git submodule add git://github.com/dwolla/dwolla-sdk-ios.git DwollaOAuth`
1. Use the "Add files to "...."" feature in XCode 4 to include the following folders:
	1. OAuthConsumer
	1. SBJSON
	1. DwollaOAuth
1. Add the following into "Header Search Paths" and checkmark "RECURSIVE":
	1. "$(SOURCE_ROOT)/DwollaOAuth"
	
### You should now be able to build successfully ###

-------------------------

Usage
===========

1. The view controller you wish to communicate with the Dwolla SDK will need to implement 2 interfaces:

		"DwollaOAuthEngineDelegate" and "DwollaAuthorizationControllerDelegate"

1. Next you will need to define 2 variables. A "DwollaOAuthEngine" and a "UIViewController". The Engine will hold the Class which holds a majority of the logic for passing data to and from the Dwolla OAuth REST methods. The "UIViewController" is the authorization view that will pop up to do the verification and token processing for the OAuth workflow.

1. Next, you need to implement the functions for both Delegates:

	DwollaEngineDelegate

		#Is called  the AccessToken for storing. Tokens can store themselves with "storeInUserDefaultsWithServiceProviderName:prefix:"
		- (void)dwollaEngineAccessToken:(DwollaOAuthEngine *)engine setAccessToken:(DwollaToken *)token 
		
		#Is called when the DwollaEngine needs the AccessToken out of the data store. Tokens can be recalled with: "initWithUserDefaultsUsingServiceProviderName:prefix:"
		- (OAToken *)dwollaEngineAccessToken:(DwollaOAuthEngine *)engine 
		
		#Is called  results from OAuth REST calls. 'results' returns as an NSDictionary with the same structure as the JSON returned from Dwolla.
		- (void)dwollaEngine:(DwollaOAuthEngine *)engine requestSucceeded:(DwollaConnectionID *)identifier withResults:(id)results 
		
		#Is called  the error to you if a problem occured with a Rest call within the Engine.
		- (void)dwollaEngine:(DwollaOAuthEngine *)engine requestFailed:(DwollaConnectionID *)identifier withError:(NSError *)error 

	DwollaAuthorizationControllerDelegate

		#Is called if the user is successfully Authorized.
		- (void)dwollaAuthorizationControllerSucceeded:(DwollaAuthorizationController *)controller 
		
		#Is called if the user's authroization Fails.
		- (void)dwollaAuthorizationControllerFailed:(DwollaAuthorizationController *)controller 
		
		#Is called if the user cancels the Authorization.
		- (void)dwollaAuthorizationControllerCanceled:(DwollaAuthorizationController *)controller 

1. Next, you need to create your DwollaEngine with your Consumer Key,Secret, Scope, and Callback.
   NOTE: The callback in this isn't really used, we scrap the URL for the needed results. 
   Would probably be best if was some sort of a "We are logining you in page".

		dwollaEngine = [[DwollaOAuthEngine 
                     engineWithConsumerKey:@"KEY" 
                     consumerSecret:@"SECRET"
                     scope: @"AccountAPI:AccountInfoFull|AccountAPI:Send|AccountAPI:Contacts|AccountAPI:Transactions|AccountAPI:Balance"
                     callback: @"http://www.<url>.com/" //Needs 'http://' and also trailing '/'
                     delegate:self] retain];  
                     
1. You can try and make API calls through the dwollaEngine at this point and it will attempt to grab
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