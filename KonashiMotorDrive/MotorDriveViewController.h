//
//  MotorDriveViewController.h
//  KonashiMotorDrive
//
//  Created by Shiro Fukuda on 2013/05/05.
//  Copyright (c) 2013年 chan-shiro. All rights reserved.
//

#import <UIKit/UIKit.h>

#define PWM_PERIOD 20000 // 20ms 50Hz
#define RIGHT 1 // Right slider tag
#define LEFT 2 // Left slider tag

static NSString *const kDisconnect = @"Disconnect";
static NSString *const kFindAndConnect = @"Find & Connect";
static NSString *const kConnected = @"Connected";
static NSString *const kNotConnected = @"Not Connected";

@interface MotorDriveViewController : UIViewController

@property int onPinR;
@property int offPinR;
@property int onPinL;
@property int offPinL;

@property (weak, nonatomic) IBOutlet UILabel *dutyLabelR;
@property (weak, nonatomic) IBOutlet UILabel *dutyLabelL;
@property (weak, nonatomic) IBOutlet UIButton *connectBtn;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;

- (void) initializer;
- (void) disconnected;
- (void) afterReady;
- (void) setForwardState:(int)motor;
- (void) setBackwardState:(int)motor;
- (void) setStopState:(int)motor;
- (void) setDutyRatio:(int)pin ratio:(float)ratio dutyLabel:(UILabel *)dutyLabel;

@end
