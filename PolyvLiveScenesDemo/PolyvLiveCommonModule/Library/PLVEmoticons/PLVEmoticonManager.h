//
//  PLVEmoticonManager.h
//  PLVCloudClassStreamerModul
//
//  Created by ftao on 2019/10/30.
//  Copyright © 2019 easefun. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PLVEmoticon : NSObject

@property (nonatomic, strong) NSString *text;

@property (nonatomic, strong) NSString *imageName;

+ (instancetype)emoticonWithDictionary:(NSDictionary *)diction;

@end

@interface PLVEmoticonManager : NSObject

@property (class, nonatomic, readonly) PLVEmoticonManager *sharedManager;

@property (nonatomic, strong, readonly) NSDictionary *emoticonDict;

@property (nonatomic, strong, readonly) NSArray<PLVEmoticon *> *models;

- (UIImage *)imageForEmoticonName:(NSString*)imoticonName;

- (NSMutableAttributedString *)converEmoticonTextToEmotionFormatText:(NSString *)emoticonText attributes:(NSDictionary<NSAttributedStringKey,id> *)attributes;

- (NSMutableAttributedString *)converEmoticonTextToEmotionFormatText:(NSAttributedString *)emoticonText font:(UIFont *)font;

@end

NS_ASSUME_NONNULL_END
