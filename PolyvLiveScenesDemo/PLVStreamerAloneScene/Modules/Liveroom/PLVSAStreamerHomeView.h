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
#import "PLVSAMixLayoutSheet.h"

NS_ASSUME_NONNULL_BEGIN

@class PLVSAStreamerHomeView, PLVLinkMicOnlineUser, PLVLinkMicOnlineUser, PLVSALinkMicWindowsView, PLVRTCStatistics;
@class PLVStickerCanvas;

@protocol PLVSAStreamerHomeViewDelegate <NSObject>

/// 禁言/取消禁言某个用户回调
- (void)bandUsersInStreamerHomeView:(PLVSAStreamerHomeView *)homeView withUserId:(NSString *)userId banned:(BOOL)banned;

/// 踢出某个用户回调
- (void)kickUsersInStreamerHomeView:(PLVSAStreamerHomeView *)homeView withUserId:(NSString *)userId;

/// 邀请某个用户加入连麦的回调
- (void)inviteUserJoinLinkMicInStreamerHomeView:(PLVSAStreamerHomeView *)homeView withUser:(PLVLinkMicWaitUser *)user;

/// 获取当前清晰度
- (PLVResolutionType)streamerHomeViewCurrentQuality:(PLVSAStreamerHomeView *)homeView;

/// 获取当前推流质量等级
- (NSString *)streamerHomeViewCurrentStreamQualityLevel:(PLVSAStreamerHomeView *)homeView;

/// 获取连麦开启状态
- (BOOL)streamerHomeViewChannelLinkMicOpen:(PLVSAStreamerHomeView *)homeView;

/// 改变 清晰度 触发回调
- (void)streamerHomeView:(PLVSAStreamerHomeView *)homeView didChangeResolutionType:(PLVResolutionType)type;

/// 改变 清晰度 触发回调（模版中推流质量等级）
- (void)streamerHomeView:(PLVSAStreamerHomeView *)homeView didChangeStreamQualityLevel:(NSString *)streamQualityLevel;

/// 获取当前混流布局
- (PLVMixLayoutType)streamerHomeViewCurrentMixLayoutType:(PLVSAStreamerHomeView *)homeView;

/// 改变 混流布局 触发回调
- (void)streamerHomeView:(PLVSAStreamerHomeView *)homeView didChangeMixLayoutType:(PLVMixLayoutType)type;

/// 改变 视频流画质偏好 触发回调
- (void)streamerHomeView:(PLVSAStreamerHomeView *)homeView didChangeVideoQosPreference:(PLVBRTCVideoQosPreference)videoQosPreference;

/// 获取当前视频流画质偏好
- (PLVBRTCVideoQosPreference)streamerHomeViewCurrentVideoQosPreference:(PLVSAStreamerHomeView *)homeView;

/// 点击 连麦 按钮回调
- (void)streamerHomeViewDidTapLinkMicButton:(PLVSAStreamerHomeView *)homeView linkMicButtonSelected:(BOOL)selected videoLinkMic:(BOOL)videoLinkMic;

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

/// 点击 屏幕共享 按钮 触发回调
- (void)streamerHomeView:(PLVSAStreamerHomeView *)homeView didChangeScreenShareOpen:(BOOL)screenShareOpen;

/// 点击 闪光灯 按钮触发回调
- (void)streamerHomeView:(PLVSAStreamerHomeView *)homeView didChangeFlashOpen:(BOOL)flashOpen;

/// 点击 关闭 按钮触发回调
- (void)streamerHomeViewDidTapCloseButton:(PLVSAStreamerHomeView *)homeView;

/// 点击 美颜 按钮触发回调
- (void)streamerHomeViewDidTapBeautyButton:(PLVSAStreamerHomeView *)homeView;

/// 点击 分享 按钮触发回调
- (void)streamerHomeViewDidTapShareButton:(PLVSAStreamerHomeView *)homeView;

/// 点击 开启/关闭连麦设置按钮 按钮触发回调
- (void)streamerHomeViewDidAllowRaiseHandButton:(PLVSAStreamerHomeView *)homeView wannaChangeAllowRaiseHand:(BOOL)allowRaiseHand;

/// 点击 开启/关闭连麦设置按钮 按钮触发回调
- (void)streamerHomeView:(PLVSAStreamerHomeView *)homeView wannaChangeLinkMicType:(BOOL)linkMicOnAudio;

/// 点击 连麦设置 触底回调
- (PLVChannelLinkMicMediaType)streamerHomeViewCurrentChannelLinkMicMediaType:(PLVSAStreamerHomeView *)homeView;

/// 点击 观众下麦 按钮触发回调
- (void)streamerHomeViewDidTapRemoveAllAudiencesButton:(PLVSAStreamerHomeView *)homeView;

- (void)streamerHomeView:(PLVSAStreamerHomeView *)homeView didChangeDesktopChatEnable:(BOOL)desktopChatEnable;

/// 贴图按钮点击
- (void)streamerHomeViewDidTapStickerButton:(PLVSAStreamerHomeView *)homeView;

/// AI抠像按钮点击
- (void)streamerHomeViewDidTapAiMattingButton:(PLVSAStreamerHomeView *)homeView;

@end

@interface PLVSAStreamerHomeView : UIView

/// PLVSAStreamerHomeViewDelegate 代理
@property (nonatomic, weak)id<PLVSAStreamerHomeViewDelegate> delegate;

// 混流布局选择面板，用于更新当前混流布局类型
@property (nonatomic, strong, readonly) PLVSAMixLayoutSheet *mixLayoutSheet;

- (instancetype)initWithLocalOnlineUser:(PLVLinkMicOnlineUser *)localOnlineUser
                     linkMicWindowsView:(PLVSALinkMicWindowsView *)linkMicWindowsView;

/// 开始上课/结束上课
/// @param start YES - 开始上课 NO - 结束上课
- (void)startClass:(BOOL)start;

/// 设置状态栏推流时长
- (void)setPushStreamDuration:(NSTimeInterval)duration;

/// 设置状态栏网络信号
- (void)setNetworkQuality:(PLVBRTCNetworkQuality)netState;

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
- (void)showNewWaitUserAdded;

/// 添加外部连麦引导视图
/// @param guideView 连麦引导视图
- (void)addExternalLinkMicGuideView:(UIView *)guideView;

/// 更新在线用户数量
/// @note 用户数量改变时更新内部UI控件的状态
/// @param onlineUserCount 当前连麦人数
- (void)updateHomeViewOnlineUserCount:(NSInteger)onlineUserCount;

/// 改变闪光灯按钮选中状态
/// @param selectedState 选中状态 (YES:选中，闪光灯开启 NO:未选中，闪光灯关闭)
- (void)changeFlashButtonSelectedState:(BOOL)selectedState;

/// 改变屏幕共享按钮选中状态
/// @param selectedState 选中状态 (YES:选中，开启屏幕共享 NO:未选中，关闭屏幕共享)
- (void)changeScreenShareButtonSelectedState:(BOOL)selectedState;

/// 改变 开启/关闭观众连麦按钮 选中状态
/// @param selectedState 选中状态 (YES:选中，开启观众连麦 NO:未选中，关闭观众连麦)
- (void)changeAllowRaiseHandButtonSelectedState:(BOOL)selectedState;

/// 更新选中连麦按钮
/// @param linkMicOnAudio 连麦类型 (YES:音频连麦 NO:视频连麦)
- (void)updateHomeViewLinkMicType:(BOOL)linkMicOnAudio;

/// 是否显示美颜弹窗
/// @param show YES: 显示；NO：隐藏
- (void)showBeautySheet:(BOOL)show;

- (void)updateStatistics:(PLVRTCStatistics *)statistics;

- (void)dismissBottomSheet;

- (void)showBadNetworkTipsView;

/// 更新评论上墙视图
/// @param show 是否显示 评论上墙视图
/// @param message 消息详情模型
- (void)showPinMessagePopupView:(BOOL)show message:(PLVSpeakTopMessage *)message;

/// 获取当前最新消息
- (NSAttributedString *)currentNewMessage;

/// 更新桌面聊天是否开启
- (void)updateDesktopChatEnable:(BOOL)enable;

/// 添加贴图视图
/// @param stickerView  贴图组件
/// @param editMode 是否编辑模式加入 会影响到图层布局
- (void)addStickerCanvasView:(PLVStickerCanvas *)stickerView editMode:(BOOL)editMode;

@end

NS_ASSUME_NONNULL_END
