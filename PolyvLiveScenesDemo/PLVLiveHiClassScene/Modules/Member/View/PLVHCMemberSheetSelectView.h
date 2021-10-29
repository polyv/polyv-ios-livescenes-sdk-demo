//
//  PLVHCMemberSheetSelectView.h
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2021/8/2.
//  Copyright © 2021 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class PLVHCMemberSheetSelectView;

@protocol PLVHCMemberSheetSelectViewDelegate <NSObject>

- (void)selectButtonInSelectView:(PLVHCMemberSheetSelectView *)selectView atIndex:(NSInteger)index;

@end

@interface PLVHCMemberSheetSelectView : UIView

@property (nonatomic, weak) id<PLVHCMemberSheetSelectViewDelegate> delegate;

/// 初始化方法
/// @param userCount 在线成员数
/// @param kickedUserCount 移出成员数
- (instancetype)initWithOnlineUserCount:(NSInteger)userCount kickedUserCount:(NSInteger)kickedUserCount;

- (void)updateWithOnlineUserCount:(NSInteger)userCount kickedUserCount:(NSInteger)kickedUserCount;

/// 弹出弹层
/// @param superView 展示弹层的父视图，弹层会插入到父视图的最顶上
- (void)showInView:(UIView *)superView;

/// 收起弹层
- (void)dismiss;

@end

NS_ASSUME_NONNULL_END
