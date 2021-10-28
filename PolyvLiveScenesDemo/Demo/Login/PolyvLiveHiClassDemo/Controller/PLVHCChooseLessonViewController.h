//
//  PLVHCChooseClassViewController.h
//  PolyvLiveScenesDemo
//
//  Created by jiaweihuang on 2021/7/1.
//  Copyright © 2021 polyv. All rights reserved.
//  课节选择页

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PLVHCChooseLessonViewController : UIViewController

@property (nonatomic, strong) NSString *userId; // 公司Id，讲师端从公司选择页进入课节列表页时该属性必须设置
@property (nonatomic, strong) NSString *courseCode; // 课程码，学生端使用课程码登录时该属性必须设置
@property (nonatomic, strong) NSString *lessonId; // 课节ID，学生端使用课节ID登录时该属性必须设置

/// 初始化方法
/// @param viewerId 用户唯一标识
/// @param viewerName 用户昵称
/// @param teacher 用户是否是讲师
/// @param lessonArray 登录接口返回的课节列表
- (instancetype)initWithViewerId:(NSString *)viewerId
                      viewerName:(NSString *)viewerName
                         teacher:(BOOL)teacher
                     lessonArray:(NSArray *)lessonArray;

@end

NS_ASSUME_NONNULL_END
