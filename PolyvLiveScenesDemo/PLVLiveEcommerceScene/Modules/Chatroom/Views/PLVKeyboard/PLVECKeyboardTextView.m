//
//  PLVECKeyboardTextView.m
//  PolyvLiveScenesDemo
//
//  Created by Sakya on 2023/8/8.
//  Copyright © 2023 PLV. All rights reserved.
//

#import "PLVECKeyboardTextView.h"
#import "PLVEmoticonManager.h"
#import "PLVMultiLanguageManager.h"

static NSInteger kPLVECKeyboardFontSize = 16.0;
static NSString *kPLVECTextBackedStringAttributeName = @"kTextBackedStringAttributeName";

@interface PLVECKeyboardTextView ()

@property (nonatomic, assign) BOOL isInPlaceholder; // 是否正显示占位
@property (nonatomic, strong) UILabel *placeholderLabel;
@property (nonatomic, strong) NSAttributedString *emptyContent;

@end

@implementation PLVECKeyboardTextView

#pragma mark - Life Cycle

- (instancetype)init {
    self = [super init];
    if (self) {
        self.returnKeyType = UIReturnKeySend;
        self.scrollEnabled = YES;
        self.showsHorizontalScrollIndicator = NO;

        self.emptyContent = [[NSAttributedString alloc] initWithString:@"" attributes:[self defaultAttribute]];
        self.textColor = [self editingTextColor];
        self.font = [UIFont systemFontOfSize:kPLVECKeyboardFontSize];

        [self addSubview:self.placeholderLabel];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.placeholderLabel.frame = CGRectMake(20, 0, self.bounds.size.width - 40, self.bounds.size.height);
}

#pragma mark - Public Method

- (void)setupWithFrame:(CGRect)frame {
    self.frame = frame;
    
    self.layer.cornerRadius = 20;
    if (@available(iOS 11.0, *)) {
        self.textDragInteraction.enabled = NO;
    }
    
    UIEdgeInsets oldTextContainerInset = self.textContainerInset;
    oldTextContainerInset.right = 14.0;
    oldTextContainerInset.left = 14.0;
    self.textContainerInset = oldTextContainerInset;
}

- (void)changePlaceholderText:(NSString *)text {
    self.placeholderLabel.text = text;
}

- (UIColor *)editingTextColor {
   return [UIColor whiteColor];
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
    self.attributedText = self.emptyContent;
    self.isInPlaceholder = YES;
    self.placeholderLabel.hidden = NO;
}

- (void)clearText {
    self.isInPlaceholder = YES;
    self.placeholderLabel.hidden = NO;
    self.attributedText = self.emptyContent;
}

- (void)attributedTextDidChange {
    BOOL showPlaceholderLabel = !(self.attributedText.length > 0);
    self.isInPlaceholder = showPlaceholderLabel;
    self.placeholderLabel.hidden = !showPlaceholderLabel;
}

- (NSString *)plvTextForRange:(NSRange)range {
   NSMutableString *result = [[NSMutableString alloc] init];
   NSString *string = self.attributedText.string;
   [self.attributedText enumerateAttribute:kPLVECTextBackedStringAttributeName inRange:range options:kNilOptions usingBlock:^(id value, NSRange range, BOOL *stop) {
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
       
       UIFont *font = [UIFont systemFontOfSize:kPLVECKeyboardFontSize];
       CGRect emojiFrame = CGRectMake(0.0, font.descender, font.lineHeight, font.lineHeight);
       attachMent.bounds = emojiFrame;
       
       NSMutableAttributedString *emojiAttrStr = [[NSMutableAttributedString alloc] initWithAttributedString:[NSAttributedString attributedStringWithAttachment:attachMent]];
       [emojiAttrStr addAttribute:kPLVECTextBackedStringAttributeName value:imageText range:NSMakeRange(0, emojiAttrStr.length)];
       [emojiAttrStr addAttributes:[self defaultAttribute] range:NSMakeRange(0, emojiAttrStr.length)];
       [attributeStr replaceCharactersInRange:range withAttributedString:emojiAttrStr];
       offset += result.range.length - emojiAttrStr.length;
   }
   
   return attributeStr;
}

#pragma mark - Private Method

- (NSDictionary *)defaultAttribute {
   UIFont *font = [UIFont systemFontOfSize:kPLVECKeyboardFontSize];
   NSMutableParagraphStyle *paragraphStyle = [self paragraphStyle];
   UIColor *textColor = [self editingTextColor];
   NSDictionary *attributes = @{NSFontAttributeName:font,
                                NSParagraphStyleAttributeName:paragraphStyle,
                                NSForegroundColorAttributeName:textColor};
   return attributes;
}

- (NSMutableParagraphStyle *)paragraphStyle {
   NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
   paragraphStyle.lineSpacing = 2.0;
   paragraphStyle.minimumLineHeight = 19.0;
   paragraphStyle.maximumLineHeight = 30.0;
   return paragraphStyle;
}

- (UILabel *)placeholderLabel {
    if (!_placeholderLabel) {
        _placeholderLabel = [[UILabel alloc] init];
        _placeholderLabel.text = PLVLocalizedString(@"聊点什么～");
        _placeholderLabel.font = [UIFont systemFontOfSize:kPLVECKeyboardFontSize];
        _placeholderLabel.textColor = [UIColor colorWithWhite:1 alpha:0.2];
    }
    return _placeholderLabel;
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
       NSString *processString = string;
       NSRange cursorRange = self.selectedRange;
       NSUInteger newLength = self.text.length + string.length - cursorRange.length;
       if (newLength > PLVECKeyboardMaxTextLength) {
           processString = [string substringToIndex:string.length - (newLength - PLVECKeyboardMaxTextLength)];
       }
       
       NSAttributedString *attrStr = [self convertTextWithEmoji:processString];
       
       [self replaceCharactersInRange:cursorRange withAttributedString:attrStr];
       self.selectedRange = NSMakeRange(cursorRange.location + attrStr.length, 0);
       
       if (self.delegate && [self.delegate respondsToSelector:@selector(textViewDidChange:)]) {
           [self.delegate textViewDidChange:self];
       }
   }
}

@end
