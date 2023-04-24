//
//  PLVLCLandscapeRedpackMessageCell.h
//  PolyvLiveScenesDemo
//
//  Created by MissYasiky on 2023/1/11.
//  Copyright © 2023 PLV. All rights reserved.
//

#import "PLVLCLandscapeBaseCell.h"

NS_ASSUME_NONNULL_BEGIN

/*
 云课堂场景，横屏聊天室红包消息 cell
 可支持多种不同的红包类型，目前只支持支付宝口令红包
 */
@interface PLVLCLandscapeRedpackMessageCell : PLVLCLandscapeBaseCell

@property (nonatomic, copy) void (^redpackTapHandler)(PLVChatModel *model);

@end

NS_ASSUME_NONNULL_END
