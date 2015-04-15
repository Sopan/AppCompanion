//
//  AppDelegate.m
//  AppCompanion
//
//  Created by Sopan Sharma on 4/15/15.
//  Copyright (c) 2015 Sopan Sharma. All rights reserved.
//

#import "AppDelegate.h"
#import <MapKit/MapKit.h>
#import <sys/sysctl.h>


#define kFiringTime 15
#define kProcessNameText @"ProcessName"
#define kAppNameText @"AppName"
#define kCustomURL @"appURL://"
#define kErrorTitle @"URL error"

@interface AppDelegate ()

@property (nonatomic, strong) NSTimer *updateAppTimer;
@property (nonatomic, strong) CLLocationManager *locationManager;

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    [[UIApplication sharedApplication] performSelector:@selector(suspend)];
    [self openCustomURL];
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    return YES;
}


- (void)fireTimer:(NSTimer *)iTimer {
    if (![self checkIfAppRunning]) {
        [self openCustomURL];
    }
    
    [self.locationManager startUpdatingLocation];
    [self.locationManager stopUpdatingLocation];
}


- (void)openCustomURL {
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:kCustomURL]]) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:kCustomURL]];
    } else {
        UIAlertView *anAlertView = [[UIAlertView alloc] initWithTitle:kErrorTitle
                                                              message:[NSString stringWithFormat:
                                                                       @"No custom URL defined for %@", kCustomURL]
                                                             delegate:self cancelButtonTitle:@"Ok"
                                                    otherButtonTitles:nil];
        [anAlertView show];
    }
}


- (BOOL)checkIfAppRunning {
    BOOL aReturnVal = NO;
    for (NSDictionary *aProcessData in [self runningProcesses]) {
        if ([aProcessData[kProcessNameText] isEqualToString:kAppNameText]) {
            aReturnVal = YES;
            break;
        }
    }
    
    return aReturnVal;
}


- (NSArray *)runningProcesses {
    
    int mib[4] = {CTL_KERN, KERN_PROC, KERN_PROC_ALL, 0};
    size_t miblen = 4;
    
    size_t size;
    int st = sysctl(mib, miblen, NULL, &size, NULL, 0);
    
    struct kinfo_proc * process = NULL;
    struct kinfo_proc * newprocess = NULL;
    
    do {
        size += size / 10;
        newprocess = realloc(process, size);
        
        if (!newprocess){
            
            if (process){
                free(process);
            }
            
            return nil;
        }
        
        process = newprocess;
        st = sysctl(mib, miblen, process, &size, NULL, 0);
        
    } while (st == -1 && errno == ENOMEM);
    
    if (st == 0) {
        
        if (size % sizeof(struct kinfo_proc) == 0){
            long nprocess = size / sizeof(struct kinfo_proc);
            
            if (nprocess){
                
                NSMutableArray * array = [[NSMutableArray alloc] init];
                
                for (long i = nprocess - 1; i >= 0; i--){
                    
                    NSString * processID = [[NSString alloc] initWithFormat:@"%d", process[i].kp_proc.p_pid];
                    NSString * processName = [[NSString alloc] initWithFormat:@"%s", process[i].kp_proc.p_comm];
                    
                    NSDictionary * dict = [[NSDictionary alloc] initWithObjects:[NSArray arrayWithObjects:processID, processName, nil]
                                                                        forKeys:[NSArray arrayWithObjects:@"ProcessID", kProcessNameText, nil]];
                    [array addObject:dict];
                }
                
                free(process);
                return array;
            }
        }
    }
    
    return nil;
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    
    UIBackgroundTaskIdentifier aBackgroundTask;
    UIApplication *anApplication = [UIApplication sharedApplication];
    aBackgroundTask = [anApplication beginBackgroundTaskWithExpirationHandler:^{
        [anApplication endBackgroundTask:aBackgroundTask];
    }];
    self.locationManager = [[CLLocationManager alloc] init];
    self.updateAppTimer = [NSTimer scheduledTimerWithTimeInterval:kFiringTime target:self
                                                         selector:@selector(fireTimer:) userInfo:nil repeats:YES];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
