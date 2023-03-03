//
//  WizardViewController.m
//  ezClocker
//
//  Created by Raya Khashab on 8/4/15.
//  Copyright (c) 2015 ezNova Technologies LLC. All rights reserved.
//

#import "WizardViewController.h"
#import "LoginViewController.h"

@interface WizardViewController ()

@end

@implementation WizardViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    //#ifdef IPAD_VERSION
    //    _pageImages = @[@"wiz_iPad_welcome.png", @"wiz_iPad_GPS.png", @"wiz_iPad_schedule.png"];
    //#else
    _pageImages = @[@"wiz_welcome.png", @"wiz_iPhone_GPS.png", @"wiz_iPhone_schedule.png"];
    _logoImages = @[@"wiz_welcome_logo.png", @"wiz_GPS_logo.png", @"wiz_Schedule_logo.png"];
    _titleNames = @[@"Welcome to ezClocker!", @"GPS Verification", @"Online scheduling"];
    _subTitleNames = @[@"An easy to use employee time tracking software", @"Use our simple map view to verify the location of your employee's clock in/out", @"Use ezClocker to setup schedules and let your employees view their shift in real time."];
    //#endif
    // Create page view controller
    self.pageViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"PageViewController"];
    self.pageViewController.dataSource = self;
    
    PageContentViewController *startingViewController = [self viewControllerAtIndex:0];
    NSArray *viewControllers = @[startingViewController];
    [self.pageViewController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
    
    //    if (@available(iOS 11.0, *)) {
    //        UIWindow *window = UIApplication.sharedApplication.keyWindow;
    //        CGFloat topPadding = window.safeAreaInsets.top;
    //        CGFloat bottomPadding = window.safeAreaInsets.bottom;
    // Change the size of page view controller
    
    self.pageViewController.view.frame = self.addView.frame;//CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height - (bottomPadding + 70));
    //    }
    
    
    [self addChildViewController:_pageViewController];
    [self.addView addSubview:_pageViewController.view];
    [self.pageViewController didMoveToParentViewController:self];
    
    _getStartedButton.layer.borderColor = [UIColor grayColor].CGColor;
    
    _getStartedButton.layer.borderWidth = 1.0;
    
    _getStartedButton.layer.cornerRadius = 10;
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad && [[UIDevice currentDevice] orientation] != UIDeviceOrientationPortraitUpsideDown && [[UIDevice currentDevice] orientation] != UIDeviceOrientationPortrait) {
        self.widthConstraint.constant = -self.view.frame.size.width / 2;
    }
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)  {
        [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
        [[NSNotificationCenter defaultCenter]
         addObserver:self selector:@selector(orientationChanged:)
         name:UIDeviceOrientationDidChangeNotification
         object:[UIDevice currentDevice]];
    }
    
}

- (void) orientationChanged:(NSNotification *)note
{
    UIDevice * device = note.object;
    switch(device.orientation)
    {
        case UIDeviceOrientationPortrait:
            /* start special animation */
            self.view.backgroundColor = [UIColor whiteColor];
            self.widthConstraint.constant = 0;
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            /* start special animation */
            self.view.backgroundColor = [UIColor whiteColor];
            self.widthConstraint.constant = 0;
            break;
        default:
            self.view.backgroundColor = [UIColor whiteColor];
            self.widthConstraint.constant = -self.view.frame.size.width / 2;
            break;
    };
    [self.view layoutIfNeeded];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (PageContentViewController *)viewControllerAtIndex:(NSUInteger)index
{
    if (([self.pageImages count] == 0) || (index >= [self.pageImages count])) {
    //    [self.delegate wizardViewControllerDidFinish:self];
        return nil;
    }
    
    if (index == [self.pageImages count] - 1)
    {

   //     [self.delegate wizardViewControllerDidFinish:self];
    
  //      return nil;
    }
    
    // Create a new view controller and pass suitable data.
    PageContentViewController *pageContentViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"PageContentController"];
    pageContentViewController.imageFile = self.pageImages[index];
    pageContentViewController.imageLogoFile = self.logoImages[index];
    pageContentViewController.titleFile = self.titleNames[index];
    pageContentViewController.subTitleFile = self.subTitleNames[index];

  //  pageContentViewController.titleText = self.pageTitles[index];
    pageContentViewController.pageIndex = index;
    
    return pageContentViewController;
}
#pragma mark - Page View Controller Data Source

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController
{
    NSUInteger index = ((PageContentViewController*) viewController).pageIndex;
    
    if ((index == 0) || (index == NSNotFound)) {
        return nil;
    }
    
    index--;
    return [self viewControllerAtIndex:index];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{
    NSUInteger index = ((PageContentViewController*) viewController).pageIndex;
    
    if (index == NSNotFound) {
        return nil;
    }
    
    index++;
    return [self viewControllerAtIndex:index];
}

/*- (PageContentViewController *)viewControllerAtIndex:(NSUInteger)index
{
    if (([self.pageImages count] == 0) || (index >= [self.pageImages count])) {
        return nil;
    }
    
    // Create a new view controller and pass suitable data.
    PageContentViewController *pageContentViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"PageContentController"];
    pageContentViewController.imageFile = self.pageImages[index];
    pageContentViewController.pageIndex = index;
    
    return pageContentViewController;
}
#pragma mark - Page View Controller Data Source

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController
{
    NSUInteger index = ((PageContentViewController*) viewController).pageIndex;
    
    if ((index == 0) || (index == NSNotFound)) {
        return nil;
    }
    
    index--;
    return [self viewControllerAtIndex:index];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{
    NSUInteger index = ((PageContentViewController*) viewController).pageIndex;
    
    if (index == NSNotFound) {
        return nil;
    }
    
    index++;
    return [self viewControllerAtIndex:index];
}
*/
- (NSInteger)presentationCountForPageViewController:(UIPageViewController *)pageViewController
{
    return [self.pageImages count];
}

- (NSInteger)presentationIndexForPageViewController:(UIPageViewController *)pageViewController
{
    return 0;
}

- (IBAction)startWalkthrough:(id)sender {
    PageContentViewController *startingViewController = [self viewControllerAtIndex:0];
    NSArray *viewControllers = @[startingViewController];
    [self.pageViewController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionReverse animated:NO completion:nil];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)doGetStarted:(id)sender {
    [self.delegate wizardViewControllerDidFinish:self];
}
@end
