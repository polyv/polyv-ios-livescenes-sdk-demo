//
//  PLVLCDownloadProgressView.h
//  PolyvLiveScenesDemo
//
//  Created by junotang on 2022/5/25.
//  Copyright © 2022 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 进度条显示类型
typedef NS_ENUM(NSInteger, PLVLCProgressStyle) {
    PLVLCProgressStyleDownload = 0,      //!< 立即下载
    PLVLCProgressStyleDownloading = 1,   //!< 下载中
    PLVLCProgressStyleDownloadStop = 2,  //!< 已暂停
    PLVLCProgressStyleDownloaded = 3     //!< 已下载
};

/// 下载进度的view
@interface PLVLCDownloadProgressView : UIView

/// 下载进度
@property (nonatomic, assign) CGFloat downloadProgress;

@property (nonatomic, assign) PLVLCProgressStyle progressStyle;

@property (nonatomic, copy) void (^clickDownloadButtonBlock)(void);

@end

NS_ASSUME_NONNULL_END
