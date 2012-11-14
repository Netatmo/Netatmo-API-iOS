//
// Copyright 2011-2012 Netatmo
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//


#import "LoginViewController.h"

#import "NAAPI.h"

@interface LoginViewController ()

@property (nonatomic, readwrite, retain) SyncAssistant *syncAssistant;

// This triggers login logic
- (void)launchLogIn;


// UI
- (void)configureTextField: (UITextField *)textField
               placeHolder: (NSString *)placeHolder;
- (BOOL)isValidEmail: (NSString *)email;
- (void)buttonPressed: (id)sender;

@end

@implementation LoginViewController

@synthesize syncAssistant=_syncAssistant;

#pragma mark UIViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        _emailEditItem = [[UITextField alloc] init];
        _pwdEditItem = [[UITextField alloc] init];
        _pwdEditItem.secureTextEntry = YES;
    }
    return self;
}

- (void)dealloc
{
    [_emailEditItem release];
    _emailEditItem = nil;
    
    [_pwdEditItem release];
    _pwdEditItem = nil;
    
    self.syncAssistant = nil;
    
    [super dealloc];
}

-(void)loadView
{
    [super loadView];
    
	self.view.backgroundColor = [UIColor groupTableViewBackgroundColor];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle: @"Done"
                                                                               style: UIBarButtonItemStyleDone
                                                                              target: self
                                                                              action: @selector(buttonPressed:)] autorelease];
    
    self.navigationItem.title = @"Login";
    
    
    [self configureTextField: _emailEditItem placeHolder: @"Email"];
    [self configureTextField: _pwdEditItem placeHolder: @"Password"];
    
    _emailEditItem.returnKeyType = UIReturnKeyNext;
    _pwdEditItem.returnKeyType = UIReturnKeyDone;
    
    [_emailEditItem setFrame: CGRectMake(20.0f, 60.0f, 280.0f, 40.0f)];
    [_pwdEditItem setFrame: CGRectMake(20.0f, 120.0f, 280.0f, 40.0f)];
    
    [self.view addSubview: _emailEditItem];
    [self.view addSubview: _pwdEditItem];
}

- (void)viewDidUnload
{
    
    [super viewDidUnload];
}

-(void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    
    
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // Set observers on oAuthHandler to get notified about login progress                                     //
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(loginDidStart:) 
                                                 name:[[[NAAPI gUserAPI] oAuthHandler] loginStartNotificationName]  
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loginDidSucceed:) 
                                                 name:[[[NAAPI gUserAPI] oAuthHandler] loginSuccessNotificationName] 
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loginDidFail:) 
                                                 name:[[[NAAPI gUserAPI] oAuthHandler] loginFailureNotificationName] 
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(apiNotReachable:) 
                                                 name:NAAPINotReachableNotification
                                               object:nil];
    
    [_emailEditItem setDelegate: self];
    [_pwdEditItem setDelegate: self];
}



-(void)viewWillDisappear:(BOOL)animated
{
    [_emailEditItem setDelegate: nil];
    [_pwdEditItem setDelegate: nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self 
                                                    name:[[[NAAPI gUserAPI] oAuthHandler] loginStartNotificationName] 
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self  
                                                    name:[[[NAAPI gUserAPI] oAuthHandler] loginSuccessNotificationName] 
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self 
                                                    name:[[[NAAPI gUserAPI] oAuthHandler] loginFailureNotificationName] 
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self 
                                                    name:NAAPINotReachableNotification 
                                                  object:nil];
    
    [super viewWillDisappear:animated];
    
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


-(void) loginFailedWithMsg:(NSString*) errMsg
{
    self.navigationItem.rightBarButtonItem.customView = nil;
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil 
                                                    message: errMsg
                                                   delegate:self 
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
    [alert release];
    
}



#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if(textField == _emailEditItem)
    {
        [_pwdEditItem becomeFirstResponder];
    }
    else if(textField == _pwdEditItem)
    {
        [textField resignFirstResponder];
        [self launchLogIn];
    }
    
    return YES;
}



#pragma mark - Observer methods

-(void) loginDidStart:(NSNotification *)aNotification
{    
    UIActivityIndicatorView *spinner = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge] autorelease];
    
    self.navigationItem.rightBarButtonItem.customView = spinner;
    [spinner startAnimating];
}

-(void) loginDidSucceed:(NSNotification *)aNotification
{
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // After authentication, download user information (device list, preferences)                             //
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////
    
    if (LoginViewControllerStateAuthenticating == _state) {
        _state = LoginViewControllerStateSyncing;
        self.syncAssistant = [SyncAssistant syncAssistantLaunchedWithDelegate:self];
    }
}

-(void) loginDidFail:(NSNotification *)aNotification
{
    if (LoginViewControllerStateAuthenticating == _state) {
        if ([NAAPI loginFailNotification:aNotification isCausedByError:NtmoAPIErrorCodeOauthInvalidGrant]) {
            [self loginFailedWithMsg:@"Bad login or password"];
        } else {
            [self loginFailedWithMsg:@"No data connection"];
        }
    }
    _state = LoginViewControllerStateIdle;
}

-(void) apiNotReachable:(NSNotification *)aNotification
{
    if (LoginViewControllerStateAuthenticating == _state) {
        [self loginFailedWithMsg:@"No data connection"];
    }
    _state = LoginViewControllerStateIdle;
}




#pragma mark - SyncAssystantDelegate

-(void)syncDidComplete
{
    // sync complete (received user preferences and device list)
    // ready to get data
    // go back to MainViewController
    
    _state = LoginViewControllerStateIdle;
    [self dismissModalViewControllerAnimated:YES];
}

-(void)syncDidFail
{
    if (LoginViewControllerStateSyncing == _state) {
        [self loginFailedWithMsg:@"Could not login"];
    }
    _state = LoginViewControllerStateIdle;
    
}



#pragma mark - private methods

- (void)configureTextField: (UITextField *)textField
               placeHolder: (NSString *)placeHolder
{
    textField.backgroundColor = [UIColor whiteColor];
    textField.textColor = [UIColor blackColor];
    textField.placeholder = placeHolder;
    textField.font = [UIFont systemFontOfSize: 18.0f];
    textField.borderStyle = UITextBorderStyleRoundedRect;
    textField.clearButtonMode = UITextFieldViewModeWhileEditing;
    textField.textAlignment = UITextAlignmentLeft;
    textField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    textField.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
    textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
}

- (BOOL)isValidEmail: (NSString *)email
{
    if(!(email != nil && email.length > 0))
    {
        return NO;
    }
    
    NSString *regExS = @"^[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]+$";
    NSError *error = NULL;
    
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern: regExS
                                                                           options: NSRegularExpressionCaseInsensitive
                                                                             error: &error];
    NSUInteger numberOfMatches = [regex numberOfMatchesInString: email
                                                        options: 0
                                                          range: NSMakeRange(0, [email length])];
    
    return (numberOfMatches == 1);
}

- (void)buttonPressed: (id)sender
{
    if(sender == self.navigationItem.rightBarButtonItem)
    {
        [self launchLogIn];
    }
}

-(void) launchLogIn
{    
    if (_state != LoginViewControllerStateIdle) {
        NTAWARNING(@"Trying to re-log in while on process");
        return;
    }
    
    if(![self isValidEmail: _emailEditItem.text])
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                        message:@"Invalid email"
                                                       delegate:self
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
        [alert release];
        return;
    }
    
    if(!(_pwdEditItem.text != nil && _pwdEditItem.text.length > 0))
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                        message:@"Invalid password"
                                                       delegate:self
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
        [alert release];
        return;
    }
    
    
    _state = LoginViewControllerStateAuthenticating;
    [[NAAPI gUserAPI] loginWithId: _emailEditItem.text secret: _pwdEditItem.text];
}


@end
