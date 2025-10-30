//
//  PLVSAMixLayoutSheet.h
//  PLVLiveScenesDemo
//
//  Created by Dhan on 2023/7/25.
//  Copyright © 2023 PLV. All rights reserved.
//

#import "PLVSABottomSheet.h"
#import "PLVRoomData.h"

NS_ASSUME_NONNULL_BEGIN

@class PLVSAMixLayoutSheet;

@protocol PLVSAMixLayoutSheetDelegate <NSObject>

- (void)plvsaMixLayoutSheet:(PLVSAMixLayoutSheet *)mixLayoutSheet mixLayoutButtonClickWithMixLayoutType:(PLVMixLayoutType)type;
- (void)plvsaMixLayoutSheet:(PLVSAMixLayoutSheet *)mixLayoutSheet didSelectBackgroundColor:(PLVMixLayoutBackgroundColor)colorType;

@end

@interface PLVSAMixLayoutSheet : PLVSABottomSheet

@property (nonatomic, weak) id<PLVSAMixLayoutSheetDelegate> delegate;

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
