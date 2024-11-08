//
//  PLVMultiMeetingManager.h
//  PolyvLiveScenesDemo
//
//  Created by Dhan on 2024/10/10.
//  Copyright © 2024 PLV. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <PLVFoundationSDK/PLVSafeModel.h>

NS_ASSUME_NONNULL_BEGIN

static NSString * const kPLVMultiMeetingSplashImgURLString = @"https://s1.videocc.net/default-img/channel/default-splash.png";//讲师默认封面图地址

typedef void (^PLVMultiMeetingJumpCallback)(NSString *channelId, BOOL isPlayback);

typedef NS_ENUM(NSInteger, PLVMultiMeetingLiveStatus) {
    PLVMultiMeetingLiveStatus_Live,
    PLVMultiMeetingLiveStatus_UnStart,
    PLVMultiMeetingLiveStatus_Waiting,
    PLVMultiMeetingLiveStatus_Playback,
    PLVMultiMeetingLiveStatus_End
};

@interface PLVMultiMeetingModel : PLVSafeModel

@property (nonatomic, copy) NSString *channelId;
@property (nonatomic, copy) NSString *channelName;
@property (nonatomic, copy) NSString *liveStatus;
@property (nonatomic, copy) NSString *liveStatusDesc;
@property (nonatomic, copy) NSString *multiMeetingName;
/// 观看数
@property (nonatomic, copy) NSNumber *pv;
/// 占位图
@property (nonatomic, copy) NSString *splashImg;
/// 直播时间
@property (nonatomic, assign) NSTimeInterval startTime;
/// 流名
@property (nonatomic, copy) NSString *streamName;

@property (nonatomic, assign, readonly) PLVMultiMeetingLiveStatus liveStatusType;

@property (nonatomic, copy, readonly) NSString *splashImgUrl;

@end

@interface PLVMultiMeetingManager : NSObject

/// 多会场更新的回调
@property (nonatomic, copy) PLVMultiMeetingJumpCallback jumpCallback;

#pragma mark - API

/// 单例方法
+ (instancetype)sharedManager;

- (void)jumpToMultiMeeting:(NSString *)channelId isPlayback:(BOOL)isPlayback;

@end

NS_ASSUME_NONNULL_END
