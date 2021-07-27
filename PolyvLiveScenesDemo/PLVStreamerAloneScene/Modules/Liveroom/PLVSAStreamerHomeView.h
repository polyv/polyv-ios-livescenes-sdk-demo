//
//  PLVSAStreamerHomeView.h
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2021/5/19.
//  Copyright © 2021 PLV. All rights reserved.
//
// 开播时主页面顶部视图，覆盖在 PLVSAStreamerViewController 之上

#import <UIKit/UIKit.h>
#import "PLVRoomData.h"
#import "PLVChatUser.h"

NS_ASSUME_NONNULL_BEGIN

@class PLVSAStreamerHomeView, PLVLinkMicOnlineUser, PLVLinkMicOnlineUser, PLVSALinkMicWindowsView;

@protocol PLVSAStreamerHomeViewDelegate <NSObject>

/// 禁言/取消禁言某个用户回调
- (void)bandUsersInStreamerHomeView:(PLVSAStreamerHomeView *)homeView withUserId:(NSString *)userId banned:(BOOL)banned;

/// 踢出某个用户回调
- (void)kickUsersInStreamerHomeView:(PLVSAStreamerHomeView *)homeView withUserId:(NSString *)userId;

/// 获取当前清晰度
- (PLVResolutionType)streamerHomeViewCurrentQuality:(PLVSAStreamerHomeView *)homeView;

/// 获取连麦开启状态
- (BOOL)streamerHomeViewChannelLinkMicOpen:(PLVSAStreamerHomeView *)homeView;

/// 改变 清晰度 触发回调
- (void)streamerHomeView:(PLVSAStreamerHomeView *)homeView didChangeResolutionType:(PLVResolutionType)type;

/// 点击 连麦 按钮回调
- (void)streamerHomeViewDidTapLinkMicButton:(PLVSAStreamerHomeView *)homeView linkMicButtonSelected:(BOOL)selected;

/// 点击 人员 按钮回调
- (void)streamerHomeViewDidMemberSheetDismiss:(PLVSAStreamerHomeView *)homeView;

/// 点击 摄像头 按钮 触发回调
- (void)streamerHomeView:(PLVSAStreamerHomeView *)homeView didChangeCameraOpen:(BOOL)cameraOpen;

/// 点击 麦克风 按钮 触发回调
- (void)streamerHomeView:(PLVSAStreamerHomeView *)homeView didChangeMicOpen:(BOOL)micOpen;

/// 点击 翻转 按钮 触发回调
- (void)streamerHomeViewDidChangeCameraFront:(PLVSAStreamerHomeView *)homeView;

/// 点击 镜像 按钮 触发回调
- (void)streamerHomeView:(PLVSAStreamerHomeView *)homeView didChangeMirrorOpen:(BOOL)mirrorOpen;

/// 点击 闪光灯 按钮触发回调
- (void)streamerHomeView:(PLVSAStreamerHomeView *)homeView didChangeFlashOpen:(BOOL)flashOpen;

/// 点击 关闭 按钮触发回调
- (void)streamerHomeViewDidTapCloseButton:(PLVSAStreamerHomeView *)homeView;

@end

@interface PLVSAStreamerHomeView : UIView

/// PLVSAStreamerHomeViewDelegate 代理
@property (nonatomic, weak)id<PLVSAStreamerHomeViewDelegate> delegate;

- (instancetype)initWithLocalOnlineUser:(PLVLinkMicOnlineUser *)localOnlineUser
                     linkMicWindowsView:(PLVSALinkMicWindowsView *)linkMicWindowsView;

/// 开始上课/结束上课
/// @param start YES - 开始上课 NO - 结束上课
- (void)startClass:(BOOL)start;

/// 设置状态栏推流时长
- (void)setPushStreamDuration:(NSTimeInterval)duration;

/// 设置状态栏网络信号
- (void)setNetworkQuality:(PLVBLinkMicNetworkQuality)netState;

/// 更新成员列表弹层所需数据
/// @param userList 成员列表数据
/// @param userCount 在线成员总数
/// @param onlineCount 连麦人数
- (void)updateUserList:(NSArray <PLVChatUser *> *)userList
             userCount:(NSInteger)userCount
           onlineCount:(NSInteger)onlineCount;

/// 设置本地用户麦克风音量值 (0.0~1.0)
- (void)setLocalMicVolume:(CGFloat)micVolume;

/// 设置本地用户麦克风开启
- (void)setCurrentMicOpen:(BOOL)micOpen;

/// 设置连麦状态，用于更新实际连麦状态，更新连麦按钮UI
- (void)setLinkMicButtonSelected:(BOOL)selected;

/// 人员按钮右上角红点显示或隐藏
/// @param show YES: 显示；NO：隐藏
- (void)showMemberBadge:(BOOL)show;

/// 显示 有新用户等待连麦，弹出“有人正在申请连麦”提示
- (void)ShowNewWaitUserAdded;

/// 显示、隐藏连麦新手引导
/// @note 内部处理显示或隐藏
/// @param onlineUserCount 当前连麦人数，大于1: 显示视图；
- (void)showOrHiddenLinMicGuied:(NSInteger)onlineUserCount;

/// 改变闪光灯按钮选中状态
/// @param selectedState 选中状态 (YES:选中，闪光灯开启 NO:未选中，闪光灯关闭)
- (void)changeFlashButtonSelectedState:(BOOL)selectedState;

@end

NS_ASSUME_NONNULL_END
