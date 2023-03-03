//
//  InitialSlidingViewController.h
//  ECSlidingViewController
//
//  Created by Michael Enriquez on 1/25/12.
//  Copyright (c) 2012 EdgeCase. All rights reserved.
//

#import "ECSlidingViewController.h"
#import "LoginViewController.h"
#import "SubscriptionViewController.h"
#import "Reachability.h"
#import "SetupPersonalAccount.h"
#import "CreateEmployerAccountViewController.h"
#import "CreateEmployerStep2ViewController.h"
#import "WizardViewController.h"
#import "AddPersonInitialViewController.h"
#import "TeamModeViewController.h"
#import "EmployerStartScreenViewController.h"

@interface InitialSlidingViewController : ECSlidingViewController<LoginViewControllerDelegate, SubscriptionDelegate, SubscriptionViewControllerDelegate, AddIndividualAccountDelegate, CreateEmployerAccountViewControllerDelegate, CreateEmployerAccountStep2Delegate, EmployerStartScreenViewControllerDelegate, newEmployeeAddedDelegate, TeamModeViewControllerDelegate>
{
    CreateEmployerAccountViewController *createController;
    CreateEmployerStep2ViewController *createControllerStep2;
    WizardViewController *wizardController;
    LoginViewController *loginController;
    AddPersonInitialViewController *addPersonIntitialController;
    UINavigationController *addPersonInitialNavController;
    BOOL shouldHideStatusBar;
    UIViewController *V2;
    
}
@end
