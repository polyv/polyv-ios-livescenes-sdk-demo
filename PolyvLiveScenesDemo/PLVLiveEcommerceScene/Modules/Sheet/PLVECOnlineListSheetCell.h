//
//  PLVECOnlineListSheetCell.h
//  PolyvLiveScenesDemo
//
//  Created by Dhan on 2024/9/6.
//  Copyright © 2024 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PLVChatUser.h"

NS_ASSUME_NONNULL_BEGIN

@interface PLVECOnlineListSheetCell : UITableViewCell

- (void)updateUser:(PLVChatUser *)user;

@end

NS_ASSUME_NONNULL_END
