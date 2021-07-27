//
//  PLVLCMediaPlayerCanvasView.h
//  PLVLiveScenesDemo
//
//  Created by Lincal on 2020/9/24.
//  Copyright © 2020 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>

NS_ASSUME_NONNULL_BEGIN

/// ’播放器画布视图’ 类型
typedef NS_ENUM(NSUInteger, PLVLCMediaPlayerCanvasViewType) {
    PLVLCMediaPlayerCanvasViewType_Video = 0, // 视频模式
    PLVLCMediaPlayerCanvasViewType_Audio = 2, // 音频模式
};

@protocol PLVLCMediaPlayerCanvasViewDelegate;

/// 播放器画布视图 （用于承载 ‘播放器’）
@interface PLVLCMediaPlayerCanvasView : UIView

/// 播放器父视图
@property (nonatomic, strong, readonly) UIView * playerSuperview;

@property (nonatomic, strong, readonly) UIButton * playCanvasButton; // 播放画面按钮

@property (nonatomic, strong, readonly) UIImageView * restImageView; // 休息一会视图

@property (nonatomic, assign, readonly) PLVLCMediaPlayerCanvasViewType type; // 视图类型

@property (nonatomic, weak) id <PLVLCMediaPlayerCanvasViewDelegate> delegate;

@property (nonatomic, assign) CGSize videoSize;

/// 切换 ‘画布视图’ 类型
- (void)switchTypeTo:(PLVLCMediaPlayerCanvasViewType)toType;

/// 根据直播流状态，刷新 ‘画布视图’
///
/// @note 调用后，会记录 直播流状态，用于后续相关UI的更新判断；
///       因此 部分UI更新 逻辑，会与此方法是否被正常调用有关系；
- (void)refreshCanvasViewWithStreamState:(PLVChannelLiveStreamState)newestStreamState;

@end

@protocol PLVLCMediaPlayerCanvasViewDelegate <NSObject>

/// ‘播放画面’按钮被点击
- (void)plvLCMediaPlayerCanvasViewPlayCanvasButtonClicked:(PLVLCMediaPlayerCanvasView *)playerCanvasView;

@end


NS_ASSUME_NONNULL_END
