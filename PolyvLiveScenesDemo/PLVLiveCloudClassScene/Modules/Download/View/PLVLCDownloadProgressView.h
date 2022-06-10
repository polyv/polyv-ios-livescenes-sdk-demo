//
//  PLVLCDownloadProgressView.h
//  PolyvLiveScenesDemo
//
//  Created by junotang on 2022/5/25.
//  Copyright © 2022 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
/// 下载进度的view
@interface PLVLCDownloadProgressView : UIView

/// 下载进度：-1~1；-1为立即下载、[0, 1)为下载中、1为已下载
@property (nonatomic, assign) CGFloat downloadProgress;

@property (nonatomic, copy) void (^clickDownloadButtonBlock)(void);

@end

NS_ASSUME_NONNULL_END
