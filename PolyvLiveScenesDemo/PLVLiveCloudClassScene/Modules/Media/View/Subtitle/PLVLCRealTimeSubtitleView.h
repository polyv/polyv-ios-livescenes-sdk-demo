//
//  PLVLCRealTimeSubtitleView.h
//  PolyvLiveScenesDemo
//

#import <UIKit/UIKit.h>
#import "PLVLiveSubtitleModel.h"

NS_ASSUME_NONNULL_BEGIN

/// 实时字幕视图（云课堂场景 - 单条显示）
/// 纯UI组件，只负责显示字幕，不处理Socket消息
@interface PLVLCRealTimeSubtitleView : UIView

/// 更新实时字幕
/// @param subtitle 字幕数据模型
- (void)updateRealTimeSubtitle:(nullable PLVLiveSubtitleModel *)subtitle;

@end

NS_ASSUME_NONNULL_END
