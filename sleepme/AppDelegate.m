//
//  AppDelegate.m
//  sleepme
//
//  Created by Seth Raphael on 12/31/11.
//  Copyright (c) 2011 Bump Technologies. All rights reserved.
//

#import "AppDelegate.h"
#import <IOKit/ps/IOPowerSources.h>
#include <IOKit/pwr_mgt/IOPMLib.h>
#import <notify.h>



@implementation AppDelegate

@synthesize window = _window;

- (void)dealloc
{
    [super dealloc];
}


-(void) addAppAsLoginItem{
	NSString * appPath = [[NSBundle mainBundle] bundlePath];
    
	// This will retrieve the path for the application
	// For example, /Applications/test.app
	CFURLRef url = (CFURLRef)[NSURL fileURLWithPath:appPath]; 
    
	// Create a reference to the shared file list.
    // We are adding it to the current user only.
    // If we want to add it all users, use
    // kLSSharedFileListGlobalLoginItems instead of
    //kLSSharedFileListSessionLoginItems
	LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL,
                                                            kLSSharedFileListSessionLoginItems, NULL);
	if (loginItems) {
		//Insert an item to the list.
		LSSharedFileListItemRef item = LSSharedFileListInsertItemURL(loginItems,
                                                                     kLSSharedFileListItemLast, NULL, NULL,
                                                                     url, NULL, NULL);
		if (item){
			CFRelease(item);
        }
	}	
    
	CFRelease(loginItems);
}

-(void) deleteAppFromLoginItem{
	NSString * appPath = [[NSBundle mainBundle] bundlePath];
    
	// This will retrieve the path for the application
	// For example, /Applications/test.app
	CFURLRef url = (CFURLRef)[NSURL fileURLWithPath:appPath]; 
    
	// Create a reference to the shared file list.
	LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL,
                                                            kLSSharedFileListSessionLoginItems, NULL);
    
	if (loginItems) {
		UInt32 seedValue;
		//Retrieve the list of Login Items and cast them to
		// a NSArray so that it will be easier to iterate.
		NSArray  *loginItemsArray = (NSArray *)LSSharedFileListCopySnapshot(loginItems, &seedValue);
		int i = 0;
		for(i = 0; i< [loginItemsArray count]; i++){
			LSSharedFileListItemRef itemRef = (LSSharedFileListItemRef)[loginItemsArray
                                                                        objectAtIndex:i];
			//Resolve the item with URL
			if (LSSharedFileListItemResolve(itemRef, 0, (CFURLRef*) &url, NULL) == noErr) {
				NSString * urlPath = [(NSURL*)url path];
				if ([urlPath compare:appPath] == NSOrderedSame){
					LSSharedFileListItemRemove(loginItems,itemRef);
				}
			}
		}
		[loginItemsArray release];
	}
}

- (void) sleep;
{
    
    mach_port_t master;
    io_connect_t pmcon;
    
    if (IOMasterPort(bootstrap_port, &master) != kIOReturnSuccess) {
        perror("IOMasterPort() failed");
    }
    
    pmcon = IOPMFindPowerManagement(master);
    if (pmcon == 0) {
        fprintf(stderr, "IOPMFindPowerManagement() failed!\n");
    }
    
    if (IOPMSleepSystem(pmcon) != kIOReturnSuccess) {
        perror("IOPMSleepSystem() failed");
    }

//    system("pmset sleepnow");
}
#define FINE 0
#define WAITING 1
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    
    int outtoken;
    double minMinutes = 3;
    __block double targetSeconds = 0;
    __block int mode = FINE;
    notify_register_dispatch(kIOPSTimeRemainingNotificationKey, &outtoken, dispatch_get_main_queue(), ^(int token) {
        //
        CFTimeInterval remaining = IOPSGetTimeRemainingEstimate();
        IOPSLowBatteryWarningLevel  level = IOPSGetBatteryWarningLevel();
//        NSLog(@"level is %d with remaining time %f", level, remaining);
        if (level == kIOPSLowBatteryWarningNone) {
            mode = FINE;
        }
        if (mode == FINE && level == kIOPSLowBatteryWarningFinal) {
            targetSeconds = .2 * remaining;
            mode = WAITING;
        }
        if (mode == WAITING && remaining > 0 && remaining < targetSeconds) {
            [self sleep];
            mode = FINE;
        }
        if (remaining > 0 && remaining < 60* minMinutes ) {
            [self sleep];
        }
    });
    [self addAppAsLoginItem];
}

//
//kIOPSNotifyLowBattery
//Notify(3) key. The system delivers notifications on this key when the battery time remaining drops into a warnable level.
//
//kIOPSPowerSourcesNotificationKey
//C-string key for a notification that fires when the power source(s) time remaining changes.
//
//kIOPSTimeRemainingNotificationKey
//C-string key for a notification that fires when the power source(s) time remaining changes.
//
//kIOPSTimeRemainingUnknown
//Possible return value from IOPSGetTimeRemainingEstimate
//
//kIOPSTimeRemainingUnlimited
@end
