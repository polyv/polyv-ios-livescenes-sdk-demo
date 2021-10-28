//
//  PLVLessonInfoModel.m
//  PLVLiveScenesSDK
//
//  Created by Sakya on 2021/8/10.
//  Copyright © 2021 polyv. All rights reserved.
//

#import "PLVLessonInfoModel.h"

@interface PLVLessonInfoModel ()

@property (nonatomic, copy) NSString *lessonId;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *cover;
@property (nonatomic, assign) NSInteger linkNumber;
@property (nonatomic, assign) BOOL autoLinkMic;
@property (nonatomic, assign) NSInteger duration;
@property (nonatomic, assign) NSInteger lessonStartTime;
@property (nonatomic, assign) NSInteger lessonEndTime;
@property (nonatomic, copy) NSString *startDate;
@property (nonatomic, copy) NSString *startTime;
@property (nonatomic, assign) NSInteger serverTime;
@property (nonatomic, assign) NSInteger gapClassTime;
@property (nonatomic, assign) NSInteger classTime;
@property (nonatomic, assign) NSInteger inClassTime;
@property (nonatomic, assign) NSInteger delayClassTime;

@end

@implementation PLVLessonInfoModel

- (instancetype)initWithDictionary:(NSDictionary *)dict {
    self = [super init];
    if (self) {
        self.lessonId = PLV_SafeStringForDictKey(dict, @"lessonId");
        self.name = PLV_SafeStringForDictKey(dict, @"name");
        self.cover = PLV_SafeStringForDictKey(dict, @"cover");
        self.linkNumber = PLV_SafeIntegerForDictKey(dict, @"linkNumber");
        self.autoLinkMic = PLV_SafeBoolForDictKey(dict, @"autoConnectMicroEnabled");
        self.hiClassStatus = PLV_SafeIntegerForDictKey(dict, @"status");
        self.duration = PLV_SafeIntegerForDictKey(dict, @"duration");
        self.lessonStartTime = PLV_SafeIntegerForDictKey(dict, @"lessonStartTime");
        self.lessonEndTime = PLV_SafeIntegerForDictKey(dict, @"lessonEndTime");
        self.startDate = PLV_SafeStringForDictKey(dict, @"startDate");
        self.startTime = PLV_SafeStringForDictKey(dict, @"startTime");
        self.serverTime = PLV_SafeIntegerForDictKey(dict, @"serverTime");
        self.gapClassTime = PLV_SafeIntegerForDictKey(dict, @"gapClassTime");
        self.classTime = PLV_SafeIntegerForDictKey(dict, @"classTime");
        self.inClassTime = PLV_SafeIntegerForDictKey(dict, @"inClassTime");
        self.delayClassTime = PLV_SafeIntegerForDictKey(dict, @"delayClassTime");
    }
    return self;
}

#pragma mark Getter

- (PLVHiClassLessonStatus)lessonStatus {
    if (self.hiClassStatus == PLVHiClassStatusNotInClass) {
        if (self.serverTime > self.lessonStartTime) {
            return PLVHiClassLessonStatusDelayInClass;
        } else {
            return PLVHiClassLessonStatusNotInClass;
        }
    } else if (self.hiClassStatus == PLVHiClassStatusInClass) {
        return PLVHiClassLessonStatusInClass;
    } else {
        return PLVHiClassLessonStatusFinishClass;
    }
}

@end
