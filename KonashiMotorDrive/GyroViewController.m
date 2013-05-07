//
//  GyroViewController.m
//  KonashiMotorDrive
//
//  Created by Shiro Fukuda on 2013/05/04.
//  Copyright (c) 2013年 chan-shiro. All rights reserved.
//

#import "GyroViewController.h"
#import "Konashi.h"
#import "KonashiMotorDriveAppDelegate.h"

#define MAX_ANGLE 105.0
#define LOOSENESS 5.0
#define GYRO_UPDATE_INTERVAL 0.02
#define PITCH_SENSE -3.5
#define ROLL_SENSE 1.0

static const NSTimeInterval gyroMin = 0.01;

@interface GyroViewController ()

@property (weak, nonatomic) IBOutlet UILabel *rollAngleLabel;
@property (weak, nonatomic) IBOutlet UILabel *pitchAngleLabel;
@property (weak, nonatomic) IBOutlet UILabel *yawAngleLabel;

@end

@implementation GyroViewController

// calibrated values
float croll = 0.0;
float cpitch = 0.0;
float cyaw = 0.0;

// raw values
float roll = 0.0;
float pitch = 0.0;
float yaw = 0.0;

// amount of calibration
float droll = 0.0;
float dpitch = 0.0;
float dyaw = 0.0;

#pragma mark - Override Methods

- (void)disconnected
{
    [super disconnected];
    [self stopUpdates];
}

- (void)afterReady
{
    [self calibPressed:nil];
    [self startGyroUpdate:GYRO_UPDATE_INTERVAL];
}

#pragma mark - Button Actions

- (IBAction)calibPressed:(id)sender
{
    droll = roll;
    dpitch = pitch;
    dyaw = yaw;
}

#pragma mark - Helpers
- (void)startGyroUpdate:(float)interval
{
    NSTimeInterval delta = 1.0;
    NSTimeInterval updateInterval = gyroMin + delta * interval;
    
    CMMotionManager *mManager = [(KonashiMotorDriveAppDelegate *)[[UIApplication sharedApplication] delegate] sharedManager];
    
    if ([mManager isDeviceMotionAvailable] == YES) {
        [mManager setDeviceMotionUpdateInterval:updateInterval];
        [mManager startDeviceMotionUpdatesToQueue:[NSOperationQueue mainQueue] withHandler:^(CMDeviceMotion *deviceMotion, NSError *error) {
            // get raw attitude
            roll = deviceMotion.attitude.roll;
            pitch = deviceMotion.attitude.pitch;
            yaw = deviceMotion.attitude.yaw;
            
            // apply calibration and linearly transform values into [-1, 1]
            croll =  (roll - droll) / M_PI;
            cpitch = (pitch - dpitch) / M_PI;
            cyaw = (yaw - dyaw) / M_PI;
            
            [self setLabelValueRoll:croll pitch:cpitch yaw:cyaw];
            [self updateSpeedWithRoll:croll pitch:cpitch yaw:cyaw];
        }];
    }
    
}

- (void)updateSpeedWithRoll:(float)roll pitch:(float)pitch yaw:(float)yaw
{
    // Calculate absolute value of complex number (pich, roll)

    // adjust pitch for easy and intuitive control
    // value of PITCH_SENSE and ROLL_SENSE needs to be tuned up
    float adjustedPitch = PITCH_SENSE * pitch;
    float adjustedRoll = ROLL_SENSE * roll;
    
    // Set limiter at 1.0 for adjusted values
    adjustedPitch = [self limitAbsoluteValueOf:adjustedPitch max:1.0];
    adjustedRoll = [self limitAbsoluteValueOf:adjustedRoll max:1.0];
    
    
    // pitch contols forward and back
    if (adjustedPitch >= 0)
    {
        [self setForwardState:RIGHT];
        [self setForwardState:LEFT];
    }
    else
    {
        [self setBackwardState:RIGHT];
        [self setBackwardState:LEFT];
    }
    
    
    // roll controls balance of both motors (RIGHT and LEFT)
    float ratioR = 0.0;
    float ratioL = 0.0;
    if (adjustedRoll >=0 )
    {
        // roll value reduces output of one motor
        if (adjustedPitch >= 0)
        {
            // Moving forward
            
            ratioR = adjustedPitch - adjustedRoll;
            
            if (ratioR < 0.0)
            {
                ratioR = 0.0;
            }
        }
        else
        {
            // Moving backward
            
            ratioR = adjustedPitch + adjustedRoll;
            
            if (ratioR > 0.0)
            {
                ratioR = 0.0;
            }
        }
        
        
        [self setDutyRatio:self.onPinL ratio:adjustedPitch dutyLabel:self.dutyLabelL];
        [self setDutyRatio:self.onPinR ratio:ratioR dutyLabel:self.dutyLabelR];
    }
    else if (adjustedRoll < 0)
    {
        // roll value reduces output of one motor
        if (adjustedPitch >= 0)
        {
            ratioL = adjustedPitch + adjustedRoll;
        }
        else
        {
            ratioL = adjustedPitch - adjustedRoll;
        }
        
        if (ratioL < 0)
        {
            // because we are moving backward now
            ratioL = 0.0;
        }
        
        [self setDutyRatio:self.onPinR ratio:adjustedPitch dutyLabel:self.dutyLabelR];
        [self setDutyRatio:self.onPinL ratio:ratioL dutyLabel:self.dutyLabelL];
    }
}

- (float)limitAbsoluteValueOf:(float)value max:(float)maxNum
{
    maxNum = abs(maxNum);
    float returnValue = 0.0;
    if (value > maxNum)
    {
        returnValue = maxNum;
    }
    else if (value < -maxNum)
    {
        returnValue = -maxNum;
    }
    else
    {
        returnValue = value;
    }
    
    return returnValue;
}

- (void)stopUpdates
{
    CMMotionManager *mManager = [(KonashiMotorDriveAppDelegate *)[[UIApplication sharedApplication] delegate] sharedManager];
    
    if ([mManager isDeviceMotionActive] == YES) {
        [mManager stopDeviceMotionUpdates];
    }
}

- (void)setLabelValueRoll:(float)roll pitch:(float)pitch yaw:(float)yaw
{
    self.rollAngleLabel.text = [NSString stringWithFormat:@"%1.3f", roll];
    self.pitchAngleLabel.text = [NSString stringWithFormat:@"%1.3f", pitch];
    self.yawAngleLabel.text = [NSString stringWithFormat:@"%1.3f", yaw];
}

- (int)radianToDegree:(float)radian
{
    float returnValue;
    returnValue = radian / M_PI * 180.0;
    return returnValue;
}

@end
