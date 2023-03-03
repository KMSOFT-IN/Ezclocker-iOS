//
//  BreakViewController.m
//  ezClocker
//
//  Created by Raya Khashab on 12/11/21.
//  Copyright © 2021 ezNova Technologies LLC. All rights reserved.
//

#import "BreakViewController.h"
#import "CommonLib.h"
#import "NSDate+Extensions.h"
#import "ECSlidingViewController.h"

@interface BreakViewController ()

@end

@implementation BreakViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    _breakOutBtn.backgroundColor = UIColorFromRGB(BREAK_BLUE_COLOR);
    _clockOutBtn.backgroundColor = UIColorFromRGB(ORANGE_COLOR);
  
    [_timerLabel setFont:[UIFont fontWithName:@"Helvetica-Bold" size:36.0f]];
    running = FALSE;
    if (@available(iOS 15.0, *)) {
//        _tableView.sectionHeaderTopPadding = 0;
    }
  //  self.navigationItem.leftBarButtonItems = [[NSArray alloc] init];
  //[self.navigationItem setHidesBackButton:YES animated:NO];
    
 /*   NSDate *preDate = [NSUserDefaults.standardUserDefaults valueForKey:@"CurrentTime"];
    if (preDate != nil) {
        _timerLabel.text = @"00.00.00";
        startDate = preDate;
    } else  {
        [NSUserDefaults.standardUserDefaults setValue:[NSDate date] forKey:@"CurrentTime"];
        [NSUserDefaults.standardUserDefaults synchronize];
        _timerLabel.text = @"00.00.00";
        startDate = [NSDate date];
    }
  */
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if(!running){
        running = TRUE;
 //       [sender setTitle:@"Stop" forState:UIControlStateNormal];
        if (stopTimer == nil) {
            stopTimer = [NSTimer scheduledTimerWithTimeInterval:1.0/10.0
                                                         target:self
                                                       selector:@selector(updateTimer)
                                                       userInfo:nil
                                                        repeats:YES];
        }
    }else{
        running = FALSE;
 //       [sender setTitle:@"Start" forState:UIControlStateNormal];
        [stopTimer invalidate];
        stopTimer = nil;
    }

}

-(NSString *) formatInterval: (NSTimeInterval) interval{
    unsigned long milliseconds = interval;
  //  unsigned long seconds = milliseconds / 1000;
    unsigned long seconds = interval / 1000;
    unsigned long minutes = seconds / 60;
    unsigned long hours = minutes / 60;
    minutes %= 60;
    NSString *duration = [NSString stringWithFormat:@"%ldhrs %ldmins", hours, minutes];
    return duration;
}

- (int) daysBetweenDates: (NSDate *)startDate currentDate: (NSDate *)endDate
{
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *dateComponent = [calendar components:NSCalendarUnitDay fromDate:startDate toDate:endDate options:0];

    int totalDays = (int)dateComponent.day;
    return totalDays;

}

-(void) updateTimer {
     NSDate *currentDate = [NSDate date];
     NSTimeInterval timeInterval = [currentDate timeIntervalSinceDate:_breakInTime];
     double secondsInAnHour = 3600;
     NSInteger hoursBetweenDates = timeInterval / secondsInAnHour;

//     NSTimeInterval timeInterval = [currentDate timeIntervalSinceDate:_breakInTime];
     NSDate *timerDate = [NSDate dateWithTimeIntervalSince1970:timeInterval];
     NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"mm:ss"];
    [dateFormatter setTimeZone: [NSTimeZone timeZoneForSecondsFromGMT:0.0]];
     NSString *mmss=[dateFormatter stringFromDate:timerDate];
    NSString *timeString = [NSString stringWithFormat:@"%ld:%@", hoursBetweenDates, mmss];
    _timerLabel.text = timeString;
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/



- (IBAction)revealMenu:(id)sender {
    [self.slidingViewController anchorTopViewTo:ECRight];

}

- (IBAction)doEndBreakClick:(id)sender {
    [NSUserDefaults.standardUserDefaults removeObjectForKey:@"CurrentTime"];
    [_delegate breakScreenDone];
}


+(UINavigationController *) getInstance {
    UINavigationController* webViewContrtoller = [[UIStoryboard storyboardWithName:@"Web" bundle:nil] instantiateViewControllerWithIdentifier:@"WebNavigation"];
    return webViewContrtoller;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return @"Clock-in Time";
    }
    else if (section == 1) {
        return @"Break Start Time";
    }
    else {
        return @"";
    }
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 30;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    //this is to fix the large font issue with iPhone PLUS
    if (cell.textLabel.font.pointSize > 20)
        [cell.textLabel setFont:[UIFont fontWithName:@"Helvetica-Bold" size:20.0]];
    if (indexPath.section == 0) {
      //  NSDate *startDate = [NSUserDefaults.standardUserDefaults valueForKey:@"CurrentTime"];
        cell.textLabel.text = [NSString stringWithFormat:@"IN:     %@",_strClockInTime];
    }
    else if (indexPath.section == 1) {
        cell.textLabel.text = [NSString stringWithFormat:@"IN:     %@",_strBreakInTime];
    }
    return cell;
}



@end
