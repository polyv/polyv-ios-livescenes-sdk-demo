//
//  PLVLCBrushToolBarView.h
//  PLVLiveScenesDemo
//
//  Created by lijingtong on 2021/7/20.
//  Copyright © 2021 PLV. All rights reserved.
// 画笔工具视图，讲师或有画笔权限的学生可以操作以下画笔功能: 撤回、删除、选择画笔颜色、选择画笔工具
// 显示于PPT、白板右下角
// 本视图只做本地UI处理，不做JS事件的发送

#import <UIKit/UIKit.h>
#import "PLVLCBrushToolSelectSheet.h"
#import "PLVRoomUser.h"

NS_ASSUME_NONNULL_BEGIN

@class PLVLCBrushToolBarView;

@protocol PLVLCBrushToolBarViewDelegate <NSObject>

/// 点击 画笔工具按钮 回调
- (void)brushToolBarViewDidTapToolButton:(PLVLCBrushToolBarView *)brushToolBarView;

/// 点击 画笔颜色按钮 回调
- (void)brushToolBarViewDidTapColorButton:(PLVLCBrushToolBarView *)brushToolBarView;

/// 点击 撤销按钮 回调
- (void)brushToolBarViewDidTapRevokeButton:(PLVLCBrushToolBarView *)brushToolBarView;

@end

@interface PLVLCBrushToolBarView : UIView

@property (nonatomic, weak) id<PLVLCBrushToolBarViewDelegate> delegate;

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
- (void)updateSelectToolType:(PLVLCBrushToolType)toolType selectImage:(UIImage *)selectImage;

/// 更新选择的画笔颜色，刷新UI
/// @param color 画笔颜色
- (void)updateSelectColor:(NSString *)color;

@end

NS_ASSUME_NONNULL_END
