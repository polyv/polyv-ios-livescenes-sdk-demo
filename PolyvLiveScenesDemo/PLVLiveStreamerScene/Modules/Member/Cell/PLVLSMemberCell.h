//
//  PLVLSMemberCell.h
//  PLVLiveStreamerDemo
//
//  Created by MissYasiky on 2021/3/29.
//  Copyright © 2021 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PLVChatUser, PLVLSMemberCell;

NS_ASSUME_NONNULL_BEGIN

extern NSString *PLVLSMemberCellNotification;

@protocol PLVLSMemberCellDelegate <NSObject>

- (void)memberCell_didEditing:(BOOL)editing;

- (void)memberCell_didTapBan:(BOOL)banned withUser:(PLVChatUser *)user;

- (void)memberCell_didTapKickWithUser:(PLVChatUser *)user;

- (void)memberCell_didTapCameraSwitch;

- (void)memberCell_inviteUserJoinLinkMic:(PLVChatUser *)user;

- (BOOL)allowLinkMicInCell:(PLVLSMemberCell *)cell;

- (BOOL)localUserIsRealMainSpeakerInCell:(PLVLSMemberCell *)cell;

/// 本地用户是否是第一画面
- (BOOL)localUserIsRealFirstSiteInCell:(PLVLSMemberCell *)cell;

/// 是否开启音视频连麦（YES开启，NO关闭）
- (BOOL)enableAudioVideoLinkMicInCell:(PLVLSMemberCell *)cell;

/// 是否开始上课
- (BOOL)startClassInCell:(PLVLSMemberCell *)cell;

@end

@interface PLVLSMemberCell : UITableViewCell

@property (nonatomic, weak) id<PLVLSMemberCellDelegate> delegate;

- (void)updateUser:(PLVChatUser *)user;

/// 显示左滑动画
- (void)showLeftDragAnimation;

/// 关闭麦克风和摄像头 (调用该方法时 app暂未获得麦克风和摄像头权限 所以该方法只是在UI上做了处理)
- (void)closeLinkmicAndCamera;

+ (CGFloat)cellHeight;

@end

NS_ASSUME_NONNULL_END
