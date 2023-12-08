//
//  PLVSipLinkMicPresenter.h
//  PolyvLiveScenesDemo
//
//  Created by Dhan on 2022/6/23.
//  Copyright © 2022 PLV. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PLVSipLinkMicUser.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, PLVSipLinkMicListStatus) {
    PLVSipLinkMicListStatus_Unknown = 0, // 未知状态
    PLVSipLinkMicListStatus_CallIn  = 2, // 待接通
    PLVSipLinkMicListStatus_CallOut = 4, // 呼叫中
    PLVSipLinkMicListStatus_InLine  = 6, // 已入会
};

@protocol PLVSipLinkMicPresenterDelegate;

@interface PLVSipLinkMicPresenter : NSObject

#pragma mark - [ 属性 ]

#pragma mark 可配置项

/// delegate
@property (nonatomic, weak) id <PLVSipLinkMicPresenterDelegate> delegate;

/// 已入会列表
@property (nonatomic, copy, readonly) NSArray <PLVSipLinkMicUser *> *inLineDialsArray;
/// 呼叫中列表
@property (nonatomic, copy, readonly) NSArray <PLVSipLinkMicUser *> *callOutDialsArray;
/// 待接通列表
@property (nonatomic, copy, readonly) NSArray <PLVSipLinkMicUser *> *callInDialsArray;

@end

#pragma mark - [ 代理方法 ]
/// 拨号入会管理器 代理方法
@protocol PLVSipLinkMicPresenterDelegate <NSObject>

@optional

/// ’拨号入会房间在线用户数组‘ 发生改变
///
/// @param presenter 拨号入会管理器
- (void)plvSipLinkMicPresenterUserListRefresh:(PLVSipLinkMicPresenter *)presenter;

/// 拨号入会房间有新“呼叫中”用户加入
- (void)plvSipLinkMicPresenterHasNewCallInUser:(PLVSipLinkMicPresenter *)presenter;

/// 拨号入会房间有新“待接通”用户加入
- (void)plvSipLinkMicPresenterHasNewCallOutUser:(PLVSipLinkMicPresenter *)presenter;


@end
NS_ASSUME_NONNULL_END
