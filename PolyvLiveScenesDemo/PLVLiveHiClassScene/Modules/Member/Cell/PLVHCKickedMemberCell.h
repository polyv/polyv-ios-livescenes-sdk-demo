//
//  PLVHCKickedMemberCell.h
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2021/8/3.
//  Copyright © 2021 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class PLVHCKickedMemberCell, PLVChatUser;

@protocol PLVHCKickedMemberCellDelegate <NSObject>

- (void)unkickUserInKickedMemberCell:(PLVHCKickedMemberCell *)memberCell user:(PLVChatUser *)user;

@end

@interface PLVHCKickedMemberCell : UITableViewCell

@property (nonatomic, weak) id<PLVHCKickedMemberCellDelegate> delegate;

- (void)setChatUser:(PLVChatUser *)user even:(BOOL)even;

+ (CGFloat)cellHeight;

@end

NS_ASSUME_NONNULL_END
