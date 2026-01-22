//
//  PLVLiveSubtitleSocketEvent.h
//  PolyvLiveScenesDemo
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// ADD 事件数据模型
@interface PLVLiveSubtitleSocketEventAdd : NSObject

@property (nonatomic, strong, nullable) NSNumber *index;
@property (nonatomic, copy, nullable) NSString *language;
@property (nonatomic, strong, nullable) NSNumber *relativeTime;
@property (nonatomic, strong, nullable) NSNumber *replaceIndex;
@property (nonatomic, strong, nullable) NSNumber *sliceType;
@property (nonatomic, copy, nullable) NSString *text;

+ (instancetype)modelWithDictionary:(NSDictionary *)dictionary;

@end

/// TRANSLATE 事件数据模型
@interface PLVLiveSubtitleSocketEventTranslate : NSObject

@property (nonatomic, strong, nullable) NSNumber *index;
@property (nonatomic, copy, nullable) NSString *language;
@property (nonatomic, copy, nullable) NSString *result;

+ (instancetype)modelWithDictionary:(NSDictionary *)dictionary;

@end

/// ENABLE 事件数据模型
@interface PLVLiveSubtitleSocketEventEnable : NSObject

@property (nonatomic, strong, nullable) NSNumber *enable;
@property (nonatomic, strong, nullable) NSDictionary *currentSubtitle;

+ (instancetype)modelWithDictionary:(NSDictionary *)dictionary;

@end

NS_ASSUME_NONNULL_END
