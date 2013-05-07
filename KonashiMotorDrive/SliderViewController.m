//
//  KonashiMoroDriveViewController.m
//  KonashiMotorDrive
//
//  Created by Shiro Fukuda on 2013/04/21.
//  Copyright (c) 2013年 chan-shiro. All rights reserved.
//

#import "SliderViewController.h"
#import "Konashi.h"

@interface SliderViewController ()

@property (weak, nonatomic) IBOutlet UISlider *motorValueR;
@property (weak, nonatomic) IBOutlet UISlider *motorValueL;

@end

@implementation SliderViewController

@synthesize connectBtn = _connectBtn;
@synthesize statusLabel = _statusLabel;
@synthesize motorValueR = _motorValueR;
@synthesize motorValueL = _motorValueL;
@synthesize dutyLabelR = _dutyLabelR;
@synthesize dutyLabelL = _dutyLabelL;

float oldSliderValueR = 0;
float oldSliderValueL = 0;


#pragma mark - Override Methods

- (void)initializer
{
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
    [self stopAllMotor];
}

- (void)disconnected
{
    [super disconnected];
    [self hideControls];
}

- (void)afterReady
{
    [self showControls];
    [self stopAllMotor];
    NSLog(@"Connected");
}

#pragma mark - Button Actions

- (IBAction)sliderTouchUp:(UISlider *)sender
{
    sender.value = 0.0;
    [self updateSpeed:sender];
}

- (IBAction)updateSpeed:(UISlider *)sender
{
    float newSliderValue = (float) sender.value;
    float oldSliderValue = 0;
    int motor = sender.tag; // Detect motor to be controlled by sender tag (RIGHT = 1, LEFT = 2)
    
    if (motor == RIGHT)
    {
        oldSliderValue = oldSliderValueR;
    }
    else if (motor == LEFT)
    {
        oldSliderValue = oldSliderValueL;
    }
    
    // Make dead time if move state has changed
    if (oldSliderValue * newSliderValue <= 0)
    {
        if (newSliderValue > 0)
        {
            [self setForwardState:motor];
        }
        else if (newSliderValue < 0)
        {
            [self setBackwardState:motor];
        }
        else
        {
            [self setStopState:motor];
        }
    }
    
    // Setup move state
    if (motor == RIGHT)
    {
        [self setDutyRatio:self.onPinR ratio:newSliderValue dutyLabel:self.dutyLabelR];
        // Update old state
        oldSliderValueR = newSliderValue;
    }
    else if (motor == LEFT)
    {
        [self setDutyRatio:self.onPinL ratio:newSliderValue dutyLabel:self.dutyLabelL];
        // Update old state
        oldSliderValueL = newSliderValue;
    }

}

- (void)stopAllMotor
{
    self.motorValueR.value = 0.0;
    self.motorValueL.value = 0.0;
    [self updateSpeed:self.motorValueR];
    [self updateSpeed:self.motorValueL];
}

#pragma mark - Helpers

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
