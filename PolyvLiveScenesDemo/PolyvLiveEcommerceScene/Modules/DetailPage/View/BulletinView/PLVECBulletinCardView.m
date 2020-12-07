//
//  PLVECBulletinCardView.m
//  PolyvLiveEcommerceDemo
//
//  Created by ftao on 2020/5/25.
//  Copyright © 2020 polyv. All rights reserved.
//

#import "PLVECBulletinCardView.h"
#import "PLVECUtils.h"

@interface PLVECBulletinCardView () <UITextViewDelegate>

@property (nonatomic, strong) NSDictionary *linkAttributes;

@end

@implementation PLVECBulletinCardView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.titleLB.text = @"公告";
        self.iconImgView.image = [PLVECUtils imageForWatchResource:@"plv_bulletin_bg_icon"];
        
        self.contentTextView = [[UITextView alloc] init];
        self.contentTextView.backgroundColor = UIColor.clearColor;
        self.contentTextView.textColor = UIColor.blackColor;
        self.contentTextView.font = [UIFont systemFontOfSize:12];
        self.contentTextView.textAlignment = NSTextAlignmentLeft;
        self.contentTextView.textContainer.lineFragmentPadding = 0;
        self.contentTextView.textContainerInset = UIEdgeInsetsZero;
        self.contentTextView.showsVerticalScrollIndicator = NO;
        self.contentTextView.showsHorizontalScrollIndicator = NO;
        self.contentTextView.editable = NO;
        self.contentTextView.delegate = self;
        [self addSubview:self.contentTextView];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat originY = CGRectGetMaxY(self.iconImgView.frame);
    self.contentTextView.frame = CGRectMake(15, originY+15, CGRectGetWidth(self.bounds)-30, CGRectGetHeight(self.bounds)-originY);
}

#pragma mark - Setter

- (void)setContent:(NSString *)content {
    _content = content;
    if ([content isKindOfClass:NSString.class]) {
        // font 12; color black
        NSString *style = @"<style> body { font-size: 12px; color: black; } p:last-of-type { margin: 0; }</style>";
        NSString *styledHtml = [NSString stringWithFormat:@"%@%@", style, content];
        NSError *err = nil;
        NSAttributedString *htmlContentAttr = [[NSAttributedString alloc] initWithData:[styledHtml dataUsingEncoding:NSUnicodeStringEncoding] options:@{NSDocumentTypeDocumentAttribute:NSHTMLTextDocumentType} documentAttributes:nil error:&err];
        if (err) {
            NSLog(@"setContent err:%@",err.localizedDescription);
        }
        self.contentTextView.attributedText = htmlContentAttr;
    } else {
        self.contentTextView.attributedText = nil;
    }
}

#pragma mark - <UITextViewDelegate>

- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange interaction:(UITextItemInteraction)interaction  API_AVAILABLE(ios(10.0)) {
    if ([self.delegate respondsToSelector:@selector(cardView:didInteractWithURL:)]) {
        [self.delegate cardView:self didInteractWithURL:URL];
    }
    return NO;
}

- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange {
    if ([self.delegate respondsToSelector:@selector(cardView:didInteractWithURL:)]) {
        [self.delegate cardView:self didInteractWithURL:URL];
    }
    return NO;
}

@end
