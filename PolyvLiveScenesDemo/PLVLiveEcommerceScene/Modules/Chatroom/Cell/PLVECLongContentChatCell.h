//
//  PLVECLongContentChatCellTableViewCell.h
//  PolyvLiveScenesDemo
//
//  Created by MissYasiky on 2022/11/17.
//  Copyright © 2022 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PLVECChatBaseCell.h"

NS_ASSUME_NONNULL_BEGIN

/*
 直播带货场景，聊天室消息，长文本消息 cell
 */
@interface PLVECLongContentChatCell : PLVECChatBaseCell

@property (nonatomic, copy) void (^copButtonHandler)(void);
@property (nonatomic, copy) void (^foldButtonHandler)(void);

@end

NS_ASSUME_NONNULL_END
