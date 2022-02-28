//
//  PLVHCLinkMicAreaView.m
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2021/6/24.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVHCLinkMicAreaView.h"

/// UI
#import "PLVHCLinkMicWindowsView.h"

/// 工具类
#import "PLVHCUtils.h"

@interface PLVHCLinkMicAreaView ()<
PLVHCLinkMicWindowsViewDelegate
>

#pragma mark UI
/// view hierarchy
///
/// (PLVHCLinkMicAreaView) self
///   └── (PLVHCLinkMicWindowsView) windowsView
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

- (void)enableLocalMic:(BOOL)enable {
    [self.windowsView enableLocalMic:enable];
}

- (void)enableLocalCamera:(BOOL)enable {
    [self.windowsView enableLocalCamera:enable];
}

- (void)startPreview {
    [self.windowsView startPreview];
}

- (void)showLocalSettingView {
    [self.windowsView showLocalSettingView];
}

- (void)showSettingViewWithUser:(PLVLinkMicOnlineUser *)user {
    [self.windowsView showSettingViewWithUser:user];
}

- (UIView *)getLinkMicItemViewWithUserId:(NSString *)userId {
    return [self.windowsView getLinkMicItemViewWithUserId:userId];
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


- (void)plvHCLinkMicWindowsView:(PLVHCLinkMicWindowsView *)windowsView didSwitchLinkMicWithExternalView:(UIView *)externalView userId:(nonnull NSString *)userId showInZoom:(BOOL)showInZoom {
    if ([self.delegate respondsToSelector:@selector(plvHCLinkMicAreaView:didSwitchLinkMicWithExternalView:userId:showInZoom:)]) {
        return [self.delegate plvHCLinkMicAreaView:self didSwitchLinkMicWithExternalView:externalView userId:userId showInZoom:showInZoom];
    }
}

- (void)plvHCLinkMicWindowsView:(PLVHCLinkMicWindowsView *)windowsView didRefreshLinkMiItemView:(nonnull PLVHCLinkMicItemView *)linkMiItemView {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(plvHCLinkMicAreaView:didRefreshLinkMiItemView:)]) {
        [self.delegate plvHCLinkMicAreaView:self didRefreshLinkMiItemView:linkMiItemView];
    }
}

@end
