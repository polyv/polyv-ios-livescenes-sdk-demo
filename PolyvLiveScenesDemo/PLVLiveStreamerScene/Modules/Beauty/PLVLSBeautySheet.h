//
//  PLVSABeautySheet.h
//  PolyvLiveScenesDemo
//
//  Created by JTom on 2022/4/13.
//  Copyright © 2022 PLV. All rights reserved.
// 美颜管理弹层

#import "PLVLSBottomSheet.h"

NS_ASSUME_NONNULL_BEGIN
@class PLVLSBeautySheet;
@protocol PLVLSBeautySheetDelegate <NSObject>

/// 美颜开启、关闭 回调
/// @param on YES: 开启 NO: 关闭
- (void)beautySheet:(PLVLSBeautySheet *)beautySheet didChangeOn:(BOOL)on;

/// 美颜设置弹层显示、隐藏回调 可用于做一些显示、隐藏UI操作
/// @param show YES: 显示 NO: 隐藏
- (void)beautySheet:(PLVLSBeautySheet *)beautySheet didChangeShow:(BOOL)show;

@end

@interface PLVLSBeautySheet : PLVLSBottomSheet

@property (nonatomic, weak) id<PLVLSBeautySheetDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
