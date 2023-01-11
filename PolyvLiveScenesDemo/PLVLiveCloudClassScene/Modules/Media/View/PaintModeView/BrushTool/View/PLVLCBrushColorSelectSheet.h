//
//  PLVLCBrushColorSelectSheet.h
//  PLVLiveScenesDemo
//
//  Created by lijingtong on 2021/7/20.
//  Copyright © 2021 PLV. All rights reserved.
// 画笔颜色选择弹层，用于选择画笔颜色值
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@class PLVLCBrushColorSelectSheet;

@protocol PLVLCBrushColorSelectSheetDelegate <NSObject>

/// 选择 颜色 回调
/// @param color 当前选择的颜色
/// @param localTouch 是否为本地点击 YES:本地用户点击，NO:JS事件回调（由-[PLVLCBrushColorSelectSheet updateSelectColor:]触发）
- (void)brushColorSelectSheet:(PLVLCBrushColorSelectSheet *)brushColorSelectSheet didSelectColor:(NSString *)color localTouch:(BOOL)localTouch;

@end

@interface PLVLCBrushColorSelectSheet : UIView

@property (nonatomic, weak)id<PLVLCBrushColorSelectSheetDelegate> delegate;

/// 弹出弹层
/// @param view 展示弹层的父视图，弹层会插入到父视图的最顶上
- (void)showInView:(UIView *)view;

/// 隐藏弹层
- (void)dismiss;

/// 更新当前 画笔颜色，刷新UI
/// @note 用于接收JS事件'changeStrokeStyle'回调后更新当前画笔颜色
/// @param color 画笔颜色
/// @param localTrigger 是否是本地触发的
- (void)updateSelectColor:(NSString *)color localTrigger:(BOOL)localTrigger;

@end

NS_ASSUME_NONNULL_END
