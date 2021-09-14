//
//  PLVLCImageMessageCell.m
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2020/12/1.
//  Copyright © 2020 PLV. All rights reserved.
//

#import "PLVLCImageMessageCell.h"
#import "PLVPhotoBrowser.h"
#import <PLVLiveScenesSDK/PLVImageMessage.h>
#import <PLVFoundationSDK/PLVColorUtil.h>
#import <SDWebImage/UIImageView+WebCache.h>

@interface PLVLCImageMessageCell ()

@property (nonatomic, strong) UIImageView *chatImageView; /// 聊天消息图片

@property (nonatomic, strong) PLVPhotoBrowser *photoBrowser; /// 消息图片Browser

@end

@implementation PLVLCImageMessageCell

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
    
    CGSize imageViewSize = [PLVLCImageMessageCell calculateImageViewSizeWithMessage:self.model.message];
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
    
    if (self.cellWidth == 0 || ![PLVLCImageMessageCell isModelValid:model]) {
        self.cellWidth = 0;
        return;
    }
    
    PLVImageMessage *message = (PLVImageMessage *)model.message;
    NSURL *imageURL = [PLVLCImageMessageCell imageURLWithMessage:message];
    UIImage *placeHolderImage = [PLVColorUtil createImageWithColor:[PLVColorUtil colorFromHexString:@"#777786"]];
    if (imageURL) {
        [self.chatImageView sd_setImageWithURL:imageURL
                              placeholderImage:placeHolderImage
                                       options:SDWebImageRetryFailed];
    } else if (message.image) {
        [self.chatImageView setImage:message.image];
    } else {
        [self.chatImageView setImage:placeHolderImage];
    }
}

#pragma mark UI - ViewModel

/// 获取图片URL
+ (NSURL *)imageURLWithMessage:(PLVImageMessage *)message {
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
    if (cellHeight == 0 || ![PLVLCImageMessageCell isModelValid:model]) {
        return 0;
    }
    
    CGFloat originY = 28.0; // 64 为气泡初始y值
    CGSize imageViewSize = [PLVLCImageMessageCell calculateImageViewSizeWithMessage:model.message];
    return originY + imageViewSize.height + 16; // 16为气泡底部外间距
}

+ (CGSize)calculateImageViewSizeWithMessage:(PLVImageMessage *)message {
    CGSize imageSize = message.imageSize;
    CGFloat maxLength = 120.0;
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
    if (!message || ![message isKindOfClass:[PLVImageMessage class]]) {
        return NO;
    }
    
    return YES;
}

@end
