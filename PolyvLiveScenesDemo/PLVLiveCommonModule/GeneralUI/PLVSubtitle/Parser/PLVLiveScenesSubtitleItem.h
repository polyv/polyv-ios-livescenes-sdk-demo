//
//  PLVLiveScenesSubtitleItem.h
//  PolyvLiveScenesDemo
//
//  Created by Dhan on 2025/04/24.
//  Copyright © 2025 PLV. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef struct {
    NSInteger hours;
    NSInteger minutes;
    NSInteger seconds;
    NSInteger milliseconds;
} PLVLiveScenesSubtitleTime;

NS_ASSUME_NONNULL_BEGIN

NS_INLINE NSMutableAttributedString *HTMLString(NSString *string);
NSTimeInterval PLVLiveScenesSubtitleTimeGetSeconds(PLVLiveScenesSubtitleTime time);

@interface PLVLiveScenesSubtitleItem : NSObject

@property (nonatomic, assign) PLVLiveScenesSubtitleTime startTime;
@property (nonatomic, assign) PLVLiveScenesSubtitleTime endTime;

@property (nonatomic, copy) NSString *text;
@property (nonatomic, copy) NSAttributedString *attributedText;

@property (nonatomic, assign) NSString *identifier;

@property (nonatomic, assign) BOOL atTop;

- (instancetype)initWithText:(NSString *)text start:(PLVLiveScenesSubtitleTime)startTime end:(PLVLiveScenesSubtitleTime)endTime;

@end


NS_ASSUME_NONNULL_END
