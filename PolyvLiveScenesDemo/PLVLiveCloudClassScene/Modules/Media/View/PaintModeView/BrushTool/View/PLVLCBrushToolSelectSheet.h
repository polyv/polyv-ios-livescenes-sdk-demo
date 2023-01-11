//
//  PLVLCBrushToolSelectSheet.h
//  PLVLiveScenesDemo
//
//  Created by lijingtong on 2021/7/20.
//  Copyright © 2021 PLV. All rights reserved.
// 画笔工具选择弹层，用于选择画笔工具

#import <UIKit/UIKit.h>

// 依赖库
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>

NS_ASSUME_NONNULL_BEGIN
@class PLVLCBrushToolSelectSheet;

/// 类型枚举
typedef NS_ENUM(NSInteger, PLVLCBrushToolType) {
    PLVLCBrushToolTypeUnknown, // 未知
    PLVLCBrushToolTypeFreeLine, // 自由画笔
    PLVLCBrushToolTypeArrow, // 箭头
    PLVLCBrushToolTypeText, // 文本
    PLVLCBrushToolTypeRect, // 矩形框
    PLVLCBrushToolTypeEraser, // 橡皮擦
    PLVLCBrushToolTypeClear, // 清除画面
    PLVLCBrushToolTypeRevoke, // 撤回
};

@protocol PLVLCBrushToolSelectSheetDelegate <NSObject>

/// 选择画笔工具类型 回调
/// @param toolType 当前选择的画笔工具类型
/// @param selectImage 工具图像
/// @param localTouch 是否为本地点击 YES:本地用户点击，NO:JS事件回调（由-[PLVLCBrushToolSelectSheet updateBrushToolApplianceType:]触发）
- (void)brushToolSelectSheet:(PLVLCBrushToolSelectSheet *)brushToolSelectSheet didSelectToolType:(PLVLCBrushToolType)toolType selectImage:(UIImage *)selectImage localTouch:(BOOL)localTouch;

@end

@interface PLVLCBrushToolSelectSheet : UIView

@property (nonatomic, weak)id<PLVLCBrushToolSelectSheetDelegate> delegate;

/// 弹出弹层
/// @param view 展示弹层的父视图，弹层会插入到父视图的最顶上
- (void)showInView:(UIView *)view;

/// 隐藏弹层
- (void)dismiss;

/// 更新当前 画笔工具 类型，刷新UI
/// @param applianceType 画笔工具类型
- (void)updateBrushToolApplianceType:(PLVLCBrushToolType)applianceType;

- (void)updateLayout;

@end

NS_ASSUME_NONNULL_END
