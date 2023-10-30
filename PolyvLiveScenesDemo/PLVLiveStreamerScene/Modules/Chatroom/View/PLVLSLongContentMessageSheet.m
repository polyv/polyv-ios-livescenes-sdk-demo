//
//  PLVLSLongContentMessageSheet.m
//  PolyvLiveScenesDemo
//
//  Created by MissYasiky on 2022/11/21.
//  Copyright © 2022 PLV. All rights reserved.
//

#import "PLVLSLongContentMessageSheet.h"
#import "PLVEmoticonManager.h"
#import "PLVLSUtils.h"
#import "PLVMultiLanguageManager.h"
#import "PLVToast.h"

static NSString *kChatAdminLinkTextColor = @"#0092FA";
static NSString *kFilterRegularExpression = @"((http[s]{0,1}://)?[a-zA-Z0-9\\.\\-]+\\.([a-zA-Z]{2,4})(:\\d+)?(/[a-zA-Z0-9\\.\\-~!@#$%^&*+?:_/=<>]*)?)|(www.[a-zA-Z0-9\\.\\-]+\\.([a-zA-Z]{2,4})(:\\d+)?(/[a-zA-Z0-9\\.\\-~!@#$%^&*+?:_/=<>]*)?)";

@interface PLVLSLongContentMessageSheet ()

#pragma mark 数据
@property (nonatomic, strong) PLVChatModel *model;
@property (nonatomic, copy, readonly) NSString *content; // 弹窗文本

#pragma mark UI
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIView *titleLine;
@property (nonatomic, strong) UITextView *contentTextView;
@property (nonatomic, strong) UIButton *copButton;

@end

@implementation PLVLSLongContentMessageSheet

#pragma mark - [ Life Cycle ]

- (void)layoutSubviews {
    [super layoutSubviews];
    
    BOOL isPad = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
    CGFloat titleLabelTop = 14 + (isPad ? PLVLSUtils.safeTopPad : 0);
    CGFloat titleLineTop = 44 + (isPad ? PLVLSUtils.safeTopPad : 0);
    
    self.titleLabel.frame = CGRectMake(16, titleLabelTop, 70, 22);
    self.titleLine.frame = CGRectMake(16, titleLineTop, self.sheetWidth - 16 - PLVLSUtils.safeSidePad, 1);
    
    CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
    CGFloat copButtonOriginY = screenHeight - 28 - (P_SafeAreaBottomEdgeInsets() > 0 ? P_SafeAreaBottomEdgeInsets() : 10);
    self.copButton.frame = CGRectMake((self.sheetWidth - 120) / 2.0, copButtonOriginY, 88, 28);
    
    CGFloat contentTop = CGRectGetMaxY(self.titleLine.frame) + 23;
    self.contentTextView.frame = CGRectMake(24, contentTop, self.sheetWidth - 24 * 2, CGRectGetMinY(self.copButton.frame) - contentTop - 10);
}

#pragma mark - [ Public Method ]

- (instancetype)initWithChatModel:(PLVChatModel *)model {
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    BOOL isPad = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
    CGFloat sheetWidth = screenWidth * (isPad ? 0.43 : 0.52);
    
    self = [super initWithSheetWidth:sheetWidth];
    if (self) {
        self.model = model;
        
        [self setupUI];
    }
    return self;
}

#pragma mark - [ Private Method ]

- (void)setupUI {
    [self.contentView addSubview:self.titleLabel];
    [self.contentView addSubview:self.titleLine];
    [self.contentView addSubview:self.contentTextView];
    [self.contentView addSubview:self.copButton];
    
    if (!self.model ||
        ![self.model isKindOfClass:[PLVChatModel class]] ) {
        return;
    }
    
    NSMutableAttributedString *attributedString = [self contentLabelAttributedString];
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
    self.contentTextView.linkTextAttributes = adminLinkAttributes;
    self.contentTextView.attributedText = attributedString;
}

/// 获取消息多属性文本
- (NSMutableAttributedString *)contentLabelAttributedString {
    PLVChatUser *user = self.model.user;
    UIFont *font = [UIFont systemFontOfSize:14.0];
    NSString *nickNameColorHexString = [user isUserSpecial] ? @"#FFCA43" : @"#4399FF";
    UIColor *nickNameColor = [PLVColorUtil colorFromHexString:nickNameColorHexString];
    UIColor *contentColor = [PLVColorUtil colorFromHexString:@"#F0F1F5"];
    
    NSDictionary *nickNameAttDict = @{NSFontAttributeName: font,
                                      NSForegroundColorAttributeName: nickNameColor};
    NSDictionary *contentAttDict = @{NSFontAttributeName: font,
                                     NSForegroundColorAttributeName:contentColor};
    
    NSString *content = user.userName;
    if (user.actor && [user.actor isKindOfClass:[NSString class]] && user.actor.length > 0) {
        content = [NSString stringWithFormat:@"%@-%@", user.actor, content];
    }
    content = [content stringByAppendingString:@"："];
    
    NSAttributedString *nickNameString = [[NSAttributedString alloc] initWithString:content attributes:nickNameAttDict];
    NSAttributedString *conentString = [[NSAttributedString alloc] initWithString:self.content attributes:contentAttDict];
    NSMutableAttributedString *emojiContentString = [[PLVEmoticonManager sharedManager] converEmoticonTextToEmotionFormatText:conentString font:font];
    
    NSMutableAttributedString *contentLabelString = [[NSMutableAttributedString alloc] init];
    [contentLabelString appendAttributedString:nickNameString];
    [contentLabelString appendAttributedString:[emojiContentString copy]];
    
    NSMutableParagraphStyle *paragraph = [[NSMutableParagraphStyle alloc] init];
    paragraph.minimumLineHeight = 24.0;
    paragraph.paragraphSpacing = 20.0;
    [contentLabelString addAttribute:NSParagraphStyleAttributeName value:paragraph range:NSMakeRange(0, contentLabelString.length - 1)];
    
    return contentLabelString;
}

/// 获得字符串中 https、http 链接所在位置，并将这些结果放入数组中返回
- (NSArray *)linkRangesWithContent:(NSString *)content {
    NSRegularExpression *regex = [[NSRegularExpression alloc] initWithPattern:kFilterRegularExpression options:0 error:nil];
    return [regex matchesInString:content options:0 range:NSMakeRange(0, content.length)];
}

#pragma mark Getter

- (NSString *)content {
    if (!self.model) {
        return nil;
    }
    NSString *content = [self.model isOverLenMsg] ? self.model.overLenContent : self.model.content;
    return content;
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = [UIFont systemFontOfSize:16];
        _titleLabel.text = PLVLocalizedString(@"全文");
        _titleLabel.textColor = [PLVColorUtil colorFromHexString:@"#f0f1f5"];
    }
    return _titleLabel;
}

- (UIView *)titleLine {
    if (!_titleLine) {
        _titleLine = [[UIView alloc] init];
        _titleLine.backgroundColor = [PLVColorUtil colorFromHexString:@"#f0f1f5" alpha:0.1];
    }
    return _titleLine;
}

- (UITextView *)contentTextView {
    if (!_contentTextView) {
        _contentTextView = [[UITextView alloc] init];
        _contentTextView.backgroundColor = [UIColor clearColor];
        _contentTextView.editable = NO;
        _contentTextView.showsHorizontalScrollIndicator = NO;
        _contentTextView.showsVerticalScrollIndicator = NO;
        _contentTextView.textContainer.lineFragmentPadding = 0;
    }
    return _contentTextView;
}

- (UIButton *)copButton {
    if (!_copButton) {
        _copButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_copButton addTarget:self action:@selector(copButtonAction) forControlEvents:UIControlEventTouchUpInside];
        [_copButton setTitle:PLVLocalizedString(@"复制") forState:UIControlStateNormal];
        _copButton.titleLabel.font = [UIFont systemFontOfSize:12];
        [_copButton setTitleColor:[PLVColorUtil colorFromHexString:@"#4399FF"] forState:UIControlStateNormal];
        _copButton.layer.masksToBounds = YES;
        _copButton.layer.cornerRadius = 14.0;
        _copButton.layer.borderWidth = 1;
        _copButton.layer.borderColor = [PLVColorUtil colorFromHexString:@"#4399FF"].CGColor;
    }
    return _copButton;
}

#pragma mark - [ Event ]

#pragma mark Action

- (void)copButtonAction {
    [self dismiss];
    
    [UIPasteboard generalPasteboard].string = self.content;
    [PLVToast showToastWithMessage:PLVLocalizedString(@"复制成功") inView:[PLVLSUtils sharedUtils].homeVC.view afterDelay:3.0];
}

@end
