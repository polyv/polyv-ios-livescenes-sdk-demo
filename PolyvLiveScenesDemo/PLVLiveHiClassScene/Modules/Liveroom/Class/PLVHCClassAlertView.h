//
//  PLVHCClassAlertView.h
//  PLVLiveScenesDemo
//
//  Created by Sakya on 2021/7/4.
//  Copyright © 2021 PLV. All rights reserved.
//
// 学生端和讲师端上下课流程弹窗


#import <UIKit/UIKit.h>

//模块
#import "PLVRoomUser.h"

NS_ASSUME_NONNULL_BEGIN

///弹窗回调方法
typedef void (^PLVHCClassAlertBlock)(void);

@interface PLVHCClassAlertView : UIView

#pragma mark - 公用的

/// 离开教室确认提醒  学生或者讲师
/// @param view 需要添加到的视图
/// @param cancelActionBlock 撤销事件
/// @param confirmActionBlock 确定事件
+ (void)showExitClassroomAlertInView:(UIView *)view
                   cancelActionBlock:(PLVHCClassAlertBlock _Nullable)cancelActionBlock
                  confirmActionBlock:(PLVHCClassAlertBlock _Nullable)confirmActionBlock;

/// 【讲师端】课程结束后提示弹窗：查看课节
/// @param duration 本节课持续时间
/// @param callback 点击进入下节课的回调
+ (void)showTeacherLessonFinishNoticeInView:(UIView * _Nullable)view
                                   duration:(NSInteger)duration
                            confirmCallback:(PLVHCClassAlertBlock _Nullable)callback;

/// 【学生端】课程结束后提示弹窗：分为有下节课权限和无下节课权限
/// @param duration 本节课持续时间
/// @param nextClass 是否有下节课权限 当为NO的时候 title，time为空(学生端特有)
/// @param title 下节课课节名(学生端特有)
/// @param time 下节课的时间(学生端特有)
/// @param callback 点击进入下节课的回调
+ (void)showStudeentLessonFinishNoticeInView:(UIView * _Nullable)view
                                    duration:(NSInteger)duration
                               haveNextClass:(BOOL)nextClass
                                  classTitle:(NSString * _Nullable)title
                                   classTime:(NSString * _Nullable)time
                             confirmCallback:(PLVHCClassAlertBlock _Nullable)callback;

/// 清除视图
+ (void)clear;

#pragma mark - 讲师端

/// 讲师 - 下课确认提醒
/// @param cancelActionBlock 撤销回调
/// @param confirmActionBlock 确认回调
+ (void)showFinishClassConfirmInView:(UIView *)view
                   cancelActionBlock:(PLVHCClassAlertBlock _Nullable)cancelActionBlock
                  confirmActionBlock:(PLVHCClassAlertBlock _Nullable)confirmActionBlock;

/// 讲师开始上课3s 倒计时
/// @param callback 倒计时结束回调
+ (void)showTeacherStartClassCountdownInView:(UIView *)view
                                 endCallback:(PLVHCClassAlertBlock _Nullable)callback;

#pragma mark - 学生端

/// 学生端距离上课的倒计时
/// @param callback 倒计时结束回调
+ (void)showStudentClassCountdownInView:(UIView *)view
                               duration:(NSInteger)duration
                            endCallback:(PLVHCClassAlertBlock _Nullable)callback;


/// 学生端开始上课提醒， 可立即前往（讲师点了上课按钮，开始推流的时候 学生端显示的）
/// @param goClassCallback 立即前往回调
/// @param callback 倒计时结束回调
+ (void)showGoClassNowCountdownInView:(UIView * _Nullable)view
                      goClassCallback:(PLVHCClassAlertBlock _Nullable)goClassCallback
                          endCallback:(PLVHCClassAlertBlock _Nullable)callback;

/// 学生端 超时未上课提示占位图
+ (void)showOvertimeNoClassInView:(UIView *)view;

/// 学生端收到老师的上台连麦通知
/// @param callback 需要开始连麦回调
+ (void)showStudentLinkMicAlertInView:(UIView *)view
                      linkMicCallback:(PLVHCClassAlertBlock)callback;

/// 学生端 显示分组提示倒计时
/// @param titleString 标题
/// @param confirmActionTitle 确定按钮标题，可立即结束倒计时
/// @param callback 倒计时结束时的回调
+ (void)showStudentGroupCountdownInView:(UIView *)view
                            titleString:(NSString *)titleString
                        confirmActionTitle:(NSString * _Nullable)confirmActionTitle
                               endCallback:(PLVHCClassAlertBlock _Nullable)callback;

/// 学生端 开始分组 3s 倒计时
/// @param callback 倒计时结束回调
+ (void)showStudentStartGroupCountdownInView:(UIView *)view
                                 endCallback:(PLVHCClassAlertBlock _Nullable)callback;

@end

@interface PLVHCTeacherStartClassCountdownView : UIView

/// 开始倒计时，并且结束时回调
/// @param callback 倒计时结束时的回调
- (void)countdownViewEndCallback:(PLVHCClassAlertBlock)callback;

@end

@interface PLVHCStudentClassCountdownView : UIView

/// 开始倒计时，并且结束时回调
/// @param duration 倒计时时长
/// @param callback 倒计时结束时的回调
- (void)studentStartClassCountdownDuration:(NSTimeInterval)duration
                               endCallback:(PLVHCClassAlertBlock)callback;

- (void)clear;

@end

//老师点了上课按钮，开始推流的时候显示 学生端显示的
@interface PLVHCStudentGoClassCountdownView : UIView

/// 进入教室的倒计时提示框默认3s
/// @param goClassCallback 点击立即前往回调
/// @param callback 倒计时结束时的回调
- (void)startClassCountdownGoClassCallback:(PLVHCClassAlertBlock)goClassCallback
                               endCallback:(PLVHCClassAlertBlock)callback;

@end

///讲师端和学生端下课确认提示样式一样，文字不同
@interface PLVHCFinishClassConfirmAlertView : UIView
//下课确认提示文案
@property (nonatomic, copy) NSString *content;

- (void)finishClassConfirmCancelActionBlock:(PLVHCClassAlertBlock)cancelActionBlock
                        confirmActionBlock:(PLVHCClassAlertBlock)confirmActionBlock;

@end

@interface PLVHCClassFinishNoNextLessonAlertView : UIView

//确认按钮文案
@property (nonatomic, copy) NSString *confirmTitle;

- (void)setupLessonAlertWithDuration:(NSInteger)duration
                  confirmActionBlock:(PLVHCClassAlertBlock)confirmActionBlock;

@end

@interface PLVHCClassFinishHaveNextLessonAlertView : UIView

- (void)setupDuration:(NSInteger)duration
           classTitle:(NSString *)title
            classTime:(NSString *)time
    nextClassCallback:(PLVHCClassAlertBlock)callback;

@end


/// 学生收到连麦上台提醒的弹窗
@interface PLVHCStudentLinkMicAlertView : UIView

- (void)studentLinkMicAlertCallback:(PLVHCClassAlertBlock)callback;

@end

@interface PLVHCPlaceholderAlertView : UIView

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIImageView *imageView;

@end

NS_ASSUME_NONNULL_END
