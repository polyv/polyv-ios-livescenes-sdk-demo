//
//  PLVSAMemberCell.h
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2021/6/4.
//  Copyright © 2021 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PLVChatUser;
@class PLVSAMemberCell;

NS_ASSUME_NONNULL_BEGIN

@protocol PLVSAMemberCellDelegate <NSObject>

@required

- (BOOL)allowLinkMicInCell:(PLVSAMemberCell *)cell;

- (void)didTapMoreButtonInCell:(PLVSAMemberCell *)cell chatUser:(PLVChatUser *)chatUser;

@end

@interface PLVSAMemberCell : UITableViewCell

@property (nonatomic, weak) id<PLVSAMemberCellDelegate> delegate;

- (void)updateUser:(PLVChatUser *)user;

+ (CGFloat)cellHeight;

@end

NS_ASSUME_NONNULL_END
