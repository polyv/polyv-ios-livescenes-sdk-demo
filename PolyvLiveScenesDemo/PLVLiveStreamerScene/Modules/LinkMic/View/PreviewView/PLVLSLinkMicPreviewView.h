//
//  PLVLSLinkMicPreviewView.h
//  PolyvLiveScenesDemo
//
//  Created by Sakya on 2023/5/17.
//  Copyright © 2023 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
typedef NS_ENUM(NSUInteger, PLVLSCancelLinkMicInvitationReason) {
    PLVLSCancelLinkMicInvitationReason_Manual = 1,      // 主动手动取消连麦邀请
    PLVLSCancelLinkMicInvitationReason_Timeout = 2,     // 超时取消连麦邀请
    PLVLSCancelLinkMicInvitationReason_Permissions = 3, // 未授权音视频权限连麦邀请
};

@class PLVLSLinkMicPreviewView;

@protocol PLVLSLinkMicPreviewViewDelegate <NSObject>

/// 同意 连麦邀请
///
/// @param linkMicPreView 邀请连麦的预览视图
- (void)plvLSLinkMicPreviewViewAcceptLinkMicInvitation:(PLVLSLinkMicPreviewView *)linkMicPreView;

/// 取消 连麦邀请
/// @param linkMicPreView 邀请连麦的预览视图
/// @param reason 连麦邀请取消的原因
- (void)plvLSLinkMicPreviewView:(PLVLSLinkMicPreviewView *)linkMicPreView cancelLinkMicInvitationReason:(PLVLSCancelLinkMicInvitationReason)reason;

/// 需要获取 连麦邀请 剩余的等待时间
/// @param linkMicPreView 邀请连麦的预览视图
/// @param callback 获取剩余时间的回调
- (void)plvLSLinkMicPreviewView:(PLVLSLinkMicPreviewView *)linkMicPreView inviteLinkMicTTL:(void (^)(NSInteger ttl))callback;

@end

@interface PLVLSLinkMicPreviewView : UIView

#pragma mark - [ 属性 ]
@property (nonatomic, weak) id <PLVLSLinkMicPreviewViewDelegate> delegate;
/// 当前频道是否只开启音频连麦 默认NO 开启音视频连麦
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
