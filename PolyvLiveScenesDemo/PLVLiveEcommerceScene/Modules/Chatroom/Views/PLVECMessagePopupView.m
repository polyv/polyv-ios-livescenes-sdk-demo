//
//  PLVECMessagePopupView.m
//  PolyvLiveScenesDemo
//
//  Created by MissYasiky on 2022/11/16.
//  Copyright © 2022 PLV. All rights reserved.
//

#import "PLVECMessagePopupView.h"
#import "PLVEmoticonManager.h"
#import "PLVECUtils.h"
#import "PLVMultiLanguageManager.h"
#import "PLVRoomDataManager.h"
#import <PLVFoundationSDK/PLVFoundationSDK.h>

static CGFloat kMaxContainerHeightScale = 0.64; // 弹窗最大高度为屏幕高度的0.64倍
static NSString *kChatAdminLinkTextColor = @"#0092FA";
static NSString *kFilterRegularExpression = @"((http[s]{0,1}://)?[a-zA-Z0-9\\.\\-]+\\.([a-zA-Z]{2,4})(:\\d+)?(/[a-zA-Z0-9\\.\\-~!@#$%^&*+?:_/=<>]*)?)|(www.[a-zA-Z0-9\\.\\-]+\\.([a-zA-Z]{2,4})(:\\d+)?(/[a-zA-Z0-9\\.\\-~!@#$%^&*+?:_/=<>]*)?)";

@interface PLVECMessagePopupView ()

#pragma mark 数据
@property (nonatomic, strong) PLVChatModel *model;
@property (nonatomic, assign) CGFloat containerHeight;
@property (nonatomic, assign) BOOL showAll; // 内容能一屏显示完全，不需要滚动

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

@implementation PLVECMessagePopupView

#pragma mark - [ Life Cycle ]

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.bgView.frame = self.bounds;
    
    CGFloat containerWidth = self.containerView.bounds.size.width;
    CGFloat xPadding = 26.0; // 内容文本跟屏幕左右的间隙
    CGFloat contentOriginY = 70.0;
    CGFloat buttonTopPad = 10.0;
    CGFloat buttonHeight = 32.0;
    CGFloat buttonBottom = P_SafeAreaBottomEdgeInsets() > 0 ? P_SafeAreaBottomEdgeInsets() : 10;
    
    UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:self.containerView.bounds byRoundingCorners:UIRectCornerTopLeft | UIRectCornerTopRight cornerRadii:CGSizeMake(8,8)];
    CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
    maskLayer.frame = self.containerView.bounds;
    maskLayer.path = maskPath.CGPath;
    self.containerView.layer.mask = maskLayer;
    
    self.titleLable.frame = CGRectMake(19, 0, 250, 50);
    self.closeButton.frame = CGRectMake(containerWidth - 48 - 6, 2.5, 48, 48);
    self.sepLine.frame = CGRectMake(0, 50, containerWidth, 1);
    
    CGFloat copButtonOriginY = self.containerHeight - buttonHeight - buttonBottom;
    self.copButton.frame = CGRectMake((containerWidth - 120) / 2.0, copButtonOriginY, 120, buttonHeight);
    
    self.contentTextView.frame = CGRectMake(xPadding, contentOriginY, containerWidth - xPadding * 2, copButtonOriginY - contentOriginY - buttonTopPad);
    self.gradientLayer.frame = self.contentTextView.frame;
}

- (void)dealloc {
    _delegate = nil;
}

#pragma mark - [ Public Method ]

- (instancetype)initWithChatModel:(PLVChatModel *)model {
    self = [super init];
    if (self) {
        self.model = model;
        
        [self setupUI];
    }
    return self;
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
    [self.containerView addSubview:self.contentTextView];
    [self.containerView addSubview:self.copButton];
    
    [self.containerView.layer addSublayer:self.gradientLayer];
    
    if (!self.model ||
        ![self.model isKindOfClass:[PLVChatModel class]] ) {
        return;
    }
    
    NSMutableAttributedString *attributedString = [self chatLabelAttributedString];
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
    
    {// 这部分layoutSubviews方法里面布局时可复用
        CGFloat xPadding = 26.0; // 内容文本跟屏幕左右的间隙
        CGFloat maxContentTextViewWidth = PLVScreenWidth - 2 * xPadding; // 内容文本宽度
        CGSize contentLabelSize = [attributedString boundingRectWithSize:CGSizeMake(maxContentTextViewWidth, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:nil].size;
        CGFloat contentHeight = ceil(contentLabelSize.height) + 6; // 内容文本实际高度，实际需要空间会比计算出来的多几像素，所以加上8
        
        CGFloat contentOriginY = 70.0;
        CGFloat buttonTopPad = 10.0;
        CGFloat buttonHeight = 32.0;
        CGFloat buttonBottom = P_SafeAreaBottomEdgeInsets() > 0 ? P_SafeAreaBottomEdgeInsets() : 10;
        CGFloat caculateContainerHeight = contentOriginY + contentHeight + buttonTopPad + buttonHeight + buttonBottom;
        self.containerHeight = MIN(caculateContainerHeight, kMaxContainerHeightScale * PLVScreenHeight);
        self.showAll = (self.containerHeight == caculateContainerHeight);
        self.gradientLayer.hidden = self.showAll;
    }
}

- (NSMutableAttributedString *)chatLabelAttributedString {
    NSAttributedString *actorAttributedString = [PLVECMessagePopupView actorAttributedStringWithUser:self.model.user];
    NSAttributedString *nickNameAttributedString = [PLVECMessagePopupView nickNameAttributedStringWithUser:self.model.user];
    NSAttributedString *contentAttributedString = [PLVECMessagePopupView contentAttributedStringWithContent:self.content];
    
    NSMutableAttributedString *mutableAttributedString = [[NSMutableAttributedString alloc] init];
    if (actorAttributedString) {
        [mutableAttributedString appendAttributedString:actorAttributedString];
    }
    if (nickNameAttributedString) {
        [mutableAttributedString appendAttributedString:nickNameAttributedString];
    }
    if (contentAttributedString) {
        [mutableAttributedString appendAttributedString:contentAttributedString];
    }
    
    NSMutableParagraphStyle *paragraph = [[NSMutableParagraphStyle alloc] init];
    paragraph.minimumLineHeight = 24.0;
    paragraph.paragraphSpacing = 20.0;
    [mutableAttributedString addAttribute:NSParagraphStyleAttributeName value:paragraph range:NSMakeRange(0, mutableAttributedString.length - 1)];
    
    return mutableAttributedString;
}

/// 获取头衔
+ (NSAttributedString *)actorAttributedStringWithUser:(PLVChatUser *)user {
    if (!user.specialIdentity ||
        !user.actor || ![user.actor isKindOfClass:[NSString class]] || user.actor.length == 0) {
        return nil;
    }
    
    CGFloat scale = [UIScreen mainScreen].scale;
    CGFloat actorFontSize = 12.0;
    
    // 设置昵称label
    UILabel *actorLabel = [[UILabel alloc] init];
    actorLabel.text = user.actor;
    actorLabel.font = [UIFont systemFontOfSize:actorFontSize * scale];
    actorLabel.backgroundColor = [PLVECMessagePopupView actorLabelBackground:user];
    actorLabel.textColor = [UIColor whiteColor];
    actorLabel.textAlignment = NSTextAlignmentCenter;
    
    CGRect actorContentRect = [user.actor boundingRectWithSize:CGSizeMake(MAXFLOAT, 18) options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:actorFontSize]} context:nil];
    CGSize actorLabelSize = CGSizeMake(actorContentRect.size.width + 12.0, 18);
    actorLabel.frame = CGRectMake(0, 0, actorLabelSize.width * scale, actorLabelSize.height * scale);
    actorLabel.layer.cornerRadius = 9.0 * scale;
    actorLabel.layer.masksToBounds = YES;
    
    // 将昵称label再转换为NSAttributedString对象
    UIImage *actorImage = [PLVImageUtil imageFromUIView:actorLabel];
    NSTextAttachment *labelAttach = [[NSTextAttachment alloc] init];
    labelAttach.bounds = CGRectMake(0, -3, actorLabelSize.width, actorLabelSize.height);
    labelAttach.image = actorImage;
    NSAttributedString *actorAttributedString = [NSAttributedString attributedStringWithAttachment:labelAttach];
    
    NSMutableAttributedString *mutableString = [[NSMutableAttributedString alloc] init];
    [mutableString appendAttributedString:actorAttributedString];
    
    NSAttributedString *emptyAttributedString = [[NSAttributedString alloc] initWithString:@" "
                                                                                attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:actorFontSize]}];
    [mutableString appendAttributedString:emptyAttributedString];
    
    return [mutableString copy];
}

/// 获取昵称
+ (NSAttributedString *)nickNameAttributedStringWithUser:(PLVChatUser *)user {
    if (!user.userName || ![user.userName isKindOfClass:[NSString class]] || user.userName.length == 0) {
        return nil;
    }
    
    NSString *content = [NSString stringWithFormat:@"%@：",[user getDisplayNickname:[PLVRoomDataManager sharedManager].roomData.menuInfo.hideViewerNicknameEnabled loginUserId:[PLVRoomDataManager sharedManager].roomData.roomUser.viewerId]];
    NSDictionary *attributeDict = @{
                                    NSFontAttributeName: [UIFont systemFontOfSize:14.0],
                                    NSForegroundColorAttributeName:[PLVColorUtil colorFromHexString:@"#FFD16B"]
    };
    NSAttributedString *string = [[NSAttributedString alloc] initWithString:content attributes:attributeDict];
    return string;
}

/// 获取聊天文本
+ (NSAttributedString *)contentAttributedStringWithContent:(NSString *)content {
    NSDictionary *attributeDict = @{
                                    NSFontAttributeName: [UIFont systemFontOfSize:14.0],
                                    NSForegroundColorAttributeName:[PLVColorUtil colorFromHexString:@"#333333"]
    };
    NSMutableAttributedString *emotionAttrStr = [[PLVEmoticonManager sharedManager] converEmoticonTextToEmotionFormatText:content attributes:attributeDict];
    return [emotionAttrStr copy];
}

/// 获取头衔label文本背景色
+ (UIColor *)actorLabelBackground:(PLVChatUser *)user {
    UIColor *backgroundColor = [UIColor clearColor];
    if (user.userType == PLVRoomUserTypeGuest) {
        backgroundColor = [PLVColorUtil colorFromHexString:@"#EB6165"];
    } else if (user.userType == PLVRoomUserTypeTeacher) {
        backgroundColor = [PLVColorUtil colorFromHexString:@"#289343"];
    } else if (user.userType == PLVRoomUserTypeAssistant) {
        backgroundColor = [PLVColorUtil colorFromHexString:@"#598FE5"];
    } else if (user.userType == PLVRoomUserTypeManager) {
        backgroundColor = [PLVColorUtil colorFromHexString:@"#33BBC5"];
    }
    return backgroundColor;
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
        _titleLable.text = PLVLocalizedString(@"全文");
    }
    return _titleLable;
}

- (UIButton *)closeButton {
    if (!_closeButton) {
        _closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_closeButton addTarget:self action:@selector(closeButtonAction) forControlEvents:UIControlEventTouchUpInside];
        UIImage *image = [PLVECUtils imageForWatchResource:@"plvec_chatroom_popup_close"];
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
        [_copButton setTitle:PLVLocalizedString(@"复制") forState:UIControlStateNormal];
        _copButton.titleLabel.font = [UIFont systemFontOfSize:14];
        [_copButton setTitleColor:[PLVColorUtil colorFromHexString:@"#333333"] forState:UIControlStateNormal];
        _copButton.layer.masksToBounds = YES;
        _copButton.layer.cornerRadius = 16.0;
        _copButton.layer.borderWidth = 1;
        _copButton.layer.borderColor = [PLVColorUtil colorFromHexString:@"#E1E1E1"].CGColor;
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

@end
