//
//  PLVLSStatusAreaView.h
//  PLVLiveStreamerDemo
//
//  Created by MissYasiky on 2021/3/10.
//  Copyright © 2021 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PLVLinkMicUserDefine.h"
#import "PLVLSSignalButton.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, PLVLSStatusBarNetworkQuality){
    PLVLSStatusBarNetworkQuality_Unknown = 0,   // 未知
    PLVLSStatusBarNetworkQuality_Excellent = 1, // 当前网络非常好
    PLVLSStatusBarNetworkQuality_Good = 2,      // 当前网络比较好
    PLVLSStatusBarNetworkQuality_Poor = 3,      // 当前网络一般
    PLVLSStatusBarNetworkQuality_Bad = 4,       // 当前网络较差
    PLVLSStatusBarNetworkQuality_VBad = 5,      // 当前网络很差
    PLVLSStatusBarNetworkQuality_Down = 6       // 无法连接
};

typedef NS_ENUM(NSInteger, PLVLSStatusBarControls){
    PLVLSStatusBarControls_All              = -1,
    PLVLSStatusBarControls_ChannelInfo      = 1 << 0,
    PLVLSStatusBarControls_TimeLabel        = 1 << 1,
    PLVLSStatusBarControls_SignalButton     = 1 << 2,
    PLVLSStatusBarControls_WhiteboardButton = 1 << 3,
    PLVLSStatusBarControls_DocumentButton   = 1 << 4,
    PLVLSStatusBarControls_LinkmicButton    = 1 << 5,
    PLVLSStatusBarControls_MemberButton     = 1 << 6,
    PLVLSStatusBarControls_SettingButton    = 1 << 7,
    PLVLSStatusBarControls_ShareButton      = 1 << 8,
    PLVLSStatusBarControls_PushButton       = 1 << 9,
};

@class PLVRTCStatistics;

@protocol PLVLSStatusAreaViewProtocol <NSObject>

- (void)statusAreaView_didTapChannelInfoButton;

- (void)statusAreaView_didTapWhiteboardOrDocumentButton:(BOOL)whiteboard;

- (void)statusAreaView_didTapMemberButton;

- (void)statusAreaView_didTapSettingButton;

- (void)statusAreaView_didTapShareButton;

- (BOOL)statusAreaView_didTapStartPushOrStopPushButton:(BOOL)start;

- (BOOL)statusAreaView_didTapVideoLinkMicButton:(BOOL)start;

- (BOOL)statusAreaView_didTapAudioLinkMicButton:(BOOL)start;

- (void)statusAreaView_didRequestJoinLinkMic:(BOOL)requestJoin;

- (void)statusAreaView_didTapCloseLinkMicButton;

- (void)statusAreaView_didTapAudienceRaiseHandButton:(BOOL)start;

- (PLVLSStatusBarControls)statusAreaView_selectControlsInDemand;

@end

@interface PLVLSStatusAreaView : UIView

@property (nonatomic, weak) id<PLVLSStatusAreaViewProtocol> delegate;

@property (nonatomic, assign, readonly) BOOL inClass; // 当前是否处于推流状态

@property (nonatomic, assign) NSTimeInterval duration; // 已上课时长，同时更新界面时长文本

@property (nonatomic, assign) PLVLSStatusBarNetworkQuality netState; // 网络状态，设置该值同时更新界面网络状态

@property (nonatomic, strong, readonly) UIButton *linkmicButton;

@property (nonatomic, strong, readonly) PLVLSSignalButton *signalButton;
@property (nonatomic, strong, readonly) UIButton *stopPushButton;

/// 禁止点击上课按钮
/// @param enable YES - 禁止 NO - 解除禁止
- (void)startPushButtonEnable:(BOOL)enable;

/// 开始上课/结束上课
/// @param start YES - 开始上课 NO - 结束上课
- (void)startClass:(BOOL)start;

/// 有新成员上线，成员按钮显示红点
- (void)hasNewMember;

/// 选中白板或文档
/// @param whiteboard YES - 选中白板 NO - 选中文档
- (void)selectedWhiteboardOrDocument:(BOOL)whiteboard;

/// 同步白板或文档选中状态，只做UI同步
/// @param whiteboard YES - 选中白板 NO - 选中文档
- (void)syncSelectedWhiteboardOrDocument:(BOOL)whiteboard;

/// 收到新的连麦申请
- (void)receivedNewJoinLinkMicRequest;

/// 本地用户授权为主讲(当为主讲权限时，可以管理文档)
/// @param auth 是否授权(YES授权，NO取消授权)
- (void)updateDocumentSpeakerAuth:(BOOL)auth;

/// 更新当前连麦状态
/// @param status 当前用户的连麦状态
- (void)updateStatusViewLinkMicStatus:(PLVLinkMicUserLinkMicStatus)status;

///  更新推流时RTC统计数据
- (void)updateStatistics:(PLVRTCStatistics *)statistics;

- (void)changeMemberButtonSelectedState:(BOOL)selected;

/// 更新连麦状态是否开启
- (void)changeLinkmicButtonSelectedState:(BOOL)selected;

@end

NS_ASSUME_NONNULL_END
