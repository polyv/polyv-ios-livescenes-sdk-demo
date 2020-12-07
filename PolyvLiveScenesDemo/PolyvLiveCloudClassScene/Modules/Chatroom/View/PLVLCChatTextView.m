//
//  PLVLCChatTextView.m
//  TextViewLink
//
//  Created by MissYasiky on 2019/11/12.
//  Copyright © 2019 MissYasiky. All rights reserved.
//

#import "PLVLCChatTextView.h"
#import "PLVEmoticonManager.h"
#import <PolyvFoundationSDK/PLVColorUtil.h>
#import <PolyvFoundationSDK/PLVFdUtil.h>

// admin用户链接色号
static NSString *kChatAdminLinkTextColor = @"#0092FA";

static NSString *kFilterRegularExpression = @"((http[s]{0,1}://)?[a-zA-Z0-9\\.\\-]+\\.([a-zA-Z]{2,4})(:\\d+)?(/[a-zA-Z0-9\\.\\-~!@#$%^&*+?:_/=<>]*)?)|(www.[a-zA-Z0-9\\.\\-]+\\.([a-zA-Z]{2,4})(:\\d+)?(/[a-zA-Z0-9\\.\\-~!@#$%^&*+?:_/=<>]*)?)";


@interface PLVLCChatTextView ()

@property (nonatomic, assign) BOOL showingMenu;
@property (nonatomic, assign) NSRange lastSelectedRange;

@end

@implementation PLVLCChatTextView

#pragma mark - Life Cycle

- (instancetype)init {
    self = [super init];
    if (self) {
        self.editable = NO;
        self.scrollEnabled = NO;
        self.showsHorizontalScrollIndicator = NO;
        self.showsVerticalScrollIndicator = NO;
        self.textContainer.lineFragmentPadding = 0;
        
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

#pragma mark - NSNotification

- (void)addObserver {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(menuControllerWillShow) name:UIMenuControllerWillShowMenuNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(menuControllerDidShow) name:UIMenuControllerDidShowMenuNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(menuControllerDidHide) name:UIMenuControllerDidHideMenuNotification object:nil];
}

- (void)removeObserver {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIMenuControllerWillShowMenuNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIMenuControllerDidShowMenuNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIMenuControllerDidHideMenuNotification object:nil];
}

- (void)menuControllerDidHide {
    self.showingMenu = NO;
    [self performSelector:@selector(resignFirstResponder) withObject:nil afterDelay:0.1];
}

- (void)menuControllerWillShow {
    self.showingMenu = YES;
}

- (void)menuControllerDidShow {
    self.lastSelectedRange = self.selectedRange;
}

#pragma mark - Override

- (BOOL)becomeFirstResponder {
    [self addObserver];
    return [super becomeFirstResponder];
}

- (BOOL)resignFirstResponder {
    /*if (self.showingMenu || self.lastSelectedRange.location != self.selectedRange.location || self.lastSelectedRange.length != self.selectedRange.length) {
        return NO;
    }*/
    [self removeObserver];
    return [super resignFirstResponder];
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    return (action == @selector(copy:));
}

#pragma mark - Public

- (void)setContent:(NSMutableAttributedString *)attributedString showUrl:(BOOL)showUrl {
    NSDictionary *adminLinkAttributes = @{
        NSForegroundColorAttributeName:[PLVColorUtil colorFromHexString:kChatAdminLinkTextColor],
        NSUnderlineColorAttributeName:[PLVColorUtil colorFromHexString:kChatAdminLinkTextColor],
        NSUnderlineStyleAttributeName:@(1)
    };
    
    if (showUrl) {
        NSArray *linkRanges = [self linkRangesWithContent:attributedString.string];
        for (NSTextCheckingResult *result in linkRanges) {
            NSString *originString = [attributedString.string substringWithRange:result.range];
            NSString *resultString = [PLVFdUtil packageURLStringWithHTTPS:originString];
            [attributedString addAttribute:NSLinkAttributeName value:resultString range:result.range];
            [attributedString addAttributes:adminLinkAttributes range:result.range];
        }
        self.linkTextAttributes = adminLinkAttributes;
    }
    
    self.attributedText = attributedString;
}

- (CGSize)setContent:(NSAttributedString *)attributedString
            fontSize:(CGFloat)contentFontSize
             showUrl:(BOOL)showUrl
               width:(CGFloat)width {
    UIFont *font = [UIFont systemFontOfSize:contentFontSize];
    NSDictionary *adminLinkAttributes = @{NSForegroundColorAttributeName:[PLVColorUtil colorFromHexString:kChatAdminLinkTextColor],
             NSFontAttributeName:font,
    NSUnderlineColorAttributeName:[PLVColorUtil colorFromHexString:kChatAdminLinkTextColor],
    NSUnderlineStyleAttributeName:@(1)};
    
    NSMutableAttributedString *muString = [[NSMutableAttributedString alloc] initWithAttributedString:attributedString];
    if (showUrl) {
        NSArray *linkRanges = [self linkRangesWithContent:muString.string];
        for (NSTextCheckingResult *result in linkRanges) {
            NSString *originString = [muString.string substringWithRange:result.range];
            NSString *resultString = [PLVFdUtil packageURLStringWithHTTPS:originString];
            [muString addAttribute:NSLinkAttributeName value:resultString range:result.range];
            [muString addAttributes:adminLinkAttributes range:result.range];
        }
        self.linkTextAttributes = adminLinkAttributes;
    }
    
    self.attributedText = muString;
    
    // 调整 PLVLCChatTextView 的大小到刚好显示完全部文本
    CGRect originRect = self.frame;
    CGSize newSize = [self sizeThatFits:CGSizeMake(width, MAXFLOAT)];
    self.frame = CGRectMake(originRect.origin.x, originRect.origin.y, newSize.width, newSize.height);
    
    return newSize;
}

#pragma mark - Private

/// 获得字符串中 https、http 链接所在位置，并将这些结果放入数组中返回
- (NSArray *)linkRangesWithContent:(NSString *)content {
    NSRegularExpression *regex = [[NSRegularExpression alloc] initWithPattern:kFilterRegularExpression options:0 error:nil];
    return [regex matchesInString:content options:0 range:NSMakeRange(0, content.length)];
}

@end
