//
//  PLVHCStudentGroupCountdownView.h
//  PLVLiveScenesDemo
//
//  Created by lijingtong on 2021/10/26.
//  Copyright © 2021 PLV. All rights reserved.
// 学生分组讨论倒计时视图

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

///弹窗回调方法
typedef void (^PLVHCStudentGroupCountdownViewEndCallBlock)(void);

@interface PLVHCStudentGroupCountdownView : UIView

/// 开始倒计时，并且结束时回调
/// @param titleString 标题
/// @param confirmActionTitle 确定按钮标题，可立即结束倒计时
/// @param callback 倒计时结束时的回调
- (void)countdownViewWithTitleString:(NSString *)titleString
                        confirmActionTitle:(NSString * _Nullable)confirmActionTitle
                               endCallback:(PLVHCStudentGroupCountdownViewEndCallBlock)callback;


/// 开始倒计时，并且结束时回调
/// @param callback 倒计时结束时的回调
- (void)countdownViewEndCallback:(PLVHCStudentGroupCountdownViewEndCallBlock)callback;

/// 清除倒计时视图
/// @note 内部会停止与清除定时器
- (void)clear;

@end

NS_ASSUME_NONNULL_END
