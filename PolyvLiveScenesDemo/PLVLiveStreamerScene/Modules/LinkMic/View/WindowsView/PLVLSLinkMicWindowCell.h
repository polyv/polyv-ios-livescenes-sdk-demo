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

/// 切换至 显示默认内容视图
- (void)switchToShowRtcContentView:(UIView *)rtcCanvasView;

/// 切换至 显示外部内容视图
- (void)switchToShowExternalContentView:(UIView *)externalContentView;

@end

NS_ASSUME_NONNULL_END
