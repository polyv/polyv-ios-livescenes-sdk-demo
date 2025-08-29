//
//  PLVLCAISummaryViewController.h
//  PLVLiveScenesDemo
//
//  Created by Dhan on 2025/07/22.
//  Copyright © 2025 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

@class PLVLCAISummaryViewController;

@protocol PLVLCAISummaryViewControllerDelegate <NSObject>

@optional

/// AI看Web页面请求跳转到指定视频时间点
/// @param time 目标时间点（秒）
- (void)aiSummaryViewController:(PLVLCAISummaryViewController *)viewController seekToTime:(NSTimeInterval)time;

- (void)aiSummaryViewControllerShouldSetupVideo:(PLVLCAISummaryViewController *)viewController;

@end

@interface PLVLCAISummaryViewController : UIViewController

@property (nonatomic, weak) id<PLVLCAISummaryViewControllerDelegate> delegate;

/// 更新视频信息
/// @param videoId 视频ID
/// @param videoType 视频类型
- (void)updateVideoInfoWithVideoId:(NSString *)videoId
                         videoType:(NSString *)videoType;

@end

NS_ASSUME_NONNULL_END 
