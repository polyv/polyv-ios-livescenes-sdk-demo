//
//  PLVLCMediaMoreView.h
//  PLVLiveScenesDemo
//
//  Created by Lincal on 2020/9/29.
//  Copyright © 2020 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "PLVLCMediaMoreModel.h"

NS_ASSUME_NONNULL_BEGIN

@class PLVPlaybackSubtitleModel;
@protocol PLVLCMediaMoreViewDelegate;

/// 媒体更多视图
@interface PLVLCMediaMoreView : UIView

@property (nonatomic, weak) id <PLVLCMediaMoreViewDelegate> delegate;

@property (nonatomic, assign, readonly) BOOL moreViewShow;

@property (nonatomic, strong, readonly) NSMutableArray <PLVLCMediaMoreModel *> * dataArray;

/// 顶部安全距离
///
/// @note 当低于 iOS 11 时，内部无法判断顶部有无状态栏遮挡。
///       此时外部需根据对 CanvasView 的布局，告知顶部距离 (若无状态栏遮挡，则此值应该为0)；
///       此值仅在系统是 iOS 11 以下时，内部会使用；
@property (nonatomic, assign) CGFloat topPaddingBelowiOS11;

- (void)refreshTableView;

- (void)refreshTableViewWithDataArray:(NSArray <PLVLCMediaMoreModel *> *)dataArray;

/// 更新数据 (若无此数据，则会添加)
- (void)updateTableViewWithDataArrayByMatchModel:(NSArray <PLVLCMediaMoreModel *> *)updateDataArray;

///显示窗口
- (void)showMoreViewOnSuperview:(UIView *)superview;

/// 更新moreView父视图及布局
/// @note 在横竖屏旋转切换的场景下，适合调用该方法；仅在moreView已显示的情况下，该方法调用有效
- (void)updateMoreViewOnSuperview:(UIView *)superview;

- (void)switchShowStatusWithAnimation;

- (void)openDanmuButton:(BOOL)open;

- (PLVLCMediaMoreModel * _Nullable)getMoreModelAtIndex:(NSInteger)index;

@end

@protocol PLVLCMediaMoreViewDelegate <NSObject>

- (void)plvLCMediaMoreView:(PLVLCMediaMoreView *)moreView optionItemSelected:(PLVLCMediaMoreModel *)model;

- (void)plvLCMediaMoreView:(PLVLCMediaMoreView *)moreView didUpdateSubtitleState:(PLVPlaybackSubtitleModel *)originalSubtitle translateSubtitle:(PLVPlaybackSubtitleModel *)translateSubtitle;
@end


NS_ASSUME_NONNULL_END
