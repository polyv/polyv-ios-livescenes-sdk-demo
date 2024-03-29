//
//  PLVHCGrantCupView.h
//  PLVLiveScenesDemo
//
//  Created by lijingtong on 2021/8/23.
//  Copyright © 2021 PLV. All rights reserved.
// 被授权奖杯的特效、音效视图

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PLVHCGrantCupView : UIView

/// 显示在目标视图上层
/// @param nickName 被授予奖杯的学生昵称
+ (void)showWithNickName:(NSString *)nickName;

@end

NS_ASSUME_NONNULL_END
