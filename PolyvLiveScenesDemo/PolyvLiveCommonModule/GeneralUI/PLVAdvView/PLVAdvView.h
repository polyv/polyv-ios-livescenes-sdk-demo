//
//  PLVAdvView.h
//  PolyvLiveScenesDemo
//
//  Created by Hank on 2020/12/23.
//  Copyright © 2020 polyv. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, PLVAdvViewStatus) { // 播放器态类型
    PLVAdvViewStatusUnkown = 0, // 未知类型（初始状态）
    PLVAdvViewStatusPlay, // 展示中
    PLVAdvViewStatusFinish, // 展示完成
};

@class PLVAdvView;

@protocol PLVAdvViewDelegate <NSObject>

@required
/// 广告状态回调
- (void)advView:(PLVAdvView *)advView status:(PLVAdvViewStatus)status;

@end

@interface PLVAdvView : UIView

@property (nonatomic, assign, readonly) BOOL playing; // 是否正在播放中
@property (nonatomic, assign, readonly) PLVAdvViewStatus status; // 播放器状态
@property (nonatomic, weak) id<PLVAdvViewDelegate> delegate;

/// 设置广告外部容器
- (void)setupDisplaySuperview:(UIView *)displayeSuperview;

/// 展示图片url
- (void)showImageWithUrl:(NSString *)url time:(NSInteger)time;

/// 播放url
- (void)showVideoWithUrl:(NSString *)url time:(NSInteger)time;

/// 销毁 广告
- (void)distroy;

@end

NS_ASSUME_NONNULL_END
