//
//  TermsOfServiceViewController.m
//  ezClocker
//
//  Created by Raya Khashab on 3/1/14.
//  Copyright (c) 2014 ezNova Technologies LLC. All rights reserved.
//

#import "TermsOfServiceViewController.h"

@interface TermsOfServiceViewController ()

@end

@implementation TermsOfServiceViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
 static NSString *CellIdentifier = @"Cell";
 UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
 if (cell == nil) {
 cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
 //        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
 }

    cell.textLabel.text = @"sub Hi";
 return cell;
 }


- (void)viewDidLoad
{
    [super viewDidLoad];
    NSString *url= [NSString stringWithFormat:@"%@public/ezclocker_terms_of_service.html", SERVER_URL];
    NSURL *nsurl=[NSURL URLWithString:url];
    NSURLRequest *nsrequest=[NSURLRequest requestWithURL:nsurl];
    [_mainWebView loadRequest:nsrequest];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)doBackBtnClick:(id)sender {
    [self.delegate termsOfServiceControllerDidFinishViewing:self];

}
@end
