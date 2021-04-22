//
//  PLVPhotoPreBaseViewController.m
//  zPin_Pro
//
//  Created by zykhbl on 2017/12/17.
//  Copyright © 2017年 zykhbl. All rights reserved.
//

#import "PLVPhotoPreBaseViewController.h"
#import "PLVAlbumTool.h"
#import "PLVPicDefine.h"

@implementation PLVPhotoPreBaseViewController

@synthesize originY;
@synthesize verticalCut;

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = ViewBackgroupColor;
    self.originY = self.navigationController.navigationBar.frame.origin.y + self.navigationController.navigationBar.frame.size.height;
}

- (void)back {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationItem.hidesBackButton = YES;
    self.navigationController.interactivePopGestureRecognizer.enabled = YES;
    self.navigationController.interactivePopGestureRecognizer.delegate = (id)self;
    [PLVAlbumTool leftBarButtonItemAction:@selector(back) target:self];
}

#pragma mark - view controls
- (BOOL)shouldAutorotate {
    return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (BOOL)prefersStatusBarHidden {
    return NO;
}

@end
