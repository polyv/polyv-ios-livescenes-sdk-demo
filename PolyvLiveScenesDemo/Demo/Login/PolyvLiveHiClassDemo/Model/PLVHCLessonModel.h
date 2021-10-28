//
//  PLVHCLessonModel.h
//  PolyvLiveScenesDemo
//
//  Created by jiaweihuang on 2021/7/30.
//  Copyright © 2021 polyv. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PLVHCLessonModel : NSObject

/// 课程名称
@property (nonatomic, copy) NSString *courseNames;
/// 课节封面图url
@property (nonatomic, copy) NSString *cover;
/// 时间（哪一天）
@property (nonatomic, copy) NSString *date;
/// 课程节码
@property (nonatomic, copy) NSString *lessonCode;
/// 课节Id
@property (nonatomic, copy) NSString *lessonId;
/// 课节名称
@property (nonatomic, copy) NSString *name;
/// 课节开始时间 yyyy-MM-dd HH:mm
@property (nonatomic, copy) NSString *startTime;
/// 课节状态，  0：未开课，1：上课中，2：已下课
@property (nonatomic, copy) NSString *status;
/// 上课时间: HH:mm
@property (nonatomic, copy) NSString *time;

+ (instancetype)lessonModelWithDict:(NSDictionary *)dict;

@end

NS_ASSUME_NONNULL_END
