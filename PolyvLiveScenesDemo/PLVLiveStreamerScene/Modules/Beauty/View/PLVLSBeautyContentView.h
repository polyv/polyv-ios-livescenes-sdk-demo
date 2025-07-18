//
//  PLVLSBeautyContentView.h
//  PolyvLiveScenesDemo
//
//  Created by JTom on 2022/4/14.
//  Copyright © 2022 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PLVBeautyViewModel.h"

NS_ASSUME_NONNULL_BEGIN
@interface PLVLSBeautyContentView : UIView

- (void)selectContentViewWithType:(PLVBeautyType)type;

/// 开启/关闭 美颜
/// @param open YES:开启 NO:关闭
- (void)beautyOpen:(BOOL)open;

/// 重置美颜
- (void)resetBeauty;

/// 强制刷新内容视图布局，用于处理开播时的布局变化
- (void)refreshContentViewLayout;

@end

NS_ASSUME_NONNULL_END
