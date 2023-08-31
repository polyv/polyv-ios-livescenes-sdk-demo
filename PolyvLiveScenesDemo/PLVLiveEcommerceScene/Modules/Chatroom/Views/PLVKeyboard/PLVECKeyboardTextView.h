//
//  PLVECKeyboardTextView.h
//  PolyvLiveScenesDemo
//
//  Created by Sakya on 2023/8/8.
//  Copyright © 2023 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

static NSInteger PLVECKeyboardMaxTextLength = 200;

@interface PLVECKeyboardTextView : UITextView

@property (nonatomic, assign, readonly) BOOL isInPlaceholder;

@property (nonatomic, strong, readonly) NSAttributedString *emptyContent;

- (void)changePlaceholderText:(NSString *)text;

- (void)setupWithFrame:(CGRect)frame;

- (void)startEdit;

- (void)endEdit;

- (void)clearText;

- (void)attributedTextDidChange;

- (UIColor *)editingTextColor;

- (NSString *)plvTextForRange:(NSRange)range;

- (void)replaceCharactersInRange:(NSRange)range withAttributedString:(NSAttributedString *)attrStr;

- (NSAttributedString *)convertTextWithEmoji:(NSString *)text;

@end

NS_ASSUME_NONNULL_END
