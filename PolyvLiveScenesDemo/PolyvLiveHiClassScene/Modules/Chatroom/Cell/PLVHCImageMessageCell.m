//
//  PLVHCImageMessageCell.m
//  PolyvLiveScenesDemo
//
//  Created by lijingtong on 2021/6/25.
//  Copyright © 2021 polyv. All rights reserved.
//

#import "PLVHCImageMessageCell.h"

// 工具
#import "PLVPhotoBrowser.h"
#import "PLVHCUtils.h"

// UI
#import "PLVHCProhibitWordTipView.h"

// 模块
#import "PLVChatModel.h"

// 依赖库
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>
#import <PLVFoundationSDK/PLVFoundationSDK.h>
#import <SDWebImage/UIImageView+WebCache.h>

@interface PLVHCImageMessageCell()

// Data
@property (nonatomic, assign) CGFloat cellWidth; // cell宽度
@property (nonatomic, strong) NSString *loginUserId; // 用户的聊天室userId
@property (nonatomic, assign) PLVImageMessageSendState msgState; // 消息状态
@property (nonatomic, assign) PLVChatMsgState imageLoadState; // 图片加载状态

// UI
@property (nonatomic, strong) UIImageView *chatImageView; // 聊天消息图片
@property (nonatomic, strong) PLVPhotoBrowser *photoBrowser; // 消息图片Browser

@property (nonatomic, strong) UIImageView *prohibitImageView;  // 严禁图片提示
@property (nonatomic, strong) PLVHCProhibitWordTipView *prohibitWordTipView; // 严禁词提示视图

@property (nonatomic, strong) UIActivityIndicatorView *sendingIndicatorView; // 正在发送提示视图
@property (nonatomic, strong) UIButton *resendButton; // 重新发送按钮
@property (nonatomic, strong) UIButton *reloadButton; // 重新加载按钮
@property (nonatomic, strong) UIImageView *headerImageView; // 头像视图
@property (nonatomic, strong) UILabel *nickNameLabel;; // 昵称视图

@end

static NSString *KEYPATH_MSGSTATE = @"sendState";
static NSString *otherCellId = @"PLVHCImageMessageCell_Other";
static NSString *selfCellId = @"PLVHCImageMessageCell_Self";

static CGFloat kCellTopMargin = 10;

@implementation PLVHCImageMessageCell


#pragma mark - [ Life Cycle ]

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.allowReply = YES;
        self.menuSuperView = self.chatImageView;
        
        [self.contentView addSubview:self.headerImageView];
        [self.contentView addSubview:self.nickNameLabel];
        
        [self.contentView addSubview:self.chatImageView];
        
        [self.contentView addSubview:self.prohibitImageView];
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
    
    CGFloat bubbleXPadding = 8.0; // 气泡与nickLabel的左右内间距
    CGFloat headerWidth = 30;
    CGFloat maxViewWidth = self.cellWidth - bubbleXPadding * 2 - headerWidth - bubbleXPadding;
    CGSize nickNameViewSize = CGSizeMake(maxViewWidth, 17);

    NSAttributedString *attri = [PLVHCImageMessageCell contentLabelAttributedStringWithProhibitWordTip:[PLVHCImageMessageCell prohibitWordTip]];
    CGSize tipSize = [attri boundingRectWithSize:CGSizeMake(maxViewWidth, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:nil].size;
    tipSize = CGSizeMake(tipSize.width + bubbleXPadding * 2, tipSize.height + 20);
    
    CGSize imageViewSize;
    if ([self.model isProhibitMsg]) {
        imageViewSize = CGSizeMake(36, 36);
    } else {
        imageViewSize = [PLVHCImageMessageCell calculateImageViewSizeWithMessage:self.model.message];
    }
    CGSize bubbleSize = imageViewSize;
    
    CGFloat headerImageViewX;
    CGFloat nickNameLabelX;
    CGFloat bubbleViewX;
    CGFloat tipViewX;
    
    // 自己的发言，右对齐、隐藏昵称；
    if ([PLVHCImageMessageCell isLoginUser:self.model.user.userId]) {
        headerImageViewX = self.cellWidth - headerWidth;
        nickNameLabelX = 0; // 昵称会被隐藏
        nickNameViewSize = CGSizeZero;
        bubbleViewX = self.cellWidth - headerWidth - bubbleXPadding - bubbleSize.width;
        tipViewX = self.cellWidth - headerWidth - tipSize.width;
        
    } else { // 他人的发言，左对齐，显示昵称
        headerImageViewX = 0;
        nickNameLabelX = headerImageViewX + headerWidth + bubbleXPadding;
        bubbleViewX = nickNameLabelX;
        tipViewX = 0;
    }
    
    self.headerImageView.frame = CGRectMake(headerImageViewX, kCellTopMargin, headerWidth, headerWidth);
    
    self.nickNameLabel.frame = CGRectMake(nickNameLabelX, kCellTopMargin, nickNameViewSize.width, nickNameViewSize.height);
  
    self.chatImageView.frame = CGRectMake(bubbleViewX, CGRectGetMaxY(self.nickNameLabel.frame) + 4, ceilf(bubbleSize.width), bubbleSize.height);;
    
    if ([self.model isProhibitMsg] &&
        !self.model.prohibitWordTipIsShowed) {
        _prohibitWordTipView.frame = CGRectMake(tipViewX, CGRectGetMaxY(self.chatImageView.frame), tipSize.width, tipSize.height);
    } else {
        _prohibitWordTipView.frame = CGRectZero;
    }
    
    // 发送状态
    CGRect rect = self.chatImageView.frame;
    self.reloadButton.frame = rect;
    self.sendingIndicatorView.frame = rect;
    self.resendButton.frame = rect;
    
    [self setButtonInsets:self.resendButton];
    [self setButtonInsets:self.reloadButton];
    
}

#pragma mark 覆盖重写BaseMessageCell方法

+ (NSString *)reuseIdentifierWithUser:(PLVChatUser *)user {
    if (!user ||
        ![user isKindOfClass:[PLVChatUser class]] ||
        ![PLVFdUtil checkStringUseable:user.userId]) {
        return nil;
    }
    
    NSString *cellId = nil;
    if ([self isLoginUser:user.userId]) {
        cellId = selfCellId;
    } else {
        cellId = otherCellId;
    }
    
    return cellId;
}

/// 判断model是否为有效类型
+ (BOOL)isModelValid:(PLVChatModel *)model {
    if (!model || ![model isKindOfClass:[PLVChatModel class]]) {
        return NO;
    }
    
    id message = model.message;
    if (!message || ![message isKindOfClass:[PLVImageMessage class]]) {
        return NO;
    }
    
    return YES;
}

#pragma mark - [ Public Method ]

- (void)updateWithModel:(PLVChatModel *)model loginUserId:(NSString *)loginUserId cellWidth:(CGFloat)cellWidth {
    if (![PLVHCImageMessageCell isModelValid:model] || cellWidth == 0) {
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
        PLVImageMessage *message = (PLVImageMessage *)[self.model message];
        self.msgState = message.sendState;
    }

    // 设置昵称文本
    NSMutableAttributedString *nickLabelString = [PLVHCImageMessageCell nickNameLabelAttributedStringWithUser:model.user];
    
    self.nickNameLabel.attributedText = nickLabelString;
    
    self.prohibitImageView.hidden = ![model isProhibitMsg];
    // 如果是违规图片，设置本地图片
    if ([model isProhibitMsg]) {
        [self dealProhibitWordTipWithModel:model];
    } else {
        [self loadImageWithModel:model];
    }
    
    [self loadHeaderImageWithModel:model];
}

#pragma mark 根据数据源设置cell视图
- (void)dealProhibitWordTipWithModel:(PLVChatModel *)model {
    [self.chatImageView setImage:[PLVHCUtils imageForChatroomResource:@"plvhc_chatroom_cell_image_error"]];
    
    self.prohibitImageView.hidden = NO;

    // 严禁词提示
    if (!model.prohibitWordTipIsShowed) {
        [self.prohibitWordTipView setTipType:PLVHCProhibitWordTipTypeImage prohibitWord:model.prohibitWord];
        [self.prohibitWordTipView showInView:self.contentView];
        
        __weak typeof(self)weakSelf = self;
        self.prohibitWordTipView.dismissBlock = ^{
            weakSelf.model.prohibitWordTipShowed = YES;
            if (weakSelf.prohibitWordTipdismissHandler) {
                weakSelf.prohibitWordTipdismissHandler();
            }
        };
    } else {
        if (_prohibitWordTipView) {
            [self.prohibitWordTipView dismissNoCallblck];
        }
    }
}

- (void)loadImageWithModel:(PLVChatModel *)model {
    PLVImageMessage *message = (PLVImageMessage *)model.message;
    NSURL *imageURL = [PLVHCImageMessageCell imageURLWithMessage:message];
    UIImage *placeHolderImage = [PLVHCUtils imageForChatroomResource:@"plvhc_chatroom_cell_image_placeholder"];
    if (imageURL) {
        self.imageLoadState = PLVChatMsgStateImageLoading;
        
        __weak typeof(self) weakSelf = self;
        [self.chatImageView sd_setImageWithURL:imageURL placeholderImage:placeHolderImage completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
            weakSelf.imageLoadState = image ? PLVChatMsgStateImageLoadSuccess : PLVChatMsgStateImageLoadFail;
        }];
    } else if (message.image) {
        [self.chatImageView setImage:message.image];
    } else {
        [self.chatImageView setImage:placeHolderImage];
    }
}

#pragma mark 加载头像
- (void)loadHeaderImageWithModel:(PLVChatModel *)model {
    PLVChatUser *user = model.user;
    
    UIImage *placeHolderImage = [PLVHCUtils imageForChatroomResource:@"plvhc_chatroom_cell_image_placeholder"];
    if (!user ||
        ![user isKindOfClass:[PLVChatUser class]] ||
        ![PLVFdUtil checkStringUseable:user.avatarUrl]) {
        [self.headerImageView setImage:placeHolderImage];
        return;
    }
    
    NSURL *imageURL = [NSURL URLWithString:user.avatarUrl];
    if (imageURL) {
        [self.headerImageView sd_setImageWithURL:imageURL placeholderImage:placeHolderImage];
    } else {
        [self.headerImageView setImage:placeHolderImage];
    }
}


+ (CGFloat)cellHeightWithModel:(PLVChatModel *)model loginUserId:(NSString *)loginUserId cellWidth:(CGFloat)cellWidth{
    if (![PLVHCImageMessageCell isModelValid:model] || cellWidth == 0) {
        return 0;
    }
    
    CGFloat originY = 8.0;
    CGFloat bubbleXPadding = originY; // 气泡与nickLabel的左右内间距
    CGFloat headerWidth = 30;
    CGFloat maxViewWidth = cellWidth - bubbleXPadding * 2 - headerWidth - bubbleXPadding;

    // 违禁提示语高度
    if ([model isProhibitMsg]) {
        // 设置为本地图片36*36
        originY += 36 + 8;
        if (!model.prohibitWordTipIsShowed) {
            originY += 8 + 38;
        }
    } else{
        originY += 8;
        
        CGSize imageViewSize = [PLVHCImageMessageCell calculateImageViewSizeWithMessage:model.message];

        originY += imageViewSize.height + 4;
    }
    
    // 昵称，当前消息为他人发送的才显示，自己的发言隐藏昵称
    if (![self isLoginUser:model.user.userId]) {
        NSMutableAttributedString *nickNameLabelString = [PLVHCImageMessageCell nickNameLabelAttributedStringWithUser:model.user];
        CGSize  nickNameLabelSize = [nickNameLabelString boundingRectWithSize:CGSizeMake(maxViewWidth, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:nil].size;
        originY +=  nickNameLabelSize.height + 4;
    }
    
    return kCellTopMargin + 8 + originY;
}

#pragma mark - [ Private Method ]

#pragma mark Getter


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
        _prohibitImageView.image = [PLVHCUtils imageForChatroomResource:@"plvhc_chatroom_cell_icon_error"];
        _prohibitImageView.hidden = YES;
    }
    return _prohibitImageView;
}

- (PLVHCProhibitWordTipView *)prohibitWordTipView {
    if (!_prohibitWordTipView) {
        _prohibitWordTipView = [[PLVHCProhibitWordTipView alloc] init];
    }
    return _prohibitWordTipView;
}

- (UIButton *)resendButton {
    if (!_resendButton) {
        _resendButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _resendButton.backgroundColor = [UIColor colorWithWhite:0 alpha:0.4];
        _resendButton.titleLabel.textColor = [UIColor whiteColor];
        _resendButton.titleLabel.font = [UIFont systemFontOfSize:10];
        _resendButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
        
        [_resendButton setTitle:@"重新发送" forState:UIControlStateNormal];
        [_resendButton setImage:[PLVHCUtils imageForChatroomResource:@"plvhc_chatroom_cell_image_resend"] forState:UIControlStateNormal];
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
        _reloadButton.titleLabel.font = [UIFont systemFontOfSize:10];
        _reloadButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
        
        [_reloadButton setTitle:@"重新加载" forState:UIControlStateNormal];
        [_reloadButton setImage:[PLVHCUtils imageForChatroomResource:@"plvhc_chatroom_cell_image_reload"] forState:UIControlStateNormal];
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

- (UIImageView *)headerImageView {
    if (!_headerImageView) {
        _headerImageView = [[UIImageView alloc] init];
        _headerImageView.layer.cornerRadius = 15;
        _headerImageView.layer.masksToBounds = YES;
    }
    return _headerImageView;
}

- (UILabel *)nickNameLabel {
    if (!_nickNameLabel) {
        _nickNameLabel = [[UILabel alloc] init];
        _nickNameLabel.numberOfLines = 1;
        _nickNameLabel.font = [UIFont systemFontOfSize:12];
    }
    return _nickNameLabel;
}

#pragma mark Setter

- (void)setMsgState:(PLVImageMessageSendState)msgState {
    _msgState = msgState;
    
    BOOL showResendButton = NO;
    BOOL showSendingButton = NO;
    
    switch (msgState) {
        case PLVImageMessageSendStateFailed:
            showResendButton = YES;
            break;
        case PLVImageMessageSendStateSuccess:
            break;
        case PLVImageMessageSendStateReady: {
            PLVImageMessage *message = (PLVImageMessage *)[self.model message];
            if (message.sendState == PLVImageUploadStateSuccess) {
                showSendingButton = YES;
            }
        } break;
        default:
            break;
    }
    
    plv_dispatch_main_async_safe(^{
        self.resendButton.hidden = !showResendButton;
        if (showSendingButton) {
            [self.sendingIndicatorView startAnimating];
        } else {
            [self.sendingIndicatorView stopAnimating];
        }
    })
}

- (void)setImageLoadState:(PLVChatMsgState)imageLoadState {
    _imageLoadState = imageLoadState;
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
+ (NSMutableAttributedString *)nickNameLabelAttributedStringWithUser:(PLVChatUser *)user {
 
    UIFont *font = [UIFont systemFontOfSize:12.0];
    NSDictionary *nickNameAttDict = @{NSFontAttributeName: font,
                                      NSForegroundColorAttributeName: [PLVColorUtil colorFromHexString:@"#8D909A"]};
    
    NSMutableAttributedString *nickNameAttributedString = [[NSMutableAttributedString alloc] initWithString: user.userName attributes:nickNameAttDict];
    
    // 特殊身份头衔
    if (user.actor &&
        [user.actor isKindOfClass:[NSString class]] &&
        user.actor.length > 0 &&
        [PLVHCBaseMessageCell showActorLabelWithUser:user]) {
        
        UIImage *image = [PLVHCBaseMessageCell actorImageWithUser:user];
        //创建Image的富文本格式
        NSTextAttachment *attach = [[NSTextAttachment alloc] init];
        CGFloat paddingTop = font.lineHeight - font.pointSize + 1;
        attach.bounds = CGRectMake(0, -ceilf(paddingTop), image.size.width, image.size.height);
        attach.image = image;
        //添加到富文本对象里
        NSAttributedString * imageStr = [NSAttributedString attributedStringWithAttachment:attach];
        [nickNameAttributedString insertAttributedString:[[NSAttributedString alloc] initWithString:@" "] atIndex:0];
        [nickNameAttributedString insertAttributedString:imageStr atIndex:0];
    }
    
    return nickNameAttributedString;
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
+ (NSURL *)imageURLWithMessage:(PLVImageMessage *)message {
    NSString *imageUrl = message.imageUrl;
    if (!imageUrl || ![imageUrl isKindOfClass:[NSString class]] || imageUrl.length == 0) {
        return nil;
    }
    
    return [NSURL URLWithString:imageUrl];
}

+ (CGSize)calculateImageViewSizeWithMessage:(PLVImageMessage *)message {
    CGSize imageSize = message.imageSize;
    CGFloat maxLength = 80.0;
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
    // 只有在发送失败时方可触发重发点击事件，避免重复发送
    if (self.msgState == PLVImageMessageSendStateFailed) {
        __weak typeof(self) weakSelf = self;
        [PLVHCUtils showAlertWithMessage:@"重发该消息？" cancelActionTitle:@"取消" cancelActionBlock:nil confirmActionTitle:@"确定" confirmActionBlock:^{
            weakSelf.model.msgState = (PLVChatMsgState)PLVImageMessageSendStateReady;
            if (weakSelf.resendImageHandler) {
                weakSelf.resendImageHandler(weakSelf.model);
            }
        }];
    } else {
        self.resendButton.hidden = YES;
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
        [(PLVImageMessage *)[self.model message] addObserver:self forKeyPath:KEYPATH_MSGSTATE options:NSKeyValueObservingOptionNew context:nil];
    }
}

- (void)removeObserveMsgState {
    if (self.observingMsgState &&
        self.model) {
        self.observingMsgState = NO;
        [(PLVImageMessage *)[self.model message]  removeObserver:self forKeyPath:KEYPATH_MSGSTATE];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if (object == [self.model message] &&
        [keyPath isEqual:KEYPATH_MSGSTATE]) {
        
        self.msgState = (PLVImageMessageSendState)[[change objectForKey:NSKeyValueChangeNewKey] integerValue];
        
    }
}
@end
