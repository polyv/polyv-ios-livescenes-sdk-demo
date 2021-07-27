//
//  PLVLSMemberCell.h
//  PLVLiveStreamerDemo
//
//  Created by MissYasiky on 2021/3/29.
//  Copyright © 2021 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PLVChatUser;

NS_ASSUME_NONNULL_BEGIN

extern NSString *PLVLSMemberCellNotification;

@protocol PLVLSMemberCellDelegate <NSObject>

- (void)memberCell_didEditing:(BOOL)editing;

- (void)memberCell_didTapBan:(BOOL)banned withUer:(PLVChatUser *)user;

- (void)memberCell_didTapKickWithUer:(PLVChatUser *)user;

- (void)memberCell_didTapCameraSwitch;

@end

@interface PLVLSMemberCell : UITableViewCell

@property (nonatomic, weak) id<PLVLSMemberCellDelegate> delegate;

- (void)updateUser:(PLVChatUser *)user;

/// 显示左滑动画
- (void)showLeftDragAnimation;

+ (CGFloat)cellHeight;

@end

NS_ASSUME_NONNULL_END
