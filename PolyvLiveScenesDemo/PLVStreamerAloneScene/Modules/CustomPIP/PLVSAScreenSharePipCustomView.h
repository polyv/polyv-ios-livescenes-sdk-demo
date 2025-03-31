//
//  PLVSAScreenSharePipCustomView.h
//  PolyvLiveScenesDemo
//
//  Created by Dhan on 2025/3/13.
//  Copyright © 2025 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVKit/AVKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol PLVSAScreenSharePipCustomViewDelegate;

/// 画中画自定义视图基类
API_AVAILABLE(ios(15.0))
@interface PLVSAScreenSharePipCustomView : UIView

/// 内容更新代理
@property (nonatomic, weak) id<PLVSAScreenSharePipCustomViewDelegate> delegate;

/// 是否暂停
@property (nonatomic, assign) BOOL isPaused;

/// 帧率
@property (nonatomic, assign) NSInteger preferredFramesPerSecond;

/// 获取画中画内容源
- (id)pipContentSource;

- (void)startDisplayLink;

- (void)stopDisplayLink;

@end

/// 画中画自定义视图代理
API_AVAILABLE(ios(15.0))
@protocol PLVSAScreenSharePipCustomViewDelegate <NSObject>

@optional

/// 内容更新回调
- (void)pipCustomViewContentWannaUpdate;

@end


NS_ASSUME_NONNULL_END 
