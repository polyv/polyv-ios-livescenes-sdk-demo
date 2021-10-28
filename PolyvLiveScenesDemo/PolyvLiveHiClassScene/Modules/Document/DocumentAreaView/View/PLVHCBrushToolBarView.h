//
//  PLVHCBrushToolBarView.h
//  PolyvLiveScenesDemo
//
//  Created by lijingtong on 2021/7/20.
//  Copyright © 2021 polyv. All rights reserved.
// 画笔工具视图，讲师或有画笔权限的学生可以操作以下画笔功能: 撤回、删除、选择画笔颜色、选择画笔工具
// 显示于PPT、白板右下角
// 本视图只做本地UI处理，不做JS事件的发送

#import <UIKit/UIKit.h>
#import "PLVHCBrushToolSelectSheet.h"
#import "PLVRoomUser.h"

NS_ASSUME_NONNULL_BEGIN

@class PLVHCBrushToolBarView;

@protocol PLVHCBrushToolbarViewDelegate <NSObject>

/// 点击 画笔工具按钮 回调
- (void)brushToolBarViewDidTapToolButton:(PLVHCBrushToolBarView *)brushToolBarView;

/// 点击 画笔颜色按钮 回调
- (void)brushToolBarViewDidTapColorButton:(PLVHCBrushToolBarView *)brushToolBarView;

/// 点击 撤销按钮 回调
- (void)brushToolBarViewDidTapRevokeButton:(PLVHCBrushToolBarView *)brushToolBarView;

/// 点击 删除按钮 回调
- (void)brushToolBarViewDidTapDeleteButton:(PLVHCBrushToolBarView *)brushToolBarView;

@end

@interface PLVHCBrushToolBarView : UIView

@property (nonatomic, weak) id<PLVHCBrushToolbarViewDelegate> delegate;

/// 是否有画笔权限，YES：可以使用画笔工具；NO：不可以使用画笔工具
/// @note 讲师登录为YES，其他身份默认为NO，可通过讲师授权设置为YES
@property (nonatomic, assign) BOOL haveBrushPermission;

/// 屏幕的安全宽度，本视图根据此数值设置自身frame
@property (nonatomic, assign) CGFloat screenSafeWidth;

#pragma mark  UI

/// 弹出弹层
/// @param view 展示弹层的父视图，弹层会插入到父视图的最顶上
- (void)showInView:(UIView *)view;

/// 隐藏弹层
- (void)dismiss;

#pragma mark 画笔

/// 更新选择的画笔工具类型，刷新UI
/// @param toolType 画笔工具类型
/// @param selectImage 画笔工具图片
- (void)updateSelectToolType:(PLVHCBrushToolType)toolType selectImage:(UIImage *)selectImage;

/// 更新选择的画笔颜色，刷新UI
/// @param color 画笔颜色
- (void)updateSelectColor:(NSString *)color;

/// 更新工具状态
/// @param dict 工具状态
- (void)updateBrushToolStatusWithDict:(NSDictionary *)dict;

@end

NS_ASSUME_NONNULL_END
