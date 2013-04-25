//
//  KonashiMoroDriveViewController.m
//  KonashiMotorDrive
//
//  Created by Shiro Fukuda on 2013/04/21.
//  Copyright (c) 2013年 chan-shiro. All rights reserved.
//

#import "KonashiMoroDriveViewController.h"

#define PWM_PERIOD 2000 // 2000us 500Hz
#define RIGHT_SLIDER 1 // Right slider tag
#define LEFT_SLIDER 2 // Left slider tag

NSString *const kDisconnect = @"Disconnect";
NSString *const kFindAndConnect = @"Find & Connect";
NSString *const kConnected = @"Connected";
NSString *const kNotConnected = @"Not Connected";

@interface KonashiMoroDriveViewController ()

@end

@implementation KonashiMoroDriveViewController

@synthesize connectBtn = _connectBtn;
@synthesize statusLabel = _statusLabel;
@synthesize motorValueR = _motorValueR;
@synthesize motorValueL = _motorValueL;
@synthesize dutyLabelR = _dutyLabelR;
@synthesize dutyLabelL = _dutyLabelL;

float oldSliderValueR = 0;
float oldSliderValueL = 0;
int onPinR;
int offPinR;
int onPinL;
int offPinL;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [Konashi initialize];
    // Setup Konashi observers
    [Konashi addObserver:self selector:@selector(ready) name:KONASHI_EVENT_READY];
    [Konashi addObserver:self selector:@selector(disconnected) name:KONASHI_EVENT_DISCONNECTED];
    
    // Rotate Sliders
    self.motorValueR.transform = CGAffineTransformMakeRotation(-M_PI * 0.5);
    self.motorValueL.transform = CGAffineTransformMakeRotation(-M_PI * 0.5);

    // Setup labels
    self.connectBtn.titleLabel.text = kFindAndConnect;
    self.statusLabel.text = kNotConnected;
    
    // Setup slidebar value
    // Slidebar absolute value is duty ratio (0.0 to 1.0)
    // Slidebar sign is move mode (forward(+) backward(-))
    self.motorValueR.maximumValue = 1.0;
    self.motorValueR.minimumValue = -1.0;
    self.motorValueR.value = 0;
    self.motorValueL.maximumValue = 1.0;
    self.motorValueL.minimumValue = -1.0;
    self.motorValueL.value = 0;
    oldSliderValueR = self.motorValueR.value;
    oldSliderValueL = self.motorValueL.value;
    
    [self hideControls];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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

- (IBAction)sliderTouchUp:(UISlider *)sender
{
    sender.value = 0.0;
    [self updateSpeed:sender];
}

- (IBAction)updateSpeed:(UISlider *)sender
{
    float newSliderValue = (float) sender.value;
    float oldSliderValue = 0;
    int tag = sender.tag;
    
    if (tag == RIGHT_SLIDER)
    {
        oldSliderValue = oldSliderValueR;
    }
    else if (tag == LEFT_SLIDER)
    {
        oldSliderValue = oldSliderValueL;
    }
    
    // Make dead time if move state has changed
    if (oldSliderValue * newSliderValue <= 0)
    {
        [self makeDeadTime:tag];

        if (newSliderValue > 0)
        {
            [self setForwardState:tag];
        }
        else if (newSliderValue < 0)
        {
            [self setBackwardState:tag];
        }
        else
        {
            [self setStopState:tag];
        }
    }
    
    // Setup move state
    if (tag == RIGHT_SLIDER)
    {
        [self setDutyRatio:onPinR ratio:newSliderValue dutyLabel:self.dutyLabelR];
        // Update old state
        oldSliderValueR = newSliderValue;
    }
    else if (tag == LEFT_SLIDER)
    {
        [self setDutyRatio:onPinL ratio:newSliderValue dutyLabel:self.dutyLabelL];
        // Update old state
        oldSliderValueL = newSliderValue;
    }

}

- (IBAction)stopPressed:(id)sender
{
    self.motorValueR.value = 0.0;
    self.motorValueL.value = 0.0;
    [self updateSpeed:self.motorValueR];
    [self updateSpeed:self.motorValueL];
}


#pragma mark - Konashi Observer
- (void)ready
{
    self.connectBtn.titleLabel.text = kDisconnect;
    self.statusLabel.text = kConnected;
    
    
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
    
    [self showControls];
    [self stopPressed:nil];
    NSLog(@"Connected");
}

- (void)disconnected
{
    self.connectBtn.titleLabel.text = kFindAndConnect;
    self.statusLabel.text = kNotConnected;
    
    [self hideControls];
}

#pragma mark - Helpers

- (void)setDutyRatio:(int)pin ratio:(float)ratio dutyLabel:(UILabel *)dutyLabel
{
    int duty;
    duty = abs((int)(ratio * PWM_PERIOD));
    [self setDutyRatio:pin ratio:ratio];
    dutyLabel.text = [NSString stringWithFormat:@"%.2f", ratio];
}

- (void)setDutyRatio:(int)pin ratio:(float)ratio
{
    int duty;
    duty = abs((int)(ratio * PWM_PERIOD));
    [Konashi pwmDuty:pin duty:duty];
}

- (void)setStopState:(int)tag
{
    // Stop PWM mode
    if (tag == RIGHT_SLIDER)
    {
        [self setDutyRatio:PIO6 ratio:0.0 dutyLabel:self.dutyLabelR];
        [self setDutyRatio:PIO7 ratio:0.0 dutyLabel:self.dutyLabelR];
    }
    else if (tag == LEFT_SLIDER)
    {
        [self setDutyRatio:PIO4 ratio:0.0 dutyLabel:self.dutyLabelL];
        [self setDutyRatio:PIO5 ratio:0.0 dutyLabel:self.dutyLabelL];
    }
}

- (void)setForwardState:(int)tag
{
    if (tag == RIGHT_SLIDER)
    {
        onPinR = PIO6;
        offPinR = PIO7;
        [self setUpState:onPinR off:offPinR tag:tag];
    }
    else if (tag == LEFT_SLIDER)
    {
        onPinL = PIO4;
        offPinL = PIO5;
        [self setUpState:onPinL off:offPinL tag:tag];
    }
}

- (void)setBackwardState:(int)tag
{
    if (tag == RIGHT_SLIDER)
    {
        onPinR = PIO7;
        offPinR = PIO6;
        [self setUpState:onPinR off:offPinR tag:tag];
    }
    else if (tag == LEFT_SLIDER)
    {
        onPinL = PIO5;
        offPinL = PIO4;
        [self setUpState:onPinL off:offPinL tag:tag];
    }
}

- (void)setUpState:(int)onPin off:(int)offPin tag:(int)tag
{
    if (tag == RIGHT_SLIDER)
    {
        [self setDutyRatio:offPin ratio:0.0 dutyLabel:self.dutyLabelR];
    }
    else if (tag == LEFT_SLIDER)
    {
        [self setDutyRatio:offPin ratio:0.0 dutyLabel:self.dutyLabelL];
    }
}

- (void)makeDeadTime:(int)tag
{
    [self setStopState:tag]; // Dead
    // [NSThread sleepForTimeInterval:0.001]; // Sleep 10ms
}

- (void)hideControls
{
    [self setVisibilityOfControls:NO];
}

- (void)showControls
{
    [self setVisibilityOfControls:YES];
}

- (void)setVisibilityOfControls:(BOOL)value
{
    self.motorValueR.hidden = !value;
    self.motorValueL.hidden = !value;
    self.dutyLabelR.hidden = !value;
    self.dutyLabelL.hidden = !value;
}

@end
