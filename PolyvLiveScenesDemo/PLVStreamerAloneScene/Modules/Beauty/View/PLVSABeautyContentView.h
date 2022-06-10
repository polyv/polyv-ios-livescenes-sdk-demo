//
//  PLVSABeautyContentView.h
//  PolyvLiveScenesDemo
//
//  Created by JTom on 2022/4/14.
//  Copyright © 2022 PLV. All rights reserved.
// 美颜详细内容视图

#import <UIKit/UIKit.h>
#import "PLVSABeautyViewModel.h"

NS_ASSUME_NONNULL_BEGIN
@interface PLVSABeautyContentView : UIView

/// 选中美颜类型
/// @param type 美颜类型
- (void)selectContentViewWithType:(PLVSABeautyType)type;

/// 开启/关闭 美颜
/// @param open YES:开启 NO:关闭
- (void)beautyOpen:(BOOL)open;

/// 重置美颜
- (void)resetBeauty;

@end

NS_ASSUME_NONNULL_END
