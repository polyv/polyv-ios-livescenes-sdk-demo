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
    [self setBgImageViewImage]; // 设置背景图片，适配横竖屏
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

- (void)setBgImageViewImage {
    if ([PLVSAUtils sharedUtils].isLandscape) {
        self.bgImageView.image = [PLVSAUtils imageForLinkMicResource:@"plvsa_linkmic_bg_landscape"];
    } else {
        self.bgImageView.image = [PLVSAUtils imageForLinkMicResource:@"plvsa_linkmic_bg"];
    }
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

- (BOOL)localUserPreviewViewInLinkMicWindowsView:(PLVSALinkMicWindowsView *)windowsView {
    if (self.delegate && [self.delegate respondsToSelector:@selector(localUserPreviewViewInLinkMicAreaView:)]) {
        return [self.delegate localUserPreviewViewInLinkMicAreaView:self];
    } else {
        return NO;
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
    CGFloat heightScale = 0.33;
    CGFloat widthScale = 0.37;
    CGFloat maxWH = MAX([UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width);
    
    CGFloat sheetHeight = maxWH * heightScale;
    CGFloat sheetLandscapeWidth = maxWH * widthScale;
    
    PLVSALinkMicUserInfoSheet *linkMicUserSheet = [[PLVSALinkMicUserInfoSheet alloc] initWithSheetHeight:sheetHeight sheetLandscapeWidth:sheetLandscapeWidth];
    [linkMicUserSheet updateLinkMicUserInfoWithUser:onlineUser];
    [linkMicUserSheet showInView:[PLVSAUtils sharedUtils].homeVC.view];
    
    // 触发回调
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(didSelectLinkMicUserInLinkMicAreaView:)]) {
        [self.delegate didSelectLinkMicUserInLinkMicAreaView:self];
    }
}

- (void)linkMicWindowsView:(PLVSALinkMicWindowsView *)windowsView showGuideViewOnExternal:(UIView *)guideView {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(linkMicAreaView:showGuideViewOnExternal:)]) {
        [self.delegate linkMicAreaView:self showGuideViewOnExternal:guideView];
    }
}

- (BOOL)classStartedInLinkMicWindowsView:(PLVSALinkMicWindowsView *)windowsView {
    if (self.delegate && [self.delegate respondsToSelector:@selector(classStartedInLinkMicAreaView:)]) {
        return [self.delegate classStartedInLinkMicAreaView:self];
    } else {
        return NO;
    }
}

@end
