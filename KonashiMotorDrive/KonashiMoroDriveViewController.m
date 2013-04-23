//
//  KonashiMoroDriveViewController.m
//  KonashiMotorDrive
//
//  Created by Shiro Fukuda on 2013/04/21.
//  Copyright (c) 2013年 chan-shiro. All rights reserved.
//

#import "KonashiMoroDriveViewController.h"

NSString *const kDisconnect = @"Disconnect";
NSString *const kFindAndConnect = @"Find & Connect";
NSString *const kConnected = @"Connected";
NSString *const kNotConnected = @"Not Connected";

@interface KonashiMoroDriveViewController ()

@end

@implementation KonashiMoroDriveViewController

@synthesize connectBtn = _connectBtn;
@synthesize statusLabel = _statusLabel;
@synthesize motorValue = _motorValue;
@synthesize stopBtn = _stopBtn;
@synthesize backLabel = _backLabel;
@synthesize forwardLabel = _forwardLabel;
@synthesize stopLabel = _stopLabel;
@synthesize stateLabel = _stateLabel;
@synthesize analogValueLabel = _analogValueLabel;
@synthesize analogWriteLable = _analogWriteLable;

int oldSliderValue;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [Konashi initialize];
    // Setup Konashi observers
    [Konashi addObserver:self selector:@selector(ready) name:KONASHI_EVENT_READY];
    [Konashi addObserver:self selector:@selector(disconnected) name:KONASHI_EVENT_DISCONNECTED];
    [Konashi addObserver:self selector:@selector(pio_updated) name:KONASHI_EVENT_UPDATE_PIO_INPUT];

    // Setup labels
    self.connectBtn.titleLabel.text = kFindAndConnect;
    self.statusLabel.text = kNotConnected;
    self.motorValue.maximumValue = KONASHI_ANALOG_REFERENCE;
    self.motorValue.minimumValue = -KONASHI_ANALOG_REFERENCE;
    self.motorValue.value = 0;
    oldSliderValue = (int) self.motorValue.value;
    
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

- (IBAction)updateSpeed:(UISlider *)sender
{
    int newSliderValue = (int) sender.value;
    
    // Make dead time if move state has changed
    if (oldSliderValue * newSliderValue <= 0)
    {
        [self makeDeadTime];

        if (newSliderValue > 0)
        {
            [self setForwardState];
        }
        else if (newSliderValue < 0)
        {
            [self setBackwardState];
        }
        else
        {
            [self setStopState];
        }
    }
    
    // Setup move state
    // Update Vref voltage
    // Output milliVolt must be POSITIVE value
    [Konashi analogWrite:AIO0 milliVolt:abs(newSliderValue)];
    self.analogValueLabel.text = [NSString stringWithFormat:@"%d mV", abs(newSliderValue)];

    // Update old state
    oldSliderValue = newSliderValue;
}

- (IBAction)stopPressed:(id)sender
{
    self.motorValue.value = 0;
    [self updateSpeed:self.motorValue];
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
    [Konashi pinMode:PIO6 mode:OUTPUT]; // to TA7291P pin5
    [Konashi pinMode:PIO7 mode:OUTPUT]; // to TA7291P pin6
    [Konashi pinMode:LED2 mode:OUTPUT];
    [Konashi pinMode:LED3 mode:OUTPUT];
    
    // AIO0 must be connected to pin4 of TA7291P and controls output voltage to motor
    [Konashi pinMode:AIO0 mode:OUTPUT]; // to TA7291P pin4
    
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

- (void)pio_updated
{
    NSLog(@"Yup!");
    if ([Konashi digitalRead:PIO0] == HIGH)
    {
        NSLog(@"Hey Man");
        [self stopPressed:nil];
    }
}


#pragma mark - Helpers

- (void)setStopState
{
    [Konashi digitalWrite:PIO6 value:LOW];
    [Konashi digitalWrite:PIO7 value:LOW];
    self.stateLabel.text = @"Stop";
    [Konashi digitalWrite:LED2 value:LOW];
    [Konashi digitalWrite:LED3 value:LOW];
}

- (void)setForwardState
{
    [Konashi digitalWrite:PIO6 value:HIGH];
    [Konashi digitalWrite:PIO7 value:LOW];
    self.stateLabel.text = @"Forward";
    [Konashi digitalWrite:LED2 value:HIGH];
    [Konashi digitalWrite:LED3 value:LOW];
}

- (void)setBackwardState
{
    [Konashi digitalWrite:PIO6 value:LOW];
    [Konashi digitalWrite:PIO7 value:HIGH];
    self.stateLabel.text = @"Back";
    [Konashi digitalWrite:LED2 value:LOW];
    [Konashi digitalWrite:LED3 value:HIGH];
}

- (void)makeDeadTime
{
    [self setStopState]; // Dead
    [NSThread sleepForTimeInterval:0.01]; // Sleep 10ms
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
    self.stopBtn.hidden = !value;
    self.stopLabel.hidden = !value;
    self.forwardLabel.hidden = !value;
    self.backLabel.hidden = !value;
    self.motorValue.hidden = !value;
    self.stateLabel.hidden = !value;
    self.analogWriteLable.hidden = !value;
    self.analogValueLabel.hidden = !value;
}

@end
