//
//  PLVHCHiClassToast.h
//  PLVLiveScenesDemo
//
//  Created by Sakya on 2021/8/4.
//  Copyright © 2021 PLV. All rights reserved.
//
// 互动学堂通用Toast

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, PLVHCToastType) {
    PLVHCToastTypeText = 0, //仅文本toast
    
    PLVHCToastTypeIcon_OnStage, //已上台提示
    PLVHCToastTypeIcon_OpenMic, //开启麦克风
    PLVHCToastTypeIcon_CloseMic, //关闭麦克风
    PLVHCToastTypeIcon_OpenCamera, //开启摄像头
    PLVHCToastTypeIcon_CloseCamera, //关闭摄像头
    PLVHCToastTypeIcon_AuthBrush, //授予画笔权限
    PLVHCToastTypeIcon_CancelAuthBrush, //撤销画笔权限
    PLVHCToastTypeIcon_MicDamage, //麦克风已损坏
    PLVHCToastTypeIcon_CameraDamage, //摄像头已损坏
    PLVHCToastTypeIcon_DocumentCountOver, //只支持同时打开 5 个文档
    PLVHCToastTypeIcon_CoursewareDelete, //已删除课件
    PLVHCToastTypeIcon_MicAllAanned, //已全体禁麦(关闭麦克风)
    PLVHCToastTypeIcon_AllStepDown, //已全体下台
    PLVHCToastTypeIcon_StudentOnStage, //学生已上台
    PLVHCToastTypeIcon_StudentStepDown, //学生已下台
    PLVHCToastTypeIcon_NoStudentOnStage, //台上没有学生
    PLVHCToastTypeIcon_MuteOpen, //开启禁言
    PLVHCToastTypeIcon_MuteClose, //关闭禁言
    PLVHCToastTypeIcon_StudentMoveOut, //已将学生移出教室
    PLVHCToastTypeIcon_AwardTrophy, //奖励一个奖杯
    PLVHCToastTypeIcon_NetworkError, //网络异常
    PLVHCToastTypeIcon_StartGroup, // 开始分组

};

@interface PLVHCHiClassToast : UIView

#pragma mark - Methods

+ (PLVHCHiClassToast *)sharedView;

/// 只有文字的toast
/// @param message 提示文字
+ (void)showToastWithMessage:(NSString *)message;

/// 只有文字的toast
/// @param message 提示文字
/// @param delay Toast持续时长
+ (void)showToastWithMessage:(NSString *)message delay:(NSTimeInterval)delay;

/// 包含不同图案和文字的提示
/// @param type 提示toast类型
/// @param message 提示文字
+ (void)showToastWithType:(PLVHCToastType)type message:(NSString *)message;

@end

NS_ASSUME_NONNULL_END
