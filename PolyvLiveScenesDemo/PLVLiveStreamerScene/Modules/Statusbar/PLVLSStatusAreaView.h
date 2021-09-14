//
//  PLVLSStatusAreaView.h
//  PLVLiveStreamerDemo
//
//  Created by MissYasiky on 2021/3/10.
//  Copyright © 2021 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, PLVLSStatusBarNetworkQuality){
    PLVLSStatusBarNetworkQuality_Unknown = 0, // 未知
    PLVLSStatusBarNetworkQuality_Good = 1,    // 信号良好
    PLVLSStatusBarNetworkQuality_Fine = 2,    // 信号一般
    PLVLSStatusBarNetworkQuality_Bad = 3,     // 信号差
    PLVLSStatusBarNetworkQuality_Disconnect = 4, // 无法连接
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

@protocol PLVLSStatusAreaViewProtocol <NSObject>

- (void)statusAreaView_didTapChannelInfoButton;

- (void)statusAreaView_didTapWhiteboardOrDocumentButton:(BOOL)whiteboard;

- (void)statusAreaView_didTapMemberButton;

- (void)statusAreaView_didTapSettingButton;

- (void)statusAreaView_didTapShareButton;

- (BOOL)statusAreaView_didTapStartPushOrStopPushButton:(BOOL)start;

- (BOOL)statusAreaView_didTapVideoLinkMicButton:(BOOL)start;

- (BOOL)statusAreaView_didTapAudioLinkMicButton:(BOOL)start;

- (PLVLSStatusBarControls)statusAreaView_selectControlsInDemand;

@end

@interface PLVLSStatusAreaView : UIView

@property (nonatomic, weak) id<PLVLSStatusAreaViewProtocol> delegate;

@property (nonatomic, assign, readonly) BOOL inClass; // 当前是否处于推流状态

@property (nonatomic, assign) NSTimeInterval duration; // 已上课时长，同时更新界面时长文本

@property (nonatomic, assign) PLVLSStatusBarNetworkQuality netState; // 网络状态，设置该值同时更新界面网络状态

/// 禁止点击上课按钮
/// @param enable YES - 禁止 NO - 解除禁止
- (void)startPushButtonEnable:(BOOL)enable;

/// 开始上课/结束上课
/// @param start YES - 开始上课 NO - 结束上课
- (void)startClass:(BOOL)start;

/// 选中白板或文档
/// @param whiteboard YES - 选中白板 NO - 选中文档
- (void)selectedWhiteboardOrDocument:(BOOL)whiteboard;

/// 有新成员上线，成员按钮显示红点
- (void)hasNewMember;

/// 收到新的连麦申请
- (void)receivedNewJoinLinkMicRequest;

@end

NS_ASSUME_NONNULL_END
