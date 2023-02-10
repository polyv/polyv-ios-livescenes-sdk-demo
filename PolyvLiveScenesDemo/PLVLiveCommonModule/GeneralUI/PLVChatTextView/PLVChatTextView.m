//
//  PLVChatTextView.m
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2019/11/12.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVChatTextView.h"
#import <PLVFoundationSDK/PLVFoundationSDK.h>

// admin用户链接色号
static NSString *kChatAdminLinkTextColor = @"#0092FA";
static NSString *kFilterRegularExpression = @"((http[s]{0,1}://)?[a-zA-Z0-9\\.\\-]+\\.([a-zA-Z]{2,4})(:\\d+)?(/[a-zA-Z0-9\\.\\-~!@#$%^&*+?:_/=<>]*)?)|(www.[a-zA-Z0-9\\.\\-]+\\.([a-zA-Z]{2,4})(:\\d+)?(/[a-zA-Z0-9\\.\\-~!@#$%^&*+?:_/=<>]*)?)";

@implementation PLVChatTextView

#pragma mark - Life Cycle

- (instancetype)init {
    self = [super init];
    if (self) {
        self.editable = NO;
        self.selectable = NO;
        self.scrollEnabled = NO;
        self.showsHorizontalScrollIndicator = NO;
        self.showsVerticalScrollIndicator = NO;
        self.textContainer.lineFragmentPadding = 0;
        
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

#pragma mark - Override

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    return NO;
}

#pragma mark - Public

- (void)setContent:(NSMutableAttributedString *)attributedString showUrl:(BOOL)showUrl {
    if (showUrl) {
        NSDictionary *adminLinkAttributes = @{
            NSForegroundColorAttributeName:[PLVColorUtil colorFromHexString:kChatAdminLinkTextColor],
            NSUnderlineColorAttributeName:[PLVColorUtil colorFromHexString:kChatAdminLinkTextColor],
            NSUnderlineStyleAttributeName:@(1)
        };
        
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

#pragma mark - Private

/// 获得字符串中 https、http 链接所在位置，并将这些结果放入数组中返回
- (NSArray *)linkRangesWithContent:(NSString *)content {
    NSRegularExpression *regex = [[NSRegularExpression alloc] initWithPattern:kFilterRegularExpression options:0 error:nil];
    return [regex matchesInString:content options:0 range:NSMakeRange(0, content.length)];
}

@end
