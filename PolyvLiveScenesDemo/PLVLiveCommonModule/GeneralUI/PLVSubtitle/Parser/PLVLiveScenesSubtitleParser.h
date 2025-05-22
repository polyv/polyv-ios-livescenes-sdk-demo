//
//  PLVLiveScenesSubtitleParser.h
//  PolyvLiveScenesDemo
//
//  Created by Dhan on 2025/04/24.
//  Copyright © 2025 PLV. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PLVLiveScenesSubtitleItem.h"

NS_ASSUME_NONNULL_BEGIN

@interface PLVLiveScenesSubtitleParser : NSObject

@property (nonatomic, strong, readonly) NSMutableArray<PLVLiveScenesSubtitleItem *> *subtitleItems;

+ (instancetype)parserWithSubtitle:(NSString *)content error:(NSError **)error;
- (NSDictionary *)subtitleItemAtTime:(NSTimeInterval)time;

@end

NS_ASSUME_NONNULL_END
