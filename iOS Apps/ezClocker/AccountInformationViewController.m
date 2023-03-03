//
//  AccountInformationViewController.m
//  ezClocker
//
//  Created by Raya Khashab on 3/27/22.
//  Copyright © 2022 ezNova Technologies LLC. All rights reserved.
//

#import "AccountInformationViewController.h"

@interface AccountInformationViewController ()

@end

@implementation AccountInformationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)doCancel:(id)sender {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}
@end
