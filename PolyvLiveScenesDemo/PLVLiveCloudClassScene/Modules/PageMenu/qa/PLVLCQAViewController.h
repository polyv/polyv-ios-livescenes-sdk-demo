//
//  PLVLCQAViewController.h
//  PolyvLiveScenesDemo
//
//  Created by Sakya on 2021/10/27.
//  Copyright © 2021 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PLVRoomData;

NS_ASSUME_NONNULL_BEGIN

@interface PLVLCQAViewController : UIViewController

/// 问答模块初始化方法
/// @param theme 皮肤，可选值：white、black，默认white
- (instancetype)initWithRoomData:(PLVRoomData *)roomData theme:(NSString *)theme;

@end

NS_ASSUME_NONNULL_END
