//
//  PLVECLiveStatusView.h
//  PLVLiveScenesDemo
//
//  Created by polyv on 2026/09/04.
//  Copyright © 2026 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 展示直播状态及开播中的动态信号图标。
@interface PLVECLiveStatusView : UIView

- (void)updateStatusText:(NSString *)statusText showsLiveSignal:(BOOL)showsLiveSignal;

@end

NS_ASSUME_NONNULL_END
