//
//  PLVLCLandscapeImageEmotionCell.m
//  PLVLiveScenesDemo
//
//  Created by Sakya on 2021/7/8.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVLCLandscapeImageEmotionCell.h"
#import "PLVPhotoBrowser.h"
#import "PLVLCUtils.h"
#import "PLVMultiLanguageManager.h"
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>
#import <PLVFoundationSDK/PLVFoundationSDK.h>

@interface PLVLCLandscapeImageEmotionCell ()

#pragma mark UI
 
@property (nonatomic, strong) UILabel *nickLabel; /// 发出消息用户昵称
@property (nonatomic, strong) UIImageView *chatImageView; /// 聊天消息图片
@property (nonatomic, strong) PLVPhotoBrowser *photoBrowser; /// 消息图片Browser

@end

@implementation PLVLCLandscapeImageEmotionCell

#pragma mark - [ Life Cycle ]

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.allowReply = YES;
        
        [self.contentView addSubview:self.nickLabel];
        [self.contentView addSubview:self.chatImageView];
        
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
    
    CGSize imageViewSize = [PLVLCLandscapeImageEmotionCell calculateImageViewSizeWithMessage:self.model.message];
    self.chatImageView.frame = CGRectMake(originX, originY, imageViewSize.width, imageViewSize.height);
    originY += imageViewSize.height + 4;
    
    CGFloat bubbleWidth = MAX(nickLabelSize.width, imageViewSize.width) + bubbleXPadding * 2;
    self.bubbleView.frame = CGRectMake(0, 0, bubbleWidth, originY);
}

#pragma mark - [ Public Method ]

- (void)updateWithModel:(PLVChatModel *)model loginUserId:(NSString *)loginUserId cellWidth:(CGFloat)cellWidth {
    if (![PLVLCLandscapeImageEmotionCell isModelValid:model] || cellWidth == 0) {
        self.cellWidth = 0;
        return;
    }
    
    self.cellWidth = cellWidth;
    self.model = model;
    
    // 设置昵称文本
    // 设置昵称文本
    NSMutableAttributedString *nickLabelString;
    if (model.landscapeAttributeString) {
        // 如果在 model 中已经存在计算好的 横屏 消息多属性文本 ，那么 就直接使用；
        nickLabelString = model.landscapeAttributeString;
    } else {
        nickLabelString = [[NSMutableAttributedString alloc] initWithAttributedString:[PLVLCLandscapeImageEmotionCell nickLabelAttributedStringWithUser:model.user
                                                                                                                                            loginUserId:loginUserId]];
        model.landscapeAttributeString = nickLabelString;
    }
    
    self.nickLabel.attributedText = nickLabelString;
    
    PLVImageEmotionMessage *message = (PLVImageEmotionMessage *)model.message;
    NSURL *imageURL = [PLVLCLandscapeImageEmotionCell imageURLWithMessage:message];
    UIImage *placeHolderImage = [PLVColorUtil createImageWithColor:[PLVColorUtil colorFromHexString:@"#777786"]];
    if (imageURL) {
        [PLVLCUtils setImageView:self.chatImageView url:imageURL placeholderImage:placeHolderImage options:SDWebImageRetryFailed];
    } else {
        [self.chatImageView setImage:placeHolderImage];
    }
}

+ (CGFloat)cellHeightWithModel:(PLVChatModel *)model loginUserId:(NSString *)loginUserId cellWidth:(CGFloat)cellWidth {
    if (![PLVLCLandscapeImageEmotionCell isModelValid:model] || cellWidth == 0) {
        return 0;
    }
    
    CGFloat bubbleYPadding = 4.0; // 气泡与nickLabel的左右内间距
    CGFloat nickLabelHeight = 16.0; // nickLabel高度
    CGSize imageViewSize = [PLVLCLandscapeImageEmotionCell calculateImageViewSizeWithMessage:model.message];
    return bubbleYPadding + nickLabelHeight + 4 + imageViewSize.height + bubbleYPadding + 5; // nickLabel跟图片之间距离4，气泡底部外间距5
}

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

#pragma mark - [ Private Methods ]

/// 生成昵称多属性文本
+ (NSAttributedString *)nickLabelAttributedStringWithUser:(PLVChatUser *)user
                                              loginUserId:(NSString *)loginUserId {
    if (!user.userName || ![user.userName isKindOfClass:[NSString class]] || user.userName.length == 0) {
        return nil;
    }
    
    NSString *content = user.userName;
    if (user.userId && [user.userId isKindOfClass:[NSString class]] &&
        loginUserId && [loginUserId isKindOfClass:[NSString class]] && [loginUserId isEqualToString:user.userId]) {
        content = [content stringByAppendingString:PLVLocalizedString(@"（我）")];
    }
    if (user.actor && [user.actor isKindOfClass:[NSString class]] && user.actor.length > 0) {
        content = [NSString stringWithFormat:@"%@-%@", user.actor, content];
    }
    content = [content stringByAppendingString:@"："];
    
    NSString *colorHexString = [user isUserSpecial] ? @"#FFD36D" : @"#6DA7FF";
    NSDictionary *attributeDict = @{
                                    NSFontAttributeName: [UIFont systemFontOfSize:14.0],
                                    NSForegroundColorAttributeName:[PLVColorUtil colorFromHexString:colorHexString]
    };
    NSAttributedString *string = [[NSAttributedString alloc] initWithString:content attributes:attributeDict];
    return string;
}

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

#pragma mark Getter

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

#pragma mark - [ Event ]

#pragma mark Action

- (void)tapImageViewAction {
    [self.photoBrowser scaleImageViewToFullScreen:self.chatImageView];
}


@end
