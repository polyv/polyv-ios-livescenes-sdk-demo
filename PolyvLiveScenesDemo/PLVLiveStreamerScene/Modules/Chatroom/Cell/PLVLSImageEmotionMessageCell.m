//
//  PLVLSImageEmotionMessageCell.m
//  PLVLiveScenesDemo
//
//  Created by Sakya on 2021/7/9.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVLSImageEmotionMessageCell.h"
#import "PLVChatModel.h"
#import "PLVPhotoBrowser.h"
#import "PLVLSUtils.h"
#import <PLVLiveScenesSDK/PLVImageMessage.h>
#import <PLVFoundationSDK/PLVColorUtil.h>
#import <SDWebImage/UIImageView+WebCache.h>

@interface PLVLSImageEmotionMessageCell ()

#pragma mark 数据

@property (nonatomic, assign) CGFloat cellWidth; /// cell宽度
@property (nonatomic, strong) NSString *loginUserId; /// 登录用户的聊天室userId

#pragma mark UI
 
@property (nonatomic, strong) UILabel *nickLabel; /// 发出消息用户昵称
@property (nonatomic, strong) UIImageView *chatImageView; /// 聊天消息图片
@property (nonatomic, strong) UIView *bubbleView; /// 背景气泡
@property (nonatomic, strong) PLVPhotoBrowser *photoBrowser; /// 消息图片Browser
@property (nonatomic, strong) UILabel *prohibitImageTipLabel;  /// 严禁词提示

@end

@implementation PLVLSImageEmotionMessageCell

#pragma mark - Life Cycle

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.allowReply = YES;
        
        [self.contentView addSubview:self.bubbleView];
        [self.contentView addSubview:self.nickLabel];
        [self.contentView addSubview:self.chatImageView];
        [self.contentView addSubview:self.prohibitImageTipLabel];
        
        self.photoBrowser = [[PLVPhotoBrowser alloc] init];
    }
    return self;
}

- (void)layoutSubviews {
    if (self.cellWidth == 0) {
        return;
    }
    
    CGFloat originX = 12.0;
    CGFloat originY = 4.0;
    CGFloat bubbleXPadding = 12.0; // 气泡与nickLabel的左右内间距
    
    NSAttributedString *nickAttributeString = self.nickLabel.attributedText;
    CGSize nickLabelSize = [nickAttributeString boundingRectWithSize:CGSizeMake(MAXFLOAT, 16) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:nil].size;
    self.nickLabel.frame = CGRectMake(originX, originY, nickLabelSize.width, 16);
    originY += 16 + 4; // nickLabel跟图片之间距离4
    
    CGSize imageViewSize = [PLVLSImageEmotionMessageCell calculateImageViewSizeWithMessage:self.model.message];
    self.chatImageView.frame = CGRectMake(originX, originY, imageViewSize.width, imageViewSize.height);
    originY += imageViewSize.height + 4;
    
    CGFloat bubbleWidth = MAX(nickLabelSize.width, imageViewSize.width) + bubbleXPadding * 2;
    
    if ([self.model isProhibitMsg]) {
        // 设置为本地图片36*36
        originY = 4 + 16 + 4; // 恢复到昵称下面显示
        self.chatImageView.frame = CGRectMake(originX, originY, 36, 36);
        originY += 36 + 4;
        bubbleWidth = MAX(nickLabelSize.width, 36) + bubbleXPadding * 2;
        
        // 违规提示语
        NSAttributedString *tipAttri = self.prohibitImageTipLabel.attributedText;
        CGSize labelViewSize =  [tipAttri boundingRectWithSize:CGSizeMake(MAXFLOAT, 17) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:nil].size;
        
        self.prohibitImageTipLabel.frame = CGRectMake(originX, CGRectGetMaxY(self.chatImageView.frame) + 4,  labelViewSize.width, labelViewSize.height);
        
        originY += labelViewSize.height + 4;
        bubbleWidth = MAX(bubbleWidth, CGRectGetMaxY(self.prohibitImageTipLabel.frame));
        
    }
    
    self.bubbleView.frame = CGRectMake(0, 0, bubbleWidth, originY);
}

#pragma mark - Getter

- (UIView *)bubbleView {
    if (!_bubbleView) {
        _bubbleView = [[UIView alloc] init];
        _bubbleView.backgroundColor = [UIColor colorWithRed:0x1b/255.0 green:0x20/255.0 blue:0x2d/255.0 alpha:0.4];
        _bubbleView.layer.cornerRadius = 8.0;
        _bubbleView.layer.masksToBounds = YES;
    }
    return _bubbleView;
}

- (UILabel *)nickLabel {
    if (!_nickLabel) {
        _nickLabel = [[UILabel alloc] init];
    }
    return _nickLabel;
}

- (UIImageView *)chatImageView {
    if (!_chatImageView) {
        _chatImageView = [[UIImageView alloc] init];
        _chatImageView.layer.masksToBounds = YES;
        _chatImageView.layer.cornerRadius = 4.0;
        _chatImageView.userInteractionEnabled = YES;
        _chatImageView.contentMode = UIViewContentModeScaleAspectFill;
        
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapImageViewAction)];
        [_chatImageView addGestureRecognizer:tapGesture];
    }
    return _chatImageView;
}

- (UILabel *)prohibitImageTipLabel {
    if(!_prohibitImageTipLabel) {
        _prohibitImageTipLabel = [[UILabel alloc] init];
        _prohibitImageTipLabel.font = [UIFont systemFontOfSize:12];
        _prohibitImageTipLabel.textColor = [UIColor colorWithRed:240/255.0 green:241/255.0 blue:245/255.0 alpha:0.6];
        _prohibitImageTipLabel.hidden = YES;
    }
    return _prohibitImageTipLabel;
}
#pragma mark - UI

- (void)updateWithModel:(PLVChatModel *)model loginUserId:(NSString *)loginUserId cellWidth:(CGFloat)cellWidth {
    if (![PLVLSImageEmotionMessageCell isModelValid:model] || cellWidth == 0) {
        self.cellWidth = 0;
        return;
    }
    
    self.cellWidth = cellWidth;
    self.model = model;
    if (loginUserId && [loginUserId isKindOfClass:[NSString class]] && loginUserId.length > 0) {
        self.loginUserId = loginUserId;
    }
    
    // 设置昵称文本
    NSAttributedString *nickLabelString = [PLVLSImageEmotionMessageCell nickLabelAttributedStringWithUser:model.user
                                                                                         loginUserId:self.loginUserId];
    self.nickLabel.attributedText = nickLabelString;
    
    PLVImageMessage *message = (PLVImageMessage *)model.message;
    NSURL *imageURL = [PLVLSImageEmotionMessageCell imageURLWithMessage:message];
    UIImage *placeHolderImage = [PLVColorUtil createImageWithColor:[PLVColorUtil colorFromHexString:@"#777786"]];
    // 如果是违规图片，设置本地图片，并跳过后续操作
    if ([model isProhibitMsg]) {
        [self.chatImageView setImage:[PLVLSUtils imageForStatusResource:@"plvls_status_signal_error_img_icon"]];
        self.prohibitImageTipLabel.attributedText = [PLVLSImageEmotionMessageCell contentLabelAttributedStringWithProhibitWordTip:[PLVLSImageEmotionMessageCell prohibitWordTip]];
        self.prohibitImageTipLabel.hidden = NO;
        return;
    }
    self.prohibitImageTipLabel.hidden = YES;
    if (imageURL) {
        [self.chatImageView sd_setImageWithURL:imageURL
                              placeholderImage:placeHolderImage
                                       options:SDWebImageRetryFailed];
    } else {
        [self.chatImageView setImage:placeHolderImage];
    }
}

#pragma mark UI - ViewModel

/// 获取昵称多属性文本
+ (NSAttributedString *)nickLabelAttributedStringWithUser:(PLVChatUser *)user
                                              loginUserId:(NSString *)loginUserId {
    if (!user.userName || ![user.userName isKindOfClass:[NSString class]] || user.userName.length == 0) {
        return nil;
    }
    
    NSString *content = user.userName;
    if (user.userId && [user.userId isKindOfClass:[NSString class]] &&
        loginUserId && [loginUserId isKindOfClass:[NSString class]] && [loginUserId isEqualToString:user.userId]) {
        content = [content stringByAppendingString:@"（我）"];
    }
    if (user.actor && [user.actor isKindOfClass:[NSString class]] && user.actor.length > 0) {
        content = [NSString stringWithFormat:@"%@-%@", user.actor, content];
    }
    content = [content stringByAppendingString:@"："];
    
    NSString *colorHexString = [user isUserSpecial] ? @"#FFCA43" : @"#4399FF";
    NSDictionary *attributeDict = @{
                                    NSFontAttributeName: [UIFont systemFontOfSize:12.0],
                                    NSForegroundColorAttributeName:[PLVColorUtil colorFromHexString:colorHexString]
    };
    NSAttributedString *string = [[NSAttributedString alloc] initWithString:content attributes:attributeDict];
    return string;
}

/// 获取严禁词提示多属性文本
+ (NSAttributedString *)contentLabelAttributedStringWithProhibitWordTip:(NSString *)prohibitTipString{
    UIFont *font = [UIFont systemFontOfSize:12.0];
    UIColor *color = [UIColor colorWithRed:240/255.0 green:241/255.0 blue:245/255.0 alpha:0.6];
    
    NSDictionary *AttDict = @{NSFontAttributeName: font,
                                      NSForegroundColorAttributeName: color};
    NSAttributedString *attributed = [[NSAttributedString alloc] initWithString:prohibitTipString attributes:AttDict];
    
    return attributed;
}

/// 获取图片URL
+ (NSURL *)imageURLWithMessage:(PLVImageMessage *)message {
    NSString *imageUrl = message.imageUrl;
    if (!imageUrl || ![imageUrl isKindOfClass:[NSString class]] || imageUrl.length == 0) {
        return nil;
    }
    
    return [NSURL URLWithString:imageUrl];
}

#pragma mark - 高度计算

+ (CGFloat)cellHeightWithModel:(PLVChatModel *)model cellWidth:(CGFloat)cellWidth {
    if (![PLVLSImageEmotionMessageCell isModelValid:model] || cellWidth == 0) {
        return 0;
    }
    
    CGFloat bubbleYPadding = 4.0; // 气泡与nickLabel的左右内间距
    CGFloat nickLabelHeight = 16.0; // nickLabel高度
    CGSize imageViewSize = [PLVLSImageEmotionMessageCell calculateImageViewSizeWithMessage:model.message];
    CGFloat prohibitTipHeight = 0; // 违禁提示语高度
    if ([model isProhibitMsg]) {
        imageViewSize = CGSizeMake(36, 36);
        prohibitTipHeight = 4 + 17 + 4;
    }
    return bubbleYPadding + nickLabelHeight + 4 + imageViewSize.height + prohibitTipHeight + bubbleYPadding + 4; // nickLabel跟图片之间距离4，气泡底部外间距4
}

//图片表情是固定的大小
+ (CGSize)calculateImageViewSizeWithMessage:(PLVImageMessage *)message {
    CGFloat maxLength = 80.0;
    return CGSizeMake(maxLength, maxLength);
}

#pragma mark - Action

- (void)tapImageViewAction {
    [self.photoBrowser scaleImageViewToFullScreen:self.chatImageView];
}

#pragma mark - Utils

/// 判断model是否为有效类型
+ (BOOL)isModelValid:(PLVChatModel *)model {
    if (!model || ![model isKindOfClass:[PLVChatModel class]]) {
        return NO;
    }
    
    id message = model.message;
    if (!message || ![message isKindOfClass:[PLVImageEmotionMessage class]]) {
        return NO;
    }
    
    return YES;
}

+ (NSString *)prohibitWordTip {
    return @"图片不合法";
}

@end
