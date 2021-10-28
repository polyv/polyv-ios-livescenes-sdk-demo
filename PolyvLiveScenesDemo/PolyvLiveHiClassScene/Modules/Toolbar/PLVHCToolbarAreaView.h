//
//  PLVHCToolbarAreaView.h
//  PolyvLiveScenesDemo
//
//  Created by MissYasiky on 2021/6/24.
//  Copyright © 2021 polyv. All rights reserved.
//
// 工具栏区域视图

#import <UIKit/UIKit.h>


NS_ASSUME_NONNULL_BEGIN

/// PLVHCToolbarAreaView 工具栏状态
typedef NS_ENUM(NSInteger, PLVHCToolbarViewStatus) {
    PLVHCToolbarViewStatusStudentPreparing, //学生端老师准备中
    PLVHCToolbarViewStatusStudentInClass, //学生端上课中
    PLVHCToolbarViewStatusTeacherPreparing, //讲师端准备中
    PLVHCToolbarViewStatusTeacherInClass //讲师端上课中
};

@protocol PLVHCToolbarAreaViewDelegate;

@interface PLVHCToolbarAreaView : UIView

@property (nonatomic, weak) id<PLVHCToolbarAreaViewDelegate> delegate;

///工具栏当前状态
@property (nonatomic, assign, readonly) PLVHCToolbarViewStatus toolbarStatus;

/// 开始上课操作
- (void)startClass;

/// 结束上课
- (void)finishClass;

/// 清除置空计时器
- (void)clear;

///从外部清除所有按钮的选中状态
- (void)clearAllButtonSelected;

/// 【讲师端】
/// 设置上下课按钮enable 状态
- (void)setClassButtonEnable:(BOOL)enable;

/// 【讲师端】收到学生举手数量提醒
/// @param raiseHand (YES 举手 NO 取消举手)
/// @param count 举手数量 当举手数为0时则隐藏举手提醒
- (void)toolbarAreaViewRaiseHand:(BOOL)raiseHand
                          userId:(NSString *)userId
                           count:(NSInteger)count;

///【讲师端】【学生端】收到新消息提醒
- (void)toolbarAreaViewReceiveNewMessage;

@end

// 工具栏区域视图Delegate
@protocol PLVHCToolbarAreaViewDelegate <NSObject>

@optional

/// 【文档管理】按钮选中状态改变
/// @param toolbarAreaView 工具栏区域视图
/// @param selected 【文档管理】按钮选中状态（YES-展开文档管理弹层, NO-收起文档管理弹层）
- (void)toolbarAreaView:(PLVHCToolbarAreaView *)toolbarAreaView documentButtonSelected:(BOOL)selected;

/// 【成员列表】按钮选中状态改变
/// @param toolbarAreaView 工具栏区域视图
/// @param selected 【成员列表】按钮选中状态（YES-展开成员列表弹层, NO-收起成员列表弹层）
- (void)toolbarAreaView:(PLVHCToolbarAreaView *)toolbarAreaView memberButtonSelected:(BOOL)selected;

/// 【聊天室】按钮选中状态改变
/// @param toolbarAreaView 工具栏区域视图
/// @param selected 【聊天室】按钮选中状态（YES-展开聊天室弹层, NO-收起聊天室弹层）
- (void)toolbarAreaView:(PLVHCToolbarAreaView *)toolbarAreaView chatroomButtonSelected:(BOOL)selected;

/// 【设置】按钮选中状态改变
/// @param toolbarAreaView 工具栏区域视图
/// @param selected 【设置】按钮选中状态（YES-展开设置弹层, NO-收起设置弹层）
- (void)toolbarAreaView:(PLVHCToolbarAreaView *)toolbarAreaView settingButtonSelected:(BOOL)selected;

/// 【上课下课操作】可根据 toolstatus 状态判断是上课还是下课
/// @param toolbarAreaView 工具栏区域视图
/// @param starClass 上课或者下课操作
- (void)toolbarAreaView_classButtonSelected:(PLVHCToolbarAreaView *)toolbarAreaView
                                 startClass:(BOOL)starClass;

/// 【学生端】
/// 【举手】
/// @param toolbarAreaView 工具栏区域视图
/// @param userId 当前用户id
- (void)toolbarAreaView_handUpButtonSelected:(PLVHCToolbarAreaView *)toolbarAreaView
                                      userId:(NSString *)userId;

@end

NS_ASSUME_NONNULL_END
