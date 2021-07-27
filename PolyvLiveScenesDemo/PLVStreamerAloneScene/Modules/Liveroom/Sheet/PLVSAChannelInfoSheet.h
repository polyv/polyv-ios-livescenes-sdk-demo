//
//  PLVSAChannelInfoSheet.h
//  PLVLiveScenesDemo
//
//  Created by lijingtong on 2021/5/25.
//  Copyright © 2021 PLV. All rights reserved.
// 直播信息弹层

#import "PLVSABottomSheet.h"

@class PLVLiveVideoChannelMenuInfo;
@class PLVRoomData;

NS_ASSUME_NONNULL_BEGIN

/// 频道信息弹层
@interface PLVSAChannelInfoSheet : PLVSABottomSheet

/// 初始化方法
/// @param sheetHeight 弹层弹出高度
- (instancetype)initWithSheetHeight:(CGFloat)sheetHeight;

/// 展示频道信息
/// @param roomData 频道信息所需要的元数据
- (void)updateChannelInfoWithData:(PLVRoomData *)roomData;

@end

NS_ASSUME_NONNULL_END
