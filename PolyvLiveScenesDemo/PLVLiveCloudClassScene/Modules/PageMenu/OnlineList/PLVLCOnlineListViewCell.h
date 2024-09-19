//
//  PLVLCOnlineListViewCell.h
//  PolyvLiveScenesDemo
//
//  Created by Dhan on 2024/9/3.
//  Copyright © 2024 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PLVChatUser.h"

NS_ASSUME_NONNULL_BEGIN

@interface PLVLCOnlineListViewCell : UITableViewCell

- (void)updateUser:(PLVChatUser *)user;

- (void)updateUser:(PLVChatUser *)user isLandscape:(BOOL)isLandscape;

@end

NS_ASSUME_NONNULL_END
