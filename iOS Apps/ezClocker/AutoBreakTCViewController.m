//
//  AutoBreakTCViewController.m
//  ezClocker
//
//  Created by Raya Khashab on 7/18/22.
//  Copyright © 2022 ezNova Technologies LLC. All rights reserved.
//

#import "AutoBreakTCViewController.h"

@interface AutoBreakTCViewController ()

@end

@implementation AutoBreakTCViewController

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

- (IBAction)agreedBtnClick:(UIButton *)sender {
    [self.delegate autoBreaksTandCDidFinish:true];

}

- (IBAction)declinedBtnClick:(UIButton *)sender {
    [self.delegate autoBreaksTandCDidFinish:false];
}
@end
