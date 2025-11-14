//
//  PLVECQuoteChatCell.h
//  PolyvLiveScenesDemo
//
//  Created by MissYasiky on 2023/2/7.
//  Copyright © 2023 PLV. All rights reserved.
//

#import "PLVECChatBaseCell.h"

NS_ASSUME_NONNULL_BEGIN

/*
 直播带货场景，聊天室消息，回复消息 cell
 */
@interface PLVECQuoteChatCell : PLVECChatBaseCell

+ (NSAttributedString * _Nullable)contentAttributedStringWithChatModel:(PLVChatModel *)chatModel;

+ (NSAttributedString * _Nullable)chatLabelAttributedStringWithModel:(PLVChatModel *)user;

@end

NS_ASSUME_NONNULL_END
