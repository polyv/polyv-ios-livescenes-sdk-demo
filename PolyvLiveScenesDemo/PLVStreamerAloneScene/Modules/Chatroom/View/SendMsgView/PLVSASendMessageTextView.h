//
//  PLVSASendMessageTextView.h
//  PLVLiveScenesDemo
//
//  Created by lijingtong on 2021/5/26.
//  Copyright © 2021 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

static NSInteger PLVSASendMessageMaxTextLength = 200;

@interface PLVSASendMessageTextView : UITextView

@property (nonatomic, assign, readonly) BOOL isInPlaceholder;

@property (nonatomic, strong, readonly) NSAttributedString *emptyContent;

- (void)startEdit;

- (void)endEdit;

- (void)clearText;

- (UIColor *)editingTextColor;

- (NSString *)plvTextForRange:(NSRange)range;

- (void)replaceCharactersInRange:(NSRange)range withAttributedString:(NSAttributedString *)attrStr;

- (NSAttributedString *)convertTextWithEmoji:(NSString *)text;


@end

NS_ASSUME_NONNULL_END
