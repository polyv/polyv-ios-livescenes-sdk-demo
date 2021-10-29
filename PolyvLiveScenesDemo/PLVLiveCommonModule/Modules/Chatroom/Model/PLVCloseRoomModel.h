//
//  PLVCloseRoomModel.h
//  PLVLiveScenesDemo
//
//  Created by lijingtong on 2021/7/7.
//  Copyright © 2021 PLV. All rights reserved.
// 聊天室关闭、开启消息模型
// 用于在接收到聊天室关闭、开启状态变更时，生成一条本地的聊天室关闭、开启状态消息

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 聊天室关闭、开启模型
@interface PLVCloseRoomModel : NSObject

/// 聊天室是否关闭; YES:已关闭、NO:开启
@property (nonatomic, assign) BOOL closeRoom;

/// 聊天室关闭、开启提示文字
@property (nonatomic, copy, readonly) NSString *closeRoomString;

@end

NS_ASSUME_NONNULL_END
