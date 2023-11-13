//
//  PLVLCLandscapeSpeakCell.h
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2020/12/1.
//  Copyright © 2020 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PLVLCLandscapeBaseCell.h"

NS_ASSUME_NONNULL_BEGIN

/*
 云课堂场景，横屏聊天室消息 cell
 支持文本消息
 */
@interface PLVLCLandscapeSpeakCell : PLVLCLandscapeBaseCell

/// 生成消息多属性文本
+ (NSMutableAttributedString *)contentLabelAttributedStringWithMessage:(PLVSpeakMessage *)message
                                                                  user:(PLVChatUser *)user
                                                           loginUserId:(NSString *)loginUserId;

@end

NS_ASSUME_NONNULL_END
