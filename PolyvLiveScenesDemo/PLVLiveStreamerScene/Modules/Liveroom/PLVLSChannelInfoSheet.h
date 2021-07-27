//
//  PLVLSChannelInfoSheet.h
//  PLVLiveStreamerDemo
//
//  Created by MissYasiky on 2021/3/3.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVLSBottomSheet.h"

@class PLVLiveVideoChannelMenuInfo;

NS_ASSUME_NONNULL_BEGIN

/// 频道信息弹层
@interface PLVLSChannelInfoSheet : PLVLSBottomSheet

/// 初始化方法
/// @param sheetHeight 弹层弹出高度
- (instancetype)initWithSheetHeight:(CGFloat)sheetHeight;

/// 展示频道信息
/// @param menuInfo 频道信息所需要的元数据
- (void)updateChannelInfoWithData:(PLVLiveVideoChannelMenuInfo *)menuInfo;

@end

NS_ASSUME_NONNULL_END
