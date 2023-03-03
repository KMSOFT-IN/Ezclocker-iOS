//
//  RolesListViewController.m
//  ezClocker
//
//  Created by Raya Khashab on 01/13/21.
//  Copyright © 2021 ezNova Technologies LLC. All rights reserved.
//

#import "RolesListViewController.h"
#import "user.h"
#import "SharedUICode.h"
#import "NSString+Extensions.h"
#import "CommonLib.h"



@implementation RolesListViewController
@synthesize delegate;
- (void)viewDidLoad {
    [super viewDidLoad];
    [self.navigationItem setTitle:@"Select a Role"];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    //if the signed in user is an employer or Payroll Manager then show them 3 choices (employee, manager, payroll manager) else only show them 2 employee and manager.
    if (CommonLib.userHasPayrollPermission)
        return 3;
    else
        return 2;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];

        cell.detailTextLabel.textColor = UIColorFromRGB(GRAY_TEXT_COLOR);
    }
    if (indexPath.row == 0)
    {
        cell.textLabel.text = @"Employee";
        cell.detailTextLabel.text = @"Only has access to their own timesheet.";
    }
    else if (indexPath.row == 1)
    {
        cell.textLabel.text = @"Manager";
        cell.detailTextLabel.text = @"Has full access except for Payrate and account/subscription.";
    }
    else
    {
        cell.textLabel.text = @"Payroll Manager";
        cell.detailTextLabel.text = @"Has full access except for account/subscription.";
    }

    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath  {
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    NSString *selectedText = cell.textLabel.text;
    [delegate roleWasSelected:selectedText];
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

/*
#pragma mark - SearchBar Delegate Methods

-(void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    if ([searchText isEqualToString:@""]) {
        searchJobCodesList = _jobCodes;
    } else {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"self.displayValue contains[c] %@", searchText];
    searchJobCodesList = [_jobCodes filteredArrayUsingPredicate:predicate];
    }
    [_tableView reloadData];
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)SearchBar
{
    SearchBar.showsCancelButton=YES;
}
- (void)searchBarTextDidEndEditing:(UISearchBar *)theSearchBar
{
    [theSearchBar resignFirstResponder];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)SearchBar
{
    @try
    {
        SearchBar.showsCancelButton=NO;
        SearchBar.text = @"";
        searchJobCodesList = _jobCodes;
        [SearchBar resignFirstResponder];
        [_tableView reloadData];
    }
    @catch (NSException *exception) {
    }
}
- (void)searchBarSearchButtonClicked:(UISearchBar *)SearchBar
{
    [SearchBar resignFirstResponder];
}
 */

- (IBAction)cancelButtonClick:(id)sender {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

@end
