//
//  PLVLSMixLayoutSheet.h
//  PLVLiveScenesDemo
//
//  Created by Dhan on 2023/7/25.
//  Copyright © 2023 PLV. All rights reserved.
//

#import "PLVLSSideSheet.h"
#import "PLVRoomData.h"

NS_ASSUME_NONNULL_BEGIN

@protocol PLVLSMixLayoutSheetDelegate <NSObject>

- (void)mixLayoutSheet_didChangeMixLayoutType:(PLVMixLayoutType)type;
- (void)mixLayoutSheet_didSelectBackgroundColor:(PLVMixLayoutBackgroundColor)colorType;

@end

@interface PLVLSMixLayoutSheet : PLVLSSideSheet

@property (nonatomic, weak) id<PLVLSMixLayoutSheetDelegate> delegate;


/**
 初始化连麦布局和背景设置选项
 
 @param currentMixLayoutType 当前连麦布局类型
 @param currentBackgroundColor 当前背景颜色类型
 */
- (void)setupOptionsWithCurrentMixLayoutType:(PLVMixLayoutType)currentMixLayoutType
                      currentBackgroundColor:(PLVMixLayoutBackgroundColor)currentBackgroundColor;

/**
 更新连麦布局选中对应按钮
 
 @param currentType 当前连麦布局类型
 */
- (void)updateMixLayoutType:(PLVMixLayoutType)currentType;

/**
 更新背景选中对应按钮

 @param colorType 当前背景颜色类型
 */
- (void)updateBackgroundSelectedColorType:(PLVMixLayoutBackgroundColor)colorType;

@end

NS_ASSUME_NONNULL_END
