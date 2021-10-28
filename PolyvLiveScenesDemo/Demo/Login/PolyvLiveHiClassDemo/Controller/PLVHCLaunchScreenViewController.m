//
//  PLVHCLaunchScreenViewController.m
//  PolyvLiveScenesDemo
//
//  Created by Sakya on 2021/9/13.
//  Copyright © 2021 polyv. All rights reserved.
//

#import "PLVHCLaunchScreenViewController.h"

// 工具类
#import "PLVHCDemoUtils.h"

@interface PLVHCLaunchScreenViewController ()

@property (nonatomic, strong) UIImageView *logoImageView;
@property (nonatomic, strong) UILabel *copyrightLable;

@end

@implementation PLVHCLaunchScreenViewController

#pragma mark - [ Life Cycle ]

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.logoImageView];
    [self.view addSubview:self.copyrightLable];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    self.copyrightLable.center = CGPointMake(CGRectGetWidth(self.view.bounds)/2, CGRectGetHeight(self.view.bounds) - CGRectGetHeight(self.copyrightLable.bounds)/2 - 53);
    self.logoImageView.center = CGPointMake(self.copyrightLable.center.x, CGRectGetMinY(self.copyrightLable.frame) - 24 - CGRectGetHeight(self.logoImageView.bounds)/2);
}

#pragma mark - [ Private Method ]


#pragma mark Getter

- (UIImageView *)logoImageView {
    if (!_logoImageView) {
        _logoImageView = [[UIImageView alloc] init];
        _logoImageView.bounds = CGRectMake(0, 0, 141, 40);
        _logoImageView.image = [PLVHCDemoUtils imageForHiClassResource:@"plvhc_launch_image_logo"];
    }
    return _logoImageView;
}

- (UILabel *)copyrightLable {
    if (!_copyrightLable) {
        _copyrightLable = [[UILabel alloc] init];
        _copyrightLable.bounds = CGRectMake(0, 0, 160, 17);
        _copyrightLable.font = [UIFont fontWithName:@"PingFangSC-Regular" size:12];
        _copyrightLable.textAlignment = NSTextAlignmentCenter;
        _copyrightLable.textColor = [UIColor colorWithRed:143/255.0 green:143/255.0 blue:143/255.0 alpha:1];
        _copyrightLable.text = @"© 2013-2021 POLYV保利威";
    }
    return _copyrightLable;
}

@end
