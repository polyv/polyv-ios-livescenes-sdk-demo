//
//  PLVLCLandscapeLongContentCell.h
//  PolyvLiveScenesDemo
//
//  Created by MissYasiky on 2022/11/17.
//  Copyright © 2022 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PLVLCLandscapeBaseCell.h"

NS_ASSUME_NONNULL_BEGIN

/*
 云课堂场景，横屏聊天室消息，长文本消息 cell
 */
@interface PLVLCLandscapeLongContentCell : PLVLCLandscapeBaseCell

@property (nonatomic, copy) void (^copButtonHandler)(void);
@property (nonatomic, copy) void (^foldButtonHandler)(void);

@end

NS_ASSUME_NONNULL_END
