//
//  PLVCheckVoiceWarningModel.h
//  PolyvLiveScenesDemo
//
//  Created by POLYV on 2026/6/1.
//  Copyright © 2026 PLV. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, PLVCheckVoiceRiskLevel) {
    PLVCheckVoiceRiskLevelLow = 0,
    PLVCheckVoiceRiskLevelMedium,
    PLVCheckVoiceRiskLevelHigh
};

@interface PLVCheckVoiceWarningModel : NSObject

@property (nonatomic, copy) NSString *content;
@property (nonatomic, copy) NSString *type;
@property (nonatomic, assign) CGFloat score;
@property (nonatomic, assign) NSTimeInterval timestamp;
@property (nonatomic, assign, readonly) PLVCheckVoiceRiskLevel riskLevel;

+ (BOOL)isCheckVoiceEvent:(NSString * _Nullable)event subEvent:(NSString * _Nullable)subEvent;
+ (void)ensureSocketListeningEventRegistered;
+ (NSArray<PLVCheckVoiceWarningModel *> *)modelsWithSocketObject:(id _Nullable)object timestamp:(NSTimeInterval)timestamp;

- (NSString *)riskLevelText;
- (UIColor *)riskColor;

@end

NS_ASSUME_NONNULL_END
