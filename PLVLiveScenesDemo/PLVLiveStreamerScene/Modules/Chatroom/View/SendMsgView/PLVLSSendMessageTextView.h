//
//  PLVLSSendMessageTextView.h
//  PLVLiveStreamerDemo
//
//  Created by MissYasiky on 2020/9/28.
//  Copyright © 2020 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

static NSInteger PLVLSSendMessageMaxTextLength = 200;

@interface PLVLSSendMessageTextView : UITextView

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
