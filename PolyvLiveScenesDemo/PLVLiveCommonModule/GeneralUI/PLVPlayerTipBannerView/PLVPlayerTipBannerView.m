//
//  PLVPlayerTipBannerView.m
//  PolyvLiveScenesDemo
//
//  Copyright © 2026 PLV. All rights reserved.
//

#import "PLVPlayerTipBannerView.h"
#import "PLVMultiLanguageManager.h"
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>

@interface PLVPlayerTipBannerView ()

@property (nonatomic, strong) UIView *bannerView;
@property (nonatomic, strong) UILabel *prefixLabel;
@property (nonatomic, strong) UIButton *actionButton;
@property (nonatomic, strong) UILabel *suffixLabel;
@property (nonatomic, strong) UIButton *closeButton;
@property (nonatomic, assign) PLVPlayerTipBannerType type;
@property (nonatomic, copy, nullable) NSString *message;
@property (nonatomic, assign) NSInteger errorCode;

@end

@implementation PLVPlayerTipBannerView

#pragma mark - Life Cycle

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.type = PLVPlayerTipBannerTypeErrorCode;
        self.backgroundColor = [UIColor clearColor];
        self.userInteractionEnabled = YES;
        self.hidden = YES;
        [self addSubview:self.bannerView];
        [self.bannerView addSubview:self.prefixLabel];
        [self.bannerView addSubview:self.actionButton];
        [self.bannerView addSubview:self.suffixLabel];
        [self.bannerView addSubview:self.closeButton];
    }
    return self;
}

- (instancetype)init {
    return [self initWithFrame:CGRectZero];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    if (!self.hidden) {
        [self applyMessage:self.message errorCode:self.errorCode];
    }
    [self updateUI];
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    if (self.hidden || self.bannerView.hidden) {
        return NO;
    }
    return CGRectContainsPoint(self.bannerView.frame, point);
}

#pragma mark - Public

- (void)showWithErrorMessage:(NSString *)message type:(PLVPlayerTipBannerType)type {
    [self showWithErrorCode:0 message:message type:type];
}

- (void)showWithErrorCode:(NSInteger)errorCode message:(NSString *)message type:(PLVPlayerTipBannerType)type {
    if (!self.hidden && type < self.type) {
        return;
    }
    self.type = type;
    self.message = message;
    self.errorCode = errorCode;
    [self applyMessage:message errorCode:errorCode];
    [self updateUI];
    self.hidden = NO;
    if (self.superview) {
        [self.superview bringSubviewToFront:self];
    }
}

- (void)hide {
    self.hidden = YES;
}

- (void)hideIfNetworkUnstableTip {
    if (self.hidden) {
        return;
    }
    if (self.type == PLVPlayerTipBannerTypeRefresh || self.type == PLVPlayerTipBannerTypeSwitchLine) {
        [self hide];
    }
}

- (UIView *)actionControl {
    return self.actionButton;
}

#pragma mark - Private

- (void)applyMessage:(NSString *)message errorCode:(NSInteger)errorCode {
    BOOL showOnFloatView = [self isFloatViewSize];
    self.actionButton.hidden = YES;
    self.suffixLabel.hidden = YES;
    self.prefixLabel.textColor = [UIColor whiteColor];

    if (self.type == PLVPlayerTipBannerTypeRefresh && !showOnFloatView) {
        NSString *action = PLVLocalizedString(@"刷新");
        NSString *format = PLVLocalizedString(@"PLVCMNetworkUnstableTryRefreshTips");
        [self configureActionStyleWithFormat:format actionTitle:action];
    } else if (self.type == PLVPlayerTipBannerTypeSwitchLine && !showOnFloatView) {
        NSString *action = PLVLocalizedString(@"线路");
        NSString *format = PLVLocalizedString(@"PLVCMNetworkUnstableTrySwitchLineTips");
        [self configureActionStyleWithFormat:format actionTitle:action];
    } else {
        NSString *text = nil;
        if (self.type == PLVPlayerTipBannerTypeErrorCode) {
            text = [PLVFdUtil checkStringUseable:message] ? message : PLVLocalizedString(@"PLVCMVideoLoadFailedErrorCodeTips");
            if (errorCode) {
                text = [NSString stringWithFormat:PLVLocalizedString(@"%@(错误码:%ld)"), text, (long)errorCode];
            }
        } else if (self.type == PLVPlayerTipBannerTypeRefresh) {
            NSString *action = PLVLocalizedString(@"刷新");
            text = [PLVFdUtil checkStringUseable:message] ? message : [NSString stringWithFormat:PLVLocalizedString(@"PLVCMNetworkUnstableTryRefreshTips"), action];
        } else {
            NSString *action = PLVLocalizedString(@"线路");
            text = [PLVFdUtil checkStringUseable:message] ? message : [NSString stringWithFormat:PLVLocalizedString(@"PLVCMNetworkUnstableTrySwitchLineTips"), action];
        }
        self.prefixLabel.text = text ?: @"";
        self.actionButton.hidden = YES;
        self.suffixLabel.hidden = YES;
        self.suffixLabel.text = @"";
    }
}

- (void)configureActionStyleWithFormat:(NSString *)format actionTitle:(NSString *)actionTitle {
    NSArray<NSString *> *parts = [format componentsSeparatedByString:@"%@"];
    NSString *prefix = parts.count > 0 ? parts[0] : @"";
    NSString *suffix = parts.count > 1 ? parts[1] : @"";
    self.prefixLabel.text = prefix;
    [self.actionButton setTitle:actionTitle forState:UIControlStateNormal];
    self.actionButton.hidden = NO;
    self.suffixLabel.text = suffix;
    self.suffixLabel.hidden = suffix.length == 0;
}

- (BOOL)isFloatViewSize {
    BOOL isPad = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
    return isPad ? (self.bounds.size.width <= 150) : (self.bounds.size.width <= 224);
}

- (void)updateUI {
    if (CGRectEqualToRect(self.bounds, CGRectZero)) {
        return;
    }

    UIFont *font = [UIFont fontWithName:@"PingFangSC-Regular" size:12] ?: [UIFont systemFontOfSize:12];
    self.prefixLabel.font = font;
    self.suffixLabel.font = font;
    self.actionButton.titleLabel.font = font;

    CGFloat horizontalInset = [self isFloatViewSize] ? 8.0 : 16.0;
    // 电商：避开左上角主持人信息（约 y=10~46）；云课堂：避开返回/标题顶栏。小窗保持贴顶。
    CGFloat topInset = [self isFloatViewSize] ? 8.0 : 52.0;
    if (@available(iOS 11.0, *)) {
        // 播放器区域若仍延伸至刘海/状态栏下，叠加安全区；已整体下移时 insets.top 为 0
        topInset += self.safeAreaInsets.top;
    }
    CGFloat closeSize = 28.0;
    CGFloat closeIconSize = 16.0;
    CGFloat contentLeft = 12.0;
    CGFloat contentRight = 4.0;
    CGFloat maxBannerWidth = self.bounds.size.width - horizontalInset * 2;
    CGFloat maxContentWidth = maxBannerWidth - contentLeft - contentRight - closeSize;

    CGSize prefixSize = [self.prefixLabel sizeThatFits:CGSizeMake(maxContentWidth, CGFLOAT_MAX)];
    CGSize actionSize = CGSizeZero;
    CGSize suffixSize = CGSizeZero;
    if (!self.actionButton.hidden) {
        actionSize = [self.actionButton.titleLabel sizeThatFits:CGSizeMake(maxContentWidth, CGFLOAT_MAX)];
        actionSize.width = MAX(ceil(actionSize.width), 24.0);
        actionSize.height = MAX(ceil(actionSize.height), 16.0);
    }
    if (!self.suffixLabel.hidden) {
        suffixSize = [self.suffixLabel sizeThatFits:CGSizeMake(maxContentWidth, CGFLOAT_MAX)];
    }

    CGFloat contentWidth = ceil(prefixSize.width) + (self.actionButton.hidden ? 0 : actionSize.width) + (self.suffixLabel.hidden ? 0 : ceil(suffixSize.width));
    contentWidth = MIN(contentWidth, maxContentWidth);
    CGFloat contentHeight = MAX(MAX(ceil(prefixSize.height), actionSize.height), ceil(suffixSize.height));
    contentHeight = MAX(contentHeight, 16.0);
    CGFloat bannerHeight = MAX(36.0, contentHeight + 16.0);
    CGFloat bannerWidth = contentLeft + contentWidth + contentRight + closeSize;
    bannerWidth = MIN(MAX(bannerWidth, 120.0), maxBannerWidth);

    self.bannerView.frame = CGRectMake((self.bounds.size.width - bannerWidth) / 2.0,
                                       topInset,
                                       bannerWidth,
                                       bannerHeight);
    self.bannerView.layer.cornerRadius = bannerHeight / 2.0;

    CGFloat cursorX = contentLeft;
    CGFloat centerY = (bannerHeight - contentHeight) / 2.0;
    CGFloat prefixWidth = MIN(ceil(prefixSize.width), maxContentWidth);
    self.prefixLabel.frame = CGRectMake(cursorX, centerY, prefixWidth, contentHeight);
    cursorX += prefixWidth;

    if (!self.actionButton.hidden) {
        // 扩大点击热区
        CGFloat hitPaddingH = 6.0;
        CGFloat hitPaddingV = 8.0;
        self.actionButton.frame = CGRectMake(cursorX - hitPaddingH,
                                             centerY - hitPaddingV,
                                             actionSize.width + hitPaddingH * 2,
                                             contentHeight + hitPaddingV * 2);
        self.actionButton.contentEdgeInsets = UIEdgeInsetsMake(hitPaddingV, hitPaddingH, hitPaddingV, hitPaddingH);
        cursorX += actionSize.width;
    } else {
        self.actionButton.frame = CGRectZero;
    }

    if (!self.suffixLabel.hidden) {
        CGFloat suffixWidth = MIN(ceil(suffixSize.width), MAX(0, maxContentWidth - (cursorX - contentLeft)));
        self.suffixLabel.frame = CGRectMake(cursorX, centerY, suffixWidth, contentHeight);
    } else {
        self.suffixLabel.frame = CGRectZero;
    }

    self.closeButton.frame = CGRectMake(bannerWidth - closeSize,
                                        (bannerHeight - closeSize) / 2.0,
                                        closeSize,
                                        closeSize);
    // 视觉上保持小叉，热区用 closeSize
    self.closeButton.titleLabel.font = [UIFont systemFontOfSize:closeIconSize - 4 weight:UIFontWeightMedium];
}

#pragma mark - Event

- (void)actionButtonAction:(UIButton *)button {
    if (self.type == PLVPlayerTipBannerTypeRefresh) {
        [self hide];
        if ([self.delegate respondsToSelector:@selector(plvPlayerTipBannerViewWannaRefresh:)]) {
            [self.delegate plvPlayerTipBannerViewWannaRefresh:self];
        }
    } else if (self.type == PLVPlayerTipBannerTypeSwitchLine) {
        [self hide];
        if ([self.delegate respondsToSelector:@selector(plvPlayerTipBannerViewWannaSwitchLine:)]) {
            [self.delegate plvPlayerTipBannerViewWannaSwitchLine:self];
        }
    }
}

- (void)closeButtonAction:(UIButton *)button {
    [self hide];
    if ([self.delegate respondsToSelector:@selector(plvPlayerTipBannerViewDidClose:)]) {
        [self.delegate plvPlayerTipBannerViewDidClose:self];
    }
}

#pragma mark - Getter

- (UIView *)bannerView {
    if (!_bannerView) {
        _bannerView = [[UIView alloc] init];
        _bannerView.backgroundColor = [PLVColorUtil colorFromHexString:@"#000000" alpha:0.55];
        _bannerView.layer.masksToBounds = YES;
        _bannerView.userInteractionEnabled = YES;
    }
    return _bannerView;
}

- (UILabel *)prefixLabel {
    if (!_prefixLabel) {
        _prefixLabel = [[UILabel alloc] init];
        _prefixLabel.textColor = [UIColor whiteColor];
        _prefixLabel.numberOfLines = 1;
        _prefixLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        _prefixLabel.userInteractionEnabled = NO;
    }
    return _prefixLabel;
}

- (UIButton *)actionButton {
    if (!_actionButton) {
        _actionButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_actionButton setTitleColor:[PLVColorUtil colorFromHexString:@"#6DA7FF"] forState:UIControlStateNormal];
        [_actionButton setTitleColor:[[PLVColorUtil colorFromHexString:@"#6DA7FF"] colorWithAlphaComponent:0.6] forState:UIControlStateHighlighted];
        _actionButton.hidden = YES;
        [_actionButton addTarget:self action:@selector(actionButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _actionButton;
}

- (UILabel *)suffixLabel {
    if (!_suffixLabel) {
        _suffixLabel = [[UILabel alloc] init];
        _suffixLabel.textColor = [UIColor whiteColor];
        _suffixLabel.numberOfLines = 1;
        _suffixLabel.hidden = YES;
        _suffixLabel.userInteractionEnabled = NO;
    }
    return _suffixLabel;
}

- (UIButton *)closeButton {
    if (!_closeButton) {
        _closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_closeButton setTitle:@"✕" forState:UIControlStateNormal];
        [_closeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _closeButton.titleLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
        [_closeButton addTarget:self action:@selector(closeButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _closeButton;
}

@end
