//
//  DwollaAuthorizationController.m
//  DwollaOAuth
//
//  Created by James Armstead on 6/29/11.
//  Copyright 2011 Dwolla. All rights reserved.
//
//  Largely inspired by LinkedIn OAuth by Sixten Otto <https://github.com/ResultsDirect/LinkedIn-iPhone>
//

#import "DwollaAuthorizationController.h"


@implementation DwollaAuthorizationController

@synthesize engine = dwollaEngine, delegate = authorizationDelegate, navigationBar = authorizationNavBar;

+ (id)authorizationControllerWithEngine:(DwollaOAuthEngine *)engine delegate:(id<DwollaAuthorizationControllerDelegate>)delegate {
	if( engine.isAuthorized ) return nil;
	return [[[self alloc] initWithEngine:engine delegate:delegate] autorelease];
}

- (id)initWithEngine:(DwollaOAuthEngine *)engine delegate:(id<DwollaAuthorizationControllerDelegate>)delegate {
    if( self == [super initWithNibName:nil bundle:nil] ) {
        authorizationDelegate = delegate;
        dwollaEngine = [engine retain];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveRequestToken:) name:DwollaEngineRequestTokenNotification object:dwollaEngine];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveAccessToken:) name:DwollaEngineAccessTokenNotification object:dwollaEngine];
        
        [dwollaEngine requestRequestToken];
    }
    return self;
}

- (id)initWithConsumerKey:(NSString *)consumerKey 
           consumerSecret:(NSString *)consumerSecret 
                     scope:(NSString *)scope 
                 callback:(NSString *)callback 
                 delegate:(id<DwollaAuthorizationControllerDelegate>)delegate {
    
    return [self initWithEngine:[DwollaOAuthEngine 
                                 engineWithConsumerKey:consumerKey 
                                 consumerSecret:consumerSecret 
                                 scope:scope 
                                 callback:callback
                                 delegate:nil] delegate:delegate];
}

- (void)dealloc
{
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
