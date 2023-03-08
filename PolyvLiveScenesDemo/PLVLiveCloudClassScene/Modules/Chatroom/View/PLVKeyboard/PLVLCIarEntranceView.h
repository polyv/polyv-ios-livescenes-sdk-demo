//
//  PLVLCIarEntranceView.h
//  PolyvLiveScenesDemo
//
//  Created by Dhan on 2023/2/21.
//  Copyright © 2023 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

#define PLVLCIarEntranceViewHeight (28.0)

NS_ASSUME_NONNULL_BEGIN

@class PLVLCIarEntranceView;

@protocol PLVLCIarEntranceViewDelegate <NSObject>

/// 打开互动应用模块
- (void)iarEntranceView_openInteractApp:(PLVLCIarEntranceView *)iarEntranceView eventName:(NSString *)eventName;

@end

@interface PLVLCIarEntranceView : UIView

@property (nonatomic, weak) id<PLVLCIarEntranceViewDelegate> delegate;

/// 更新按钮数据（根据传入的数据动态更新按钮）
/// @param dataArray 前端传入的按钮数据
- (void)updateIarEntranceButtonDataArray:(NSArray *)dataArray;

@end

NS_ASSUME_NONNULL_END
