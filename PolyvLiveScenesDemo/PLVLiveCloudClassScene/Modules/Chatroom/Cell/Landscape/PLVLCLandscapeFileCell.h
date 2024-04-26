//
//  PLVLCLandscapeFileCell.h
//  PolyvLiveScenesDemo
//
//  Created by Dhan on 2022/7/19.
//  Copyright © 2022 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PLVLCLandscapeBaseCell.h"

NS_ASSUME_NONNULL_BEGIN

@interface PLVLCLandscapeFileCell : PLVLCLandscapeBaseCell

/// 生成消息多属性文本
+ (NSMutableAttributedString *)contentLabelAttributedStringWithMessage:(PLVFileMessage *)message
                                                                  user:(PLVChatUser *)user
                                                           loginUserId:(NSString *)loginUserId;

@end

NS_ASSUME_NONNULL_END
