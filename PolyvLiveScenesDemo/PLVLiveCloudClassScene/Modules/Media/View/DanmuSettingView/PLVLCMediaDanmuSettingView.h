//
//  PLVLCMediaDanmuSettingView.h
//  PolyvLiveScenesDemo
//
//  Created by Dhan on 2023/4/24.
//  Copyright © 2023 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol PLVLCMediaDanmuSettingViewDelegate;

/// 弹幕设置视图
@interface PLVLCMediaDanmuSettingView : UIView

@property (nonatomic, weak) id <PLVLCMediaDanmuSettingViewDelegate> delegate;

@property (nonatomic, assign, readonly) BOOL danmuSettingViewShow;

@property (nonatomic, copy) NSNumber *defaultDanmuSpeed;

///显示窗口
- (void)showDanmuSettingViewOnSuperview:(UIView *)superview;

- (void)switchShowStatusWithAnimation;

@end

@protocol PLVLCMediaDanmuSettingViewDelegate <NSObject>

- (void)plvLCMediaDanmuSettingView:(PLVLCMediaDanmuSettingView *)danmuSettingView danmuSpeedUpdate:(NSNumber *)speed;

@end


NS_ASSUME_NONNULL_END
