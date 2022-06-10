//
//  PLVSABeautyBaseViewController.m
//  PolyvLiveScenesDemo
//
//  Created by lijingtong on 2022/4/19.
//  Copyright © 2022 PLV. All rights reserved.
//

#import "PLVSABeautyBaseViewController.h"

@implementation PLVSABeautyBaseViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupDataArray];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.view.frame = CGRectMake(1, 0, self.view.bounds.size.width - 2, self.view.bounds.size.height); // 左右设置一个像素间距，避免页面与左右页面相连在一起
}

- (void)setupDataArray {
    // 由子类处理
}

- (void)showContentView {
    // 由子类处理
}

- (void)beautyOpen:(BOOL)open {
    // 由子类处理
}

- (void)resetBeauty {
    // 由子类处理
}

@end
