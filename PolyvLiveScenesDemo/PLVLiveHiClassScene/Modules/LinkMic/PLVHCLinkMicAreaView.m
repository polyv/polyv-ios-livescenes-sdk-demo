//
//  PLVHCLinkMicAreaView.m
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2021/6/24.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVHCLinkMicAreaView.h"

//UI
#import "PLVHCLinkMicWindowsView.h"

// 工具类
#import "PLVHCUtils.h"


@interface PLVHCLinkMicAreaView ()<
PLVHCLinkMicWindowsViewDelegate
>

#pragma mark UI
@property (nonatomic, strong) PLVHCLinkMicWindowsView *windowsView;          // 连麦窗口列表视图 (负责展示1v1 1v6画面窗口)

@end

@implementation PLVHCLinkMicAreaView

#pragma mark - [ Life Cycle ]
- (instancetype)init {
    if (self = [super initWithFrame:CGRectZero]) {
        [self setupUI];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
 
    self.windowsView.frame = self.bounds;
}

#pragma mark Getter & Setter

- (PLVHCLinkMicWindowsView *)windowsView {
    if (!_windowsView) {
        _windowsView = [[PLVHCLinkMicWindowsView alloc] init];
        _windowsView.delegate = self;
    }
    return _windowsView;
}

#pragma mark - [ Public Method ]

- (void)reloadLinkMicUserWindows {
    [self.windowsView reloadLinkMicUserWindows];
}

- (void)linkMicAreaViewEnableLocalMic:(BOOL)enable {
    [self.windowsView linkMicWindowsViewEnableLocalMic:enable];
}

- (void)linkMicAreaViewEnableLocalCamera:(BOOL)enable {
    [self.windowsView linkMicWindowsViewEnableLocalCamera:enable];
}

- (void)linkMicAreaViewSwitchLocalCameraFront:(BOOL)switchFront {
    [self.windowsView linkMicWindowsViewSwitchLocalCameraFront:switchFront];
}

- (void)linkMicAreaViewStartRunning {
    [self.windowsView linkMicWindowsViewStartRunning];
}

#pragma mark - [ Private Method ]

- (void)setupUI {
    [self addSubview:self.windowsView];
}

#pragma mark - [ Delegate ]

#pragma mark PLVHCLinkMicWindowsViewDelegate

- (NSArray *)plvHCLinkMicWindowsViewGetCurrentUserModelArray:(PLVHCLinkMicWindowsView *)windowsView {
    if ([self.delegate respondsToSelector:@selector(plvHCLinkMicAreaViewGetCurrentUserModelArray:)]) {
        return [self.delegate plvHCLinkMicAreaViewGetCurrentUserModelArray:self];
    }else{
        return nil;
    }
}

- (NSInteger)plvHCLinkMicWindowsView:(PLVHCLinkMicWindowsView *)windowsView findUserModelIndexWithFiltrateBlock:(BOOL (^)(PLVLinkMicOnlineUser * _Nonnull))filtrateBlockBlock {
    if ([self.delegate respondsToSelector:@selector(plvHCLinkMicAreaView:findUserModelIndexWithFiltrateBlock:)]) {
        return [self.delegate plvHCLinkMicAreaView:self findUserModelIndexWithFiltrateBlock:filtrateBlockBlock];
    }else{
        return -1;
    }
}

- (PLVLinkMicOnlineUser *)plvHCLinkMicWindowsView:(PLVHCLinkMicWindowsView *)windowsView getUserModelFromOnlineUserArrayWithIndex:(NSInteger)targetIndex {
    if ([self.delegate respondsToSelector:@selector(plvHCLinkMicAreaView:getUserModelFromOnlineUserArrayWithIndex:)]) {
        return [self.delegate plvHCLinkMicAreaView:self getUserModelFromOnlineUserArrayWithIndex:targetIndex];
    }else{
        return nil;
    }
}

- (void)plvHCLinkMicWindowsView:(PLVHCLinkMicWindowsView *)windowsView enableLocalMic:(BOOL)enable {
    if ([self.delegate respondsToSelector:@selector(plvHCLinkMicAreaView:enableLocalMic:)]) {
        return [self.delegate plvHCLinkMicAreaView:self enableLocalMic:enable];
    }
}

- (void)plvHCLinkMicWindowsView:(PLVHCLinkMicWindowsView *)windowsView enableLocalCamera:(BOOL)enable {
    if ([self.delegate respondsToSelector:@selector(plvHCLinkMicAreaView:enableLocalCamera:)]) {
        return [self.delegate plvHCLinkMicAreaView:self enableLocalCamera:enable];
    }
}

- (void)plvHCLinkMicWindowsView:(PLVHCLinkMicWindowsView *)windowsView switchLocalCameraFront:(BOOL)switchFront {
    if ([self.delegate respondsToSelector:@selector(plvHCLinkMicAreaView:switchLocalCameraFront:)]) {
        return [self.delegate plvHCLinkMicAreaView:self switchLocalCameraFront:switchFront];
    }
}

@end
