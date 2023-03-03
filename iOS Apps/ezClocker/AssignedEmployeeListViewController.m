//
//  AssignedEmployeeListViewController.m
//  ezClocker
//
//  Created by Raya Khashab on 3/3/20.
//  Copyright © 2020 ezNova Technologies LLC. All rights reserved.
//

#import "AssignedEmployeeListViewController.h"
#import "user.h"
#import "AssignEmployeeTableViewCell.h"
#import "NSNumber+Extensions.h"
#import "NSDictionary+Extensions.h"
#import "SharedUICode.h"
#import "CommonLib.h"
#import "NSString+Extensions.h"

@interface AssignedEmployeeListViewController ()

@end

@implementation AssignedEmployeeListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.navigationItem setTitle:@"Employee List"];
    self.searchBar.delegate = self;
    UserClass *user = [UserClass getInstance];
    employeeList = [[NSMutableArray alloc] init];
    NSMutableArray *list = [[NSMutableArray alloc] initWithArray: user.employeeList];
    for (int i = 0; i < [list count]; i++) {
        
        NSDictionary *object = [list objectAtIndex:i];
        NSString *name = [object valueForKey:@"Name"];
        NSString *employeeId = [NSString stringWithFormat:@"%@", [object valueForKey:@"ID"]];
//        NSString *isPrimary = [object valueForKey:@"isPrimary"];
        
        NSNumber *primaryNumber = [NSNumber numberWithBool:NO];
        NSNumber *isSelected = [NSNumber numberWithBool:NO];
        NSMutableArray *assignedEmployeeList = [_jobCodeDetails valueForKey:@"assignedEmployeeList"];
        if ([assignedEmployeeList count] > 0) {
            for (int j = 0; j < [assignedEmployeeList count]; j++)
            {
                NSDictionary *empObj = [assignedEmployeeList objectAtIndex: j];
                NSString *empId = [NSString stringWithFormat:@"%@", [empObj valueForKey:@"employeeId"]];
                if ([employeeId isEqualToString: empId]) {
                    isSelected = [NSNumber numberWithBool:YES];;//[empObj valueForKey:@"isSelected"];
                    if ([isSelected boolValue]) {
                        primaryNumber = [empObj valueForKey:@"isPrimary"];
                    }
                    break;
                }
            }
        }
        NSMutableDictionary *addEmployee = [[NSMutableDictionary alloc] init];
        [addEmployee setValue:name forKey:@"employeeName"];
        [addEmployee setValue:employeeId forKey:@"employeeId"];
        [addEmployee setValue:primaryNumber forKey:@"isPrimary"];
        [addEmployee setValue:isSelected forKey:@"isSelected"];
        [employeeList addObject:addEmployee];
    }
    
    filterEmployeeList = employeeList;
    [self.tableView setTableFooterView:[[UIView alloc] initWithFrame:CGRectZero]];
    [self.tableView reloadData];
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    CGRect mainFrame = self.view.frame;
    
    UIView *tempView=[[UIView alloc]initWithFrame:CGRectMake(0,200,mainFrame.size.width,244)];
    tempView.backgroundColor = UIColorFromRGB(GRAY_WEBSITE_COLOR);
    
    UILabel *tempLabel=[[UILabel alloc]initWithFrame:CGRectMake(16,0,(mainFrame.size.width - 86),36)];
    tempLabel.backgroundColor=[UIColor clearColor];
    tempLabel.textColor = [UIColor whiteColor];
    tempLabel.font = [UIFont fontWithName:@"Helvetica" size:16.0f];
    tempLabel.font = [UIFont boldSystemFontOfSize:16.0f];
    tempLabel.text =  @"Employees Who Do This Job";
    tempLabel.numberOfLines = 0;
    
    UILabel *primaryLabel=[[UILabel alloc] initWithFrame:CGRectMake(tempLabel.frame.size.width, 0, 70, 33)];
    
    primaryLabel.backgroundColor=[UIColor clearColor];
    primaryLabel.textColor = [UIColor whiteColor];
    primaryLabel.font = [UIFont fontWithName:@"Helvetica" size:16.0f];
    primaryLabel.font = [UIFont boldSystemFontOfSize:16.0f];
    primaryLabel.text =  @"Primary";
    primaryLabel.numberOfLines = 0;
    
    [tempView addSubview:tempLabel];
    
    [tempView addSubview:primaryLabel];
    
    return tempView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 37.f;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [filterEmployeeList count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *cellIdentifier = @"AssignEmployeeTableViewCell";
    AssignEmployeeTableViewCell *cell = (AssignEmployeeTableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    NSDictionary *jobCodeObj = [filterEmployeeList objectAtIndex:indexPath.row];
    cell.employeeNameLabel.text = [jobCodeObj valueForKey:@"employeeName"];
    [cell.selectedButton setImage:[UIImage imageNamed:@"ic_uncheck"] forState:UIControlStateNormal];
    [cell.primaryButton setImage:[UIImage imageNamed:@"ic_uncheck"] forState:UIControlStateNormal];
    
    NSNumber *selectedObj = jobCodeObj[@"isSelected"];
    BOOL isSelect = [selectedObj boolValue];
    if (isSelect) {
        [cell.selectedButton setSelected:YES];
    }
    
    NSNumber *primaryObj = jobCodeObj[@"isPrimary"];
    BOOL isPrimary = [primaryObj boolValue];
    if (isPrimary) {
        [cell.primaryButton setSelected:YES];
    }
    cell.primaryButton.tag = indexPath.row;
    [cell.primaryButton addTarget:self action:@selector(tapPrimaryButton:) forControlEvents:UIControlEventTouchUpInside];
    
    cell.selectedButton.tag = indexPath.row;
    [cell.selectedButton addTarget:self action:@selector(tapSelectedButton:) forControlEvents:UIControlEventTouchUpInside];
    
    return cell;
}

-(void)tapPrimaryButton: (UIButton *)button {
    
    NSIndexPath *indexpath = [NSIndexPath indexPathForRow:button.tag inSection:0];
    AssignEmployeeTableViewCell *cell = [_tableView cellForRowAtIndexPath:indexpath];
    [button setSelected:(![button isSelected])];
    [cell.selectedButton setSelected:([button isSelected])];
    
    NSDictionary *jobCodeObj = [filterEmployeeList objectAtIndex:button.tag];
    if ([button isSelected]) {
        [jobCodeObj setValue:[NSNumber numberWithBool:YES] forKey:@"isPrimary"];
        [jobCodeObj setValue:[NSNumber numberWithBool:YES] forKey:@"isSelected"];
    } else {
        [jobCodeObj setValue:[NSNumber numberWithBool:NO] forKey:@"isPrimary"];
        [jobCodeObj setValue:[NSNumber numberWithBool:NO] forKey:@"isSelected"];
    }
}

-(void)tapSelectedButton: (UIButton *)button {
    
    NSIndexPath *indexpath = [NSIndexPath indexPathForRow:button.tag inSection:0];
    AssignEmployeeTableViewCell *cell = [_tableView cellForRowAtIndexPath:indexpath];

    [button setSelected:(![button isSelected])];
    NSDictionary *jobCodeObj = [filterEmployeeList objectAtIndex:button.tag];
    if ([button isSelected]) {
        [jobCodeObj setValue:[NSNumber numberWithBool:YES] forKey:@"isSelected"];
    } else {
        [cell.primaryButton setSelected:([button isSelected])];
        [jobCodeObj setValue:[NSNumber numberWithBool:NO] forKey:@"isSelected"];
        [jobCodeObj setValue:[NSNumber numberWithBool:NO] forKey:@"isPrimary"];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *jobCodeObj = [filterEmployeeList objectAtIndex:indexPath.row];
    NSNumber *numObj = jobCodeObj[@"isSelected"];
    BOOL isSelect = [numObj boolValue];
    if (isSelect) {
        AssignEmployeeTableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
          [cell.selectedButton setSelected:NO];
          [cell.primaryButton setSelected:NO];
          [jobCodeObj setValue:[NSNumber numberWithBool:NO] forKey:@"isSelected"];
          [jobCodeObj setValue:[NSNumber numberWithBool:NO] forKey:@"isPrimary"];
    } else {
        AssignEmployeeTableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
          [cell.selectedButton setSelected:YES];
          [jobCodeObj setValue:[NSNumber numberWithBool:YES] forKey:@"isSelected"];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 50;
}
- (IBAction)doCancelClick:(id)sender {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)doDoneClick:(id)sender {
    
    //here I only add one selection but we need to add all the selected employees to the list
    NSMutableArray *selectedEmployees = [[NSMutableArray alloc] init];
//    for (int i = 0; i < [filterEmployeeList count]; i++)
//    {
//        NSDictionary *empObj = [filterEmployeeList objectAtIndex:i];
//        NSNumber *numObj = empObj[@"isSelected"];
//        BOOL isSelect = [numObj boolValue];
//        if (isSelect) {
//            [selectedEmployees addObject:empObj];
//        }
//    }
    bool canContinue = true;
    selectedEmployees = filterEmployeeList;
    for (NSDictionary *employee in selectedEmployees)
    {
        BOOL isSelected = [employee[@"isSelected"] boolValue];
        BOOL isPrimary = [employee[@"isPrimary"] boolValue];
        if (isSelected && isPrimary)
        {
            NSString *primaryJobCodeTagName = [self doesEmployeeAlreadyHavePrimaryCode: [employee valueForKey:@"employeeId"]];

            if (![NSString isNilOrEmpty:primaryJobCodeTagName])
            {
                NSString *employeeName = [employee valueForKey:@"employeeName"];
                NSString *msg = [NSString stringWithFormat:@"You can not make this job a primary job for %@ because the employee already has %@ assigned as a primary job", employeeName, primaryJobCodeTagName];
                [SharedUICode messageBox:nil message:msg withCompletion:^{
                return;
                }];
                canContinue = false;
                break;
            }
        }
    }
    if (canContinue)
    {
        [_delegate selectedEmployees:selectedEmployees];
        [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    }
}

//for the selected employee loop through all the job codes in the global user.jobCodesList to see if that employee has a primary job for any other job
-(NSString*) doesEmployeeAlreadyHavePrimaryCode: (NSString*) selectedEmployeeId
{
    UserClass *user = [UserClass getInstance];
    NSMutableArray *jobs = user.jobCodesList;
    for (NSDictionary *job in jobs)
    {
        NSMutableArray *assignedEmployeeList = [job valueForKey:@"assignedEmployeeList"];
       for (NSDictionary *employee in assignedEmployeeList)
       {

        NSNumber *primaryJobCode = [employee valueForKey:@"isPrimary"];
        if ([primaryJobCode boolValue])
        {
            NSString *empId = @"";
            NSNumber *value = [employee valueForKey:@"employeeId"];
            if (![NSNumber isNilOrNull:value])
                empId = [[employee valueForKey:@"employeeId"] stringValue];
            if ([selectedEmployeeId isEqualToString:empId])
            {
                NSNumber *primaryJobCodeId = [job valueForKey:@"id"];
                NSNumber *selectedEmployeeJobCodeId = [_jobCodeDetails valueForKey:@"id"];
                //check to make sure it's not the same job code
                if (![NSNumber isEquals:primaryJobCodeId dest:selectedEmployeeJobCodeId])
                {
                    NSString *primaryJobCodeName = [job valueForKey:@"name"];
                    return primaryJobCodeName;
                }
            }
        }
       }
    }
    return nil;
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    if ([searchText isEqualToString: @""]) {
        filterEmployeeList = employeeList;
        [self.view endEditing:YES];
        [self.tableView reloadData];
        
    } else {
        NSMutableArray *filterList = [[NSMutableArray alloc] init];
        for (int i = 0; i < [employeeList count] ; i++)
            {
                NSDictionary *empObj = [employeeList objectAtIndex:i];
                NSString *name = [empObj valueForKey:@"employeeName"];
                if (name.length >= searchText.length)
                {
                    NSRange titleResultsRange = [name rangeOfString:searchText options:NSCaseInsensitiveSearch];
                    if (titleResultsRange.length > 0)
                    {
                        [filterList addObject:empObj];
                    }
                }
            }
        filterEmployeeList = filterList;
        [self.tableView reloadData];
    }
 }

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    filterEmployeeList = employeeList;
    [self.tableView reloadData];
    [self.view endEditing:YES];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [self.view endEditing:YES];
 }
@end
