//
//  PLVLSImageMessageCell.m
//  PLVLiveStreamerDemo
//
//  Created by MissYasiky on 2021/3/18.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVLSImageMessageCell.h"

// 工具类
#import "PLVLSUtils.h"

// UI
#import "PLVPhotoBrowser.h"
#import "PLVLSProhibitWordTipView.h"

// 模块
#import "PLVChatModel.h"

// 依赖库
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>
#import <PLVFoundationSDK/PLVFoundationSDK.h>

@interface PLVLSImageMessageCell ()

#pragma mark UI
 
@property (nonatomic, strong) UILabel *nickLabel; /// 发出消息用户昵称
@property (nonatomic, strong) UIImageView *chatImageView; /// 聊天消息图片
@property (nonatomic, strong) UIView *bubbleView; /// 背景气泡
@property (nonatomic, strong) PLVPhotoBrowser *photoBrowser; /// 消息图片Browser
@property (nonatomic, strong) UIImageView *prohibitImageView;  // 违规图提示
@property (nonatomic, strong) PLVLSProhibitWordTipView *prohibitWordTipView; // 违规图提示视图

#pragma mark 数据

@property (nonatomic, assign) CGFloat cellWidth; /// cell宽度
@property (nonatomic, strong) NSString *loginUserId; /// 登录用户的聊天室userId

@end

@implementation PLVLSImageMessageCell

#pragma mark - Life Cycle

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.allowReply = YES;
        
        [self.contentView addSubview:self.bubbleView];
        [self.contentView addSubview:self.nickLabel];
        [self.contentView addSubview:self.chatImageView];
        [self.contentView addSubview:self.prohibitImageView];
        
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
    originY += 16 + 8; // nickLabel跟图片之间距离8
    
    CGFloat bubbleWidth;
    if ([self.model isProhibitMsg]) {
        // 设置为本地图片36*36
        self.chatImageView.frame = CGRectMake(originX, originY, 36, 36);
        originY += 36 + 4;
        // 设置 bubbleWidth
        bubbleWidth = MAX(nickLabelSize.width, 36) + bubbleXPadding * 2;
        
        // 提示图标
        self.prohibitImageView.frame = CGRectMake(CGRectGetMaxX(self.chatImageView.frame) - 7, CGRectGetMaxY(self.chatImageView.frame) - 14, 14, 14);
        
        if (!self.model.prohibitWordTipIsShowed) {
            self.prohibitWordTipView.frame = CGRectMake(0, originY + 4, 80, 38);
        } else {
            self.prohibitWordTipView.frame = CGRectZero;
        }
    } else {
        CGSize imageViewSize = [PLVLSImageMessageCell calculateImageViewSizeWithMessage:self.model.message];
        self.chatImageView.frame = CGRectMake(originX, originY, imageViewSize.width, imageViewSize.height);
        originY += imageViewSize.height + 8;
        
        bubbleWidth = MAX(nickLabelSize.width, imageViewSize.width) + bubbleXPadding * 2;
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
        _nickLabel.font = [UIFont systemFontOfSize:12];
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
        _prohibitImageView.image = [PLVLSUtils imageForChatroomResource:@"plvls_chatroom_signal_error_icon"];
        _prohibitImageView.hidden = YES;
    }
    return _prohibitImageView;
}

- (PLVLSProhibitWordTipView *)prohibitWordTipView {
    if (!_prohibitWordTipView) {
        _prohibitWordTipView = [[PLVLSProhibitWordTipView alloc] init];
    }
    return _prohibitWordTipView;
}

#pragma mark - UI

- (void)updateWithModel:(PLVChatModel *)model loginUserId:(NSString *)loginUserId cellWidth:(CGFloat)cellWidth {
    if (![PLVLSImageMessageCell isModelValid:model] || cellWidth == 0) {
        self.cellWidth = 0;
        return;
    }
    
    self.cellWidth = cellWidth;
    self.model = model;
    if (loginUserId && [loginUserId isKindOfClass:[NSString class]] && loginUserId.length > 0) {
        self.loginUserId = loginUserId;
    }
    
    PLVImageMessage *message = (PLVImageMessage *)model.message;
    // 设置昵称文本
    NSAttributedString *nickLabelString = [PLVLSImageMessageCell nickLabelAttributedStringWithUser:model.user
                                                                                         loginUserId:self.loginUserId source:message.source];
    self.nickLabel.attributedText = nickLabelString;
    
    self.prohibitImageView.hidden = ![model isProhibitMsg];
    // 如果是违规图片，设置本地图片
    if ([model isProhibitMsg]) {
        [self dealProhibitWordTipWithModel:model];
    } else {
        [self loadImageWithModel:model];
    }
}

#pragma mark UI - ViewModel

/// 获取昵称多属性文本
+ (NSAttributedString *)nickLabelAttributedStringWithUser:(PLVChatUser *)user
                                              loginUserId:(NSString *)loginUserId
                                                   source:(NSString *)source {
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
    UIFont *font = [UIFont systemFontOfSize:12.0];
    NSString *colorHexString = [user isUserSpecial] ? @"#FFCA43" : @"#4399FF";
    NSDictionary *attributeDict = @{
                                    NSFontAttributeName: font,
                                    NSForegroundColorAttributeName:[PLVColorUtil colorFromHexString:colorHexString]
    };
    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:content attributes:attributeDict];
    // 提醒消息
    if ([PLVFdUtil checkStringUseable:source] &&
        [source isEqualToString:@"extend"]) {
        
        UIImage *image = [PLVLSUtils imageForChatroomResource:@"plvls_chatroom_remind_tag"];
        //创建Image的富文本格式
        NSTextAttachment *attach = [[NSTextAttachment alloc] init];
        CGFloat paddingTop = font.lineHeight - font.pointSize + 1;
        attach.bounds = CGRectMake(0, -ceilf(paddingTop), image.size.width, image.size.height);
        attach.image = image;
        //添加到富文本对象里
        NSAttributedString * imageStr = [NSAttributedString attributedStringWithAttachment:attach];
        [string insertAttributedString:[[NSAttributedString alloc] initWithString:@" "] atIndex:0];
        [string insertAttributedString:imageStr atIndex:0];
    }
    
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
    if (![PLVLSImageMessageCell isModelValid:model] || cellWidth == 0) {
        return 0;
    }
    
    CGFloat bubbleYPadding = 4.0; // 气泡与nickLabel的左右内间距
    CGFloat nickLabelHeight = 16.0; // nickLabel高度
    CGSize imageViewSize = [PLVLSImageMessageCell calculateImageViewSizeWithMessage:model.message];
    CGFloat prohibitTipHeight = 0; // 违禁提示语高度
    if ([model isProhibitMsg]) {
        imageViewSize = CGSizeMake(36, 36);
        if (!model.prohibitWordTipIsShowed) {
            prohibitTipHeight = 8 + 38 + 4;
        }
    } else {
        prohibitTipHeight = 8;
    }
    return bubbleYPadding + nickLabelHeight + 8 + imageViewSize.height + prohibitTipHeight + bubbleYPadding + 4; // nickLabel跟图片之间距离4，气泡底部外间距4
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

#pragma mark 根据数据源设置cell视图

- (void)dealProhibitWordTipWithModel:(PLVChatModel *)model {
    [self.chatImageView setImage:[PLVLSUtils imageForChatroomResource:@"plvls_chatroom_signal_error_img_icon"]];
    
    self.prohibitImageView.hidden = NO;

    // 严禁图提示
    if (!model.prohibitWordTipIsShowed) {
    
        self.prohibitWordTipView.hidden = NO;
        [self.prohibitWordTipView setTipType:PLVLSProhibitWordTipTypeImage prohibitWord:model.prohibitWord];
        [self.prohibitWordTipView showWithSuperView:self.contentView];
        
        __weak typeof(self)weakSelf = self;
        self.prohibitWordTipView.dismissBlock = ^{
            weakSelf.model.prohibitWordTipShowed = YES;
            if (weakSelf.prohibitWordDismissHandler) {
                weakSelf.prohibitWordDismissHandler();
            }
        };
        
    }else{
        self.prohibitWordTipView.hidden = YES;
    }
}

- (void)loadImageWithModel:(PLVChatModel *)model {
    PLVImageMessage *message = (PLVImageMessage *)model.message;
    NSURL *imageURL = [PLVLSImageMessageCell imageURLWithMessage:message];
    UIImage *placeHolderImage = [PLVColorUtil createImageWithColor:[PLVColorUtil colorFromHexString:@"#777786"]];
    if (imageURL) {
        [PLVLSUtils setImageView:self.chatImageView url:imageURL placeholderImage:placeHolderImage];
    } else if (message.image) {
        [self.chatImageView setImage:message.image];
    } else {
        [self.chatImageView setImage:placeHolderImage];
    }
}

#pragma mark - Action

- (void)tapImageViewAction {
    if (self.model.isProhibitMsg) {
        if (self.model.prohibitWordTipShowed) { // 已显示过的提示，点击可以重复提示
            self.model.prohibitWordTipShowed = NO;
            self.prohibitWordShowHandler ? self.prohibitWordShowHandler() : nil;
        }
    } else {
        [self.photoBrowser scaleImageViewToFullScreen:self.chatImageView];
    }
}

#pragma mark - Utils

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

+ (NSString *)prohibitWordTip {
    return @"图片不合法";
}

@end
