//
//  PLVLSDocumentUploadTipsView.h
//  PLVCloudClassStreamerModul
//
//  Created by MissYasiky on 2020/3/24.
//  Copyright © 2020 easefun. All rights reserved.
//  上传须知

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PLVLSDocumentUploadTipsView : UIView

/// 弹出弹层
/// @param view 展示弹层的父视图，弹层会插入到父视图的最顶上
- (void)showInView:(UIView *)view;

/// 隐藏弹层
- (void)dismiss;

@end

NS_ASSUME_NONNULL_END
