//
//  PLVLiveSubtitleModel.h
//  PolyvLiveScenesDemo
//
//  Created by PLV on 2025/01/XX.
//  Copyright © 2025 PLV. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 单条字幕数据模型
@interface PLVLiveSubtitleModel : NSObject

/// 字幕索引
@property (nonatomic, assign) NSInteger index;

/// 是否稳定（不再更新）
@property (nonatomic, assign) BOOL stable;

/// 字幕文本
@property (nonatomic, copy) NSString *text;

/// 文本起始索引（用于增量更新）
@property (nonatomic, assign) NSInteger textStartIndex;

/// 语言代码
@property (nonatomic, copy) NSString *language;

/// 初始化方法
- (instancetype)initWithIndex:(NSInteger)index
                        stable:(BOOL)stable
                          text:(NSString *)text
                textStartIndex:(NSInteger)textStartIndex
                      language:(NSString *)language;

/// 复制方法（支持增量更新）
- (instancetype)copyWithAppendText:(NSString *)appendText
                      replaceIndex:(NSInteger)replaceIndex
                             stable:(BOOL)stable;

@end

NS_ASSUME_NONNULL_END
