//
//  PLVLCLandscapeMessagePopupView.m
//  PolyvLiveScenesDemo
//
//  Created by MissYasiky on 2022/11/17.
//  Copyright © 2022 PLV. All rights reserved.
//

#import "PLVLCLandscapeMessagePopupView.h"
#import "PLVEmoticonManager.h"
#import "PLVLCUtils.h"
#import <PLVFoundationSDK/PLVFoundationSDK.h>

static CGFloat kContainerWidth = 380.0;
static NSString *kChatAdminLinkTextColor = @"#0092FA";
static NSString *kFilterRegularExpression = @"((http[s]{0,1}://)?[a-zA-Z0-9\\.\\-]+\\.([a-zA-Z]{2,4})(:\\d+)?(/[a-zA-Z0-9\\.\\-~!@#$%^&*+?:_/=<>]*)?)|(www.[a-zA-Z0-9\\.\\-]+\\.([a-zA-Z]{2,4})(:\\d+)?(/[a-zA-Z0-9\\.\\-~!@#$%^&*+?:_/=<>]*)?)";

@interface PLVLCLandscapeMessagePopupView ()

#pragma mark 数据
@property (nonatomic, strong) PLVChatModel *model;

#pragma mark UI
@property (nonatomic, strong) UIView *bgView;
@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) UILabel *titleLable;
@property (nonatomic, strong) UIButton *closeButton;
@property (nonatomic, strong) UIView *sepLine;
@property (nonatomic, strong) UITextView *contentTextView;
@property (nonatomic, strong) CAGradientLayer *gradientLayer;
@property (nonatomic, strong) UIButton *copButton;

@end

@implementation PLVLCLandscapeMessagePopupView

#pragma mark - [ Life Cycle ]

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.bgView.frame = self.bounds;
    
    UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:self.containerView.bounds byRoundingCorners:UIRectCornerTopLeft | UIRectCornerTopRight cornerRadii:CGSizeMake(8,8)];
    CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
    maskLayer.frame = self.containerView.bounds;
    maskLayer.path = maskPath.CGPath;
    self.containerView.layer.mask = maskLayer;
    
    CGFloat containerWidth = self.containerView.bounds.size.width;
    self.titleLable.frame = CGRectMake(19, 0, 250, 48);
    self.closeButton.frame = CGRectMake(containerWidth - 44 - 8, 2.5, 44, 44);
    self.sepLine.frame = CGRectMake(0, 48, containerWidth, 1);
    
    CGFloat copButtonOriginY = CGRectGetMaxY(self.containerView.frame) - 32 - (P_SafeAreaBottomEdgeInsets() > 0 ? P_SafeAreaBottomEdgeInsets() : 10);
    self.copButton.frame = CGRectMake((containerWidth - 120) / 2.0, copButtonOriginY, 120, 32);
    self.contentTextView.frame = CGRectMake(26, 71, containerWidth - 26 - 21, CGRectGetMinY(self.copButton.frame) - 71 - 10);
    self.gradientLayer.frame = self.contentTextView.frame;
}

- (void)dealloc {
    _delegate = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - [ Public Method ]

- (instancetype)initWithChatModel:(PLVChatModel *)model {
    self = [super init];
    if (self) {
        self.model = model;
        
        [self setupUI];
        [self updateWithModel:self.model];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(interfaceOrientationDidChange:) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
    }
    return self;
}

- (void)showOnView:(UIView *)superView {
    self.frame = superView.bounds;
    CGSize containerSize = CGSizeMake(kContainerWidth, self.bounds.size.height);
    self.containerView.frame = CGRectMake(self.bounds.size.width, 0, containerSize.width, containerSize.height);
    [superView addSubview:self];
    
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        weakSelf.containerView.frame = CGRectMake(self.bounds.size.width - kContainerWidth, 0, containerSize.width, containerSize.height);
    } completion:nil];
}

- (void)hideWithAnimation:(BOOL)animation {
    if (animation) {
        CGSize containerSize = CGSizeMake(kContainerWidth, self.bounds.size.height);
        __weak typeof(self) weakSelf = self;
        [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            weakSelf.containerView.frame = CGRectMake(self.bounds.size.width, 0, containerSize.width, containerSize.height);
        } completion:^(BOOL finished) {
            [weakSelf removeFromSuperview];
        }];
    } else {
        [self removeFromSuperview];
    }
}

#pragma mark Getter

- (NSString *)content {
    if (!self.model) {
        return nil;
    }
    NSString *content = [self.model isOverLenMsg] ? self.model.overLenContent : self.model.content;
    return content;
}

#pragma mark - [ Private Method ]

- (void)setupUI {
    [self addSubview:self.bgView];
    [self addSubview:self.containerView];
    
    [self.containerView addSubview:self.titleLable];
    [self.containerView addSubview:self.closeButton];
    [self.containerView addSubview:self.sepLine];
    [self.containerView addSubview:self.contentTextView];
    [self.containerView addSubview:self.copButton];
    
    [self.containerView.layer addSublayer:self.gradientLayer];
}

- (void)updateWithModel:(PLVChatModel *)model {
    if (!model ||
        ![model isKindOfClass:[PLVChatModel class]] ) {
        return;
    }
    
    // 设置昵称文本
    NSAttributedString *nickLabelString = [PLVLCLandscapeMessagePopupView nickLabelAttributedStringWithUser:model.user];
    
    // 设置内容文本
    [self setContentTextViewWithContent:self.content nickNameString:nickLabelString];
}

/// 获取"头衔+昵称“多属性文本
+ (NSAttributedString *)nickLabelAttributedStringWithUser:(PLVChatUser *)user {
    // 昵称文本属性
    UIFont *font = [UIFont systemFontOfSize:14.0];
    NSString *nickNameColorHexString = [user isUserSpecial] ? @"#FFD36D" : @"#6DA7FF";
    UIColor *nickNameColor = [PLVColorUtil colorFromHexString:nickNameColorHexString];
    NSDictionary *nickNameAttDict = @{NSFontAttributeName: font,
                                      NSForegroundColorAttributeName: nickNameColor};
    // 昵称文本字符串
    NSString *content = user.userName;
    if (user.actor && [user.actor isKindOfClass:[NSString class]] && user.actor.length > 0) {
        content = [NSString stringWithFormat:@"%@-%@", user.actor, content];
    }
    content = [content stringByAppendingString:@"："];
    
    // 获得多属性昵称文本
    NSAttributedString *string = [[NSAttributedString alloc] initWithString:content attributes:nickNameAttDict];
    return string;
}

/// 获取消息多属性文本
- (void)setContentTextViewWithContent:(NSString *)content nickNameString:(NSAttributedString *)nickNameString {
    NSDictionary *attributeDict = @{
                                    NSFontAttributeName: [UIFont systemFontOfSize:14.0],
                                    NSForegroundColorAttributeName:[PLVColorUtil colorFromHexString:@"#333333"]
    };
    NSAttributedString *string = [[NSAttributedString alloc] initWithString:content attributes:attributeDict];
    //云课堂小表情显示需要变大 用font 22；
    NSMutableAttributedString *attributedString = [[PLVEmoticonManager sharedManager] converEmoticonTextToEmotionFormatText:string font:[UIFont systemFontOfSize:22.0]];
    
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
    
    [attributedString insertAttributedString:nickNameString atIndex:0];
    
    NSMutableParagraphStyle *paragraph = [[NSMutableParagraphStyle alloc] init];
    paragraph.minimumLineHeight = 24.0;
    paragraph.paragraphSpacing = 20.0;
    [attributedString addAttribute:NSParagraphStyleAttributeName value:paragraph range:NSMakeRange(0, attributedString.length - 1)];
    
    self.contentTextView.attributedText = attributedString;
}

/// 获得字符串中 https、http 链接所在位置，并将这些结果放入数组中返回
- (NSArray *)linkRangesWithContent:(NSString *)content {
    NSRegularExpression *regex = [[NSRegularExpression alloc] initWithPattern:kFilterRegularExpression options:0 error:nil];
    return [regex matchesInString:content options:0 range:NSMakeRange(0, content.length)];
}

#pragma mark Getter

- (UIView *)bgView {
    if (!_bgView) {
        _bgView = [[UIView alloc] init];
        
        UITapGestureRecognizer *gesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureAction)];
        [_bgView addGestureRecognizer:gesture];
    }
    return _bgView;
}

- (UIView *)containerView {
    if (!_containerView) {
        _containerView = [[UIView alloc] init];
        _containerView.backgroundColor = [UIColor whiteColor];
    }
    return _containerView;
}

- (UILabel *)titleLable {
    if (!_titleLable) {
        _titleLable = [[UILabel alloc] init];
        _titleLable.font = [UIFont systemFontOfSize:16];
        _titleLable.textColor = [PLVColorUtil colorFromHexString:@"#333333"];
        _titleLable.textAlignment = NSTextAlignmentLeft;
        _titleLable.text = @"全文";
    }
    return _titleLable;
}

- (UIButton *)closeButton {
    if (!_closeButton) {
        _closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_closeButton addTarget:self action:@selector(closeButtonAction) forControlEvents:UIControlEventTouchUpInside];
        UIImage *image = [PLVLCUtils imageForChatroomResource:@"plvlc_chatroom_popup_close"];
        [_closeButton setImage:image forState:UIControlStateNormal];
    }
    return _closeButton;
}

- (UIView *)sepLine {
    if (!_sepLine) {
        _sepLine = [[UIView alloc] init];
        _sepLine.backgroundColor = [PLVColorUtil colorFromHexString:@"#EDEDEF"];
    }
    return _sepLine;
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
        [_copButton setTitle:@"复制" forState:UIControlStateNormal];
        _copButton.titleLabel.font = [UIFont systemFontOfSize:14];
        [_copButton setTitleColor:[PLVColorUtil colorFromHexString:@"#333333" alpha:0.8] forState:UIControlStateNormal];
        _copButton.layer.masksToBounds = YES;
        _copButton.layer.cornerRadius = 16.0;
        _copButton.layer.borderWidth = 1;
        _copButton.layer.borderColor = [PLVColorUtil colorFromHexString:@"#E1E1E1"].CGColor;
    }
    return _copButton;
}

- (CAGradientLayer *)gradientLayer {
    if (!_gradientLayer) {
        _gradientLayer = [CAGradientLayer layer];
        _gradientLayer.colors = @[(__bridge id)[PLVColorUtil colorFromHexString:@"#FFFFFF" alpha:0].CGColor, (__bridge id)[PLVColorUtil colorFromHexString:@"#FFFFFF" alpha:1].CGColor];
        _gradientLayer.locations = @[@0.85, @1.0];
        _gradientLayer.startPoint = CGPointMake(0, 0);
        _gradientLayer.endPoint = CGPointMake(0, 1);
    }
    return _gradientLayer;
}


#pragma mark - [ Event ]

#pragma mark Action

- (void)tapGestureAction {
    [self hideWithAnimation:YES];
}

- (void)closeButtonAction {
    [self hideWithAnimation:YES];
    
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(landscapeMessagePopupViewWillClose:)]) {
        [self.delegate landscapeMessagePopupViewWillClose:self];
    }
}

- (void)copButtonAction {
    [self hideWithAnimation:YES];
    
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(landscapeMessagePopupViewWillCopy:)]) {
        [self.delegate landscapeMessagePopupViewWillCopy:self];
    }
}

#pragma mark Notification

- (void)interfaceOrientationDidChange:(NSNotification *)notification {
    [self hideWithAnimation:NO];
}

@end
