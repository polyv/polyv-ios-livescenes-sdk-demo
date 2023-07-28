//
//  PLVSALinkMicPreviewView.h
//  PolyvLiveScenesDemo
//
//  Created by Sakya on 2022/11/30.
//  Copyright © 2022 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN


typedef NS_ENUM(NSUInteger, PLVSACancelLinkMicInvitationReason) {
    PLVSACancelLinkMicInvitationReason_Manual = 1,      // 主动手动取消连麦邀请
    PLVSACancelLinkMicInvitationReason_Timeout = 2,     // 超时取消连麦邀请
    PLVSACancelLinkMicInvitationReason_Permissions = 3, // 未授权音视频权限连麦邀请
};

@class PLVSALinkMicPreviewView;

@protocol PLVSALinkMicPreviewViewDelegate <NSObject>

/// 同意 连麦邀请
///
/// @param linkMicPreView 邀请连麦的预览视图
- (void)plvSALinkMicPreviewViewAcceptLinkMicInvitation:(PLVSALinkMicPreviewView *)linkMicPreView;

/// 取消 连麦邀请
/// @param linkMicPreView 邀请连麦的预览视图
/// @param reason 连麦邀请取消的原因
- (void)plvSALinkMicPreviewView:(PLVSALinkMicPreviewView *)linkMicPreView cancelLinkMicInvitationReason:(PLVSACancelLinkMicInvitationReason)reason;

/// 需要获取 连麦邀请 剩余的等待时间
/// @param linkMicPreView 邀请连麦的预览视图
/// @param callback 获取剩余时间的回调
- (void)plvSALinkMicPreviewView:(PLVSALinkMicPreviewView *)linkMicPreView inviteLinkMicTTL:(void (^)(NSInteger ttl))callback;

@end

/// 邀请连麦预览视图模块
@interface PLVSALinkMicPreviewView : UIView

#pragma mark - [ 属性 ]
@property (nonatomic, weak) id <PLVSALinkMicPreviewViewDelegate> delegate;
/// 当前频道是否只开启音频连麦
@property (nonatomic, assign) BOOL isOnlyAudio;
/// 摄像头是否已打开
@property (nonatomic, assign, readonly) BOOL cameraOpen;
/// 麦克风是否已打开
@property (nonatomic, assign, readonly) BOOL micOpen;

#pragma mark - [ 方法 ]
/// 是否显示邀请连麦预览视图
/// @param show 是否显示  YES 显示，NO 关闭
- (void)showLinkMicPreviewView:(BOOL)show;

@end

NS_ASSUME_NONNULL_END
