//
//  PLVHCSendMessageTextView.h
//  PLVLiveScenesDemo
//
//  Created by lijingtong on 2021/6/28.
//  Copyright © 2021 PLV. All rights reserved.
// 自定义UITextView视图

#import <UIKit/UIKit.h>
#import "PLVRoomUser.h"

NS_ASSUME_NONNULL_BEGIN

static NSInteger PLVHCSendMessageMaxTextLength = 200;

@interface PLVHCSendMessageTextView : UITextView

@property (nonatomic, assign, readonly) BOOL isInPlaceholder;

@property (nonatomic, strong, readonly) NSAttributedString *emptyContent;

/// 开始直播
- (void)startClass;

/// 结束直播
- (void)finishClass;

- (void)startEdit;

- (void)endEdit;

- (void)clearText;

- (UIColor *)editingTextColor;

- (NSString *)plvTextForRange:(NSRange)range;

- (void)replaceCharactersInRange:(NSRange)range withAttributedString:(NSAttributedString *)attrStr;

- (NSAttributedString *)convertTextWithEmoji:(NSString *)text;

@end

NS_ASSUME_NONNULL_END
