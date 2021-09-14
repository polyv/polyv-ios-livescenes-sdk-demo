//
//  PLVECChatCell.m
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2020/11/28.
//  Copyright © 2020 PLV. All rights reserved.
//

#import "PLVECChatCell.h"
#import "PLVChatModel.h"
#import "PLVChatUser.h"
#import "PLVECUtils.h"
#import "PLVEmoticonManager.h"
#import "PLVPhotoBrowser.h"
#import <PLVLiveScenesSDK/PLVSpeakMessage.h>
#import <PLVLiveScenesSDK/PLVQuoteMessage.h>
#import <PLVLiveScenesSDK/PLVImageMessage.h>
#import <PLVFoundationSDK/PLVColorUtil.h>
#import <SDWebImage/UIImageView+WebCache.h>

@interface PLVECChatCell ()

@property (nonatomic, strong) PLVChatModel *model;

@property (nonatomic, assign) CGFloat cellWidth;

@property (nonatomic, strong) UILabel *chatLabel;

@property (nonatomic, strong) UIImageView *chatImageView;

@property (nonatomic, strong) UIView *bubbleView;

@property (nonatomic, strong) PLVPhotoBrowser *photoBrowser;

@end

@implementation PLVECChatCell

#pragma mark - 生命周期

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        
        [self.contentView addSubview:self.bubbleView];
        [self.contentView addSubview:self.chatLabel];
        [self.contentView addSubview:self.chatImageView];
    }
    return self;
}

- (void)layoutSubviews {
    if (!self.model || self.cellWidth == 0) {
        return;
    }
    
    CGFloat originX = 8.0;
    CGFloat originY = 4.0;
    
    // 设置内容文本frame
    CGFloat labelWidth = self.cellWidth - originX * 2;
    CGRect chatLabelRect = [self.chatLabel.attributedText boundingRectWithSize:CGSizeMake(labelWidth, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading context:nil];
    self.chatLabel.frame = CGRectMake(originX, originY, chatLabelRect.size.width, chatLabelRect.size.height);
    originY += chatLabelRect.size.height + 4;
    
    // 设置图片frame，如果有的话
    CGSize imageViewSize = CGSizeZero;
    if (!self.chatImageView.hidden) {
        PLVImageMessage *imageMessage = (PLVImageMessage *)self.model.message;
        imageViewSize = [PLVECChatCell calculateImageViewSizeWithImageSize:imageMessage.imageSize];
        
        self.chatImageView.frame = CGRectMake(originX, originY, imageViewSize.width, imageViewSize.height);
        originY += imageViewSize.height + 4;
    }
    
    CGFloat bubbleWidth = MIN((MAX(imageViewSize.width, chatLabelRect.size.width) + originX * 2), self.cellWidth);
    self.bubbleView.frame = CGRectMake(0, 0, bubbleWidth, originY);
}

#pragma mark - Getter

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

- (UIImageView *)chatImageView {
    if (!_chatImageView) {
        _chatImageView = [[UIImageView alloc] init];
        _chatImageView.layer.masksToBounds = YES;
        _chatImageView.layer.cornerRadius = 4.0;
        _chatImageView.userInteractionEnabled = YES;
        _chatImageView.contentMode = UIViewContentModeScaleAspectFill;
        _chatImageView.hidden = YES;
        
        self.photoBrowser = [[PLVPhotoBrowser alloc] init];
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureAction)];
        [_chatImageView addGestureRecognizer:tapGesture];
    }
    return _chatImageView;
}

#pragma mark - Action

- (void)tapGestureAction {
    [self.photoBrowser scaleImageViewToFullScreen:self.chatImageView];
}

#pragma mark - UI

- (void)updateWithModel:(PLVChatModel *)model cellWidth:(CGFloat)cellWidth {
    if (![PLVECChatCell isModelValid:model] || cellWidth == 0) {
        self.cellWidth = 0;
        self.model = nil;
        self.chatImageView.hidden = YES;
        self.chatLabel.text = @"";
        self.bubbleView.hidden = YES;
        return;
    }
    
    self.cellWidth = cellWidth;
    self.model = model;
    self.bubbleView.hidden = NO;
    
    // 设置聊天图片，如果是图片消息的话
    NSURL *imageURL = [PLVECChatCell chatImageURLWithMessage:model.message];
    self.chatImageView.hidden = !imageURL;
    if (imageURL) {
        UIImage *placeholderImage = [PLVECUtils imageForWatchResource:@"plv_chatroom_thumbnail_imag"];
        [self.chatImageView sd_setImageWithURL:imageURL
                              placeholderImage:placeholderImage
                                       options:SDWebImageRetryFailed];
    }
    
    // 设置 "昵称：文本（如果有的话）"
    NSAttributedString *chatLabelString = [PLVECChatCell chatLabelAttributedStringWithModel:model];
    self.chatLabel.attributedText = chatLabelString;
    
}

#pragma mark UI - ViewModel

+ (NSAttributedString *)chatLabelAttributedStringWithModel:(PLVChatModel *)model {
    NSAttributedString *actorAttributedString = [PLVECChatCell actorAttributedStringWithUser:model.user];
    NSAttributedString *nickNameAttributedString = [PLVECChatCell nickNameAttributedStringWithUser:model.user];
    NSAttributedString *contentAttributedString = [PLVECChatCell contentAttributedStringWithMessage:model.message];
    
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
    actorLabel.backgroundColor = [PLVECChatCell actorLabelBackground:user];
    actorLabel.textColor = [UIColor whiteColor];
    actorLabel.textAlignment = NSTextAlignmentCenter;
    
    CGRect actorContentRect = [user.actor boundingRectWithSize:CGSizeMake(MAXFLOAT, 12) options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:actorFontSize]} context:nil];
    CGSize actorLabelSize = CGSizeMake(actorContentRect.size.width + 12.0, 12);
    actorLabel.frame = CGRectMake(0, 0, actorLabelSize.width * scale, actorLabelSize.height * scale);
    actorLabel.layer.cornerRadius = 6.0 * scale;
    actorLabel.layer.masksToBounds = YES;
    
    // 将昵称label再转换为NSAttributedString对象
    UIImage *actorImage = [PLVECChatCell imageFromUIView:actorLabel];
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
+ (NSAttributedString *)contentAttributedStringWithMessage:(id)message {
    if (![message isKindOfClass:[PLVSpeakMessage class]] &&
        ![message isKindOfClass:[PLVQuoteMessage class]]) {
        return nil;
    }
    
    NSString *content = @"";
    if ([message isKindOfClass:[PLVSpeakMessage class]]) {
        PLVSpeakMessage *speakMessage = (PLVSpeakMessage *)message;
        content = speakMessage.content;
    } else {
        PLVQuoteMessage *quoteMessage = (PLVQuoteMessage *)message;
        content = quoteMessage.content;
    }
    
    if (!content || ![content isKindOfClass:[NSString class]] || content.length == 0) {
        return nil;
    }
    
    NSDictionary *attributeDict = @{
                                    NSFontAttributeName: [UIFont systemFontOfSize:12.0],
                                    NSForegroundColorAttributeName:[UIColor whiteColor]
    };
    NSMutableAttributedString *emotionAttrStr = [[PLVEmoticonManager sharedManager] converEmoticonTextToEmotionFormatText:content attributes:attributeDict];
    return [emotionAttrStr copy];
}

/// 获取聊天图片URL
+ (NSURL *)chatImageURLWithMessage:(id)message {
    if ([message isKindOfClass:[PLVImageMessage class]]) {
        PLVImageMessage *imageMessage = (PLVImageMessage *)message;
        NSString *imageUrl = imageMessage.imageUrl;
        if (!imageUrl || ![imageUrl isKindOfClass:[NSString class]] || imageUrl.length == 0) {
            return nil;
        }
        
        return [NSURL URLWithString:imageUrl];
    }
    if ([message isKindOfClass:[PLVImageEmotionMessage class]]) {
        PLVImageEmotionMessage *imageMessage = (PLVImageEmotionMessage *)message;
        NSString *imageUrl = imageMessage.imageUrl;
        if (!imageUrl || ![imageUrl isKindOfClass:[NSString class]] || imageUrl.length == 0) {
            return nil;
        }
        
        return [NSURL URLWithString:imageUrl];
    }
    return nil;
}

#pragma mark - 高度、尺寸计算

/// 计算图片显示宽高
+ (CGSize)calculateImageViewSizeWithImageSize:(CGSize)size {
    CGFloat maxLength = 120.0;
    if (size.width < size.height) { // 竖图
        CGFloat height = maxLength;
        CGFloat width = maxLength * size.width / size.height;
        return CGSizeMake(width, height);
    } else if (size.width > size.height) { // 横图
        CGFloat width = maxLength;
        CGFloat height = maxLength * size.height / size.width;
        return CGSizeMake(width, height);
    } else {
        return CGSizeMake(maxLength, maxLength);
    }
}

/// 计算cell高度
+ (CGFloat)cellHeightWithModel:(PLVChatModel *)model cellWidth:(CGFloat)cellWidth {
    if (![PLVECChatCell isModelValid:model] || cellWidth == 0) {
        return 0;
    }
    
    CGFloat originX = 8.0;
    CGFloat bubbleHeight = 4.0;
    
    // 内容文本高度
    NSAttributedString *chatLabelString = [PLVECChatCell chatLabelAttributedStringWithModel:model];
    CGRect chatLabelRect = CGRectZero;
    if (chatLabelString) {
        CGFloat labelWidth = cellWidth - originX * 2;
        chatLabelRect = [chatLabelString boundingRectWithSize:CGSizeMake(labelWidth, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading context:nil];
        bubbleHeight += chatLabelRect.size.height + 4;
    }
    
    // 聊天图片高度
    CGSize imageViewSize = CGSizeZero;
    if ([model.message isKindOfClass:[PLVImageMessage class]]) {
        PLVImageMessage *imageMessage = (PLVImageMessage *)model.message;
        imageViewSize = [PLVECChatCell calculateImageViewSizeWithImageSize:imageMessage.imageSize];
        bubbleHeight += imageViewSize.height + 4;
    }
    
    if ([model.message isKindOfClass:[PLVImageEmotionMessage class]]) {
        imageViewSize = [PLVECChatCell calculateImageViewSizeWithImageSize:CGSizeMake(60.0, 60.0)];
        bubbleHeight += imageViewSize.height + 4;
    }
    
    return bubbleHeight + 4;
}

#pragma mark - Utils

/// 判断model是否为有效类型
+ (BOOL)isModelValid:(PLVChatModel *)model {
    if (!model || ![model isKindOfClass:[PLVChatModel class]]) {
        return NO;
    }
    
    PLVChatUser *user = model.user;
    id message = model.message;
    if (!user || ![user isKindOfClass:[PLVChatUser class]] || !message ||
        (![message isKindOfClass:[PLVSpeakMessage class]] &&
         ![message isKindOfClass:[PLVQuoteMessage class]] &&
         ![message isKindOfClass:[PLVImageMessage class]] &&
         ![message isKindOfClass:[PLVImageEmotionMessage class]])) {
        return NO;
    }
    
    return YES;
}

+ (UIImage *)imageFromUIView:(UIView *)view {
    UIGraphicsBeginImageContext(view.bounds.size);
    CGContextRef ctxRef = UIGraphicsGetCurrentContext();
    [view.layer renderInContext:ctxRef];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

@end
