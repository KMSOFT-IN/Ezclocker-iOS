//
//  EmployerAutoBreaksTableViewController.m
//  ezClocker
//
//  Created by Raya Khashab on 7/16/22.
//  Copyright © 2022 ezNova Technologies LLC. All rights reserved.
//

#import "EmployerAutoBreaksTableViewController.h"
#import "NSNumber+Extensions.h"

@interface EmployerAutoBreaksTableViewController ()

@end

@implementation EmployerAutoBreaksTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    BOOL isOn = self.ALLOW_AUTOMATIC_BREAKS;
    if (isOn)
        [self.autoBreakSwitch setOn:isOn];
    else
    //disable the option since Auto Break is turned off
    {
        _hoursOptionCellView.contentView.alpha = 0.2;
        _hoursOptionCellView.userInteractionEnabled = NO;
        
        _durationCellView.contentView.alpha = 0.2;
        _durationCellView.userInteractionEnabled = NO;

    }

    if (![NSNumber isNilOrNull: _AUTO_BREAK_WORK_HOURS_OPTION])
        _afterHoursTextField.text =  [self.AUTO_BREAK_WORK_HOURS_OPTION stringValue];
    
    if (![NSNumber isNilOrNull: _AUTO_BREAK_WORK_MINUTES_OPTION])
        _durationBreakTextField.text = [self.AUTO_BREAK_WORK_MINUTES_OPTION stringValue];
    
    UIBarButtonItem* cancelButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(onCancelClick)];
    self.navigationItem.leftBarButtonItem = cancelButton;

    UIBarButtonItem* saveButton = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStylePlain target:self action:@selector(onSaveClick)];
    self.navigationItem.rightBarButtonItem = saveButton;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 01;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 3;
}

-(void) onSaveClick{
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    formatter.numberStyle = NSNumberFormatterNoStyle;
    
    self.ALLOW_AUTOMATIC_BREAKS = _autoBreakSwitch.isOn;
    NSNumber *afterHoursValue = [formatter numberFromString:_afterHoursTextField.text];
    self.AUTO_BREAK_WORK_HOURS_OPTION = afterHoursValue;
    
    NSNumber *breakDurationValue = [formatter numberFromString:_durationBreakTextField.text];
    self.AUTO_BREAK_WORK_MINUTES_OPTION = breakDurationValue;
    
    if ([breakDurationValue intValue] > 30)
    {
        UIAlertController * alert = [UIAlertController
                                     alertControllerWithTitle:@"ERROR"
                                     message:@"Auto Break duration can only be 30 minutes max."
                                     preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];
        
        [alert addAction:defaultAction];
        
        [self presentViewController:alert animated:YES completion:nil];

    }
    else
    {
        [self.delegate saveAutoBreaksOptionsDidFinish:self.ALLOW_AUTOMATIC_BREAKS breakAfterHours:(NSNumber*) self.AUTO_BREAK_WORK_HOURS_OPTION breakDuration: self.AUTO_BREAK_WORK_MINUTES_OPTION];
    }

}

/*
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:<#@"reuseIdentifier"#> forIndexPath:indexPath];
    
    // Configure the cell...
    
    return cell;
}
*/

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

-(void)enableOptions:(BOOL) isEnabled
{
    _hoursOptionCellView.userInteractionEnabled = isEnabled;
    _durationCellView.userInteractionEnabled = isEnabled;
    if (isEnabled)
    {
        _hoursOptionCellView.contentView.alpha = 1.0f;
        _durationCellView.contentView.alpha = 1.0f;
    }
    else
    {
        _hoursOptionCellView.contentView.alpha = 0.2;
        _durationCellView.contentView.alpha = 0.2;
    }
}

- (IBAction)SwitchChanged:(UISwitch *)sender {
    BOOL isOn = sender.isOn;
    if (isOn)
    {
        [self enableOptions:TRUE];
        
        UIStoryboard *story = [UIStoryboard storyboardWithName:@"iPhone" bundle:nil];
        AutoBreakTCViewController *viewController = [story instantiateViewControllerWithIdentifier:@"breakTandC"];
        viewController.delegate = self;

        [self presentViewController:viewController animated:YES completion:nil];
        
    }
    else
    {
        [self enableOptions:FALSE];
    }
}

- (void)autoBreaksTandCDidFinish:(BOOL)userAgreed
{
    [self dismissViewControllerAnimated:YES completion:nil];
    //user has to agree to enable the auto break switch
    if (!userAgreed)
    {
        [_autoBreakSwitch setOn:FALSE];
        [self enableOptions:FALSE];
    }
}

-(void) onCancelClick{
    [self.navigationController popViewControllerAnimated:YES];
}

@end
