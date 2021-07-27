//
//  PLVSALinkMicWindowCell.h
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2021/5/28.
//  Copyright © 2021 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "PLVLinkMicOnlineUser.h"

NS_ASSUME_NONNULL_BEGIN

@interface PLVSALinkMicWindowCell : UICollectionViewCell

#pragma mark 方法

/// 设置 cell 数据模型
/// @param onlineUser 数据模型
/// @param hide 当摄像头关闭时，是否要显示canvasView视图
- (void)setUserModel:(PLVLinkMicOnlineUser *)onlineUser hideCanvasViewWhenCameraClose:(BOOL)hide;

@end

NS_ASSUME_NONNULL_END
