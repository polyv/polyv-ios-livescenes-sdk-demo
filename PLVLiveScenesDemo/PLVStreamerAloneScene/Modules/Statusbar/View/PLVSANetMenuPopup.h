//
//  PLVSANetMenuPopup.h
//  PLVLiveScenesDemo
//
//  Created by lijingtong on 2021/5/25.
//  Copyright © 2021 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 点击网络状态显示
@interface PLVSANetMenuPopup : UIView

/// 初始化menu
/// @param frame frame
- (instancetype)initWithMenuFrame:(CGRect)frame;

/// 显示menu
/// @param superView 准备显示在哪个控件上
- (void)showAtView:(UIView *)superView;

/// 关闭menu
- (void)dismiss;

@end

NS_ASSUME_NONNULL_END
