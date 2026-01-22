//
//  PLVLiveSubtitleTranslation.h
//  PolyvLiveScenesDemo
//

#import <Foundation/Foundation.h>
#import "PLVLiveSubtitleModel.h"

NS_ASSUME_NONNULL_BEGIN

/// 字幕翻译数据模型（包含原文字幕和翻译字幕）
@interface PLVLiveSubtitleTranslation : NSObject

/// 字幕索引
@property (nonatomic, assign) NSInteger index;

/// 原文字幕
@property (nonatomic, strong) PLVLiveSubtitleModel *origin;

/// 翻译字幕（可选）
@property (nonatomic, strong, nullable) PLVLiveSubtitleModel *translation;

/// 初始化方法
- (instancetype)initWithIndex:(NSInteger)index
                        origin:(PLVLiveSubtitleModel *)origin
                   translation:(nullable PLVLiveSubtitleModel *)translation;

@end

NS_ASSUME_NONNULL_END
