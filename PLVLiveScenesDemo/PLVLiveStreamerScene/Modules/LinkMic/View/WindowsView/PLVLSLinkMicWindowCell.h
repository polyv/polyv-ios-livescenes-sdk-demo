//
//  PLVLSLinkMicWindowCell.h
//  PLVLiveScenesDemo
//
//  Created by Lincal on 2021/4/9.
//  Copyright © 2021 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "PLVLinkMicOnlineUser.h"

NS_ASSUME_NONNULL_BEGIN

@interface PLVLSLinkMicWindowCell : UICollectionViewCell

#pragma mark 方法
- (void)setModel:(PLVLinkMicOnlineUser *)userModel;

@end

NS_ASSUME_NONNULL_END
