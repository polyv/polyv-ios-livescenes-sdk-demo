//
//  PLVECChatCell.m
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2020/11/28.
//  Copyright © 2020 PLV. All rights reserved.
//

#import "PLVECChatCell.h"

// 工具
#import "PLVECUtils.h"
#import "PLVMultiLanguageManager.h"

// UI
#import "PLVPhotoBrowser.h"

// 模块
#import "PLVChatUser.h"
#import "PLVEmoticonManager.h"
#import "PLVRoomDataManager.h"

// 依赖库
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>
#import <PLVFoundationSDK/PLVFoundationSDK.h>

static NSString *kRedpackMessageTapKey = @"redpackTap";

@interface PLVECChatCell ()

/// UI
@property (nonatomic, strong) UIImageView *chatImageView;
@property (nonatomic, strong) PLVPhotoBrowser *photoBrowser;
@property (nonatomic, strong) UIImageView *fileImageView;
@property (nonatomic, strong) UIView *tapGestureView;

/// 数据
@property (nonatomic, assign) NSRange tapRange;

@end

@implementation PLVECChatCell

#pragma mark - [ Life Cycle ]

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self.contentView addSubview:self.chatImageView];
        [self.contentView addSubview:self.fileImageView];
        [self.contentView addSubview:self.tapGestureView];
        
        UITapGestureRecognizer *labTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(chatLabelTapAction:)];
        self.chatLabel.userInteractionEnabled = YES;
        [self.chatLabel addGestureRecognizer:labTapGesture];
    }
    return self;
}

- (void)layoutSubviews {
    if (!self.model || self.cellWidth == 0) {
        return;
    }
    
    CGFloat originX = 8.0;
    CGFloat originY = 4.0;
    CGFloat bubbleWidth = 0;
    
    if ([self.model.message isKindOfClass:[PLVFileMessage class]]) { // 文件消息布局
        CGFloat fileImageWidth = 32;
        CGFloat fileImageHeight = 38;
        CGFloat labelWidth = self.cellWidth - fileImageWidth - originX * 3;
        CGSize chatLabelSize = [self.chatLabel.attributedText boundingRectWithSize:CGSizeMake(labelWidth, MAXFLOAT)
                                                                              options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading
                                                                              context:nil].size;
        CGFloat chatLabelHeight = ceil(chatLabelSize.height) + 8; // 修复可能出现文字显示不全的情况
        CGFloat fileImageOriginX = originX * 2 + chatLabelSize.width;
        if (chatLabelHeight < fileImageHeight) {
            self.chatLabel.frame = CGRectMake(originX, (fileImageHeight - chatLabelHeight) / 2 + originY * 2, chatLabelSize.width, chatLabelHeight);
            self.fileImageView.frame = CGRectMake(fileImageOriginX, originY * 2, fileImageWidth, fileImageHeight);
        } else {
            self.chatLabel.frame = CGRectMake(originX, originY, chatLabelSize.width, chatLabelHeight);
            self.fileImageView.frame = CGRectMake(fileImageOriginX,  (chatLabelHeight - fileImageHeight) / 2 + originY , fileImageWidth, fileImageHeight);
        }
        
        originY += MAX(chatLabelSize.height, fileImageHeight) + 12;
        bubbleWidth = MIN(chatLabelSize.width + fileImageWidth + originX * 3, self.cellWidth);
        
        self.tapGestureView.frame = CGRectMake(0, 0, bubbleWidth, originY);
    } else if ([self.model.message isKindOfClass:[PLVImageMessage class]]) { // 图片消息布局
        CGFloat labelWidth = self.cellWidth - originX * 2;
        CGSize chatLabelSize = [self.chatLabel.attributedText boundingRectWithSize:CGSizeMake(labelWidth, MAXFLOAT)
                                                                           options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading
                                                                           context:nil].size;
        CGFloat chatLabelHeight = ceil(chatLabelSize.height) + 12; // 修复可能出现文字显示不全的情况
        self.chatLabel.frame = CGRectMake(originX, originY, chatLabelSize.width, chatLabelHeight);
        PLVImageMessage *imageMessage = (PLVImageMessage *)self.model.message;
        CGSize imageViewSize = [PLVECChatCell calculateImageViewSizeWithImageSize:imageMessage.imageSize];
        BOOL lineBreak = chatLabelSize.width + imageViewSize.width + 4 * 3 > self.cellWidth;
        if (lineBreak) { // 图片需要换行
            originY += chatLabelHeight + 4;
            self.chatImageView.frame = CGRectMake(originX, originY, imageViewSize.width, imageViewSize.height);
        } else {
            self.chatImageView.frame = CGRectMake(CGRectGetMaxX(self.chatLabel.frame) + 4, originY, imageViewSize.width, imageViewSize.height);
        }
        originY += imageViewSize.height + 4;
        bubbleWidth = lineBreak ? self.cellWidth : MIN(imageViewSize.width + chatLabelSize.width + originX * 3, self.cellWidth);
    } else if ([self.model.message isKindOfClass:[PLVImageEmotionMessage class]]) { // 图片表情消息布局
        CGFloat labelWidth = self.cellWidth - originX * 2;
        CGSize chatLabelSize = [self.chatLabel.attributedText boundingRectWithSize:CGSizeMake(labelWidth, MAXFLOAT)
                                                                           options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading
                                                                           context:nil].size;
        CGFloat chatLabelHeight = ceil(chatLabelSize.height) + 12; // 修复可能出现文字显示不全的情况
        self.chatLabel.frame = CGRectMake(originX, originY, chatLabelSize.width, chatLabelHeight);
        PLVImageEmotionMessage *imageMessage = (PLVImageEmotionMessage *)self.model.message;
        CGSize imageViewSize = [PLVECChatCell calculateImageViewSizeWithImageSize:imageMessage.imageSize];
        BOOL lineBreak = chatLabelSize.width + imageViewSize.width + 4 * 3 > self.cellWidth;
        if (lineBreak) { // 图片需要换行
            originY += chatLabelHeight + 4;
            self.chatImageView.frame = CGRectMake(originX, originY, imageViewSize.width, imageViewSize.height);
        } else {
            self.chatImageView.frame = CGRectMake(CGRectGetMaxX(self.chatLabel.frame) + 4, originY, imageViewSize.width, imageViewSize.height);
        }
        originY += imageViewSize.height + 4;
        bubbleWidth = lineBreak ? self.cellWidth : MIN(imageViewSize.width + chatLabelSize.width + originX * 3, self.cellWidth);
    } else if ([self.model.message isKindOfClass:[PLVRedpackMessage class]]) { // 红包消息布局
        CGFloat labelWidth = self.cellWidth - originX * 2;
        CGSize chatLabelSize = [self.chatLabel.attributedText boundingRectWithSize:CGSizeMake(labelWidth, MAXFLOAT)
                                                                           options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading
                                                                           context:nil].size;
        CGFloat chatLabelHeight = 0;
        if (chatLabelSize.height <= 24) {
            chatLabelHeight = 20;
        } else if (chatLabelSize.height <= 37) {
            chatLabelHeight = ceil(chatLabelSize.height) + 4;
        } else {
            chatLabelHeight = ceil(chatLabelSize.height) + 8;
        }
        self.chatLabel.frame = CGRectMake(originX, originY, chatLabelSize.width, chatLabelHeight);
        
        originY += chatLabelHeight + 4;
        bubbleWidth = MIN(chatLabelSize.width + originX * 2, self.cellWidth);
    } else { // 其他消息布局
        CGFloat labelWidth = self.cellWidth - originX * 2;
        CGSize chatLabelSize = [self.chatLabel sizeThatFits:CGSizeMake(labelWidth, MAXFLOAT)];
        CGFloat chatLabelHeight = ceil(chatLabelSize.height);
        CGFloat chatLabelWidth = ceil(chatLabelSize.width);
        self.chatLabel.frame = CGRectMake(originX, originY, chatLabelWidth, chatLabelHeight);
        
        originY += chatLabelHeight + 4;
        bubbleWidth = MIN(chatLabelWidth + originX * 2, self.cellWidth);
    }
    
    self.bubbleView.frame = CGRectMake(0, 0, bubbleWidth, originY);
}

#pragma mark - [ Public Methods ]

- (void)updateWithModel:(PLVChatModel *)model cellWidth:(CGFloat)cellWidth {
    [super updateWithModel:model cellWidth:cellWidth];
    
    if (![PLVECChatCell isModelValid:model] || cellWidth == 0) {
        self.cellWidth = 0;
        self.chatImageView.hidden = YES;
        self.chatLabel.text = @"";
        self.tapGestureView.hidden = YES;
        self.fileImageView.hidden = YES;
        return;
    }
    
    self.cellWidth = cellWidth;
    self.model = model;
    
    // 设置聊天图片，如果是图片消息的话
    NSURL *imageURL = [PLVECChatCell chatImageURLWithMessage:model.message];
    self.chatImageView.hidden = !imageURL;
    if (imageURL) {
        UIImage *placeholderImage = [PLVECUtils imageForWatchResource:@"plv_chatroom_thumbnail_imag"];
        [PLVECUtils setImageView:self.chatImageView url:imageURL placeholderImage:placeholderImage options:SDWebImageRetryFailed];
    }
    
    UIImage *fileImage = [PLVECChatCell fileImageWithMessage:model.message];
    self.tapGestureView.hidden = !fileImage;
    self.fileImageView.hidden = !fileImage;
    if (fileImage) {
        [self.fileImageView setImage:fileImage];
    }
    self.chatLabel.numberOfLines = !fileImage ? 0 : 3;
    self.chatLabel.lineBreakMode = !fileImage ? NSLineBreakByTruncatingTail : NSLineBreakByTruncatingMiddle;
    
    // 设置 "昵称：文本（如果有的话）"
    NSMutableAttributedString *chatLabelString;
    if (model.attributeString) {
        chatLabelString = model.attributeString;
    } else {
        model.attributeString = [[NSMutableAttributedString alloc] initWithAttributedString:[PLVECChatCell chatLabelAttributedStringWithModel:model]];
    }
    
    self.chatLabel.attributedText = chatLabelString;
}

+ (CGFloat)cellHeightWithModel:(PLVChatModel *)model cellWidth:(CGFloat)cellWidth {
    if (![PLVECChatCell isModelValid:model] || cellWidth == 0) {
        return 0;
    }
    
    CGFloat originX = 8.0;
    CGFloat bubbleHeight = 4.0;
    
    // 内容文本高度
    NSMutableAttributedString *chatLabelString;
    if (model.attributeString) {
        chatLabelString = model.attributeString;
    } else {
        model.attributeString = [[NSMutableAttributedString alloc] initWithAttributedString:[PLVECChatCell chatLabelAttributedStringWithModel:model]];
    }
    
    CGRect chatLabelRect = CGRectZero;
    if (chatLabelString) {
        BOOL isFileMessage = model.message && [model.message isKindOfClass:[PLVFileMessage class]];
        BOOL isRedpackMessage = model.message && [model.message isKindOfClass:[PLVRedpackMessage class]];
        if (isFileMessage) {
            CGFloat fileImageWidth = 32;
            CGFloat fileImageHeight = 38;
            CGFloat labelWidth = cellWidth - fileImageWidth - originX * 3;
            UILabel *label = [[UILabel alloc]init];
            label.numberOfLines = 3;
            label.attributedText = chatLabelString;
            chatLabelRect = [label.attributedText boundingRectWithSize:CGSizeMake(labelWidth, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading context:nil];;
            bubbleHeight += MAX(ceil(chatLabelRect.size.height) + 12, fileImageHeight + 12);
        } else if (isRedpackMessage) {
            CGFloat labelWidth = cellWidth - originX * 2;
            chatLabelRect = [chatLabelString boundingRectWithSize:CGSizeMake(labelWidth, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading context:nil];
            CGFloat chatLabelHeight = 0;
            if (chatLabelRect.size.height <= 24) { //一行
                chatLabelHeight = 20;
            } else if (chatLabelRect.size.height <= 37) { //二行
                chatLabelHeight = ceil(chatLabelRect.size.height) + 4;
            } else { //三行及以上
                chatLabelHeight = ceil(chatLabelRect.size.height) + 8;
            }
            bubbleHeight += chatLabelHeight + 4;
        } else {
            CGFloat labelWidth = cellWidth - originX * 2;
            chatLabelRect = [chatLabelString boundingRectWithSize:CGSizeMake(labelWidth, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading context:nil];
            bubbleHeight += ceil(chatLabelRect.size.height) + 12;
        }
    }
    
    // 聊天图片高度
    CGSize imageViewSize = CGSizeZero;
    if ([model.message isKindOfClass:[PLVImageMessage class]]) {
        PLVImageMessage *imageMessage = (PLVImageMessage *)model.message;
        imageViewSize = [PLVECChatCell calculateImageViewSizeWithImageSize:imageMessage.imageSize];
        BOOL lineBreak = chatLabelRect.size.width + imageViewSize.width + 4 * 3 > cellWidth; // 换行
        CGFloat chatLabelHeigt = ceil(chatLabelRect.size.height) + 12;
        bubbleHeight += (lineBreak ? imageViewSize.height + 8 : (- chatLabelHeigt + MAX(chatLabelHeigt, imageViewSize.height + 4)));
    }
    
    if ([model.message isKindOfClass:[PLVImageEmotionMessage class]]) {
        imageViewSize = [PLVECChatCell calculateImageViewSizeWithImageSize:CGSizeMake(60.0, 60.0)];
        BOOL lineBreak = chatLabelRect.size.width + imageViewSize.width + 4 * 3 > cellWidth; // 换行
        CGFloat chatLabelHeigt = ceil(chatLabelRect.size.height) + 12;
        bubbleHeight += (lineBreak ? imageViewSize.height + 8 : (- chatLabelHeigt + MAX(chatLabelHeigt, imageViewSize.height + 4)));
    }
    
    return bubbleHeight + 4;
}

+ (BOOL)isModelValid:(PLVChatModel *)model {
    if (!model || ![model isKindOfClass:[PLVChatModel class]]) {
        return NO;
    }
    
    PLVChatUser *user = model.user;
    id message = model.message;
    if (!user || ![user isKindOfClass:[PLVChatUser class]] || !message ||
        (![message isKindOfClass:[PLVSpeakMessage class]] &&
         ![message isKindOfClass:[PLVImageMessage class]] &&
         ![message isKindOfClass:[PLVImageEmotionMessage class]] &&
         ![message isKindOfClass:[PLVCustomMessage class]] &&
         ![message isKindOfClass:[PLVFileMessage class]] &&
         ![message isKindOfClass:[PLVRedpackMessage class]])) {
        return NO;
    }
    
    if (message &&
        [message isKindOfClass:[PLVSpeakMessage class]] &&
        model.contentLength != PLVChatMsgContentLength_0To500) {
        return NO;
    }
    
    return YES;
}

#pragma mark - [ Private Methods ]

+ (NSAttributedString *)chatLabelAttributedStringWithModel:(PLVChatModel *)model {
    if ([model.message isKindOfClass:[PLVCustomMessage class]]) { // 自定义消息
        NSAttributedString *contentAttributedString = [PLVECChatCell customMessageContentAttributedStringWithChatModel:model];
        return [contentAttributedString copy];
    } else if ([model.message isKindOfClass:[PLVRedpackMessage class]]) { // 红包消息
        NSAttributedString *contentAttributedString = [PLVECChatCell redpackContentAttributedStringWithChatModel:model];
        return [contentAttributedString copy];
    } else {
        NSAttributedString *actorAttributedString = [PLVECChatCell actorAttributedStringWithUser:model.user];
        NSAttributedString *nickNameAttributedString = [PLVECChatCell nickNameAttributedStringWithUser:model.user];
        NSAttributedString *contentAttributedString = [PLVECChatCell contentAttributedStringWithChatModel:model];
        
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
    UIImage *actorImage = [PLVImageUtil imageFromUIView:actorLabel];
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
+ (NSAttributedString *)contentAttributedStringWithChatModel:(PLVChatModel *)chatModel {
    id message = chatModel.message;
    if (![message isKindOfClass:[PLVSpeakMessage class]] &&
        ![message isKindOfClass:[PLVFileMessage class]]) {
        return nil;
    }
    
    NSString *content = @"";
    if ([message isKindOfClass:[PLVSpeakMessage class]]) {
        PLVSpeakMessage *speakMessage = (PLVSpeakMessage *)message;
        content = speakMessage.content;
    } else if ([message isKindOfClass:[PLVFileMessage class]]) {
        PLVFileMessage *fileMessage = (PLVFileMessage *)message;
        content = fileMessage.name;
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

/// 自定义消息文本
+ (NSAttributedString *)customMessageContentAttributedStringWithChatModel:(PLVChatModel *)chatModel {
    id message = chatModel.message;
    if (![message isKindOfClass:[PLVCustomMessage class]]) {
        return nil;
    }
    
    PLVCustomMessage *customMessage = (PLVCustomMessage *)message;
    UIFont *font = [UIFont systemFontOfSize:12.0];
    NSDictionary *contentAttDict = @{NSFontAttributeName: font,
                                     NSForegroundColorAttributeName:[UIColor whiteColor]};
    NSDictionary *dataDic = customMessage.data;
    
    // 礼物内容(昵称 + 礼物名称)
    NSString *tip = customMessage.tip;
    tip = [PLVFdUtil checkStringUseable:tip] ? tip : @"";
    PLVChatUser *user = chatModel.user;
    if ([user.userId isEqualToString:[PLVRoomDataManager sharedManager].roomData.roomUser.viewerId]) { // 自己的赠送记录
        NSString *giftName = PLV_SafeStringForDictKey(dataDic, @"giftName");
        giftName = [PLVFdUtil checkStringUseable:giftName] ? giftName : @"";
        tip = [NSString stringWithFormat:PLVLocalizedString(@"%@(我) 赠送了 %@"), user.userName, giftName];
    }
    NSMutableAttributedString *conentString = [[NSMutableAttributedString alloc] initWithString:tip attributes:contentAttDict];
    
    // 礼物图片
    NSString *giftType = PLV_SafeStringForDictKey(dataDic, @"giftType");
    giftType = [PLVFdUtil checkStringUseable:giftType] ? giftType : @"";
    NSString *giftImageStr = [NSString stringWithFormat:@"plv_gift_icon_%@",giftType];
    NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
    attachment.image = [PLVECUtils imageForWatchResource:giftImageStr];
    attachment.bounds = CGRectMake(0, font.descender, font.lineHeight, font.lineHeight);
    NSAttributedString *emoticonAttrStr = [NSAttributedString attributedStringWithAttachment:attachment];
    
    // 礼物内容 + 图片
    [conentString appendAttributedString:emoticonAttrStr];
    
    return [[[PLVEmoticonManager sharedManager] converEmoticonTextToEmotionFormatText:conentString font:font] copy];
}

/// 获取红包消息文本
+ (NSAttributedString *)redpackContentAttributedStringWithChatModel:(PLVChatModel *)chatModel {
    id message = chatModel.message;
    if (![message isKindOfClass:[PLVRedpackMessage class]]) {
        return nil;
    }
    
    PLVRedpackMessage *redpackMessage = (PLVRedpackMessage *)message;
    
    // 红包icon
    UIImage *image = [PLVECUtils imageForWatchResource:@"plvec_chatroom_redpack_icon"];
    NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
    attachment.image = image;
    attachment.bounds = CGRectMake(0, -2, 20, 20);
    
    // 白色文本
    NSString *redpackTypeString = @"";
    if (redpackMessage.type == PLVRedpackMessageTypeAliPassword) {
        redpackTypeString = PLVLocalizedString(@"支付宝口令");
    }
    NSString *contentString = [NSString stringWithFormat:PLVLocalizedString(@" %@ 发了一个%@红包，"), chatModel.user.userName, redpackTypeString];
    NSDictionary *attributeDict = @{NSFontAttributeName:[UIFont systemFontOfSize:12],
                                    NSForegroundColorAttributeName:[UIColor whiteColor],
                                    NSBaselineOffsetAttributeName:@(4.0)};
    NSAttributedString *string = [[NSAttributedString alloc] initWithString:contentString attributes:attributeDict];
    
    // 红色文本
    NSDictionary *redAttributeDict = @{NSFontAttributeName:[UIFont systemFontOfSize:12],
                                       kRedpackMessageTapKey:@(1),
                                       NSForegroundColorAttributeName:[PLVColorUtil colorFromHexString:@"#FF5959"],
                                       NSBaselineOffsetAttributeName:@(4.0)};
    NSAttributedString *redString = [[NSAttributedString alloc] initWithString:PLVLocalizedString(@"点击领取") attributes:redAttributeDict];
    
    NSMutableAttributedString *muString = [[NSMutableAttributedString alloc] init];
    [muString appendAttributedString:[NSAttributedString attributedStringWithAttachment:attachment]];
    [muString appendAttributedString:string];
    [muString appendAttributedString:redString];
    return [muString copy];
}

/// 计算图片消息图片显示宽高
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

/// 获取文件类型图标
+ (UIImage *)fileImageWithMessage:(id)message {
    if ([message isKindOfClass:[PLVFileMessage class]]) {
        PLVFileMessage *fileMessage = (PLVFileMessage *)message;
        NSString *fileUrl = fileMessage.url;
        
        if (![PLVFdUtil checkStringUseable:fileUrl]) {
            return nil;
        }
        
        NSString *fileType = [[[fileUrl pathExtension] lowercaseString] substringToIndex:3];
        NSString *fileImageString = [NSString stringWithFormat:@"plvec_chatroom_file_%@_icon",fileType];
        
        return [PLVECUtils imageForWatchResource:fileImageString];
    }
    return nil;
}

// 将UIView转换为UIImage对象
+ (UIImage *)imageFromUIView:(UIView *)view {
    UIImage *image = [PLVImageUtil imageFromUIView:view];
    return image;
}

#pragma mark Getter

- (UIImageView *)chatImageView {
    if (!_chatImageView) {
        _chatImageView = [[UIImageView alloc] init];
        _chatImageView.layer.masksToBounds = YES;
        _chatImageView.layer.cornerRadius = 4.0;
        _chatImageView.userInteractionEnabled = YES;
        _chatImageView.contentMode = UIViewContentModeScaleAspectFill;
        _chatImageView.hidden = YES;
        
        self.photoBrowser = [[PLVPhotoBrowser alloc] init];
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(chatImageViewTapAction)];
        [_chatImageView addGestureRecognizer:tapGesture];
    }
    return _chatImageView;
}

- (UIImageView *)fileImageView {
    if (!_fileImageView) {
        _fileImageView = [[UIImageView alloc] init];
        _fileImageView.layer.masksToBounds = YES;
        _fileImageView.userInteractionEnabled = NO;
        _fileImageView.hidden = YES;
        _fileImageView.contentMode = UIViewContentModeScaleAspectFill;
    }
    return _fileImageView;
}

- (UIView *)tapGestureView {
    if (!_tapGestureView) {
        _tapGestureView = [[UIView alloc] init];
        _tapGestureView.backgroundColor = [UIColor clearColor];
        _tapGestureView.userInteractionEnabled = YES;
        _tapGestureView.hidden = YES;
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureViewAction)];
        [_tapGestureView addGestureRecognizer:tap];
    }
    return _tapGestureView;
}

#pragma mark - [ Event ]

#pragma mark Action

- (void)chatImageViewTapAction {
    [self.photoBrowser scaleImageViewToFullScreen:self.chatImageView];
}

- (void)tapGestureViewAction {
    if ([self.model.message isKindOfClass:[PLVFileMessage class]]) {
        PLVFileMessage *fileMessage = (PLVFileMessage *)self.model.message;
        NSString *url = fileMessage.url;
        if ([PLVFdUtil checkStringUseable:url]) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
        }
    }
}

- (void)chatLabelTapAction:(UITapGestureRecognizer *)gesture {
    if (![self.model.message isKindOfClass:[PLVRedpackMessage class]]) {
        return;
    }
    
    if (gesture.state == UIGestureRecognizerStateRecognized) {
        CGPoint point = [gesture locationInView:self.chatLabel];
        NSDictionary *dict = [PLVFdUtil textAttributesAtPoint:point withLabel:self.chatLabel];
        for (NSString *attributeName in dict.allKeys) {
            if ([attributeName isEqualToString:kRedpackMessageTapKey]) {
                if (self.redpackTapHandler) {
                    self.redpackTapHandler(self.model);
                }
            }
        }
    }
}

@end
