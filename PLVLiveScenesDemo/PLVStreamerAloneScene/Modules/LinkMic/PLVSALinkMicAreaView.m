//
//  PLVSALinkMicAreaView.m
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2021/5/19.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVSALinkMicAreaView.h"
#import "PLVSAUtils.h"
#import "PLVSALinkMicWindowsView.h"
#import "PLVSALinkMicUserInfoSheet.h"
#import "PLVLinkMicOnlineUser+SA.h"

@interface PLVSALinkMicAreaView ()<
PLVSALinkMicWindowsViewDelegate
>

#pragma mark UI

/// view hierarchy
///
/// (UIView) superview
///  └── (PLVSALinkMicAreaView) self (lowest)
///    ├── (UIImageView) bgImageView
///    └── (PLVSALinkMicWindowsView) windowsView
@property (nonatomic, strong) UIImageView *bgImageView; // 默认背景图
@property (nonatomic, strong) PLVSALinkMicWindowsView *windowsView; // 连麦窗口视图

@end

@implementation PLVSALinkMicAreaView

#pragma mark - [ Life Cycle ]

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.bgImageView.frame = self.bounds;
    if (self.windowsView.superview == self) { // 开播后windowsView会被移到homeView上
        self.windowsView.frame = self.bounds;
    }
}

#pragma mark - [ Public Method ]

- (void)reloadLinkMicUserWindows {
    [self.windowsView reloadLinkMicUserWindows];
}

- (void)clear {
    [self.windowsView removeFromSuperview];
}

#pragma mark - [ Private Method ]

- (void)setupUI {
    [self addSubview:self.bgImageView];
    [self addSubview:self.windowsView];
}

#pragma mark Getter & Setter

- (UIImageView *)bgImageView {
    if (!_bgImageView) {
        _bgImageView = [[UIImageView alloc] init];
        _bgImageView.image = [PLVSAUtils imageForLinkMicResource:@"plvsa_linkmic_bg"];
    }
    return _bgImageView;
}

- (PLVSALinkMicWindowsView *)windowsView {
    if (!_windowsView) {
        _windowsView = [[PLVSALinkMicWindowsView alloc] init];
        _windowsView.delegate = self;
    }
    return _windowsView;
}

#pragma mark - [ Delegate ]

#pragma mark PLVSALinkMicWindowsViewDelegate

- (PLVLinkMicOnlineUser *)localUserInLinkMicWindowsView:(PLVSALinkMicWindowsView *)windowsView {
    if (self.delegate) {
        return [self.delegate localUserInLinkMicAreaView:self];
    } else {
        return nil;
    }
}

- (NSArray *)currentOnlineUserListInLinkMicWindowsView:(PLVSALinkMicWindowsView *)windowsView {
    if (self.delegate) {
        return [self.delegate currentOnlineUserListInLinkMicAreaView:self];
    } else {
        return nil;
    }
}

- (NSInteger)onlineUserIndexInLinkMicWindowsView:(PLVSALinkMicWindowsView *)windowsView
                                     filterBlock:(BOOL(^)(PLVLinkMicOnlineUser * enumerateUser))filterBlock {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(onlineUserIndexInLinkMicAreaView:filterBlock:)]) {
        return [self.delegate onlineUserIndexInLinkMicAreaView:self filterBlock:filterBlock];
    } else {
        return -1;
    }
}

- (PLVLinkMicOnlineUser *)onlineUserInLinkMicWindowsView:(PLVSALinkMicWindowsView *)windowsView
                                         withTargetIndex:(NSInteger)targetIndex {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(onlineUserInLinkMicAreaView:withTargetIndex:)]) {
        return [self.delegate onlineUserInLinkMicAreaView:self withTargetIndex:targetIndex];
    } else {
        return nil;
    }
}

- (void)linkMicWindowsView:(PLVSALinkMicWindowsView *)windowsView didSelectOnlineUser:(PLVLinkMicOnlineUser *)onlineUser {
    // 显示连麦成员信息弹层
    CGFloat sheetHeight = [UIScreen mainScreen].bounds.size.height * 0.32;
    PLVSALinkMicUserInfoSheet *linkMicUserSheet = [[PLVSALinkMicUserInfoSheet alloc] initWithSheetHeight:sheetHeight];
    [linkMicUserSheet updateLinkMicUserInfoWithUser:onlineUser];
    [linkMicUserSheet showInView:[PLVSAUtils sharedUtils].homeVC.view];
    
    // 触发回调
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(didSelectLinkMicUserInLinkMicAreaView:)]) {
        [self.delegate didSelectLinkMicUserInLinkMicAreaView:self];
    }
}

@end
