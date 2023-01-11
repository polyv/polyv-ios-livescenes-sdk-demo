//
//  PLVECLongContentChatCellTableViewCell.m
//  PolyvLiveScenesDemo
//
//  Created by MissYasiky on 2022/11/17.
//  Copyright © 2022 PLV. All rights reserved.
//

#import "PLVECLongContentChatCell.h"
#import "PLVChatModel.h"
#import "PLVChatUser.h"
#import "PLVEmoticonManager.h"
#import "PLVECUtils.h"
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>
#import <PLVFoundationSDK/PLVFoundationSDK.h>

static CGFloat kMaxFoldedContentHeight = 108.0;
static CGFloat kButtonoHeight = 32.0;

@interface PLVECLongContentChatCell ()

#pragma mark 数据
@property (nonatomic, strong) PLVChatModel *model;
@property (nonatomic, assign) CGFloat cellWidth;

#pragma mark UI
@property (nonatomic, strong) UIView *bubbleView;
@property (nonatomic, strong) UILabel *chatLabel;
@property (nonatomic, strong) UIView *contentSepLine; /// 文本和按钮之间的分隔线
@property (nonatomic, strong) UIView *buttonSepLine; /// 两个按钮中间的分隔线
@property (nonatomic, strong) UIButton *copButton;
@property (nonatomic, strong) UIButton *foldButton;

@end

@implementation PLVECLongContentChatCell

#pragma mark - [ Life Cycle ]

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        
        [self.contentView addSubview:self.bubbleView];
        [self.contentView addSubview:self.chatLabel];
        [self.contentView addSubview:self.contentSepLine];
        [self.contentView addSubview:self.buttonSepLine];
        [self.contentView addSubview:self.copButton];
        [self.contentView addSubview:self.foldButton];
    }
    return self;
}

- (void)layoutSubviews {
    if (!self.model || self.cellWidth == 0) {
        return;
    }
    
    // 设置内容文本frame
    CGFloat labelOriginX = 8.0;
    CGFloat labelMaxWidth = self.cellWidth - labelOriginX * 2;
    CGSize labelStringSize = [self.chatLabel.attributedText boundingRectWithSize:CGSizeMake(labelMaxWidth, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading context:nil].size;
    CGFloat chatLabelHeight = MIN(ceil(labelStringSize.height), kMaxFoldedContentHeight) + 8;
    self.chatLabel.frame = CGRectMake(labelOriginX, 4, labelStringSize.width, chatLabelHeight);
    
    CGFloat bubbleWidth = CGRectGetWidth(self.chatLabel.frame) + labelOriginX * 2;
    self.bubbleView.frame = CGRectMake(0, 0, bubbleWidth, CGRectGetHeight(self.chatLabel.frame) + 4 * 2 + kButtonoHeight);
    
    // 横的分割线跟气泡左右间隔11pt
    self.contentSepLine.frame = CGRectMake(CGRectGetMinX(self.bubbleView.frame) + 11, CGRectGetMaxY(self.chatLabel.frame) + 3, CGRectGetWidth(self.bubbleView.frame) - 11 * 2, 1);
    self.buttonSepLine.frame = CGRectMake(CGRectGetMinX(self.bubbleView.frame) + CGRectGetWidth(self.bubbleView.frame) / 2.0 - 0.5, CGRectGetMaxY(self.contentSepLine.frame) + 10.5, 1, 15);
    
    CGSize buttonSize = CGSizeMake(CGRectGetWidth(self.bubbleView.frame)/ 2.0, kButtonoHeight);
    self.copButton.frame = CGRectMake(CGRectGetMinX(self.bubbleView.frame), CGRectGetMaxY(self.bubbleView.frame) - buttonSize.height, buttonSize.width, buttonSize.height);
    self.foldButton.frame = CGRectMake(CGRectGetMaxX(self.copButton.frame), CGRectGetMinY(self.copButton.frame), buttonSize.width, buttonSize.height);
}

#pragma mark - [ Public Method ]

- (void)updateWithModel:(PLVChatModel *)model cellWidth:(CGFloat)cellWidth {
    if (![PLVECLongContentChatCell isModelValid:model] || cellWidth == 0) {
        self.cellWidth = 0;
        return;
    }
    
    self.cellWidth = cellWidth;
    self.model = model;
    
    NSAttributedString *chatLabelString = [PLVECLongContentChatCell chatLabelAttributedStringWithWithModel:model];
    self.chatLabel.attributedText = chatLabelString;
}

+ (CGFloat)cellHeightWithModel:(PLVChatModel *)model cellWidth:(CGFloat)cellWidth {
    if (![PLVECLongContentChatCell isModelValid:model] || cellWidth == 0) {
        return 0;
    }
    
    // 内容文本高度
    NSAttributedString *chatLabelString = [PLVECLongContentChatCell chatLabelAttributedStringWithWithModel:model];
    
    CGFloat labelOriginX = 8.0;
    CGFloat labelMaxWidth = cellWidth - labelOriginX * 2;
    CGSize labelStringSize = [chatLabelString boundingRectWithSize:CGSizeMake(labelMaxWidth, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading context:nil].size;
    CGFloat chatLabelHeight = MIN(ceil(labelStringSize.height), kMaxFoldedContentHeight) + 8;
    
    CGFloat bubbleHeight = 4 + chatLabelHeight + 4 + kButtonoHeight;
    return bubbleHeight + 4;
}

+ (BOOL)isModelValid:(PLVChatModel *)model {
    if (!model || ![model isKindOfClass:[PLVChatModel class]]) {
        return NO;
    }
    
    id message = model.message;
    if (message &&
        ([message isKindOfClass:[PLVSpeakMessage class]] || [message isKindOfClass:[PLVQuoteMessage class]])) {
        return model.contentLength > PLVChatMsgContentLength_0To500;
    } else {
        return NO;
    }
}

#pragma mark - [ Private Method ]

+ (NSAttributedString *)chatLabelAttributedStringWithWithModel:(PLVChatModel *)model {
    NSAttributedString *actorAttributedString = [PLVECLongContentChatCell actorAttributedStringWithUser:model.user];
    NSAttributedString *nickNameAttributedString = [PLVECLongContentChatCell nickNameAttributedStringWithUser:model.user];
    NSAttributedString *contentAttributedString = [PLVECLongContentChatCell contentAttributedStringWithContent:model.content];
    
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
    return [mutableAttributedString copy];
}

/// 获取头衔
+ (NSAttributedString *)actorAttributedStringWithUser:(PLVChatUser *)user {
    if (!user.specialIdentity ||
        !user.actor || ![user.actor isKindOfClass:[NSString class]] || user.actor.length == 0) {
        return nil;
    }
    
    CGFloat scale = [UIScreen mainScreen].scale;
    CGFloat actorFontSize = 10.0;
    
    // 设置昵称label
    UILabel *actorLabel = [[UILabel alloc] init];
    actorLabel.text = user.actor;
    actorLabel.font = [UIFont systemFontOfSize:actorFontSize * scale];
    actorLabel.backgroundColor = [PLVECLongContentChatCell actorLabelBackground:user];
    actorLabel.textColor = [UIColor whiteColor];
    actorLabel.textAlignment = NSTextAlignmentCenter;
    
    CGRect actorContentRect = [user.actor boundingRectWithSize:CGSizeMake(MAXFLOAT, 12) options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:actorFontSize]} context:nil];
    CGSize actorLabelSize = CGSizeMake(actorContentRect.size.width + 12.0, 12);
    actorLabel.frame = CGRectMake(0, 0, actorLabelSize.width * scale, actorLabelSize.height * scale);
    actorLabel.layer.cornerRadius = 6.0 * scale;
    actorLabel.layer.masksToBounds = YES;
    
    // 将昵称label再转换为NSAttributedString对象
    UIImage *actorImage = [PLVECLongContentChatCell imageFromUIView:actorLabel];
    NSTextAttachment *labelAttach = [[NSTextAttachment alloc] init];
    labelAttach.bounds = CGRectMake(0, -1.5, actorLabelSize.width, actorLabelSize.height);
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
    
    NSString *content = [NSString stringWithFormat:@"%@：",user.userName];
    NSDictionary *attributeDict = @{
                                    NSFontAttributeName: [UIFont systemFontOfSize:12.0],
                                    NSForegroundColorAttributeName:[PLVColorUtil colorFromHexString:@"#FFD16B"]
    };
    NSAttributedString *string = [[NSAttributedString alloc] initWithString:content attributes:attributeDict];
    return string;
}

/// 获取聊天文本
+ (NSAttributedString *)contentAttributedStringWithContent:(NSString *)content {
    NSDictionary *attributeDict = @{
                                    NSFontAttributeName: [UIFont systemFontOfSize:12.0],
                                    NSForegroundColorAttributeName:[UIColor whiteColor]
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

/// 将头衔文本转换成图片
+ (UIImage *)imageFromUIView:(UIView *)view {
    UIGraphicsBeginImageContext(view.bounds.size);
    CGContextRef ctxRef = UIGraphicsGetCurrentContext();
    [view.layer renderInContext:ctxRef];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

#pragma mark Getter

- (UIView *)bubbleView {
    if (!_bubbleView) {
        _bubbleView = [[UIView alloc] init];
        _bubbleView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.39];
        _bubbleView.layer.cornerRadius = 10;
        _bubbleView.layer.masksToBounds = YES;
    }
    return _bubbleView;
}

- (UILabel *)chatLabel {
    if (!_chatLabel) {
        _chatLabel = [[UILabel alloc] init];
        _chatLabel.numberOfLines = 0;
        _chatLabel.textAlignment = NSTextAlignmentLeft;
    }
    return _chatLabel;
}

- (UIView *)contentSepLine {
    if (!_contentSepLine) {
        _contentSepLine = [[UIView alloc] init];
        _contentSepLine.backgroundColor = [PLVColorUtil colorFromHexString:@"#D8D8D8" alpha:0.3];
    }
    return _contentSepLine;
}

- (UIView *)buttonSepLine {
    if (!_buttonSepLine) {
        _buttonSepLine = [[UIView alloc] init];
        _buttonSepLine.backgroundColor = [PLVColorUtil colorFromHexString:@"#D8D8D8" alpha:0.3];
    }
    return _buttonSepLine;
}

- (UIButton *)copButton {
    if (!_copButton) {
        _copButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_copButton setTitle:@"复制" forState:UIControlStateNormal];
        _copButton.titleLabel.font = [UIFont systemFontOfSize:12.0];
        [_copButton setTitleColor:[PLVColorUtil colorFromHexString:@"#FFFEFC" alpha:0.8] forState:UIControlStateNormal];
        [_copButton setTitleColor:[PLVColorUtil colorFromHexString:@"#FFFEFC"] forState:UIControlStateHighlighted];
        [_copButton addTarget:self action:@selector(copButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _copButton;
}

- (UIButton *)foldButton {
    if (!_foldButton) {
        _foldButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_foldButton setTitle:@"更多" forState:UIControlStateNormal];
        _foldButton.titleLabel.font = [UIFont systemFontOfSize:12.0];
        [_foldButton setTitleColor:[PLVColorUtil colorFromHexString:@"#FFFEFC" alpha:0.8] forState:UIControlStateNormal];
        [_foldButton setTitleColor:[PLVColorUtil colorFromHexString:@"#FFFEFC"] forState:UIControlStateHighlighted];
        [_foldButton addTarget:self action:@selector(foldButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _foldButton;
}

#pragma mark - [ Event ]

#pragma mark Action

- (void)copButtonAction {
    if (self.copButtonHandler) {
        self.copButtonHandler();
    }
}

- (void)foldButtonAction {
    if (self.foldButtonHandler) {
        self.foldButtonHandler();
    }
}

@end
