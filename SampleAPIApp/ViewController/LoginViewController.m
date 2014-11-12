//
// Copyright 2014 Netatmo
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

@interface LoginViewController ()

@property (nonatomic, strong, readwrite) IBOutlet UITextField *email;
@property (nonatomic, strong, readwrite) IBOutlet UITextField *password;
@property (nonatomic, strong, readwrite) IBOutlet UIActivityIndicatorView *activityIdicator;

@end

@implementation LoginViewController


- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appDidEnterBackground)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
    
    [self.email setDelegate:self];
    [self.password setDelegate:self];
    [self hideAndStopActivityIndicator];
    [[NAAPI gUserAPI] registerLogInNotifications:self];
}


- (void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NAAPI gUserAPI] unregisterLogInNotifications:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) appDidEnterBackground
{
    [[NAAPI gUserAPI] cancelRequestsWithDelegate:nil];
    [self hideAndStopActivityIndicator];
}


- (IBAction)loginButtonListener:(id)sender {
    [self startLogin];
}

- (void) startLogin
{
    [self showAndAnimateActivityIndicator];
    
    if ([self.email.text isEqualToString:@""] || [self.password.text isEqualToString:@""])
    {
        
        [[[UIAlertView alloc] initWithTitle: @""
                                    message: @"Invalid Email"
                                   delegate: nil
                          cancelButtonTitle: @"OK"
                          otherButtonTitles: nil] show];
        [self hideAndStopActivityIndicator];
        return;
    }
    else if (![self validLogin:self.email.text])
    {
        [[[UIAlertView alloc] initWithTitle: @""
                                    message: @"Invalid Email"
                                   delegate: nil
                          cancelButtonTitle: @"OK"
                          otherButtonTitles: nil] show];
        [self hideAndStopActivityIndicator];
        return;
    }
    else
    {
        [[NAAPI gUserAPI] loginWithId: self.email.text
                               secret: self.password.text];
    }
}

#pragma mark - Activity indicator management

- (void) hideAndStopActivityIndicator
{
    [self.activityIdicator stopAnimating];
    self.activityIdicator.hidden = YES;
}

- (void) showAndAnimateActivityIndicator
{
    [self.activityIdicator startAnimating];
    self.activityIdicator.hidden = NO;
}

#pragma mark - Login callbacks
- (void)apiDidLogInFailure:(NSNotification *)notification
{
    [self hideAndStopActivityIndicator];
    
    NtmoAPIErrorCode errorCode = [[notification.userInfo objectForKey:@"error"] intValue];
    
    
    if(errorCode == NtmoAPIErrorCodeOauthInvalidGrant)
    {
        [[[UIAlertView alloc] initWithTitle: @""
                                    message: @"Bad login or password"
                                   delegate: nil
                          cancelButtonTitle: @"OK"
                          otherButtonTitles: nil] show];
    }
    else if (errorCode == NtmoAPIErrorCodeNoDataConnection)
    {
        [[[UIAlertView alloc] initWithTitle: @""
                                    message: @"No internet connection"
                                   delegate: nil
                          cancelButtonTitle: @"OK"
                          otherButtonTitles: nil] show];
    }
    else if (errorCode == NtmoAPIErrorCodeUnknown)
    {
        [[[UIAlertView alloc] initWithTitle: @""
                                    message: @"Check your client secret and id"
                                   delegate: nil
                          cancelButtonTitle: @"OK"
                          otherButtonTitles: nil] show];
    }
    else
    {
        [[[UIAlertView alloc] initWithTitle: @""
                                    message: @"Login failed"
                                   delegate: nil
                          cancelButtonTitle: @"OK"
                          otherButtonTitles: nil] show];
    }
}


- (void)apiDidLogInSuccess:(NSNotification *)notification
{
    [self hideAndStopActivityIndicator];
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Text fields delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == self.email) {
        [self.password becomeFirstResponder];
        return YES;
    }
    else if (textField == self.password){
        [self startLogin];
        return YES;
    }
    return NO;
}


- (void)userNeedToLogIn:(NSNotification *)notification {}

#pragma mark - Login check

- (BOOL)validLogin: (NSString *)login
{
    NSTextCheckingResult *result = [[self regexLogin] firstMatchInString: login
                                                                 options: 0
                                                                   range: NSMakeRange(0, [login length])];
    
    return !([result rangeAtIndex:0].location == NSNotFound || result == nil);
}


- (NSRegularExpression *)regexLogin
{
    return [NSRegularExpression regularExpressionWithPattern: @"^[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,4}$"
                                                     options: NSRegularExpressionCaseInsensitive
                                                       error: nil];
}


@end
