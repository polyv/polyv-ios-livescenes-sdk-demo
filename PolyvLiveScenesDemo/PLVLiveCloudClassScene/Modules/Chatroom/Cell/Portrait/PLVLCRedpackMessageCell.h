//
//  PLVLCRedpackMessageCell.h
//  PolyvLiveScenesDemo
//
//  Created by MissYasiky on 2023/1/10.
//  Copyright © 2023 PLV. All rights reserved.
//

#import "PLVLCMessageCell.h"

NS_ASSUME_NONNULL_BEGIN

/*
 云课堂场景，竖屏聊天室红包消息 cell
 可支持多种不同的红包类型，目前只支持支付宝口令红包
 */
@interface PLVLCRedpackMessageCell : PLVLCMessageCell

@property (nonatomic, copy) void (^tapRedpackHandler)(PLVChatModel *model);

@end

NS_ASSUME_NONNULL_END
