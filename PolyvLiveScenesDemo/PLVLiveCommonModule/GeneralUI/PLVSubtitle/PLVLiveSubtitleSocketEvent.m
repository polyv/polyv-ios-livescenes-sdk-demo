//
//  PLVLiveSubtitleSocketEvent.m
//  PolyvLiveScenesDemo
//

#import "PLVLiveSubtitleSocketEvent.h"

@implementation PLVLiveSubtitleSocketEventAdd

+ (instancetype)modelWithDictionary:(NSDictionary *)dictionary {
    if (![dictionary isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    
    PLVLiveSubtitleSocketEventAdd *model = [[PLVLiveSubtitleSocketEventAdd alloc] init];
    model.index = dictionary[@"index"];
    model.language = dictionary[@"language"];
    model.relativeTime = dictionary[@"relativeTime"];
    model.replaceIndex = dictionary[@"replaceIndex"];
    model.sliceType = dictionary[@"sliceType"];
    model.text = dictionary[@"text"];
    
    return model;
}

@end

@implementation PLVLiveSubtitleSocketEventTranslate

+ (instancetype)modelWithDictionary:(NSDictionary *)dictionary {
    if (![dictionary isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    
    PLVLiveSubtitleSocketEventTranslate *model = [[PLVLiveSubtitleSocketEventTranslate alloc] init];
    model.index = dictionary[@"index"];
    model.language = dictionary[@"language"];
    model.result = dictionary[@"result"];
    
    return model;
}

@end

@implementation PLVLiveSubtitleSocketEventEnable

+ (instancetype)modelWithDictionary:(NSDictionary *)dictionary {
    if (![dictionary isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    
    PLVLiveSubtitleSocketEventEnable *model = [[PLVLiveSubtitleSocketEventEnable alloc] init];
    model.enable = dictionary[@"enable"];
    model.currentSubtitle = dictionary[@"currentSubtitle"];
    
    return model;
}

@end
