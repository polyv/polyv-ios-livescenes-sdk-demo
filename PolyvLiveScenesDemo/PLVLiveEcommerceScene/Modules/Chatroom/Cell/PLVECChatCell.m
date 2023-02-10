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

// UI
#import "PLVPhotoBrowser.h"

// 模块
#import "PLVChatUser.h"
#import "PLVEmoticonManager.h"
#import "PLVRoomDataManager.h"

// 依赖库
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>
#import <PLVFoundationSDK/PLVFoundationSDK.h>

@interface PLVECChatCell ()

@property (nonatomic, strong) UIImageView *chatImageView;

@property (nonatomic, strong) PLVPhotoBrowser *photoBrowser;

@property (nonatomic, strong) UIView *tapGestureView;

@property (nonatomic, strong) UIImageView *fileImageView;

@end

@implementation PLVECChatCell

#pragma mark - 生命周期

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self.contentView addSubview:self.chatImageView];
        [self.contentView addSubview:self.fileImageView];
        [self.contentView addSubview:self.tapGestureView];
    }
    return self;
}

- (void)layoutSubviews {
    if (!self.model || self.cellWidth == 0) {
        return;
    }
    
    CGFloat originX = 8.0;
    CGFloat originY = 4.0;
    CGFloat fileImageWidth = 32;
    CGFloat fileImageHeight = 38;
    BOOL isFileMessage = self.model.message && [self.model.message isKindOfClass:[PLVFileMessage class]];
    
    // 设置内容文本frame
    CGFloat labelWidth = isFileMessage ? (self.cellWidth - fileImageWidth - originX * 3) : (self.cellWidth - originX * 2);
    CGRect chatLabelRect = [self.chatLabel.attributedText boundingRectWithSize:CGSizeMake(labelWidth, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading context:nil];
    CGFloat chatLabelHeight = ceil(chatLabelRect.size.height) + 8; // 修复可能出现文字显示不全的情况
    CGFloat textViewRealWidth = chatLabelRect.size.width;
    // 设置文件下载图标frame
    if (isFileMessage) {
        if (chatLabelHeight < fileImageHeight) {
            self.chatLabel.frame = CGRectMake(originX, (fileImageHeight - chatLabelHeight) / 2 + originY * 2, chatLabelRect.size.width, chatLabelHeight);
            self.fileImageView.frame = CGRectMake(originX * 2 + chatLabelRect.size.width, originY * 2, fileImageWidth, fileImageHeight);
        } else {
            self.chatLabel.frame = CGRectMake(originX, originY , chatLabelRect.size.width, chatLabelHeight);
            self.fileImageView.frame = CGRectMake(originX * 2 + chatLabelRect.size.width,  (chatLabelHeight - fileImageHeight) / 2 + originY , fileImageWidth, fileImageHeight);
        }
        originY += MAX(chatLabelRect.size.height,fileImageHeight) + 12;
        textViewRealWidth += fileImageWidth + originX;
    } else {
        self.chatLabel.frame = CGRectMake(originX, originY, chatLabelRect.size.width, chatLabelHeight);
        originY += chatLabelHeight + 4;
    }
    
    // 设置图片frame，如果有的话
    CGSize imageViewSize = CGSizeZero;
    if (!self.chatImageView.hidden) {
        PLVImageMessage *imageMessage = (PLVImageMessage *)self.model.message;
        imageViewSize = [PLVECChatCell calculateImageViewSizeWithImageSize:imageMessage.imageSize];
        
        self.chatImageView.frame = CGRectMake(originX, originY, imageViewSize.width, imageViewSize.height);
        originY += imageViewSize.height + 4;
    }
    
    CGFloat bubbleWidth = MIN((MAX(imageViewSize.width, textViewRealWidth) + originX * 2), self.cellWidth);
    self.bubbleView.frame = CGRectMake(0, 0, bubbleWidth, originY);
    
    // 设置文件下载手势视图
    if (isFileMessage) {
        self.tapGestureView.frame = CGRectMake(0, 0, bubbleWidth, originY);
    }
}

#pragma mark - Getter

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

#pragma mark - Action

- (void)chatImageViewTapAction {
    [self.photoBrowser scaleImageViewToFullScreen:self.chatImageView];
}

#pragma mark - UI

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
    NSAttributedString *chatLabelString = [PLVECChatCell chatLabelAttributedStringWithModel:model];
    self.chatLabel.attributedText = chatLabelString;
    
}

#pragma mark UI - ViewModel

+ (NSAttributedString *)chatLabelAttributedStringWithModel:(PLVChatModel *)model {
    if ([model.message isKindOfClass:[PLVCustomMessage class]]) { // 自定义消息
        NSAttributedString *contentAttributedString = [PLVECChatCell contentAttributedStringWithChatModel:model];
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

#pragma mark AttributedString

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
    if (!message ||
        (![message isKindOfClass:[PLVCustomMessage class]] &&
        ![message isKindOfClass:[PLVSpeakMessage class]] &&
        ![message isKindOfClass:[PLVFileMessage class]])) {
        return nil;
    }
    
    if ([message isKindOfClass:[PLVCustomMessage class]]) {
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
            tip = [NSString stringWithFormat:@"%@(我) 赠送了 %@", user.userName, giftName];
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
    } else {
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
    CGFloat fileImageWidth = 32;
    CGFloat fileImageHeight = 38;
    
    // 内容文本高度
    NSAttributedString *chatLabelString = [PLVECChatCell chatLabelAttributedStringWithModel:model];
    CGRect chatLabelRect = CGRectZero;
    if (chatLabelString) {
        BOOL isFileMessage = model.message && [model.message isKindOfClass:[PLVFileMessage class]];
        CGFloat labelWidth = isFileMessage ? (cellWidth - fileImageWidth - originX * 3) : (cellWidth - originX * 2);
        CGFloat chatLabelHeight;
        if (isFileMessage) {
            UILabel *label = [[UILabel alloc]init];
            label.numberOfLines = 3;
            label.attributedText = chatLabelString;
            chatLabelRect = [label.attributedText boundingRectWithSize:CGSizeMake(labelWidth, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading context:nil];;
        } else {
            chatLabelRect = [chatLabelString boundingRectWithSize:CGSizeMake(labelWidth, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading context:nil];
        }
        chatLabelHeight = ceil(chatLabelRect.size.height) + 12;
        
        bubbleHeight += isFileMessage ? (MAX(chatLabelHeight, fileImageHeight + 12)) : (chatLabelHeight);
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

#pragma mark - Action

- (void)tapGestureViewAction {
    if ([self.model.message isKindOfClass:[PLVFileMessage class]]) {
        PLVFileMessage *fileMessage = (PLVFileMessage *)self.model.message;
        NSString *url = fileMessage.url;
        if ([PLVFdUtil checkStringUseable:url]) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
        }
    }
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
         ![message isKindOfClass:[PLVImageMessage class]] &&
         ![message isKindOfClass:[PLVImageEmotionMessage class]] &&
         ![message isKindOfClass:[PLVCustomMessage class]] &&
         ![message isKindOfClass:[PLVFileMessage class]])) {
        return NO;
    }
    
    if (message &&
        [message isKindOfClass:[PLVSpeakMessage class]] &&
        model.contentLength != PLVChatMsgContentLength_0To500) {
        return NO;
    }
    
    return YES;
}

@end
