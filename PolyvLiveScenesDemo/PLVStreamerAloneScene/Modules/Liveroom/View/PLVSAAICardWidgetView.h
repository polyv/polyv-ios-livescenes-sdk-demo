//
//  PLVSAAICardWidgetView.h
//  PolyvLiveScenesDemo
//
//  Created by Dhan on 2025/11/04.
//  Copyright © 2025 PLV. All rights reserved.
//
// AI 手卡挂件

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class PLVSAAICardWidgetView;
@protocol PLVSAAICardWidgetViewDelegate <NSObject>

/// 点击 AI 手卡挂件的回调
/// @param aiCardWidgetView AI 手卡挂件
- (void)aiCardWidgetViewDidClickAction:(PLVSAAICardWidgetView *)aiCardWidgetView;

@end

@interface PLVSAAICardWidgetView : UIView

@property (nonatomic, weak) id<PLVSAAICardWidgetViewDelegate> delegate;

@property (nonatomic, assign, readonly) CGSize widgetSize;

@end

NS_ASSUME_NONNULL_END

