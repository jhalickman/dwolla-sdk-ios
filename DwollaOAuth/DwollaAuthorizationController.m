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

@interface DwollaAuthorizationController ()

- (void)displayAuthorization;

@end


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

- (void)loadView {
    [super loadView];
	self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    authorizationNavBar = [[UINavigationBar alloc] initWithFrame:CGRectZero];
    [authorizationNavBar setItems:[NSArray arrayWithObject:[[[UINavigationItem alloc] initWithTitle:@"LinkedIn Authorization"] autorelease]]];
    authorizationNavBar.topItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel)] autorelease];
    [authorizationNavBar sizeToFit];
    authorizationNavBar.frame = CGRectMake(0, 0, self.view.bounds.size.width, authorizationNavBar.frame.size.height);
    authorizationNavBar.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:authorizationNavBar];
    
    authorizationWebView = [[UIWebView alloc] initWithFrame:CGRectMake(0, authorizationNavBar.frame.size.height, self.view.bounds.size.width, self.view.bounds.size.height - authorizationNavBar.frame.size.height)];
    authorizationWebView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    authorizationWebView.delegate = self;
    authorizationWebView.scalesPageToFit = NO;
    authorizationWebView.dataDetectorTypes = UIDataDetectorTypeNone;
    [self.view addSubview:authorizationWebView];
    
    [self displayAuthorization];
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

- (void)didReceiveRequestToken:(NSNotification *)notification {
    [self displayAuthorization];
}
- (void)didReceiveAccessToken:(NSNotification *)notification {
   // [self success];
}

- (void)displayAuthorization {
    if( dwollaEngine.hasRequestToken ) {
        [authorizationWebView loadRequest:[dwollaEngine authorizationFormURLRequest]];
    }
}


@end
