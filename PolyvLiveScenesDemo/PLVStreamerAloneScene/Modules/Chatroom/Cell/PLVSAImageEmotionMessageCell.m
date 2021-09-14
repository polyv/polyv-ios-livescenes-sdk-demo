//
//  PLVSAImageEmotionMessageCell.m
//  PLVLiveScenesDemo
//
//  Created by Sakya on 2021/7/12.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVSAImageEmotionMessageCell.h"

// Utils
#import "PLVPhotoBrowser.h"
#import "PLVSAUtils.h"

// UI
#import "PLVSAProhibitWordTipView.h"


// Model
#import "PLVChatModel.h"

// SDK
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>
#import <PLVFoundationSDK/PLVFoundationSDK.h>
#import <SDWebImage/UIImageView+WebCache.h>

@interface PLVSAImageEmotionMessageCell ()

// Data
@property (nonatomic, assign) CGFloat cellWidth; // cell宽度
@property (nonatomic, strong) NSString *loginUserId; // 用户的聊天室userId
@property (nonatomic, assign) PLVImageEmotionMessageSendState msgState; // 消息状态
@property (nonatomic, assign) PLVChatMsgState imageLoadState; // 图片加载状态

// UI
@property (nonatomic, strong) UILabel *nickLabel; // 发出消息用户昵称
@property (nonatomic, strong) UIImageView *chatImageView; // 聊天消息图片
@property (nonatomic, strong) UIView *bubbleView; // 背景气泡
@property (nonatomic, strong) PLVPhotoBrowser *photoBrowser; // 消息图片Browser

@property (nonatomic, strong) UIImageView *prohibitImageView;  // 严禁图片提示
@property (nonatomic, strong) PLVSAProhibitWordTipView *prohibitWordTipView; // 严禁词提示视图

@property (nonatomic, strong) UIActivityIndicatorView *sendingIndicatorView; // 正在发送提示视图
@property (nonatomic, strong) UIButton *resendButton; // 重新发送按钮
@property (nonatomic, strong) UIButton *reloadButton; // 重新加载按钮

@end

static  NSString *KEYPATH_EMOTIONMSGSTATE = @"imageEmotionSendState";

@implementation PLVSAImageEmotionMessageCell

#pragma mark - [ Life Cycle ]

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.allowReply = YES;
        
        [self.contentView addSubview:self.bubbleView];
        [self.contentView addSubview:self.nickLabel];
        [self.contentView addSubview:self.chatImageView];
        [self.contentView addSubview:self.prohibitImageView];
        [self.contentView addSubview:self.prohibitWordTipView];
        [self.contentView addSubview:self.sendingIndicatorView];
        [self.contentView addSubview:self.resendButton];
        [self.contentView addSubview:self.reloadButton];
        
        self.photoBrowser = [[PLVPhotoBrowser alloc] init];
    }
    return self;
}

// cell 复用前清除数据
- (void)prepareForReuse {
    [super prepareForReuse];
    [self removeObserveMsgState];
}

- (void)dealloc {
    [self removeObserveMsgState];
}

#pragma mark - [ Override ]

- (void)layoutSubviews {
    if (self.cellWidth == 0) {
        return;
    }
    
    CGFloat originX = 8.0;
    CGFloat originY = 8.0;
    CGFloat bubbleXPadding = 8.0; // 气泡与nickLabel的左右内间距
    CGFloat maxViewWidth = self.cellWidth - bubbleXPadding * 2;
    
    NSAttributedString *nickAttributeString = self.nickLabel.attributedText;
    CGSize nickLabelSize = [nickAttributeString boundingRectWithSize:CGSizeMake(maxViewWidth, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:nil].size;
    
    self.nickLabel.frame = CGRectMake(originX, originY + 8, ceilf(nickLabelSize.width),  MAX(ceilf(nickLabelSize.height), 16));
    
    originY += MAX(ceilf(ceilf(nickLabelSize.height)), 16) + 8;
    
    CGFloat bubbleWidth;
   
    if ([self.model isProhibitMsg]) {
        // 违禁图片，将 originY 设置到 nickLabel的下面8个像素
        originY += 8;
        // 设置为本地图片36*36
        self.chatImageView.frame = CGRectMake(originX, originY, 36, 36);
        originY += 36;
        // 设置 bubbleWidth
        bubbleWidth = MAX(nickLabelSize.width, 36) + bubbleXPadding * 2;
        
        // 提示图标
        self.prohibitImageView.frame = CGRectMake(CGRectGetMaxX(self.chatImageView.frame) - 14, CGRectGetMaxY(self.chatImageView.frame) - 14, 14, 14);
        
        if (!self.model.prohibitWordTipIsShowed) {
            self.prohibitWordTipView.frame = CGRectMake(originX, originY + 8, 80, 38);
        } else {
            self.prohibitWordTipView.frame = CGRectZero;
        }
    } else {
        // nickLabel跟图片之间距离 8
        originY += 8;
        CGSize imageViewSize = [PLVSAImageEmotionMessageCell calculateImageViewSizeWithMessage:self.model.message];
        self.chatImageView.frame = CGRectMake(originX, originY, imageViewSize.width, imageViewSize.height);
        originY += imageViewSize.height + 4;
        
        bubbleWidth = MAX(nickLabelSize.width, imageViewSize.width) + bubbleXPadding * 2;
    }
     
    // 发送状态
    CGRect rect = self.chatImageView.frame;
    self.reloadButton.frame = rect;
    self.sendingIndicatorView.frame = rect;
    self.resendButton.frame = rect;
    
    [self setButtonInsets:self.resendButton];
    [self setButtonInsets:self.reloadButton];
    self.bubbleView.frame = CGRectMake(0, 8, bubbleWidth, originY);
}


#pragma mark - [ Public Method ]

- (void)updateWithModel:(PLVChatModel *)model loginUserId:(NSString *)loginUserId cellWidth:(CGFloat)cellWidth {
    if (![PLVSAImageEmotionMessageCell isModelValid:model] || cellWidth == 0) {
        self.cellWidth = 0;
        return;
    }
    
    self.cellWidth = cellWidth;
    self.model = model;
    
    // KVO
    [self removeObserveMsgState];
    [self addObserveMsgState];
    
    // 设置用户Id
    if (loginUserId && [loginUserId isKindOfClass:[NSString class]] && loginUserId.length > 0) {
        self.loginUserId = loginUserId;
    }
    // 设置消息状态
    if ([self.model message]) {
        PLVImageEmotionMessage *message = (PLVImageEmotionMessage *)[self.model message];
        self.msgState = message.sendState;
    }

    // 设置昵称文本
    NSMutableAttributedString *nickLabelString = [PLVSAImageEmotionMessageCell nickLabelAttributedStringWithUser:model.user
                                                                                         loginUserId:self.loginUserId];
    self.nickLabel.attributedText = nickLabelString;
    
    self.prohibitImageView.hidden = ![model isProhibitMsg];
    // 如果是违规图片，设置本地图片
    if ([model isProhibitMsg]) {
        [self dealProhibitWordTipWithModel:model];
    } else {
        [self loadImageWithModel:model];
    }
}

#pragma mark 根据数据源设置cell视图
- (void)dealProhibitWordTipWithModel:(PLVChatModel *)model {
    [self.chatImageView setImage:[PLVSAUtils imageForChatroomResource:@"plvsa_chatroom_cell_image_error"]];
    
    self.prohibitImageView.hidden = NO;

    // 严禁词提示
    if (!model.prohibitWordTipIsShowed) {
    
        self.prohibitWordTipView.hidden = NO;
        [self.prohibitWordTipView setTipType:PLVSAProhibitWordTipTypeImage prohibitWord:model.prohibitWord];
        [self.prohibitWordTipView show];
        
        __weak typeof(self)weakSelf = self;
        self.prohibitWordTipView.dismissBlock = ^{
            weakSelf.model.prohibitWordTipShowed = YES;
            if (weakSelf.dismissHandler) {
                weakSelf.dismissHandler();
            }
        };
        
    }else{
        self.prohibitWordTipView.hidden = YES;
    }
}

- (void)loadImageWithModel:(PLVChatModel *)model {
    PLVImageEmotionMessage *message = (PLVImageEmotionMessage *)model.message;
    NSURL *imageURL = [PLVSAImageEmotionMessageCell imageURLWithMessage:message];
    UIImage *placeHolderImage = [PLVSAUtils imageForChatroomResource:@"plvsa_chatroom_cell_image_placeholder"];
    if (imageURL) {
        self.imageLoadState = PLVChatMsgStateImageLoading;
        
        __weak typeof(self) weakSelf = self;
        [self.chatImageView sd_setImageWithURL:imageURL placeholderImage:placeHolderImage completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
            weakSelf.imageLoadState = image ? PLVChatMsgStateImageLoadSuccess : PLVChatMsgStateImageLoadFail;
        }];
    } else {
        [self.chatImageView setImage:placeHolderImage];
    }
}

+ (CGFloat)cellHeightWithModel:(PLVChatModel *)model loginUserId:(NSString *)loginUserId cellWidth:(CGFloat)cellWidth{
    if (![PLVSAImageEmotionMessageCell isModelValid:model] || cellWidth == 0) {
        return 0;
    }
    
    CGFloat originY = 8.0;
    CGFloat bubbleXPadding = 8.0; // 气泡与nickLabel的左右内间距
    CGFloat maxViewWidth = cellWidth - bubbleXPadding * 2;
    
    
    NSMutableAttributedString *nickAttributeString = [PLVSAImageEmotionMessageCell nickLabelAttributedStringWithUser:model.user
                                                                                              loginUserId:loginUserId];
    
    CGSize nickLabelSize = [nickAttributeString boundingRectWithSize:CGSizeMake(maxViewWidth, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:nil].size;
    
    CGFloat nickLabelHeight = MAX(16, ceil(nickLabelSize.height));
    nickLabelHeight += originY + 8;
    
    originY += MAX(ceilf(ceilf(nickLabelSize.height)), 16) + 8;
    
    
    // 违禁提示语高度
    if ([model isProhibitMsg]) {
        // 设置为本地图片36*36
        originY += 36 + 8;
        if (!model.prohibitWordTipIsShowed) {
            originY += 8 + 38;
        }
    } else{
        originY += 8;
        
        CGSize imageViewSize = [PLVSAImageEmotionMessageCell calculateImageViewSizeWithMessage:model.message];

        originY += imageViewSize.height + 4;
    }
    
    return 8 + originY;
}

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

#pragma mark - [ Private Method ]

#pragma mark Getter

- (UIView *)bubbleView {
    if (!_bubbleView) {
        _bubbleView = [[UIView alloc] init];
        _bubbleView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.2];
        _bubbleView.layer.cornerRadius = 8.0;
        _bubbleView.layer.masksToBounds = YES;
    }
    return _bubbleView;
}

- (UILabel *)nickLabel {
    if (!_nickLabel) {
        _nickLabel = [[UILabel alloc] init];
        _nickLabel.font = [UIFont systemFontOfSize:12];
        _nickLabel.numberOfLines = 0;
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

- (UIImageView *)prohibitImageView {
    if (!_prohibitImageView) {
        _prohibitImageView = [[UIImageView alloc] init];
        _prohibitImageView.image = [PLVSAUtils imageForChatroomResource:@"plvsa_chatroom_cell_icon_error"];
        _prohibitImageView.hidden = YES;
    }
    return _prohibitImageView;
}

- (PLVSAProhibitWordTipView *)prohibitWordTipView {
    if (!_prohibitWordTipView) {
        _prohibitWordTipView = [[PLVSAProhibitWordTipView alloc] init];
    }
    return _prohibitWordTipView;
}

- (UIButton *)resendButton {
    if (!_resendButton) {
        _resendButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _resendButton.backgroundColor = [UIColor colorWithWhite:0 alpha:0.4];
        _resendButton.titleLabel.textColor = [UIColor whiteColor];
        _resendButton.titleLabel.font = [UIFont systemFontOfSize:12];
        [_resendButton setTitle:@"重新发送" forState:UIControlStateNormal];
        [_resendButton setImage:[PLVSAUtils imageForChatroomResource:@"plvsa_chatroom_cell_image_resend"] forState:UIControlStateNormal];
        _resendButton.hidden = YES;
        [_resendButton addTarget:self action:@selector(resendButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _resendButton;
}

- (UIButton *)reloadButton {
    if (!_reloadButton) {
        _reloadButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _reloadButton.backgroundColor = [UIColor colorWithWhite:0 alpha:0.4];
        _reloadButton.titleLabel.textColor = [UIColor whiteColor];
        _reloadButton.titleLabel.font = [UIFont systemFontOfSize:12];
        [_reloadButton setTitle:@"重新加载" forState:UIControlStateNormal];
        [_reloadButton setImage:[PLVSAUtils imageForChatroomResource:@"plvsa_chatroom_cell_image_reload"] forState:UIControlStateNormal];
        _reloadButton.hidden = YES;
        [_reloadButton addTarget:self action:@selector(reloadButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _reloadButton;
}

- (UIActivityIndicatorView *)sendingIndicatorView {
    if (!_sendingIndicatorView) {
        _sendingIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        _sendingIndicatorView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.4];
        _sendingIndicatorView.hidden = YES;
    }
    return _sendingIndicatorView;
}
#pragma mark Setter

- (void)setMsgState:(PLVImageEmotionMessageSendState)msgState {
    _msgState = msgState;
    
    switch (msgState) {
        case PLVImageEmotionMessageSendStateFailed:
            self.resendButton.hidden = NO;
            break;
        case PLVImageEmotionMessageSendStateSuccess: {
            self.resendButton.hidden = YES;
            plv_dispatch_main_async_safe(^{
                [self.sendingIndicatorView startAnimating];
            })
        }
            break;
        case PLVImageEmotionMessageSendStateReady:
            self.resendButton.hidden = YES;
            break;
        default:
            break;
    }
}

- (void)setImageLoadState:(PLVChatMsgState)imageLoadState {
    _imageLoadState = imageLoadState;
    //消息发送失败则不需要关注图片加载情况
    if (_msgState == PLVImageEmotionMessageSendStateFailed ||
        _msgState == PLVImageEmotionMessageSendStateReady) return;
    if (imageLoadState == PLVChatMsgStateImageLoadFail) {
        [self.sendingIndicatorView stopAnimating];
        self.resendButton.hidden = YES;
        self.reloadButton.hidden = NO;
    } else if(imageLoadState == PLVChatMsgStateImageLoading){
        self.reloadButton.hidden = YES;
        [self.sendingIndicatorView startAnimating];
    } else {
        [self.sendingIndicatorView stopAnimating];
        self.resendButton.hidden = YES;
        self.reloadButton.hidden = YES;
    }
}

#pragma mark AttributedString

/// 获取昵称多属性文本
+ (NSMutableAttributedString *)nickLabelAttributedStringWithUser:(PLVChatUser *)user
                                              loginUserId:(NSString *)loginUserId {
    if (!user.userName || ![user.userName isKindOfClass:[NSString class]] || user.userName.length == 0) {
        return nil;
    }
    
    NSString *content = user.userName;
    if (user.userId && [user.userId isKindOfClass:[NSString class]] &&
        loginUserId && [loginUserId isKindOfClass:[NSString class]] && [loginUserId isEqualToString:user.userId]) {
        content = [content stringByAppendingString:@"（我）"];
    }
    content = [content stringByAppendingString:@"："];
    
    NSString *colorHexString = [user isUserSpecial] ? @"#FFCA43" : @"#4399FF";
    UIFont *font = [UIFont systemFontOfSize:12.0];
    NSDictionary *attributeDict = @{
                                    NSFontAttributeName: font,
                                    NSForegroundColorAttributeName:[PLVColorUtil colorFromHexString:colorHexString]
    };
    NSMutableAttributedString *contentLabelString = [[NSMutableAttributedString alloc] initWithString:content attributes:attributeDict];
    
    // 特殊身份头衔
    if (user.actor &&
        [user.actor isKindOfClass:[NSString class]] &&
        user.actor.length > 0 &&
        [PLVSABaseMessageCell showActorLabelWithUser:user]) {
        
        UIImage *image = [PLVSABaseMessageCell actorImageWithUser:user];
        //创建Image的富文本格式
        NSTextAttachment *attach = [[NSTextAttachment alloc] init];
        CGFloat paddingTop = font.lineHeight - font.pointSize + 1;
        attach.bounds = CGRectMake(0, -ceilf(paddingTop), image.size.width, image.size.height);
        attach.image = image;
        //添加到富文本对象里
        NSAttributedString * imageStr = [NSAttributedString attributedStringWithAttachment:attach];
        [contentLabelString insertAttributedString:[[NSAttributedString alloc] initWithString:@" "] atIndex:0];
        [contentLabelString insertAttributedString:imageStr atIndex:0];
    }
    return contentLabelString;
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
#pragma mark Data Model
/// 获取图片URL
+ (NSURL *)imageURLWithMessage:(PLVImageEmotionMessage *)message {
    NSString *imageUrl = message.imageUrl;
    if (!imageUrl || ![imageUrl isKindOfClass:[NSString class]] || imageUrl.length == 0) {
        return nil;
    }
    
    return [NSURL URLWithString:imageUrl];
}
//图片表情是固定的大小
+ (CGSize)calculateImageViewSizeWithMessage:(PLVImageEmotionMessage *)message {
    CGFloat maxLength = 80.0;
    return CGSizeMake(maxLength, maxLength);
}

+ (NSString *)prohibitWordTip {
    return @"图片不合法";
}

- (void)setButtonInsets:(UIButton *) button {
    UIButton *but =button;
    but.titleEdgeInsets = UIEdgeInsetsZero;
    but.imageEdgeInsets = UIEdgeInsetsZero;
    
    CGFloat padding = (but.frame.size.height > but.frame.size.width) ? -6 : 6;
    [but setTitleEdgeInsets:
     UIEdgeInsetsMake(but.frame.size.height/2 + padding,
                      (but.frame.size.width-but.titleLabel.intrinsicContentSize.width)/2-but.imageView.frame.size.width,
                      0,
                      (but.frame.size.width-but.titleLabel.intrinsicContentSize.width)/2)];
    [but setImageEdgeInsets:
     UIEdgeInsetsMake(
                      0,
                      (but.frame.size.width-but.imageView.frame.size.width)/2,
                      but.titleLabel.intrinsicContentSize.height,
                      (but.frame.size.width-but.imageView.frame.size.width)/2)];
}

#pragma mark - Event

#pragma mark Action

- (void)resendButtonAction {
    // 只有在发送失败方可触发重发点击事件，避免重复发送
    if (self.resendImageEmotionHandler &&
        self.msgState == PLVImageEmotionMessageSendStateFailed) {
        PLVImageEmotionMessage *message = (PLVImageEmotionMessage *)[self.model message];
        if (message) {
            __weak typeof(self) weakSelf = self;
            [PLVSAUtils showAlertWithMessage:@"重发该消息？" cancelActionTitle:@"取消" cancelActionBlock:nil confirmActionTitle:@"确定" confirmActionBlock:^{
                weakSelf.model.msgState = PLVChatMsgStateSending;
                weakSelf.resendImageEmotionHandler(message.imageId, message.imageUrl);
            }];
        }
    }
}

- (void)reloadButtonAction {
    [self loadImageWithModel:self.model];
}

#pragma mark Gesture

- (void)tapImageViewAction {
    [self.photoBrowser scaleImageViewToFullScreen:self.chatImageView];
}

#pragma mark - KVO

- (void)addObserveMsgState {
    if (!self.observingMsgState &&
        self.model) {
        self.observingMsgState = YES;
        [(PLVImageEmotionMessage *)[self.model message] addObserver:self forKeyPath:KEYPATH_EMOTIONMSGSTATE options:NSKeyValueObservingOptionNew context:nil];
    }
}

- (void)removeObserveMsgState {
    if (self.observingMsgState &&
        self.model) {
        self.observingMsgState = NO;
        [(PLVImageEmotionMessage *)[self.model message]  removeObserver:self forKeyPath:KEYPATH_EMOTIONMSGSTATE];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if (object == [self.model message] &&
        [keyPath isEqual:KEYPATH_EMOTIONMSGSTATE]) {
        
        self.msgState = (PLVImageEmotionMessageSendState)[[change objectForKey:NSKeyValueChangeNewKey] integerValue];
        
    }
}

@end
