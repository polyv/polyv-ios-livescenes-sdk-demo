//
//  PLVLCMessagePopupView.m
//  PolyvLiveScenesDemo
//
//  Created by MissYasiky on 2022/11/16.
//  Copyright © 2022 PLV. All rights reserved.
//

#import "PLVLCMessagePopupView.h"
#import "PLVEmoticonManager.h"
#import "PLVLCUtils.h"
#import <PLVFoundationSDK/PLVFoundationSDK.h>

static NSString *kChatAdminLinkTextColor = @"#0092FA";

static NSString *kFilterRegularExpression = @"((http[s]{0,1}://)?[a-zA-Z0-9\\.\\-]+\\.([a-zA-Z]{2,4})(:\\d+)?(/[a-zA-Z0-9\\.\\-~!@#$%^&*+?:_/=<>]*)?)|(www.[a-zA-Z0-9\\.\\-]+\\.([a-zA-Z]{2,4})(:\\d+)?(/[a-zA-Z0-9\\.\\-~!@#$%^&*+?:_/=<>]*)?)";

@interface PLVLCMessagePopupView ()

#pragma mark 数据
@property (nonatomic, strong) PLVChatModel *model;

#pragma mark UI
@property (nonatomic, strong) UIView *bgView;
@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) UILabel *titleLable;
@property (nonatomic, strong) UIButton *closeButton;
@property (nonatomic, strong) UIView *sepLine;
@property (nonatomic, strong) UIImageView *avatarImageView;
@property (nonatomic, strong) UILabel *nickNameLabel;
@property (nonatomic, strong) UITextView *contentTextView;
@property (nonatomic, strong) UIButton *copButton;
@property (nonatomic, strong) CAGradientLayer *gradientLayer;

#pragma mark 状态
@property (nonatomic, assign) CGFloat containerHeight;

@end

@implementation PLVLCMessagePopupView

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
    self.titleLable.frame = CGRectMake(0, 0, containerWidth, 48);
    self.closeButton.frame = CGRectMake(containerWidth - 48, 0, 48, 48);
    self.sepLine.frame = CGRectMake(0, 48, containerWidth, 1);
    self.avatarImageView.frame = CGRectMake(26, CGRectGetMaxY(self.sepLine.frame) + 16, 32, 32);
    
    CGFloat nickNameOriginX = CGRectGetMaxX(self.avatarImageView.frame) + 7;
    self.nickNameLabel.frame = CGRectMake(nickNameOriginX, CGRectGetMinY(self.avatarImageView.frame) + 8, containerWidth - 10 - nickNameOriginX, 16);
    
    CGFloat copButtonOriginY = self.containerHeight - 32 - (P_SafeAreaBottomEdgeInsets() > 0 ? P_SafeAreaBottomEdgeInsets() : 10);
    self.copButton.frame = CGRectMake((containerWidth - 120) / 2.0, copButtonOriginY, 120, 32);
    
    CGFloat contentOriginX = CGRectGetMinX(self.avatarImageView.frame);
    CGFloat contentOriginY = CGRectGetMaxY(self.avatarImageView.frame) + 16;
    self.contentTextView.frame = CGRectMake(contentOriginX, contentOriginY, containerWidth - contentOriginX * 2, CGRectGetMinY(self.copButton.frame) - 16 - contentOriginY);
    
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

- (void)setContainerHeight:(CGFloat)containerHeight {
    _containerHeight = containerHeight;
}

- (void)showOnView:(UIView *)superView {
    self.frame = superView.bounds;
    CGSize containerSize = CGSizeMake(self.bounds.size.width, self.containerHeight);
    self.containerView.frame = CGRectMake(0, self.bounds.size.height, containerSize.width, containerSize.height);
    [superView addSubview:self];
    
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        weakSelf.containerView.frame = CGRectMake(0, self.bounds.size.height - containerSize.height, containerSize.width, containerSize.height);
    } completion:nil];
}

- (void)hideWithAnimation:(BOOL)animation {
    if (animation) {
        CGSize containerSize = CGSizeMake(self.bounds.size.width, self.containerHeight);
        
        __weak typeof(self) weakSelf = self;
        [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            weakSelf.containerView.frame = CGRectMake(0, self.bounds.size.height, containerSize.width, containerSize.height);
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
    [self.containerView addSubview:self.avatarImageView];
    [self.containerView addSubview:self.nickNameLabel];
    [self.containerView addSubview:self.contentTextView];
    [self.containerView addSubview:self.copButton];
    
    [self.containerView.layer addSublayer:self.gradientLayer];
}

- (void)updateWithModel:(PLVChatModel *)model {
    if (!model ||
        ![model isKindOfClass:[PLVChatModel class]] ) {
        return;
    }
    
    // 设置用户头像
    NSURL *avatarURL = [PLVLCMessagePopupView avatarImageURLWithUser:model.user];
    UIImage *placeholderImage = [PLVLCUtils imageForChatroomResource:@"plvlc_chatroom_default_avatar"];
    if (avatarURL) {
        [PLVLCUtils setImageView:self.avatarImageView url:avatarURL placeholderImage:placeholderImage
                         options:SDWebImageRetryFailed];
    } else {
        self.avatarImageView.image = placeholderImage;
    }
    
    // 设置昵称文本
    NSAttributedString *nickLabelString = [PLVLCMessagePopupView nickLabelAttributedStringWithUser:model.user];
    self.nickNameLabel.attributedText = nickLabelString;
    
    // 设置内容文本
    [self setContentTextViewWithContent:self.content];
}

/// 获取用户头像URL
+ (NSURL *)avatarImageURLWithUser:(PLVChatUser *)user {
    if (!user || ![user isKindOfClass:[PLVChatUser class]]) {
        return nil;
    }
    NSString *avatarUrl = user.avatarUrl;
    if (!avatarUrl || ![avatarUrl isKindOfClass:[NSString class]] || avatarUrl.length == 0) {
        return nil;
    }
    
    return [NSURL URLWithString:avatarUrl];
}

/// 获取"头衔+昵称“多属性文本
+ (NSAttributedString *)nickLabelAttributedStringWithUser:(PLVChatUser *)user {
    if (!user.userName || ![user.userName isKindOfClass:[NSString class]] || user.userName.length == 0) {
        return nil;
    }
    
    NSString *content = user.userName;
    if (user.actor && [user.actor isKindOfClass:[NSString class]] && user.actor.length > 0) {
        content = [NSString stringWithFormat:@"%@-%@", user.actor, user.userName];
    }

    NSString *colorHexString = [user isUserSpecial] ? @"#78A7ED" : @"#ADADC0";
    NSDictionary *attributeDict = @{
                                    NSFontAttributeName: [UIFont systemFontOfSize:14.0],
                                    NSForegroundColorAttributeName:[PLVColorUtil colorFromHexString:colorHexString]
    };
    NSAttributedString *string = [[NSAttributedString alloc] initWithString:content attributes:attributeDict];
    return string;
}

/// 获取消息多属性文本
- (void)setContentTextViewWithContent:(NSString *)content {
    NSMutableParagraphStyle *paragraph = [[NSMutableParagraphStyle alloc] init];
    paragraph.minimumLineHeight = 24.0;
    paragraph.paragraphSpacing = 20.0;
    
    NSDictionary *attributeDict = @{
                                    NSFontAttributeName:            [UIFont systemFontOfSize:16.0],
                                    NSForegroundColorAttributeName: [PLVColorUtil colorFromHexString:@"#333333"],
                                    NSParagraphStyleAttributeName:  paragraph
    };
    NSAttributedString *string = [[NSAttributedString alloc] initWithString:content attributes:attributeDict];
    //云课堂小表情显示需要变大 用font 22；
    NSMutableAttributedString *attributedString = [[PLVEmoticonManager sharedManager] converEmoticonTextToEmotionFormatText:string
                                                                                                                       font:[UIFont systemFontOfSize:22.0]];
    
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
        _titleLable.textAlignment = NSTextAlignmentCenter;
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

- (UIImageView *)avatarImageView {
    if (!_avatarImageView) {
        _avatarImageView = [[UIImageView alloc] init];
        _avatarImageView.layer.masksToBounds = YES;
        _avatarImageView.layer.cornerRadius = 16.0;
        _avatarImageView.layer.borderWidth = 0.5;
        _avatarImageView.layer.borderColor = [PLVColorUtil colorFromHexString:@"#E1E1E1"].CGColor;
    }
    return _avatarImageView;
}

- (UILabel *)nickNameLabel {
    if (!_nickNameLabel) {
        _nickNameLabel = [[UILabel alloc] init];
    }
    return _nickNameLabel;
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

- (UIButton *)copButton {
    if (!_copButton) {
        _copButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_copButton addTarget:self action:@selector(copButtonAction) forControlEvents:UIControlEventTouchUpInside];
        [_copButton setTitle:@"复制" forState:UIControlStateNormal];
        _copButton.titleLabel.font = [UIFont systemFontOfSize:14];
        [_copButton setTitleColor:[PLVColorUtil colorFromHexString:@"#333333"] forState:UIControlStateNormal];
        _copButton.layer.masksToBounds = YES;
        _copButton.layer.cornerRadius = 16.0;
        _copButton.layer.borderWidth = 1;
        _copButton.layer.borderColor = [PLVColorUtil colorFromHexString:@"#EDEDEF"].CGColor;
    }
    return _copButton;
}

#pragma mark - [ Event ]

#pragma mark Action

- (void)tapGestureAction {
    [self hideWithAnimation:YES];
}

- (void)closeButtonAction {
    [self hideWithAnimation:YES];
    
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(messagePopupViewWillClose:)]) {
        [self.delegate messagePopupViewWillClose:self];
    }
}

- (void)copButtonAction {
    [self hideWithAnimation:YES];
    
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(messagePopupViewWillCopy:)]) {
        [self.delegate messagePopupViewWillCopy:self];
    }
}

#pragma mark Notification

- (void)interfaceOrientationDidChange:(NSNotification *)notification {
    [self hideWithAnimation:NO];
}

@end
