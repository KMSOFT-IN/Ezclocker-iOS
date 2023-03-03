//
//  JobCodeListViewController.m
//  ezClocker
//
//  Created by Logileap on 11/20/19.
//  Copyright © 2019 ezNova Technologies LLC. All rights reserved.
//

#import "JobCodeListViewController.h"
#import "user.h"
#import "SharedUICode.h"
#import "NSString+Extensions.h"
#import "CommonLib.h"



@interface JobCodeListViewController ()
{
    // NSMutableArray *jobCodesList;
    NSMutableArray *searchJobCodesList;
}
@end

@implementation JobCodeListViewController
@synthesize delegate;
- (void)viewDidLoad {
    [super viewDidLoad];
    [self.navigationItem setTitle:@"Select a Job"];
    UserClass *user = [UserClass getInstance];
    if ((_jobCodes == nil) || ([_jobCodes count] == 0))
    {
        _jobCodes = [[NSMutableArray alloc] initWithArray: user.jobCodesList];
        searchJobCodesList = [[NSMutableArray alloc] initWithArray: user.jobCodesList];
    }
    else{
        searchJobCodesList = [[NSMutableArray alloc] initWithArray: _jobCodes];
    }
    self.tableView.allowsSelectionDuringEditing = YES;
    self.tableView.allowsMultipleSelectionDuringEditing = NO;
    [self.tableView setTableFooterView:[[UIView alloc] initWithFrame:CGRectZero]];
    
    [self.navigationController.navigationBar setTitleTextAttributes:
     @{NSForegroundColorAttributeName:[UIColor whiteColor]}];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [searchJobCodesList count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        
        cell.detailTextLabel.textColor = UIColorFromRGB(GRAY_TEXT_COLOR);
    }
    if ((searchJobCodesList != nil) && ([searchJobCodesList count] > 0))
    {
        NSDictionary *jobCodeObj = [searchJobCodesList objectAtIndex:indexPath.row];
        cell.textLabel.text = [jobCodeObj valueForKey:@"name"];
  //      if (![NSString isNilOrEmpty:[jobCodeObj valueForKey:@"description"]])
  //          cell.detailTextLabel.text =[jobCodeObj valueForKey:@"description"];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath  {
    NSDictionary *selectedJobCode = [searchJobCodesList objectAtIndex:indexPath.row];
    [self.navigationController dismissViewControllerAnimated:YES completion:^{
        [delegate searchJobCode:selectedJobCode];
    }];
}
- (IBAction)cancelButtonClick:(UIBarButtonItem *)sender {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}
#pragma mark - SearchBar Delegate Methods

-(void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    if ([searchText isEqualToString:@""]) {
        searchJobCodesList = _jobCodes;
    } else {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"self.displayValue contains[c] %@", searchText];
        searchJobCodesList = [[_jobCodes filteredArrayUsingPredicate:predicate] mutableCopy];
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

@end
