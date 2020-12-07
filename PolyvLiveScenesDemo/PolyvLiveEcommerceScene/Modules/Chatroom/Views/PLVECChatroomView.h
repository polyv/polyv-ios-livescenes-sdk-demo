//
//  PLVChatroomView.h
//  PolyvLiveEcommerceDemo
//
//  Created by ftao on 2020/5/21.
//  Copyright © 2020 polyv. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PLVLiveRoomData.h"

NS_ASSUME_NONNULL_BEGIN

/// 聊天室视图
@interface PLVECChatroomView : UIView

/// 初始化方法
- (instancetype)initWithRoomData:(PLVLiveRoomData *)roomData;

@end

NS_ASSUME_NONNULL_END
