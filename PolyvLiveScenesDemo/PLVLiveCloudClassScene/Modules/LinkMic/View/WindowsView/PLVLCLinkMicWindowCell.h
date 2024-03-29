//
//  PLVLCLinkMicWindowCell.h
//  PLVLiveScenesDemo
//
//  Created by Lincal on 2020/8/6.
//  Copyright © 2020 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "PLVLinkMicOnlineUser.h"

@class PLVLCLinkMicWindowCellContentView;

/// 连麦窗口布局状态
typedef NS_ENUM(NSUInteger, PLVLCLinkMicWindowCellLayoutType) {
    PLVLCLinkMicWindowCellLayoutType_Default  = 0, // 默认状态，显示 canvasView
    PLVLCLinkMicWindowCellLayoutType_External = 2, // 显示外部视图状态
};

NS_ASSUME_NONNULL_BEGIN

/// 连麦窗口Cell
@interface PLVLCLinkMicWindowCell : UICollectionViewCell

#pragma mark 状态
/// 连麦窗口布局状态
@property (nonatomic, assign, readonly) PLVLCLinkMicWindowCellLayoutType layoutType;

/// 连麦窗口展示视图(包含rtc画面和其它控件)
@property (nonatomic, strong, readonly) PLVLCLinkMicWindowCellContentView *rtcContentView;

#pragma mark 方法
- (void)setModel:(PLVLinkMicOnlineUser *)userModel;

/// 切换至 显示默认内容视图
///
/// @note 切换至 显示默认内容视图后，PLVLCLinkMicWindowCell 将处于 ’状态一‘(即 PLVLCLinkMicWindowCellLayoutType_Default) 的布局层级。
///       此方法会对 rtcContentView 重新布局，同时移除 外部视图。
- (void)switchToShowDefaultRtcContentView;

/// 切换至 显示外部内容视图
///
/// @note 切换至 显示外部内容视图后，PLVLCLinkMicWindowCell 将处于 ’状态二‘(即 PLVLCLinkMicWindowCellLayoutType_External)  的布局层级。
///       此方法不会对 rtcContentView 作处理。
- (void)switchToShowExternalContentView:(UIView *)externalContentView;

@end

@interface PLVLCLinkMicWindowCellContentView : UIView

/// 当前视图是否在 PLVLCLinkMicWindowCell 中显示，默认YES 修改状态会决定部分控件是否显示
@property (nonatomic, assign) BOOL showInWindowCell;

#pragma mark 方法
- (void)setModel:(PLVLinkMicOnlineUser *)userModel;

@end

NS_ASSUME_NONNULL_END
