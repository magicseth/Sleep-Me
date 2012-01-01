//
//  AppDelegate.m
//  sleepme
//
//  Created by Seth Raphael on 12/31/11.
//  Copyright (c) 2011 Bump Technologies. All rights reserved.
//

#import "AppDelegate.h"
#import <IOKit/ps/IOPowerSources.h>
#import <notify.h>

@implementation AppDelegate

@synthesize window = _window;

- (void)dealloc
{
    [super dealloc];
}

- (void) sleep;
{
    system("pmset sleepnow");
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    
    int outtoken;
    int minMinutes = 10;
    notify_register_dispatch(kIOPSTimeRemainingNotificationKey, &outtoken, dispatch_get_main_queue(), ^(int token) {
        //
        CFTimeInterval remaining = IOPSGetTimeRemainingEstimate();
        IOPSLowBatteryWarningLevel  level = IOPSGetBatteryWarningLevel();
        NSLog(@"level is %d with remaining time %f", level, remaining);
        if ((remaining > 0 && remaining < 60* minMinutes ) || level == kIOPSLowBatteryWarningFinal) {
            [self sleep];
        }
    });
}

@end
