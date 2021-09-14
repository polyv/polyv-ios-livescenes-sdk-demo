//
//  PLVSARepliedMsgView.m
//  PLVLiveScenesDemo
//
//  Created by lijingtong on 2021/5/26.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVSARepliedMsgView.h"

// Utils
#import "PLVSAUtils.h"

// Model
#import "PLVChatModel.h"
#import "PLVEmoticonManager.h"

// SDK
#import <PLVFoundationSDK/PLVFoundationSDK.h>
#import <SDWebImage/UIImageView+WebCache.h>

@interface PLVSARepliedMsgView ()
@property (nonatomic, strong) PLVChatModel *chatModel; // 被引用的消息模型
@property (nonatomic, strong) PLVImageMessage * _Nullable imageMsg; // 被引用的图片消息
@property (nonatomic, assign) CGFloat viewHeight; // 根据 chatModel 得到的本视图高度
@property (nonatomic, strong) UIVisualEffectView *effectView; // 高斯模糊效果图
@property (nonatomic, strong) UIButton *closeButton; // 右上方关闭按钮
@property (nonatomic, strong) UILabel *label; // （图片消息）昵称文本或（文字消息）昵称+消息内容文本
@property (nonatomic, strong) UIImageView *imageView; // 图片消息的图片

@end

@implementation PLVSARepliedMsgView


#pragma mark - [ Life Cycle ]

#pragma mark - [ Override ]

- (void)layoutSubviews {
    self.effectView.frame = self.bounds;
}

#pragma mark - [ Public Method ]

- (instancetype)initWithChatModel:(PLVChatModel *)chatModel {
    self = [super init];
    if (self) {
        [self setupUI];
        [self configureChatModel:chatModel];
    }
    return self;
}

#pragma mark - [ Private Method ]

#pragma mark Initialization

- (void)setupUI {
    [self addSubview:self.effectView];
    [self addSubview:self.closeButton];
    [self addSubview:self.label];
}

- (void)configureChatModel:(PLVChatModel *)chatModel {
    _chatModel = chatModel;
    
    NSString *repliedMsgContent = nil;
    PLVImageMessage *imageMsg = nil;
    
    id message = chatModel.message;
    if ([message isKindOfClass:[PLVImageMessage class]]) {
        imageMsg = (PLVImageMessage *)message;
    } else if ([message isKindOfClass:[PLVImageEmotionMessage class]]){
        imageMsg = [[PLVImageMessage alloc] init];
        imageMsg.imageId = ((PLVImageEmotionMessage *)message).imageId;
        imageMsg.imageUrl = ((PLVImageEmotionMessage *)message).imageUrl;
        imageMsg.imageSize = ((PLVImageEmotionMessage *)message).imageSize;
    } else if ([message isKindOfClass:[PLVSpeakMessage class]] ||
               [message isKindOfClass:[PLVQuoteMessage class]]) {
        if ([message isKindOfClass:[PLVSpeakMessage class]]) {
            PLVSpeakMessage *speakMessage = (PLVSpeakMessage *)message;
            repliedMsgContent = speakMessage.content;
        } else if ([message isKindOfClass:[PLVQuoteMessage class]]) {
            PLVQuoteMessage *speakMessage = (PLVQuoteMessage *)message;
            repliedMsgContent = speakMessage.content;
        }
    }
    
    NSString *nickString = chatModel.user.userName;
    [self updateUIWithNickName:nickString content:repliedMsgContent imageMsg:imageMsg];
}

- (void)updateUIWithNickName:(NSString *)nickName content:(NSString *)content imageMsg:(PLVImageMessage *)imageMsg {
    NSMutableString *mutString = [[NSMutableString alloc] init];
    if (nickName &&
        [nickName isKindOfClass:[NSString class]] &&
        nickName.length > 0) { // 昵称
        [mutString appendString:nickName];
        [mutString appendString:@"："];
    }
    if (content &&
        [content isKindOfClass:[NSString class]] &&
        content.length > 0) { // 消息文本
        [mutString appendString:content];
    }
    
    NSMutableAttributedString *conentString = [[NSMutableAttributedString alloc] initWithString:[mutString copy] attributes:@{NSFontAttributeName:_label.font}];
    NSMutableAttributedString *emojiContentString = [[PLVEmoticonManager sharedManager] converEmoticonTextToEmotionFormatText:conentString font:_label.font];
    _label.attributedText = emojiContentString;
    
    if (imageMsg) { // 设置图片消息的图片
        _imageMsg = imageMsg; // _imageMsg不为nil时则证明为图片消息
        
        NSURL *imageURL = [PLVSARepliedMsgView imageURLWithMessage:imageMsg];
        UIImage *placeHolderImage = [PLVColorUtil createImageWithColor:[PLVColorUtil colorFromHexString:@"#777786"]];
        if (imageURL) {
            [self.imageView sd_setImageWithURL:imageURL
                              placeholderImage:placeHolderImage
                                       options:SDWebImageRetryFailed];
        } else if (imageMsg.image) {
            [self.imageView setImage:imageMsg.image];
        } else {
            [self.imageView setImage:placeHolderImage];
        }
    }
    
    [self layoutUI];
}

- (void)layoutUI {
    CGFloat width = PLVScreenWidth;
    CGFloat originX = [PLVSAUtils sharedUtils].areaInsets.left + 8;
    
    CGFloat closeButtonOriginX = width - originX - 30;
    CGFloat labelWidth = closeButtonOriginX - originX;
    CGSize labelTextSize = [self.label.text boundingRectWithSize:CGSizeMake(labelWidth, MAXFLOAT)
                                                         options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                                      attributes:@{ NSFontAttributeName : self.label.font }
                                                         context:nil].size;
    
    BOOL mutipleLine = labelTextSize.height > 16;
 
    CGFloat originY = mutipleLine ? 8 : 12;
    CGFloat labelHeight = mutipleLine ? labelTextSize.height : 16;
    
    self.closeButton.frame = CGRectMake(closeButtonOriginX, 0, 40, 40);
    self.label.frame = CGRectMake(originX, originY, labelWidth, labelHeight);
    
    CGFloat height = 0;
    if (self.imageMsg) {
        CGSize imageSize = [PLVSARepliedMsgView calculateImageViewSizeWithMessage:self.imageMsg];
        self.imageView.frame = CGRectMake(originX, CGRectGetMaxY(self.label.frame) + 4, imageSize.width, imageSize.height);
        height = CGRectGetMaxY(self.imageView.frame) + 8;
    } else {
        height = mutipleLine ? labelTextSize.height + 8 * 2 : 40;
    }
    
    _viewHeight = height;
}

#pragma mark Getter
- (UIVisualEffectView *)effectView {
    if (!_effectView) {
        UIBlurEffect *effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
        _effectView = [[UIVisualEffectView alloc] initWithEffect:effect];
    }
    return _effectView;
}

- (UIButton *)closeButton {
    if (!_closeButton) {
        UIImage *image = [PLVSAUtils imageForToolbarResource:@"plvsa_toolbar_btn_close"];
        _closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_closeButton setImage:image forState:UIControlStateNormal];
        [_closeButton addTarget:self action:@selector(closeButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _closeButton;
}

- (UILabel *)label {
    if (!_label) {
        _label = [[UILabel alloc] init];
        _label.font = [UIFont systemFontOfSize:12];
        _label.textColor = [PLVColorUtil colorFromHexString:@"#F0F1F5"];
        _label.numberOfLines = 0;
    }
    return _label;
}

- (UIImageView *)imageView {
    if (!_imageView) {
        _imageView = [[UIImageView alloc] init];
        _imageView.layer.masksToBounds = YES;
        _imageView.layer.cornerRadius = 4.0;
        [self addSubview:_imageView];
    }
    return _imageView;
}

#pragma mark Setter

#pragma mark Utils

/// 获取图片URL
+ (NSURL *)imageURLWithMessage:(PLVImageMessage *)message {
    NSString *imageUrl = message.imageUrl;
    if (!imageUrl || ![imageUrl isKindOfClass:[NSString class]] || imageUrl.length == 0) {
        return nil;
    }
    
    return [NSURL URLWithString:imageUrl];
}

/// 计算被引用消息图片尺寸
+ (CGSize)calculateImageViewSizeWithMessage:(PLVImageMessage *)message {
    CGSize imageSize = message.imageSize;
    CGFloat maxLength = 40.0;
    if (imageSize.width == 0 || imageSize.height == 0) {
        return CGSizeMake(maxLength, maxLength);
    }
    
    if (imageSize.width < imageSize.height) { // 竖图
        CGFloat height = maxLength;
        CGFloat width = maxLength * imageSize.width / imageSize.height;
        return CGSizeMake(width, height);
    } else if (imageSize.width > imageSize.height) { // 横图
        CGFloat width = maxLength;
        CGFloat height = maxLength * imageSize.height / imageSize.width;
        return CGSizeMake(width, height);
    } else {
        return CGSizeMake(maxLength, maxLength);
    }
}


#pragma mark Data Mode
#pragma mark Net Request

#pragma mark - Event

#pragma mark Action

- (void)closeButtonAction:(id)sender {
    [self removeFromSuperview];
    if (self.closeButtonHandler) {
        self.closeButtonHandler();
    }
}

#pragma mark Timer
#pragma mark Notification
#pragma mark Gesture

#pragma mark - Delegate

@end
