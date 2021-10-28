//
//  PLVHCBrushToolSelectSheet.h
//  PolyvLiveScenesDemo
//
//  Created by lijingtong on 2021/7/20.
//  Copyright © 2021 polyv. All rights reserved.
// 画笔工具选择弹层，用于选择画笔工具

#import <UIKit/UIKit.h>

// 依赖库
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>

NS_ASSUME_NONNULL_BEGIN
@class PLVHCBrushToolSelectSheet;

/// 类型枚举
typedef NS_ENUM(NSInteger, PLVHCBrushToolType) {
    PLVHCBrushToolTypeUnknown, // 未知
    PLVHCBrushToolTypeChoice, // 选择工具
    PLVHCBrushToolTypeFreeLine, // 自由画笔
    PLVHCBrushToolTypeArrow, // 箭头
    PLVHCBrushToolTypeText, // 文本
    PLVHCBrushToolTypeEraser, // 橡皮擦
    PLVHCBrushToolTypeClear, // 清除画面
    PLVHCBrushToolTypeRevoke, // 撤回
    PLVHCBrushToolTypeMove  // 移动
};

@protocol PLVHCBrushToolSelectSheetDelegate <NSObject>

/// 选择画笔工具类型 回调
/// @param toolType 当前选择的画笔工具类型
/// @param selectImage 工具图像
/// @param localTouch 是否为本地点击 YES:本地用户点击，NO:JS事件回调（由-[PLVHCBrushToolSelectSheet updateBrushToolApplianceType:]触发）
- (void)brushToolSelectSheet:(PLVHCBrushToolSelectSheet *)brushToolSelectSheet didSelectToolType:(PLVHCBrushToolType)toolType selectImage:(UIImage *)selectImage localTouch:(BOOL)localTouch;

@end

@interface PLVHCBrushToolSelectSheet : UIView

@property (nonatomic, weak)id<PLVHCBrushToolSelectSheetDelegate> delegate;

/// 弹出弹层
/// @param view 展示弹层的父视图，弹层会插入到父视图的最顶上
- (void)showInView:(UIView *)view;

/// 隐藏弹层
- (void)dismiss;

/// 更新当前 画笔工具 类型，刷新UI
/// @note 用于接收JS事件'changeAppliance'回调后更新当前画笔工具
/// @param applianceType 画笔工具类型
- (void)updateBrushToolApplianceType:(PLVContainerApplianceType)applianceType;

@end

NS_ASSUME_NONNULL_END
