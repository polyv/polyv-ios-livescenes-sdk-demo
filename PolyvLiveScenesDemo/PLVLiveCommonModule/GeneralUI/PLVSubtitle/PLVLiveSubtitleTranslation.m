//
//  PLVLiveSubtitleTranslation.m
//  PolyvLiveScenesDemo
//

#import "PLVLiveSubtitleTranslation.h"

@implementation PLVLiveSubtitleTranslation

- (instancetype)initWithIndex:(NSInteger)index
                        origin:(PLVLiveSubtitleModel *)origin
                   translation:(nullable PLVLiveSubtitleModel *)translation {
    if (self = [super init]) {
        _index = index;
        _origin = origin;
        _translation = translation;
    }
    return self;
}

@end
