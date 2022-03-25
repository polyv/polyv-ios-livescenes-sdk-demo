//
//  PLVLCImageEmotionMessageCell.m
//  PLVLiveScenesDemo
//
//  Created by Sakya on 2021/7/8.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVLCImageEmotionMessageCell.h"
#import "PLVPhotoBrowser.h"
#import <PLVLiveScenesSDK/PLVImageEmotionMessage.h>
#import <PLVFoundationSDK/PLVColorUtil.h>
#import <SDWebImage/UIImageView+WebCache.h>


@interface PLVLCImageEmotionMessageCell ()

@property (nonatomic, strong) UIImageView *chatImageView; /// 聊天消息图片

@property (nonatomic, strong) PLVPhotoBrowser *photoBrowser; /// 消息图片Browser

@end

@implementation PLVLCImageEmotionMessageCell

#pragma mark - Life Cycle

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self.contentView addSubview:self.chatImageView];
        
        self.photoBrowser = [[PLVPhotoBrowser alloc] init];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    if (self.cellWidth == 0) {
        return;
    }
    
    CGFloat originX = self.nickLabel.frame.origin.x;
    CGFloat originY =  self.nickLabel.frame.origin.y + 20;
    
    CGSize imageViewSize = [PLVLCImageEmotionMessageCell calculateImageViewSizeWithMessage:self.model.message];
    self.chatImageView.frame = CGRectMake(originX, originY, imageViewSize.width, imageViewSize.height);
}

#pragma mark - Getter

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

#pragma mark - UI

- (void)updateWithModel:(PLVChatModel *)model loginUserId:(NSString *)loginUserId cellWidth:(CGFloat)cellWidth {
    [super updateWithModel:model loginUserId:loginUserId cellWidth:cellWidth];
    
    if (self.cellWidth == 0 || ![PLVLCImageEmotionMessageCell isModelValid:model]) {
        self.cellWidth = 0;
        return;
    }
    
    PLVImageEmotionMessage *message = (PLVImageEmotionMessage *)model.message;
    NSURL *imageURL = [PLVLCImageEmotionMessageCell imageURLWithMessage:message];
    UIImage *placeHolderImage = [PLVColorUtil createImageWithColor:[PLVColorUtil colorFromHexString:@"#777786"]];
    if (imageURL) {
        [self.chatImageView sd_setImageWithURL:imageURL
                              placeholderImage:placeHolderImage
                                       options:SDWebImageRetryFailed];
    } else {
        [self.chatImageView setImage:placeHolderImage];
    }
}

#pragma mark UI - ViewModel

/// 获取图片URL
+ (NSURL *)imageURLWithMessage:(PLVImageEmotionMessage *)message {
    NSString *imageUrl = message.imageUrl;
    if (!imageUrl || ![imageUrl isKindOfClass:[NSString class]] || imageUrl.length == 0) {
        return nil;
    }
    
    return [NSURL URLWithString:imageUrl];
}

#pragma mark - 高度计算

/// 计算cell高度
+ (CGFloat)cellHeightWithModel:(PLVChatModel *)model cellWidth:(CGFloat)cellWidth {
    CGFloat cellHeight = [super cellHeightWithModel:model cellWidth:cellWidth];
    if (cellHeight == 0 || ![PLVLCImageEmotionMessageCell isModelValid:model]) {
        return 0;
    }
    
    CGFloat originY = 28.0; // 64 为气泡初始y值
    CGSize imageViewSize = [PLVLCImageEmotionMessageCell calculateImageViewSizeWithMessage:model.message];
    return originY + imageViewSize.height + 16; // 16为气泡底部外间距
}

//图片表情是固定的大小
+ (CGSize)calculateImageViewSizeWithMessage:(PLVImageEmotionMessage *)message {
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
    if (!message ||
        ![message isKindOfClass:[PLVImageEmotionMessage class]]) {
        return NO;
    }
    
    return YES;
}

@end
