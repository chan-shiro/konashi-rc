//
//  KonashiMoroDriveAppDelegate.h
//  KonashiMotorDrive
//
//  Created by Shiro Fukuda on 2013/04/21.
//  Copyright (c) 2013年 chan-shiro. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreMotion/CoreMotion.h>


@interface KonashiMotorDriveAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic, readonly) CMMotionManager *sharedManager;

@end
