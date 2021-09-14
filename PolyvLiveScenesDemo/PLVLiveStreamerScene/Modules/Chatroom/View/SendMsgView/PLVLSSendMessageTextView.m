//
//  PLVLSSendMessageTextView.m
//  PLVLiveStreamerDemo
//
//  Created by MissYasiky on 2020/9/28.
//  Copyright © 2020 PLV. All rights reserved.
//

#import "PLVLSSendMessageTextView.h"
#import "PLVEmoticonManager.h"

static NSInteger kFontSize = 12.0;
static NSString *kTextBackedStringAttributeName = @"kTextBackedStringAttributeName";

@interface PLVLSSendMessageTextView ()

@property (nonatomic, assign) BOOL isInPlaceholder;
@property (nonatomic, strong) NSDictionary *plvAttributes;
@property (nonatomic, strong) NSAttributedString *emptyContent;

@end

@implementation PLVLSSendMessageTextView

#pragma mark - Life Cycle

- (instancetype)init {
    self = [super init];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.returnKeyType = UIReturnKeySend;
        self.scrollEnabled = YES;
        self.showsHorizontalScrollIndicator = NO;
        if (@available(iOS 11.0, *)) {
            self.textDragInteraction.enabled = NO;
        }
        
        self.emptyContent = [[NSAttributedString alloc] initWithString:@"" attributes:[self defaultAttribute]];
        [self endEdit];
    }
    return self;
}

#pragma mark - Public Method

- (UIColor *)editingTextColor {
    return [UIColor colorWithRed:0xf0/255.0 green:0xf1/255.0 blue:0xf5/255.0 alpha:1];
}

- (void)startEdit {
    if (!self.isInPlaceholder) {
        return;
    }
    self.isInPlaceholder = NO;
    self.textColor = [self editingTextColor];
    self.attributedText = self.emptyContent;
}

- (void)endEdit {
    if (self.attributedText.length > 0) {
        return;
    }
    self.isInPlaceholder = YES;
    self.attributedText = [self placeholderText];
}

- (void)clearText {
    self.isInPlaceholder = YES;
    self.attributedText = [self placeholderText];
}

- (NSString *)plvTextForRange:(NSRange)range {
    NSMutableString *result = [[NSMutableString alloc] init];
    NSString *string = self.attributedText.string;
    [self.attributedText enumerateAttribute:kTextBackedStringAttributeName inRange:range options:kNilOptions usingBlock:^(id value, NSRange range, BOOL *stop) {
        NSString *backed = value;
        if (backed) {
            for (NSUInteger i = 0; i < range.length; i++) {
                [result appendString:backed];
            }
        } else {
            [result appendString:[string substringWithRange:range]];
        }
    }];
    return result;
}

- (void)replaceCharactersInRange:(NSRange)range withAttributedString:(NSAttributedString *)attrStr {
    NSMutableAttributedString *content = [[NSMutableAttributedString alloc] initWithAttributedString:self.attributedText];
    [content replaceCharactersInRange:range withAttributedString:attrStr];
    self.attributedText = content;
}

- (NSAttributedString *)convertTextWithEmoji:(NSString *)text {
    NSDictionary *placeholderrAttribute = [self defaultAttribute];
    NSMutableAttributedString *attributeStr = [[NSMutableAttributedString alloc] initWithString:text
                                                                                     attributes:placeholderrAttribute];
    
    NSRegularExpression *regularExpression = [NSRegularExpression regularExpressionWithPattern:@"\\[[^\\[]{1,5}\\]" options:kNilOptions error:nil];
    NSArray<NSTextCheckingResult *> *matchArray = [regularExpression matchesInString:attributeStr.string options:kNilOptions range:NSMakeRange(0, attributeStr.length)];
    NSUInteger offset = 0;
    for (NSTextCheckingResult *result in matchArray) {
        NSRange range = NSMakeRange(result.range.location - offset, result.range.length);
        NSTextAttachment *attachMent = [[NSTextAttachment alloc] init];
        NSString *imageText = [attributeStr.string substringWithRange:range];
        NSString *imageName = [PLVEmoticonManager sharedManager].emoticonDict[imageText];
        attachMent.image = [[PLVEmoticonManager sharedManager] imageForEmoticonName:imageName];
        
        UIFont *font = [UIFont systemFontOfSize:kFontSize];
        CGRect emojiFrame = CGRectMake(0.0, font.descender, font.lineHeight, font.lineHeight);
        attachMent.bounds = emojiFrame;
        
        NSMutableAttributedString *emojiAttrStr = [[NSMutableAttributedString alloc] initWithAttributedString:[NSAttributedString attributedStringWithAttachment:attachMent]];
        [emojiAttrStr addAttribute:kTextBackedStringAttributeName value:imageText range:NSMakeRange(0, emojiAttrStr.length)];
        [emojiAttrStr addAttributes:[self defaultAttribute] range:NSMakeRange(0, emojiAttrStr.length)];
        [attributeStr replaceCharactersInRange:range withAttributedString:emojiAttrStr];
        offset += result.range.length - emojiAttrStr.length;
    }
    
    return attributeStr;
}

#pragma mark - Private Method

- (NSAttributedString *)placeholderText {
    NSDictionary *placeholderrAttribute = [self placeholderrAttribute];
    NSMutableAttributedString *placeholderString = [[NSMutableAttributedString alloc] initWithString:@"有话要说..." attributes:placeholderrAttribute];
    return placeholderString;
}

- (NSDictionary *)placeholderrAttribute {
    UIFont *font = [UIFont systemFontOfSize:kFontSize];
    UIColor *placeholderColor = [UIColor colorWithRed:0x87/255.0 green:0x8b/255.0 blue:0x93/255.0 alpha:1];
    
    NSDictionary *placeholderAttributes = @{NSFontAttributeName:font,
                                            NSForegroundColorAttributeName:placeholderColor};
    return placeholderAttributes;
}

- (NSDictionary *)defaultAttribute {
    UIFont *font = [UIFont systemFontOfSize:kFontSize];
    UIColor *textColor = [self editingTextColor];
    NSDictionary *attributes = @{NSFontAttributeName:font,
                                 NSForegroundColorAttributeName:textColor};
    return attributes;
}

#pragma mark - UIResponder

- (void)cut:(id)sender {
    NSString *string = [self plvTextForRange:self.selectedRange];
    if (string.length > 0) {
        [UIPasteboard generalPasteboard].string = string;
        
        NSRange cursorRange = self.selectedRange;
        [self replaceCharactersInRange:cursorRange withAttributedString:self.emptyContent];
        self.selectedRange = NSMakeRange(cursorRange.location, 0);
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(textViewDidChange:)]) {
            [self.delegate textViewDidChange:self];
        }
    }
}

- (void)copy:(id)sender {
    NSString *string = [self plvTextForRange:self.selectedRange];
    if (string.length > 0) {
        [UIPasteboard generalPasteboard].string = string;
    }
}

- (void)paste:(id)sender {
    NSString *string = UIPasteboard.generalPasteboard.string;
    if (string.length) {
        NSRange cursorRange = self.selectedRange;
        NSUInteger newLength = self.text.length + string.length - cursorRange.length;
        if (newLength > PLVLSSendMessageMaxTextLength) {
            return;
        }
        
        NSAttributedString *attrStr = [self convertTextWithEmoji:string];
        
        [self replaceCharactersInRange:cursorRange withAttributedString:attrStr];
        self.selectedRange = NSMakeRange(cursorRange.location + attrStr.length, 0);
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(textViewDidChange:)]) {
            [self.delegate textViewDidChange:self];
        }
    }
}

@end
