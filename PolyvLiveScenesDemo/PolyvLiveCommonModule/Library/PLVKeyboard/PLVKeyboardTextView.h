//
//  PLVKeyboardTextView.h
//  PolyvLiveScenesDemo
//
//  Created by MissYasiky on 2020/9/28.
//  Copyright © 2020 polyv. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

static NSInteger PLVKeyboardMaxTextLength = 200;

@interface PLVKeyboardTextView : UITextView

@property (nonatomic, assign, readonly) BOOL isInPlaceholder;

@property (nonatomic, strong, readonly) NSAttributedString *emptyContent;

- (void)setupWithFrame:(CGRect)frame;

- (void)startEdit;

- (void)endEdit;

- (void)clearText;

- (UIColor *)editingTextColor;

- (NSString *)plvTextForRange:(NSRange)range;

- (void)replaceCharactersInRange:(NSRange)range withAttributedString:(NSAttributedString *)attrStr;

- (NSAttributedString *)convertTextWithEmoji:(NSString *)text;

@end

NS_ASSUME_NONNULL_END
