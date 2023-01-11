//
//  PLVSALongContentMessageSheet.m
//  PolyvLiveScenesDemo
//
//  Created by MissYasiky on 2022/11/22.
//  Copyright © 2022 PLV. All rights reserved.
//

#import "PLVSALongContentMessageSheet.h"
#import "PLVEmoticonManager.h"
#import "PLVSAUtils.h"
#import "PLVToast.h"

static CGFloat kMaxHeightScale = 0.72; // 竖屏时，弹窗最大高度为屏幕高度的0.72倍
static CGFloat kMaxLanscapeHeightScale = 0.46; // 横屏时，弹窗最大高度为屏幕高度的0.72倍
static NSString *kChatAdminLinkTextColor = @"#0092FA";
static NSString *kFilterRegularExpression = @"((http[s]{0,1}://)?[a-zA-Z0-9\\.\\-]+\\.([a-zA-Z]{2,4})(:\\d+)?(/[a-zA-Z0-9\\.\\-~!@#$%^&*+?:_/=<>]*)?)|(www.[a-zA-Z0-9\\.\\-]+\\.([a-zA-Z]{2,4})(:\\d+)?(/[a-zA-Z0-9\\.\\-~!@#$%^&*+?:_/=<>]*)?)";

@interface PLVSALongContentMessageSheet ()

#pragma mark 数据
@property (nonatomic, strong) PLVChatModel *model;
@property (nonatomic, copy, readonly) NSString *content; // 弹窗文本

#pragma mark UI
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UITextView *contentTextView;
@property (nonatomic, strong) UIButton *copButton;

@end

@implementation PLVSALongContentMessageSheet

#pragma mark - [ Life Cycle ]

- (instancetype)initWithChatModel:(PLVChatModel *)model {
    CGFloat screenHeight = MAX(PLVScreenHeight, PLVScreenWidth);
    self = [super initWithSheetHeight:kMaxHeightScale * screenHeight sheetLandscapeWidth:kMaxLanscapeHeightScale * screenHeight];
    if (self) {
        self.model = model;
       
        [self setupUI];
    }
    return self;
}

#pragma mark - [ Override ]

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat screenWidth = MIN(PLVScreenHeight, PLVScreenWidth);
    CGFloat contentViewWidth = self.contentView.bounds.size.width;
    CGFloat contentViewHeight = self.contentView.bounds.size.height;
    
    CGFloat titleLabelLeft = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad ? 56 : 32;
    self.titleLabel.frame = CGRectMake(titleLabelLeft, 32, contentViewWidth - titleLabelLeft * 2, 20);
    
    CGFloat buttonTopPad = 16.0;
    CGFloat buttonHeight = 28.0;
    CGFloat buttonBottom = P_SafeAreaBottomEdgeInsets() > 0 ? P_SafeAreaBottomEdgeInsets() : 10;
    CGFloat buttonOriginY = contentViewHeight - buttonHeight - buttonBottom;
    self.copButton.frame = CGRectMake((contentViewWidth - 88) / 2.0, buttonOriginY, 88, buttonHeight);
    
    CGFloat xPadding = 24.0; // 内容文本跟屏幕左右的间隙
    CGFloat contentTextViewOriginY = CGRectGetMaxY(self.titleLabel.frame) + 26; // titleLabel与contentTextView上下距离为26pt
    CGFloat contentTextViewWidth = screenWidth - 2 * xPadding; // 内容文本宽度
    CGFloat contenttextViewHeight = CGRectGetMinY(self.copButton.frame) - contentTextViewOriginY - buttonTopPad;
    self.contentTextView.frame = CGRectMake(xPadding, contentTextViewOriginY, contentTextViewWidth, contenttextViewHeight);
}

#pragma mark - [ Private Method ]

- (void)setupUI {
    [self.contentView addSubview:self.titleLabel];
    [self.contentView addSubview:self.contentTextView];
    [self.contentView addSubview:self.copButton];
    
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
    self.contentTextView.attributedText = [attributedString copy];
    
    if (![PLVSAUtils sharedUtils].isLandscape ||
        !self.superLandscape) { // 竖屏布局时
        CGFloat screenHeight = MAX(PLVScreenHeight, PLVScreenWidth);
        CGFloat screenWidth = MIN(PLVScreenHeight, PLVScreenWidth);
        CGFloat xPadding = 24.0; // 内容文本跟屏幕左右的间隙
        CGFloat contentTextViewWidth = screenWidth - 2 * xPadding; // 内容文本宽度

        CGSize contentLabelSize = [self.contentTextView.attributedText boundingRectWithSize:CGSizeMake(contentTextViewWidth, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:nil].size;
        CGFloat contentHeight = ceil(contentLabelSize.height) + 6; // 内容文本实际高度，实际需要空间会比计算出来的多几像素，所以加上8
        
        CGFloat contentOriginY = 32 + 20 + 26;
        CGFloat buttonTopPad = 16.0;
        CGFloat buttonHeight = 28.0;
        CGFloat buttonBottom = P_SafeAreaBottomEdgeInsets() > 0 ? P_SafeAreaBottomEdgeInsets() : 10;
        CGFloat caculateContainerHeight = contentOriginY + contentHeight + buttonTopPad + buttonHeight + buttonBottom;
        self.sheetHight = MIN(caculateContainerHeight, kMaxHeightScale * screenHeight);
    }
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
    
    NSString *content = [NSString stringWithFormat:@"%@：", user.userName];
    NSAttributedString *nickNameString = [[NSAttributedString alloc] initWithString:content attributes:nickNameAttDict];
    NSAttributedString *conentString = [[NSAttributedString alloc] initWithString:self.content attributes:contentAttDict];
    NSMutableAttributedString *emojiContentString = [[PLVEmoticonManager sharedManager] converEmoticonTextToEmotionFormatText:conentString font:font];
    
    NSMutableAttributedString *contentLabelString = [[NSMutableAttributedString alloc] init];
    [contentLabelString appendAttributedString:nickNameString];
    [contentLabelString appendAttributedString:[emojiContentString copy]];
    
    // 特殊身份头衔
    if (user.actor &&
        [user.actor isKindOfClass:[NSString class]] &&
        user.actor.length > 0 &&
        [PLVSALongContentMessageSheet showActorLabelWithUser:user]) {
        UIImage *image = [PLVSALongContentMessageSheet actorImageWithUser:user];
        //创建Image的富文本格式
        NSTextAttachment *attach = [[NSTextAttachment alloc] init];
        CGFloat paddingTop = font.lineHeight - font.pointSize;
        attach.bounds = CGRectMake(0, -ceilf(paddingTop), image.size.width, image.size.height);
        attach.image = image;
        //添加到富文本对象里
        NSAttributedString * imageStr = [NSAttributedString attributedStringWithAttachment:attach];
        [contentLabelString insertAttributedString:[[NSAttributedString alloc] initWithString:@" "] atIndex:0];
        [contentLabelString insertAttributedString:imageStr atIndex:0];
    }
    
    NSMutableParagraphStyle *paragraph = [[NSMutableParagraphStyle alloc] init];
    paragraph.minimumLineHeight = 24.0;
    paragraph.paragraphSpacing = 20.0;
    [contentLabelString addAttribute:NSParagraphStyleAttributeName value:paragraph range:NSMakeRange(0, contentLabelString.length - 1)];
    
    return contentLabelString;
}

+ (NSString *)actorBgColorHexStringWithUserType:(PLVRoomUserType)userType {
    NSString *colorHexString = nil;
    switch (userType) {
        case PLVRoomUserTypeGuest:
            colorHexString = @"#EB6165";
            break;
        case PLVRoomUserTypeTeacher:
            colorHexString = @"#F09343";
            break;
        case PLVRoomUserTypeAssistant:
            colorHexString = @"#598FE5";
            break;
        case PLVRoomUserTypeManager:
            colorHexString = @"#33BBC5";
            break;
        default:
            break;
    }
    return colorHexString;
}

+ (BOOL)showActorLabelWithUser:(PLVChatUser *)user {
    return (user.userType == PLVRoomUserTypeGuest ||
            user.userType == PLVRoomUserTypeTeacher ||
            user.userType == PLVRoomUserTypeAssistant ||
            user.userType == PLVRoomUserTypeManager);
}

+ (UIImage*)actorImageWithUser:(PLVChatUser *)user; {
    UILabel *label = [[UILabel alloc] init];
    label.font = [UIFont systemFontOfSize:12];
    label.textColor = [UIColor whiteColor];
    label.textAlignment = NSTextAlignmentCenter;
    label.layer.cornerRadius = 7;
    label.layer.masksToBounds = YES;
    label.text = user.actor;
    
    NSString *backgroundColor = [self actorBgColorHexStringWithUserType:user.userType];
    if (backgroundColor) {
        label.backgroundColor = [PLVColorUtil colorFromHexString:backgroundColor];
    }
    NSString *actor = user.actor;
    CGSize size;
    if (actor &&
        [actor isKindOfClass:[NSString class]] &&
        actor.length >0) {
        NSAttributedString *attr = [[NSAttributedString alloc] initWithString:actor attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:12]}];
        size = [attr boundingRectWithSize:CGSizeMake(100, 14) options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading context:nil].size;
        size.width += 10;
    }
    label.frame = CGRectMake(0, 0, size.width, 14);
    UIGraphicsBeginImageContextWithOptions(label.frame.size, NO, [UIScreen mainScreen].scale);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    [label.layer renderInContext:ctx];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
   
    return image;
}
/// 获得字符串中 https、http 链接所在位置，并将这些结果放入数组中返回
- (NSArray *)linkRangesWithContent:(NSString *)content {
    NSRegularExpression *regex = [[NSRegularExpression alloc] initWithPattern:kFilterRegularExpression options:0 error:nil];
    return [regex matchesInString:content options:0 range:NSMakeRange(0, content.length)];
}

#pragma mark Getter & Setter

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
        _titleLabel.font = [UIFont systemFontOfSize:18];
        _titleLabel.textColor = PLV_UIColorFromRGB(@"#F0F1F5");
        _titleLabel.text = @"全文";
    }
    return _titleLabel;
}

- (UIButton *)copButton {
    if (!_copButton) {
        _copButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_copButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _copButton.titleLabel.font = [UIFont systemFontOfSize:12];
        _copButton.backgroundColor = [UIColor colorWithRed:0/255.0 green:128/255.0 blue:255/255.0 alpha:1/1.0];
        _copButton.layer.cornerRadius = 14;
        [_copButton setTitle:@"复制" forState:UIControlStateNormal];
        [_copButton addTarget:self action:@selector(copButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _copButton;
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

#pragma mark - [ Event ]

#pragma mark Action

- (void)copButtonAction {
    if (self.content && self.content.length > 0) {
        [UIPasteboard generalPasteboard].string = self.content;
        [PLVToast showToastWithMessage:@"复制成功" inView:[PLVSAUtils sharedUtils].homeVC.view afterDelay:3.0];
    }
}

@end
