//
//  PLVHCNavigationController.m
//  PolyvLiveScenesDemo
//
//  Created by 黄佳玮 on 2021/7/31.
//  Copyright © 2021 polyv. All rights reserved.
//

#import "PLVHCNavigationController.h"

@interface PLVHCNavigationController ()

@end

@implementation PLVHCNavigationController

- (void)viewDidLoad {
    [super viewDidLoad];
}

#pragma mark - [ Override ]

- (BOOL)shouldAutorotate {
    return self.topViewController.shouldAutorotate;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return self.topViewController.supportedInterfaceOrientations;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return self.topViewController.preferredInterfaceOrientationForPresentation;
}


@end
