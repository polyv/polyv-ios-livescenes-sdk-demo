//
//  PLVECChatCell.h
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2020/11/28.
//  Copyright © 2020 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PLVECChatBaseCell.h"

NS_ASSUME_NONNULL_BEGIN

@interface PLVECChatCell : PLVECChatBaseCell

@property (nonatomic, copy) void (^redpackTapHandler)(PLVChatModel *model);

+ (NSAttributedString *)chatLabelAttributedStringWithModel:(PLVChatModel *)model;

@end

NS_ASSUME_NONNULL_END
