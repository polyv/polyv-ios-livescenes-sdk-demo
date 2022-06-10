//
//  PLVLSBeautyBaseViewController.m
//  PolyvLiveScenesDemo
//
//  Created by lijingtong on 2022/4/19.
//  Copyright © 2022 PLV. All rights reserved.
//

#import "PLVLSBeautyBaseViewController.h"

@implementation PLVLSBeautyBaseViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupDataArray];
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
