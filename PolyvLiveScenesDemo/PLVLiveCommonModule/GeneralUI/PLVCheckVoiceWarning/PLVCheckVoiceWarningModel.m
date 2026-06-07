//
//  PLVCheckVoiceWarningModel.m
//  PolyvLiveScenesDemo
//
//  Created by POLYV on 2026/6/1.
//  Copyright © 2026 PLV. All rights reserved.
//

#import "PLVCheckVoiceWarningModel.h"
#import "PLVMultiLanguageManager.h"

#import <PLVFoundationSDK/PLVFoundationSDK.h>
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>

static NSString * const kPLVCheckVoiceEventBadWord = @"badword";
static NSString * const kPLVCheckVoiceEventBadWordCompat = @"badWord";
static NSString * const kPLVCheckVoiceSubEvent = @"CHECK_VOICE";

@implementation PLVCheckVoiceWarningModel

- (PLVCheckVoiceRiskLevel)riskLevel {
    if (self.score > 0.8) {
        return PLVCheckVoiceRiskLevelHigh;
    } else if (self.score > 0.5) {
        return PLVCheckVoiceRiskLevelMedium;
    } else {
        return PLVCheckVoiceRiskLevelLow;
    }
}

+ (BOOL)isCheckVoiceEvent:(NSString *)event subEvent:(NSString *)subEvent {
    NSString *normalizedEvent = [self normalizedEventString:event];
    NSString *normalizedBadWord = [self normalizedEventString:kPLVCheckVoiceEventBadWord];
    NSString *normalizedSubEvent = [self normalizedEventString:subEvent];
    NSString *normalizedCheckVoice = [self normalizedEventString:kPLVCheckVoiceSubEvent];
    return [normalizedEvent isEqualToString:normalizedBadWord] && [normalizedSubEvent isEqualToString:normalizedCheckVoice];
}

+ (void)ensureSocketListeningEventRegistered {
    PLVSocketManager *socketManager = [PLVSocketManager sharedManager];
    NSSet *listeningEvents = socketManager.listeningEvents;
    
    NSMutableSet *mutableEvents = listeningEvents ? [listeningEvents mutableCopy] : [[NSMutableSet alloc] init];
    [mutableEvents addObjectsFromArray:@[kPLVCheckVoiceEventBadWord, kPLVCheckVoiceEventBadWordCompat]];
    socketManager.listeningEvents = [mutableEvents copy];
}

+ (NSArray<PLVCheckVoiceWarningModel *> *)modelsWithSocketObject:(id)object timestamp:(NSTimeInterval)timestamp {
    NSDictionary *payload = [object isKindOfClass:[NSDictionary class]] ? object : nil;
    if (![PLVFdUtil checkDictionaryUseable:payload]) {
        return @[];
    }
    
    NSArray *badwords = PLV_SafeArraryForDictKey(payload, @"badwords");
    if (![PLVFdUtil checkArrayUseable:badwords]) {
        return @[];
    }
    
    NSMutableArray *models = [[NSMutableArray alloc] initWithCapacity:badwords.count];
    for (id item in badwords) {
        if (![item isKindOfClass:[NSDictionary class]]) {
            continue;
        }
        
        NSDictionary *itemDict = (NSDictionary *)item;
        NSString *content = PLV_SafeStringForDictKey(itemDict, @"content");
        if (![PLVFdUtil checkStringUseable:content]) {
            content = PLV_SafeStringForDictKey(itemDict, @"word");
        }
        if (![PLVFdUtil checkStringUseable:content]) {
            content = PLV_SafeStringForDictKey(itemDict, @"value");
        }
        if (![PLVFdUtil checkStringUseable:content]) {
            continue;
        }
        
        PLVCheckVoiceWarningModel *model = [[PLVCheckVoiceWarningModel alloc] init];
        model.content = content;
        model.type = PLV_SafeStringForDictKey(itemDict, @"type");
        if (itemDict[@"score"]) {
            model.score = PLV_SafeFloatForDictKey(itemDict, @"score");
        } else if ([PLV_SafeStringForDictKey(itemDict, @"isIllegal") isEqualToString:@"Y"]) {
            model.score = 1.0;
        } else {
            model.score = 0;
        }
        model.timestamp = timestamp;
        [models addObject:model];
    }
    
    return [models copy];
}

- (NSString *)riskLevelText {
    switch (self.riskLevel) {
        case PLVCheckVoiceRiskLevelHigh:
            return PLVLocalizedString(@"高风险");
        case PLVCheckVoiceRiskLevelMedium:
            return PLVLocalizedString(@"中风险");
        case PLVCheckVoiceRiskLevelLow:
        default:
            return PLVLocalizedString(@"低风险");
    }
}

- (UIColor *)riskColor {
    switch (self.riskLevel) {
        case PLVCheckVoiceRiskLevelHigh:
            return PLV_UIColorFromRGB(@"#FF4D4F");
        case PLVCheckVoiceRiskLevelMedium:
            return PLV_UIColorFromRGB(@"#F59A23");
        case PLVCheckVoiceRiskLevelLow:
        default:
            return PLV_UIColorFromRGB(@"#F7B500");
    }
}

+ (NSString *)normalizedEventString:(NSString *)string {
    if (![string isKindOfClass:[NSString class]]) {
        return @"";
    }
    NSString *normalizedString = [[string lowercaseString] stringByReplacingOccurrencesOfString:@"_" withString:@""];
    return normalizedString;
}

@end
