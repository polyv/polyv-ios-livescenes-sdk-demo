//
//  PLVLessonInfoModel.h
//  PLVLiveScenesSDK
//
//  Created by Sakya on 2021/8/10.
//  Copyright © 2021 polyv. All rights reserved.
//

#import <PLVFoundationSDK/PLVFoundationSDK.h>

NS_ASSUME_NONNULL_BEGIN

/// 互动学堂上课状态
typedef NS_ENUM (NSInteger, PLVHiClassStatus) {
    PLVHiClassStatusNotInClass = 0, // 未开课
    PLVHiClassStatusInClass = 1, // 上课中
    PLVHiClassStatusFinishClass = 2, // 已下课
};

/// 互动学堂课程状态
typedef NS_ENUM(NSInteger, PLVHiClassLessonStatus){
    PLVHiClassLessonStatusNotInClass = 0, // 未上课
    PLVHiClassLessonStatusDelayInClass = 1, // 已延迟
    PLVHiClassLessonStatusInClass = 2, // 上课中
    PLVHiClassLessonStatusDelayFinishClass = 3, // 拖堂
    PLVHiClassLessonStatusFinishClass = 4, // 已下课
};

@interface PLVLessonInfoModel : NSObject

/// 课程码，学生端使用课程码登录时该属性必须设置
@property (nonatomic, copy) NSString *courseCode;
/// 课节Id
@property (nonatomic, copy, readonly) NSString *lessonId;
/// 标题
@property (nonatomic, copy, readonly) NSString *name;
/// 封面
@property (nonatomic, copy, readonly) NSString *cover;
/// 连麦人数
@property (nonatomic, assign, readonly) NSInteger linkNumber;
/// 是否自动连麦
@property (nonatomic, assign, readonly) BOOL autoLinkMic;
/// 上课状态 (0：未开课，1：上课中，2：已下课)
@property (nonatomic, assign) PLVHiClassStatus hiClassStatus;
///课程当前状态【根据上课时间信息判断的具体状态】分为未上课、已延迟、上课中、拖堂、已下课
@property (nonatomic, assign) PLVHiClassLessonStatus lessonStatus;
/// 持续时长，单位: 分钟
@property (nonatomic, assign, readonly) NSInteger duration;
/// 课节设定开始时间
@property (nonatomic, assign, readonly) NSInteger lessonStartTime;
/// 课节设定结束时间
@property (nonatomic, assign, readonly) NSInteger lessonEndTime;
/// 开始日期: yyyy-MM-dd
@property (nonatomic, copy, readonly) NSString *startDate;
/// 开始时间: HH:mm
@property (nonatomic, copy, readonly) NSString *startTime;
/// 服务器时间
@property (nonatomic, assign, readonly) NSInteger serverTime;
/// gapClassTime 距离开课时间，单位：秒
@property (nonatomic, assign, readonly) NSInteger gapClassTime;
/// 实际上课时间
@property (nonatomic, assign, readonly) NSInteger classTime;
/// inClassTime 直播时长，单位：秒
@property (nonatomic, assign, readonly) NSInteger inClassTime;
/// delayClassTime 拖堂时长，单位：秒
@property (nonatomic, assign, readonly) NSInteger delayClassTime;

- (instancetype)initWithDictionary:(NSDictionary *)dict;

@end

NS_ASSUME_NONNULL_END
