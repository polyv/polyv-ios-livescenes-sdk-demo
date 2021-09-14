//
//  PLVLSChannelInfoTopView.h
//  PLVLiveStreamerDemo
//
//  Created by MissYasiky on 2021/3/4.
//  Copyright © 2021 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 频道信息摘要视图
@interface PLVLSChannelInfoTopView : UIView

/// 设置频道信息摘要
- (void)setTitle:(NSString *)titleString date:(NSString *)dateString channelId:(NSString *)channelIdString;

@end

NS_ASSUME_NONNULL_END
