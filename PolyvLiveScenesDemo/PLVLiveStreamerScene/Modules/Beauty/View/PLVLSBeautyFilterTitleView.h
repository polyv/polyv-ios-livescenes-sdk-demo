//
//  PLVLSBeautyFilterTitleView.h
//  PolyvLiveScenesDemo
//
//  Created by lijingtong on 2022/4/21.
//  Copyright © 2022 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PLVLSBeautyFilterTitleView : UIView

/// 显示当前选择的滤镜
/// @param superView 准备显示在哪个控件上
/// @param title 滤镜名称
- (void)showAtView:(UIView *)superView title:(NSString *)title;

@end

NS_ASSUME_NONNULL_END
