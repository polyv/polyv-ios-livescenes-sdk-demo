//
//  PLVECBaseNavigationController.m
//  PolyvLiveEcommerceDemo
//
//  Created by Lincal on 2020/4/30.
//  Copyright © 2020 polyv. All rights reserved.
//

#import "PLVECBaseNavigationController.h"

@interface PLVECBaseNavigationController ()

@end

@implementation PLVECBaseNavigationController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (BOOL)shouldAutorotate{
    return [self.visibleViewController shouldAutorotate];
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation{
    return [self.visibleViewController preferredInterfaceOrientationForPresentation];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    if (![self.visibleViewController isKindOfClass:[UIAlertController class]]) {
        return [self.visibleViewController supportedInterfaceOrientations];
    }else{
        return UIInterfaceOrientationMaskPortrait;
    }
}

@end
