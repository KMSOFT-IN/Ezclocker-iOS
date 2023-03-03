//
//  EmployerStartScreenViewController.m
//  ezClocker
//
//  Created by Raya Khashab on 3/26/22.
//  Copyright © 2022 ezNova Technologies LLC. All rights reserved.
//

#import "EmployerStartScreenViewController.h"
#import "CommonLib.h"

@interface EmployerStartScreenViewController ()

@end

@implementation EmployerStartScreenViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    _signUpView.layer.cornerRadius = 5;
    _signUpView.layer.borderWidth = 1;
    _signUpView.layer.borderColor = UIColorFromRGB(LOGO_ORANGE_COLOR).CGColor;
    _signInView.layer.cornerRadius = 5;
    
    if (UIScreen.mainScreen.bounds.size.height > 667) {
        _centerYConstraint.constant = 0;
    } else {
        _centerYConstraint.constant = 50;
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
//    _signInBtn.titleLabel.font = [UIFont systemFontOfSize:30];
//    _signUpBtn.titleLabel.font = [UIFont systemFontOfSize:30];

}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)doSignIn:(id)sender {
    [self.delegate EmployerStartScreenSignInSelected:self];
}

- (IBAction)showInformation:(id)sender {
    UIStoryboard *story = [UIStoryboard storyboardWithName:@"iPhone" bundle:nil];
    UINavigationController *viewController = [story instantiateViewControllerWithIdentifier:@"AccountInformationNav"];
 //   JobCodeListViewController * controller = viewController.viewControllers.firstObject;
 //   controller.delegate = self;
    [self presentViewController:viewController animated:YES completion:nil];

}


- (IBAction)doSignUp:(id)sender {
    [self.delegate EmployerStartScreenSignupSelected:self];
}
@end
