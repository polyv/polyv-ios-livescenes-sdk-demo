//
//  PLVSABeautyTitleView.h
//  PolyvLiveScenesDemo
//
//  Created by JTom on 2022/4/14.
//  Copyright © 2022 PLV. All rights reserved.
// 美颜类型标题视图

#import <UIKit/UIKit.h>
#import "PLVSABeautyViewModel.h"

NS_ASSUME_NONNULL_BEGIN

@class PLVSABeautyTitleView;
@protocol PLVSABeautyTitleViewDelegate <NSObject>
/// 点击 美颜类型按钮 时回调
- (void)beautyTitleView:(PLVSABeautyTitleView *)beautyTitleView didTapButton:(PLVSABeautyType)type;

@end

@interface PLVSABeautyTitleView : UIView

@property (nonatomic, weak) id<PLVSABeautyTitleViewDelegate> delegate;

/// 选择标题
/// @param type 标题类型
- (void)selectTitleButtonWithType:(PLVSABeautyType)type;

@end

NS_ASSUME_NONNULL_END
