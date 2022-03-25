//
//  PLVLCDocumentToolViewPopup.h
//  PLVLiveScenesDemo
//
//  Created by lijingtong on 2021/10/20.
//  Copyright © 2021 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PLVLCDocumentToolViewPopup : UIView

- (instancetype)initWithMenuFrame:(CGRect)frame;

/// 弹出弹层
/// @param parentView 展示弹层的父视图，弹层会插入到父视图的最顶上
- (void)showInView:(UIView *)parentView;

/// 隐藏聊天室视图
- (void)dismiss;

@end

NS_ASSUME_NONNULL_END
