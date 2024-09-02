//
//  PLVPinMessagePopupView.m
//  PolyvLiveScenesDemo
//
//  Created by Sakya on 2024/7/1.
//  Copyright © 2024 PLV. All rights reserved.
//

#import "PLVPinMessagePopupView.h"
#import "PLVEmoticonManager.h"
#import "PLVMultiLanguageManager.h"
#import <PLVFoundationSDK/PLVFoundationSDK.h>
#import <SDWebImage/UIImageView+WebCache.h>

@interface PLVPinMessagePopupView()

@property (nonatomic, strong) PLVSpeakTopMessage *speakTopMessage;

#pragma mark UI
@property (nonatomic, strong) UILabel *contentLabel;
@property (nonatomic, strong) UIButton *closeButton;
@property (nonatomic, strong) UIButton *cancelTopButton;
@property (nonatomic, strong) UIVisualEffectView *effectView; // 高斯模糊效果图

@end

@implementation PLVPinMessagePopupView

#pragma mark - [ Life Period ]

- (instancetype)init {
    self = [super init];
    if (self) {
        _canPinMessage = NO;
        [self setupUI];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat padding = 12.0f;
    self.effectView.frame = self.bounds;
    self.closeButton.frame = CGRectMake(CGRectGetWidth(self.bounds) - 24 - padding, (CGRectGetHeight(self.bounds) - 24)/2, 24, 24);
    self.cancelTopButton.frame = CGRectMake(CGRectGetWidth(self.bounds) - 42 - padding, (CGRectGetHeight(self.bounds) - 24)/2, 42, 24);
    CGFloat contentLabelWidth = (self.closeButton.isHidden ? CGRectGetMinX(self.cancelTopButton.frame) - 8 : CGRectGetMinX(self.closeButton.frame) - 12) - padding;
    self.contentLabel.frame = CGRectMake(padding, 10, contentLabelWidth, CGRectGetHeight(self.bounds) - 10 * 2);
}

#pragma mark - [ Public Methods ]

- (void)showPopupView:(BOOL)show message:(PLVSpeakTopMessage * _Nullable)message {
    _speakTopMessage = message;
    self.hidden = !show;
    if (!show || !message) {  return; }
    
    if (![PLVFdUtil checkStringUseable:message.nick] ||
        ![PLVFdUtil checkStringUseable:message.content]) {
        return;
    }
    
    NSDictionary *nickAttributeDict = @{
        NSFontAttributeName: [UIFont systemFontOfSize:12.0f],
        NSForegroundColorAttributeName:[PLVColorUtil colorFromHexString:@"#FFD16B"]
    };
    NSDictionary *contentAttributeDict = @{
        NSFontAttributeName: [UIFont systemFontOfSize:14.0f],
        NSForegroundColorAttributeName:[UIColor whiteColor]
    };
    NSAttributedString *nickAttString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@：", message.nick] attributes:nickAttributeDict];
    NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:message.content attributes:contentAttributeDict];
    NSMutableAttributedString *emojiAttributedString = [[PLVEmoticonManager sharedManager] converEmoticonTextToEmotionFormatText:attributedString font:[UIFont systemFontOfSize:16.0]];
    NSMutableAttributedString *contentString = [[NSMutableAttributedString alloc] init];
    [contentString appendAttributedString:nickAttString];
    [contentString appendAttributedString:emojiAttributedString];
    self.contentLabel.attributedText = contentString;
    self.contentLabel.lineBreakMode = NSLineBreakByTruncatingTail;
}

#pragma mark Setter
- (void)setCanPinMessage:(BOOL)canPinMessage {
    _canPinMessage = canPinMessage;
    self.cancelTopButton.hidden = !canPinMessage;
    self.closeButton.hidden = canPinMessage;
}

#pragma mark - [ Private Methods ]

- (void)setupUI {
    self.layer.cornerRadius = 8.0f;
    self.layer.masksToBounds = YES;
    [self addSubview:self.effectView];
    [self addSubview:self.closeButton];
    [self addSubview:self.cancelTopButton];
    [self addSubview:self.contentLabel];
}

#pragma mark Getter
- (UIButton *)closeButton {
    if (!_closeButton) {
        _closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _closeButton.hidden = self.canPinMessage;
        UIImage *image = [self imageForShareResource:@"plv_pin_close_btn"];
        [_closeButton setImage:image forState:UIControlStateNormal];
        [_closeButton addTarget:self action:@selector(closeButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _closeButton;
}

- (UIButton *)cancelTopButton {
    if (!_cancelTopButton) {
        _cancelTopButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _cancelTopButton.backgroundColor = [PLVColorUtil colorFromHexString:@"#3F76FC"];
        _cancelTopButton.layer.cornerRadius = 12.0f;
        _cancelTopButton.titleLabel.font = [UIFont systemFontOfSize:12];
        _cancelTopButton.hidden = !self.canPinMessage;
        [_cancelTopButton setTitle:PLVLocalizedString(@"下墙") forState:UIControlStateNormal];
        [_cancelTopButton addTarget:self action:@selector(cancelTopButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _cancelTopButton;
}

- (UILabel *)contentLabel {
    if (!_contentLabel) {
        _contentLabel = [[UILabel alloc] init];
        _contentLabel.textColor = [UIColor whiteColor];
        _contentLabel.font = [UIFont systemFontOfSize:14];
        _contentLabel.numberOfLines = 2.0f;
        _contentLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    }
    return _contentLabel;
}

- (UIVisualEffectView *)effectView {
    if (!_effectView) {
        UIBlurEffect *effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
        _effectView = [[UIVisualEffectView alloc] initWithEffect:effect];
        _effectView.alpha = 0.9;
    }
    return _effectView;
}

#pragma mark - Utils

- (UIImage *)imageForShareResource:(NSString *)imageName {
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSBundle *resourceBundle = [NSBundle bundleWithPath:[bundle pathForResource:@"PLVPinMessage" ofType:@"bundle"]];
    return [UIImage imageNamed:imageName inBundle:resourceBundle compatibleWithTraitCollection:nil];
}

#pragma mark - [ Event ]

#pragma mark Action
- (void)closeButtonAction {
    self.hidden = YES;
}

- (void)cancelTopButtonAction {
    _cancelTopActionBlock ? _cancelTopActionBlock(self.speakTopMessage) : nil;
}

@end
