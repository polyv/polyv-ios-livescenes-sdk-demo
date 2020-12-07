//
//  PLVLCMediaPlayerCanvasView.h
//  PolyvLiveScenesDemo
//
//  Created by Lincal on 2020/9/24.
//  Copyright © 2020 polyv. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 播放器画布视图类型
typedef NS_ENUM(NSUInteger, PLVLCMediaPlayerCanvasViewType) {
    PLVLCMediaPlayerCanvasViewType_Video = 0, // 视频模式
    PLVLCMediaPlayerCanvasViewType_Audio = 2, // 音频模式
};

@protocol PLVLCMediaPlayerCanvasViewDelegate;

/// 播放器画布视图
@interface PLVLCMediaPlayerCanvasView : UIView

/// 播放器父视图
@property (nonatomic, strong, readonly) UIView * playerSuperview;

@property (nonatomic, strong, readonly) UIButton * playCanvasButton; // 播放画面按钮

@property (nonatomic, strong, readonly) UIImageView * restImageView; // 休息一会视图

@property (nonatomic, assign, readonly) PLVLCMediaPlayerCanvasViewType type; // 视图类型

@property (nonatomic, weak) id <PLVLCMediaPlayerCanvasViewDelegate> delegate;

@property (nonatomic, assign) CGSize videoSize;

- (void)switchTypeTo:(PLVLCMediaPlayerCanvasViewType)toType;

@end

@protocol PLVLCMediaPlayerCanvasViewDelegate <NSObject>

/// ‘播放画面’按钮被点击
- (void)plvLCMediaPlayerCanvasViewPlayCanvasButtonClicked:(PLVLCMediaPlayerCanvasView *)playerCanvasView;

@end


NS_ASSUME_NONNULL_END
