//
//  PLVHCLessonModel.m
//  PolyvLiveScenesDemo
//
//  Created by jiaweihuang on 2021/7/30.
//  Copyright © 2021 polyv. All rights reserved.
//

#import "PLVHCLessonModel.h"
#import <PLVFoundationSDK/PLVFdUtil.h>

@implementation PLVHCLessonModel

#pragma mark - [ Public method]

+ (instancetype)lessonModelWithDict:(NSDictionary *)dict {
    if (![PLVFdUtil checkDictionaryUseable:dict]) {
        return nil;
    }
    
    PLVHCLessonModel *model = [[PLVHCLessonModel alloc] init];
    model.courseNames = PLV_SafeStringForDictKey(dict, @"courseNames");
    model.cover = PLV_SafeStringForDictKey(dict, @"cover");
    model.date = PLV_SafeStringForDictKey(dict, @"date");
    model.lessonCode = PLV_SafeStringForDictKey(dict, @"lessonCode");
    model.lessonId = PLV_SafeStringForDictKey(dict, @"lessonId");
    model.name = PLV_SafeStringForDictKey(dict, @"name");
    model.startTime = PLV_SafeStringForDictKey(dict, @"startTime");
    model.status = PLV_SafeStringForDictKey(dict, @"status");
    model.time = PLV_SafeStringForDictKey(dict, @"time");
    
    return model;
}


#pragma mark - [ Private method ]

#pragma mark getter
- (NSString *)cover {
    NSString *fullURL = _cover;
    if ([fullURL hasPrefix:@"//"]) {
        fullURL = [@"https:" stringByAppendingString:fullURL];
    }
    return fullURL;
}

@end
