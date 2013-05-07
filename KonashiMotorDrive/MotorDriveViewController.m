//
//  MotorDriveViewController.m
//  KonashiMotorDrive
//
//  Created by Shiro Fukuda on 2013/05/05.
//  Copyright (c) 2013年 chan-shiro. All rights reserved.
//

#import "MotorDriveViewController.h"
#import "Konashi.h"

@interface MotorDriveViewController ()

@end

@implementation MotorDriveViewController

@synthesize onPinL = _onPinL;
@synthesize onPinR = _onPinR;
@synthesize offPinL = _offPinL;
@synthesize offPinR = _offPinR;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [Konashi initialize];
    // Setup Konashi observers
    [Konashi addObserver:self selector:@selector(ready) name:KONASHI_EVENT_READY];
    [Konashi addObserver:self selector:@selector(disconnected) name:KONASHI_EVENT_DISCONNECTED];
    
    [self initializer];
}

- (void)viewWillAppear:(BOOL)animated
{
    [Konashi initialize];
    // Setup Konashi observers
    [Konashi addObserver:self selector:@selector(ready) name:KONASHI_EVENT_READY];
    [Konashi addObserver:self selector:@selector(disconnected) name:KONASHI_EVENT_DISCONNECTED];
    
    [self initializer];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillDisappear:(BOOL)animated
{
    [Konashi removeObserver:self];
    [Konashi disconnect];
    [self disconnected];
}

#pragma mark - Interface

- (void) initializer
{
    return;
}

- (void) disconnected
{
    self.connectBtn.titleLabel.text = kFindAndConnect;
    self.statusLabel.text = kNotConnected;
}

- (void) afterReady
{
    return;
}

#pragma mark - Button Actions

- (IBAction)find:(UIButton *)sender
{
    if ([sender.titleLabel.text isEqualToString:kFindAndConnect])
    {
        [Konashi find];
    }
    else if ([sender.titleLabel.text isEqualToString:kDisconnect])
    {
        [Konashi disconnect];
    }
}

#pragma mark - Konashi Observer
- (void)ready
{
    
    // Setup PINs
    // PIO6 must be connected to pin5 of TA7291P and PIO7 to pin6
    // if PIO6 == LOW && PIO7 == LOW, stop motor
    // else if PIO6 == HIGH && PIO7 == LOW, move forward
    // else if PIO6 == LOW && PIO7 == HIGH, move backward
    // OUTPUT POWER is controled by PWM of each PIN
    
    // RIGHT MOTOR
    [Konashi pinMode:PIO6 mode:OUTPUT]; // to TA7291P pin5
    [Konashi pinMode:PIO7 mode:OUTPUT]; // to TA7291P pin6
    
    // Set up PWM period and initial duty
    [Konashi pwmPeriod:PIO6 period:PWM_PERIOD];
    [Konashi pwmPeriod:PIO7 period:PWM_PERIOD];
    
    // Set initial duty time (us) to 0
    [Konashi pwmDuty:PIO6 duty:0];
    [Konashi pwmDuty:PIO7 duty:0];
    
    // Enable PWM mode to avoid unwanted pin action
    [Konashi pwmMode:PIO6 mode:KONASHI_PWM_ENABLE];
    [Konashi pwmMode:PIO7 mode:KONASHI_PWM_ENABLE];
    
    // LEFT MOTOR
    [Konashi pinMode:PIO4 mode:OUTPUT]; // to TA7291P pin5
    [Konashi pinMode:PIO5 mode:OUTPUT]; // to TA7291P pin6
    
    
    // Set up PWM period and initial duty
    [Konashi pwmPeriod:PIO4 period:PWM_PERIOD];
    [Konashi pwmPeriod:PIO5 period:PWM_PERIOD];
    
    // Set initial duty time (us) to 0
    [Konashi pwmDuty:PIO4 duty:0];
    [Konashi pwmDuty:PIO5 duty:0];
    
    // Enable PWM mode to avoid unwanted pin action
    [Konashi pwmMode:PIO4 mode:KONASHI_PWM_ENABLE];
    [Konashi pwmMode:PIO5 mode:KONASHI_PWM_ENABLE];
    [Konashi digitalWrite:PIO4 value:LOW];
    [Konashi digitalWrite:PIO5 value:LOW];
    
    [Konashi pinMode:S1 mode:INPUT];
    self.connectBtn.titleLabel.text = kDisconnect;
    self.statusLabel.text = kConnected;

    [self afterReady];
}

#pragma mark - Helpers

- (void)setDutyRatio:(int)pin ratio:(float)ratio dutyLabel:(UILabel *)dutyLabel
{
    [self setDutyRatio:pin ratio:ratio];
    dutyLabel.text = [NSString stringWithFormat:@"%.2f", ratio];
}

- (void)setDutyRatio:(int)pin ratio:(float)ratio
{
    int duty;
    duty = abs((int)(ratio * PWM_PERIOD));
    [Konashi pwmDuty:pin duty:duty];
}

- (void)setStopState:(int)motor
{
    // Stop PWM mode
    if (motor == RIGHT)
    {
        [self setDutyRatio:PIO6 ratio:0.0 dutyLabel:self.dutyLabelR];
        [self setDutyRatio:PIO7 ratio:0.0 dutyLabel:self.dutyLabelR];
    }
    else if (motor == LEFT)
    {
        [self setDutyRatio:PIO4 ratio:0.0 dutyLabel:self.dutyLabelL];
        [self setDutyRatio:PIO5 ratio:0.0 dutyLabel:self.dutyLabelL];
    }
}

- (void)setForwardState:(int)motor
{
    if (motor == RIGHT)
    {
        self.onPinR = PIO7;
        self.offPinR = PIO6;
        [self setUpState:self.onPinR off:self.offPinR motor:motor];
    }
    else if (motor == LEFT)
    {
        self.onPinL = PIO5;
        self.offPinL = PIO4;
        [self setUpState:self.onPinL off:self.offPinL motor:motor];
    }
}

- (void)setBackwardState:(int)motor
{
    if (motor == RIGHT)
    {
        self.onPinR = PIO6;
        self.offPinR = PIO7;
        [self setUpState:self.onPinR off:self.offPinR motor:motor];
    }
    else if (motor == LEFT)
    {
        self.onPinL = PIO4;
        self.offPinL = PIO5;
        [self setUpState:self.onPinL off:self.offPinL motor:motor];
    }
}

- (void)setUpState:(int)onPin off:(int)offPin motor:(int)motor
{
    if (motor == RIGHT)
    {
        [self setDutyRatio:offPin ratio:0.0 dutyLabel:self.dutyLabelR];
    }
    else if (motor == LEFT)
    {
        [self setDutyRatio:offPin ratio:0.0 dutyLabel:self.dutyLabelL];
    }
}

@end
