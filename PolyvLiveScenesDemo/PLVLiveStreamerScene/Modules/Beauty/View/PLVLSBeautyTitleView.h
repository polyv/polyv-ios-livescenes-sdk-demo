//
//  PLVLSBeautyTitleView.h
//  PolyvLiveScenesDemo
//
//  Created by JTom on 2022/4/14.
//  Copyright © 2022 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PLVBeautyViewModel.h"

NS_ASSUME_NONNULL_BEGIN

@class PLVLSBeautyTitleView;
@protocol PLVLSBeautyTitleViewDelegate <NSObject>

- (void)beautyTitleView:(PLVLSBeautyTitleView *)beautyTitleView didTapButton:(PLVBeautyType)type;

@end

@interface PLVLSBeautyTitleView : UIView

@property (nonatomic, weak) id<PLVLSBeautyTitleViewDelegate> delegate;

/// 选择标题
/// @param type 标题类型
- (void)selectTitleButtonWithType:(PLVBeautyType)type;

@end

NS_ASSUME_NONNULL_END
