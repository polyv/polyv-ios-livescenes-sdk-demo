//
//  PLVLiveSubtitleModel.m
//  PolyvLiveScenesDemo
//

#import "PLVLiveSubtitleModel.h"

@implementation PLVLiveSubtitleModel

- (instancetype)initWithIndex:(NSInteger)index
                        stable:(BOOL)stable
                          text:(NSString *)text
                textStartIndex:(NSInteger)textStartIndex
                      language:(NSString *)language {
    if (self = [super init]) {
        _index = index;
        _stable = stable;
        _text = text ?: @"";
        _textStartIndex = textStartIndex;
        _language = language ?: @"";
    }
    return self;
}

- (instancetype)copyWithAppendText:(NSString *)appendText
                      replaceIndex:(NSInteger)replaceIndex
                             stable:(BOOL)stable {
    // 计算需要保留的文本长度
    NSInteger takeLength = MAX(0, replaceIndex - self.textStartIndex);
    NSString *keptText = @"";
    if (takeLength > 0 && takeLength <= self.text.length) {
        keptText = [self.text substringToIndex:takeLength];
    }
    
    // 拼接新文本
    NSString *newText = [keptText stringByAppendingString:appendText ?: @""];
    NSInteger newStartIndex = MIN(self.textStartIndex, replaceIndex);
    
    return [[PLVLiveSubtitleModel alloc] initWithIndex:self.index
                                                stable:stable
                                                  text:newText
                                        textStartIndex:newStartIndex
                                              language:self.language];
}

@end
