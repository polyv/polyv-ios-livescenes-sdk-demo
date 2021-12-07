//
//  PLVHCMemberSheet.h
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2021/6/24.
//  Copyright © 2021 PLV. All rights reserved.
//
// 成员列表弹层

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class PLVChatUser;

@protocol PLVHCMemberSheetDelegate;

@interface PLVHCMemberSheet : UIView

@property (nonatomic, weak) id<PLVHCMemberSheetDelegate> delegate;

/// 弹出弹层
/// @param superView 展示弹层的父视图，弹层会插入到父视图的最顶上
- (void)showInView:(UIView *)superView;

/// 收起弹层
- (void)dismiss;

/// 设置举手总人数
/// @param count 举手总人数
- (void)setHandupLabelCount:(NSInteger)count;

///【讲师端】收到学生上台结果回调
/// @param success YES上台成功 NO上台异常
/// @param linkMicId 上台学生的连麦ID
- (void)linkMicUserJoinAnswer:(BOOL)success linkMicId:(NSString *)linkMicId;

@end

@protocol PLVHCMemberSheetDelegate <NSObject>

@optional

/// 讲师上台下台操作
/// @param linkMic （YES 连麦 NO 下麦）
- (void)inviteUserLinkMicInMemberSheet:(PLVHCMemberSheet *)memberSheet
                               linkMic:(BOOL)linkMic
                              chatUser:(PLVChatUser *)chatUser;

/// 全员下台操作
- (void)closeAllLinkMicUserInMemberSheet:(PLVHCMemberSheet *)memberSheet;

/// 全员静音操作
/// @param mute (YES-静音;NO-取消静音 )
- (void)muteAllLinkMicUserMicInMemberSheet:(PLVHCMemberSheet *)memberSheet
                                      mute:(BOOL)mute;

@end

NS_ASSUME_NONNULL_END
