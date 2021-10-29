//
//  PLVHCOnlineMemberCell.h
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2021/8/3.
//  Copyright © 2021 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class PLVHCOnlineMemberCell, PLVChatUser;

@protocol PLVHCOnlineMemberCellDelegate <NSObject>

@required

- (BOOL)allowLinkMicInCell:(PLVHCOnlineMemberCell *)cell;

@optional

- (void)banUserInOnlineMemberCell:(PLVHCOnlineMemberCell *)memberCell bannedUser:(PLVChatUser *)user banned:(BOOL)banned;

- (void)kickUserInOnlineMemberCell:(PLVHCOnlineMemberCell *)memberCell kickedUser:(PLVChatUser *)user;

/// 点击用户上台或下台操作 - 主动
/// @param linkMic YES 上台连麦 NO 下台
- (void)linkMicInOnlineMemberCell:(PLVHCOnlineMemberCell *)memberCell linkMicUser:(PLVChatUser *)user linkMic:(BOOL)linkMic;

/// 学生连麦完成的回调 - 被动
- (void)linkMicCompleteInOnlineMemberCell:(PLVHCOnlineMemberCell *)memberCell linkMicUser:(PLVChatUser *)user;

@end

@interface PLVHCOnlineMemberCell : UITableViewCell

@property (nonatomic, weak) id<PLVHCOnlineMemberCellDelegate> delegate;

- (void)setChatUser:(PLVChatUser *)user even:(BOOL)even;

//用户上台连麦结果回调(失败时需要停止加载的计时器)
- (void)updateUserLinkMicAnswer:(BOOL)success;

+ (CGFloat)cellHeight;

@end

NS_ASSUME_NONNULL_END
