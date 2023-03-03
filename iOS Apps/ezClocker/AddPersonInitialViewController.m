//
//  AddPersonInitialViewController.m
//  ezClocker
//
//  Created by Raya Khashab on 11/9/15.
//  Copyright © 2015 ezNova Technologies LLC. All rights reserved.
//

#import "AddPersonInitialViewController.h"
#import "AddEmployeeViewController.h"
#import "ECSlidingViewController.h"
#import "MenuViewController.h"
#import "PushNotificationManager.h"
#import "WebViewController.h"

@interface AddPersonInitialViewController ()

@end

@implementation AddPersonInitialViewController

- (void)viewDidLoad {
    [super viewDidLoad];
   
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addPerson)];
    self.navigationItem.rightBarButtonItem = addButton;
    
    [self addShadow:self.watchDemoView];
    [self addShadow:self.addEmployeeView];
}

-(void) addShadow:(UIView *) sView {
    sView.layer.shadowRadius  = 20.0f;
    sView.layer.shadowColor   = [UIColor blackColor].CGColor;
    sView.layer.shadowOffset  = CGSizeMake(0.0f, 0.0f);
    sView.layer.shadowOpacity = 0.40f;
    sView.layer.masksToBounds = NO;

    UIEdgeInsets shadowInsets     = UIEdgeInsetsMake(0, 0, -1.5f, 0);
    UIBezierPath *shadowPath      = [UIBezierPath bezierPathWithRect:UIEdgeInsetsInsetRect(sView.bounds, shadowInsets)];
    sView.layer.shadowPath    = shadowPath.CGPath;
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(id)initWithCoder:(NSCoder *)decoder {
    self = [super initWithCoder:decoder];
    if (self){
        [[UINavigationBar appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor whiteColor]}];
        self.title = NSLocalizedString(@"Employees", @"Employees");
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (![self.slidingViewController.underLeftViewController isKindOfClass:[MenuViewController class]]) {
        self.slidingViewController.underLeftViewController  = [self.storyboard instantiateViewControllerWithIdentifier:@"Menu"];
    }
    
    self.slidingViewController.underRightViewController = nil;
    [self.view addGestureRecognizer:self.slidingViewController.panGesture];
    
    PushNotificationManager* manager = [PushNotificationManager sharedManager];
    [manager registerForPushNotification:^(BOOL successful, NSError *error) {
        
    }];
    
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
 -(void) addPerson
{
    AddEmployeeViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"AddEmployee"];
    
    UINavigationController *addEmployeeNavigationController = [[UINavigationController alloc] initWithRootViewController:controller];
    
    
    controller.delegate = (id) self;
    controller.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    
    [self presentViewController:addEmployeeNavigationController animated:YES completion:nil];

}
- (IBAction)doAddPerson:(UIButton *)sender {
    [self addPerson];
}

- (IBAction)watchDemoVideo:(UIButton *)sender {
    [self watchVideo];
}

- (void) watchVideo {
    [[AVAudioSession sharedInstance]
                setCategory: AVAudioSessionCategoryPlayback
                      error: nil];
//    NSURL* vedioURL = [[NSBundle mainBundle] URLForResource:@"iPhone_overview_App_Preview" withExtension:@"mp4"];
//    [CommonLib logEvent:@"View overview demo"];
//    AVPlayerItem* playerItem = [AVPlayerItem playerItemWithURL:vedioURL];
//    AVPlayer* playVideo = [[AVPlayer alloc] initWithPlayerItem:playerItem];
//    self.playerViewController = [[AVPlayerViewController alloc] init];
//    self.playerViewController.player = playVideo;
//    self.playerViewController.view.frame = self.view.bounds;
//    [self presentViewController:self.playerViewController animated:YES completion:^{
//
//    }];
    //[self.view addSubview:self.playerViewController.view];
//    [playVideo play];
    
    [CommonLib logEvent:@"View overview demo"];
    NSURL* videoURL = [[NSBundle mainBundle] URLForResource:@"iPhone_overview_App_Preview" withExtension:@"html"];
    UINavigationController* navController = [WebViewController getInstance];
    WebViewController* webController = (WebViewController *)[navController viewControllers].firstObject;
    navController.modalPresentationStyle = UIModalPresentationFullScreen;
    webController.url = videoURL;
    [self presentViewController:navController animated:YES completion:nil];
}

//- (void)safariViewControllerDidFinish:(SFSafariViewController *)controller {
//    [self dismissViewControllerAnimated:true completion:nil];
//}

- (void)addEmployeeViewControllerDidFinish:(UIViewController *)controller CancelWasSelected:(bool)cancelWasSelected
{
    [self dismissViewControllerAnimated:YES completion:nil];
    //call the initial view controller so it can switch the views to using employeeList
    [self.delegate newEmployeeAdded:self];

}


@end
