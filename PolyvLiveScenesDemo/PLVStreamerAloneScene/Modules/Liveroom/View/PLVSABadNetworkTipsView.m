//
//  PLVSABadNetworkTipsView.m
//  PolyvLiveScenesDemo
//
//  Created by MissYasiky on 2023/4/28.
//  Copyright © 2023 PLV. All rights reserved.
//

#import "PLVSABadNetworkTipsView.h"
#import "PLVSAUtils.h"
#import "PLVMultiLanguageManager.h"
#import <PLVFoundationSDK/PLVFoundationSDK.h>

static CGFloat kBadNetworkTipsViewDismissDuration = 10.0; // // 每次显示持续时长
static CGFloat kBadNetworkTipsViewShowInterval = 60 * 10.0; // 两次显示时间最小间隔
static NSString *kBadNetworkTipsSwitchAttributeName = @"switchnow";

@interface PLVSABadNetworkTipsView ()<UITextViewDelegate>

@property (nonatomic, assign) BOOL showing;
@property (nonatomic, assign) BOOL cooling;
@property (nonatomic, strong) UITextView *textView;
@property (nonatomic, strong) UIButton *switchButton;
@property (nonatomic, strong) UIButton *closeButton;

@end

@implementation PLVSABadNetworkTipsView

#pragma mark - [ Life Cycle ]

- (instancetype)init {
    self = [super init];
    if (self) {
        self.backgroundColor = [PLVColorUtil colorFromHexString:@"#1B202D" alpha:0.6];
        self.layer.cornerRadius = 10.0f;

        [self initUI];
    }
    return self;
}

- (void)layoutSubviews {
    CGFloat height = self.bounds.size.height;
    self.closeButton.frame = CGRectMake(self.bounds.size.width - 4 - 24, 0, 24, height);
    self.switchButton.frame = CGRectMake(CGRectGetMinX(self.closeButton.frame)- 70, 0, 70, height);
    CGSize labelSize = [self.textView.attributedText boundingRectWithSize:CGSizeMake(PLVScreenWidth - 40, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:nil].size;
    self.textView.frame = CGRectMake(12, (height - labelSize.height)/2, CGRectGetMinX(self.closeButton.frame) - 12, labelSize.height);
}

#pragma mark - [ Public Methods ]

- (void)showAtView:(UIView *)superView aboveSubview:(UIView *)aboveView {
    if (self.showing || self.cooling) {
        return;
    }
    
    self.showing = YES;
    [superView insertSubview:self aboveSubview:aboveView];
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(dismiss) object:nil];
    [self performSelector:@selector(dismiss) withObject:nil afterDelay:kBadNetworkTipsViewDismissDuration];
}

- (void)dismiss {
    self.showing = NO;
    [self removeFromSuperview];
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(dismiss) object:nil];
    
    [self startCooling];
}

- (void)reset {
    [self stopCooling];
}

- (CGSize)viewSize {
    CGSize labelSize = [self.textView.attributedText boundingRectWithSize:CGSizeMake(PLVScreenWidth - 40, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:nil].size;
    CGFloat viewHeight = (labelSize.height > ceil(self.textView.font.lineHeight)) ? 40 : 20;
    CGFloat viewWidth = (labelSize.height > ceil(self.textView.font.lineHeight)) ? labelSize.width : labelSize.width + 45;
    return CGSizeMake(viewWidth, viewHeight);
}

#pragma mark - [ Private Methods ]

- (void)initUI {
    [self addSubview:self.textView];
    [self addSubview:self.closeButton];
    [self addSubview:self.switchButton];
    
    [self setupLabelText];
}

- (void)setupLabelText {
    NSMutableAttributedString *muString = [[NSMutableAttributedString alloc] init];
    
    {
        NSString *string = PLVLocalizedString(@"当前网络较差，建议切换为流畅模式 ");
        NSDictionary *attributes = @{
            NSFontAttributeName : [UIFont systemFontOfSize:12],
            NSForegroundColorAttributeName : [PLVColorUtil colorFromHexString:@"#F0F1F5"]
        };
        NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:string attributes:attributes];
        [muString appendAttributedString:attributedString];
    }
    
    {
        NSString *string = PLVLocalizedString(@"马上切换");
        NSDictionary *attributes = @{
            NSLinkAttributeName : [NSString stringWithFormat:@"%@://", kBadNetworkTipsSwitchAttributeName],
            NSFontAttributeName : [UIFont systemFontOfSize:12],
            NSUnderlineStyleAttributeName : @(1)
        };
        NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:string attributes:attributes];
        [muString appendAttributedString:attributedString];
    }
    
    self.textView.linkTextAttributes = @{NSForegroundColorAttributeName: [PLVColorUtil colorFromHexString:@"#FF6363"]};
    self.textView.attributedText = [muString copy];
}

- (void)startCooling {
    self.cooling = YES;
    [self performSelector:@selector(stopCooling) withObject:nil afterDelay:kBadNetworkTipsViewShowInterval];
}

- (void)stopCooling {
    self.cooling = NO;
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(stopCooling) object:nil];
}

#pragma mark Getter & Setter

- (UITextView *)textView {
    if (!_textView) {
        _textView = [[UITextView alloc] init];
        _textView.delegate = self;
        _textView.editable = YES;        //必须禁止输入，否则点击将弹出输入键盘
        _textView.scrollEnabled = NO;
        _textView.backgroundColor = [UIColor clearColor];
        _textView.textContainerInset = UIEdgeInsetsZero;
        _textView.textContainer.lineFragmentPadding = 0;
    }
    return _textView;
}

- (UIButton *)closeButton {
    if (!_closeButton) {
        _closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        UIImage *normalImage = [PLVSAUtils imageForLiveroomResource:@"plvsa_liveroom_mode_switch_close_icon"];
        [_closeButton setImage:normalImage forState:UIControlStateNormal];
        [_closeButton addTarget:self action:@selector(closeButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _closeButton;
}

- (UIButton *)switchButton {
    if (!_switchButton) {
        _switchButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_switchButton addTarget:self action:@selector(switchButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _switchButton;
}

#pragma mark - [ Event ]

#pragma mark Action

- (void)closeButtonAction {
    [self dismiss];
    
    if (self.closeButtonActionBlock) {
        self.closeButtonActionBlock();
    }
}

- (void)switchButtonAction {
    [self dismiss];
    [self reset];
    
    if (self.switchButtonActionBlock) {
        self.switchButtonActionBlock();
    }
}

#pragma mark UITextViewDelegate
- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange {
    if ([[URL scheme] isEqualToString:kBadNetworkTipsSwitchAttributeName]) {
        [self switchButtonAction];
    }
    return NO;
}

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView {
    return NO;
}

@end
