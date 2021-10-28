//
//  PLVHCMemberSheetHeaderView.h
//  PolyvLiveScenesDemo
//
//  Created by MissYasiky on 2021/7/29.
//  Copyright © 2021 polyv. All rights reserved.
//
// 成员列表弹层顶部子视图

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PLVHCMemberSheetHeaderView : UIView

@property (nonatomic, strong) UIButton *closeMicButton; // 【全体禁麦】按钮
@property (nonatomic, strong) UIButton *leaveLinkMicButton; // 【全体下台】按钮
@property (nonatomic, strong) UIButton *changeListButton; // 切换列表数据按钮

/// 设置列表标题文本
/// @param text 列表标题文本
- (void)setTableTitle:(NSString *)text;

/// 设置举手人数
/// @param count 举手人数
- (void)setHandupLabelCount:(NSInteger)count;

@end

NS_ASSUME_NONNULL_END
