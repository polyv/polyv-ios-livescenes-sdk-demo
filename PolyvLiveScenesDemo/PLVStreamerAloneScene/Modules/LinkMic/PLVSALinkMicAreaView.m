//
//  PLVSALinkMicAreaView.m
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2021/5/19.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVSALinkMicAreaView.h"
#import "PLVSAUtils.h"
#import "PLVMultiLanguageManager.h"
#import "PLVSALinkMicWindowsView.h"
#import "PLVSALinkMicUserInfoSheet.h"
#import "PLVLinkMicOnlineUser+SA.h"
// 模块
#import "PLVRoomDataManager.h"

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

- (void)updateFirstSiteCanvasViewWithUserId:(NSString *)linkMicUserId toFirstSite:(BOOL)toFirstSite {
    [self.windowsView updateFirstSiteCanvasViewWithUserId:linkMicUserId toFirstSite:toFirstSite];
}

- (void)updateLocalUserLinkMicStatus:(PLVLinkMicUserLinkMicStatus)linkMicStatus {
    [self.windowsView updateLocalUserLinkMicStatus:linkMicStatus];
}

- (void)finishClass {
    [self.windowsView finishClass];
}

- (void)clear {
    [self.windowsView removeFromSuperview];
}

#pragma mark - [ Private Method ]

- (void)setupUI {
    [self addSubview:self.bgImageView];
    [self addSubview:self.windowsView];
}

- (void)authUserSpeakerWithUser:(PLVLinkMicOnlineUser *)onlineUser auth:(BOOL)auth {
    PLVLinkMicOnlineUser *speakerUser = nil;
    if (auth) {
        NSArray *onlineUserList = [self.delegate currentOnlineUserListInLinkMicAreaView:self];
        for (int i = 0; i < onlineUserList.count; i++) {
            PLVLinkMicOnlineUser *user = onlineUserList[i];
            if (user.isRealMainSpeaker) {
                speakerUser = user;
                break;
            }
        }
    }
    
    PLVRoomUserType viewerType = [PLVRoomDataManager sharedManager].roomData.roomUser.viewerType;
    if (viewerType == PLVRoomUserTypeTeacher &&
        ((auth && speakerUser) || (!auth && onlineUser.currentScreenShareOpen))) {
        NSString *titlePrefix = auth ? PLVLocalizedString(@"确定授予ta") : PLVLocalizedString(@"确定移除ta的");
        NSString *message = auth ? PLVLocalizedString(@"当前已有主讲人，确定后将替换为新的主讲人") : PLVLocalizedString(@"移除后主讲人的屏幕共享将会自动结束");
        NSString *alertTitle = [NSString stringWithFormat:PLVLocalizedString(@"%@主讲权限吗？"), titlePrefix];
        [PLVSAUtils showAlertWithTitle:alertTitle Message:message cancelActionTitle:PLVLocalizedString(@"取消") cancelActionBlock:nil confirmActionTitle:PLVLocalizedString(@"确定") confirmActionBlock:^{
            [onlineUser wantAuthUserSpeaker:auth];
        }];
    } else {
        [onlineUser wantAuthUserSpeaker:auth];
    }
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
    CGFloat heightScale = 0.34;
    CGFloat widthScale = 0.37;
    CGFloat maxWH = MAX([UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width);
    
    CGFloat sheetHeight = maxWH * heightScale;
    CGFloat sheetLandscapeWidth = maxWH * widthScale;
    
    PLVSALinkMicUserInfoSheet *linkMicUserSheet = [[PLVSALinkMicUserInfoSheet alloc] initWithSheetHeight:sheetHeight sheetLandscapeWidth:sheetLandscapeWidth];
    [linkMicUserSheet updateLinkMicUserInfoWithUser:onlineUser localUser:[self.delegate localUserInLinkMicAreaView:self]];
    __weak typeof(self)weakSelf = self;
    [linkMicUserSheet setFullScreenButtonClickBlock:^(PLVLinkMicOnlineUser * _Nonnull user) {
        [weakSelf.windowsView fullScreenLinkMicUser:user];
    }];
    [linkMicUserSheet setAuthSpeakerButtonClickBlock:^(PLVLinkMicOnlineUser * _Nonnull user, BOOL auth) {
        [weakSelf authUserSpeakerWithUser:user auth:auth];
    }];
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

- (void)linkMicWindowsView:(PLVSALinkMicWindowsView *)windowsView onlineUser:(PLVLinkMicOnlineUser *)onlineUser isFullScreen:(BOOL)isFullScreen {
    if (self.delegate && [self.delegate respondsToSelector:@selector(linkMicAreaView:onlineUser:isFullScreen:)]) {
        [self.delegate linkMicAreaView:self onlineUser:onlineUser isFullScreen:isFullScreen];
    }
}

- (void)plvSALinkMicWindowsView:(PLVSALinkMicWindowsView *)windowsView acceptLinkMicInvitation:(BOOL)accept timeoutCancel:(BOOL)timeoutCancel {
    if (self.delegate && [self.delegate respondsToSelector:@selector(plvSALinkMicAreaView:acceptLinkMicInvitation:timeoutCancel:)]) {
        [self.delegate plvSALinkMicAreaView:self acceptLinkMicInvitation:accept timeoutCancel:timeoutCancel];
    }
}

- (void)plvSALinkMicWindowsView:(PLVSALinkMicWindowsView *)windowsView inviteLinkMicTTL:(void (^)(NSInteger ttl))callback {
    if (self.delegate && [self.delegate respondsToSelector:@selector(plvSALinkMicAreaView:inviteLinkMicTTL:)]) {
        [self.delegate plvSALinkMicAreaView:self inviteLinkMicTTL:callback];
    }
}

@end
