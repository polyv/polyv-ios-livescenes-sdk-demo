//
//  PLVECLinkMicViewModel.h
//  PLVLiveScenesDemo
//
//  Created by Sakya on 2021/10/11.
//  Copyright © 2021 PLV. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <PLVBusinessSDK/PLVBRTCDefine.h>

NS_ASSUME_NONNULL_BEGIN

@class PLVECLinkMicViewModel;

@protocol PLVECLinkMicViewModelDelegate <NSObject>

/// RTC画面窗口 需外部展示 ‘第一画面连麦窗口’
///
/// @param canvasView 第一画面连麦窗口视图 (需外部进行添加展示)
- (void)plvECLinkMicViewModel:(PLVECLinkMicViewModel *)linkMicViewModel showFirstSiteCanvasViewOnExternal:(UIView *)canvasView;

/// RTC本地用户的网络质量回调
///
/// @param rxQuality 网络质量
- (void)plvECLinkMicViewModel:(PLVECLinkMicViewModel *)linkMicViewModel localUserNetworkRxQuality:(PLVBLinkMicNetworkQuality)rxQuality;


@end

@interface PLVECLinkMicViewModel : NSObject

/// PLVECLinkMicViewModelDelegate代理
@property (nonatomic, weak) id<PLVECLinkMicViewModelDelegate> delegate;

#pragma mark - Method

/// 开始/结束观看无延迟直播
- (void)startWatchNoDelay:(BOOL)startWatch;

@end

NS_ASSUME_NONNULL_END
