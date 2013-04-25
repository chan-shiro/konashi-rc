//
//  KonashiMoroDriveViewController.h
//  KonashiMotorDrive
//
//  Created by Shiro Fukuda on 2013/04/21.
//  Copyright (c) 2013年 chan-shiro. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Konashi.h"

@interface KonashiMoroDriveViewController : UIViewController

- (IBAction)find:(id)sender;

@property (weak, nonatomic) IBOutlet UIButton *connectBtn;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UISlider *motorValueR;
@property (weak, nonatomic) IBOutlet UISlider *motorValueL;
@property (weak, nonatomic) IBOutlet UILabel *dutyLabelR;
@property (weak, nonatomic) IBOutlet UILabel *dutyLabelL;


@end
