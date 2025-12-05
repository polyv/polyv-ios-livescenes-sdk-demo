//
//  PLVLCRewardCellTableViewCell.m
//  PolyvLiveScenesDemo
//
//  Created by jiaweihuang on 2021/3/1.
//  Copyright © 2021 polyv. All rights reserved.
//

#import "PLVLCRewardMessageCell.h"
#import "PLVMultiLanguageManager.h"
#import "PLVRoomDataManager.h"
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>
#import <PLVFoundationSDK/PLVColorUtil.h>
#import <SDWebImage/UIImageView+WebCache.h>
#if __has_include(<SDWebImage/SDAnimatedImageView.h>)
    #import <SDWebImage/SDAnimatedImageView.h>
    #define SDWebImageSDK5
#endif
#import "PLVLCUtils.h"

@interface PLVLCRewardMessageCell()

#pragma mark 数据
@property (nonatomic, strong) PLVChatModel *model; /// 消息数据模型

#pragma mark UI
@property (nonatomic, assign) CGFloat cellWidth;

@property (nonatomic, strong) UILabel *nickNameLabel;
@property (nonatomic, strong) UILabel *suffixLabel; /// "赠送"文本
#ifdef SDWebImageSDK5
@property (nonatomic, strong) SDAnimatedImageView *giftImageView;
#else
@property (nonatomic, strong) UIImageView *giftImageView;
#endif
@property (nonatomic, strong) UILabel *numLabel;

@end

@implementation PLVLCRewardMessageCell

#pragma mark - [ Life cycle ]

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self initUI];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    if (self.cellWidth == 0) {
        return;
    }
    
    // 布局：昵称label - "赠送"label - 礼物图片 - 数量label
    CGFloat spacing = 4.0;
    CGFloat giftImageSize = 40.0;
    CGFloat maxContentWidth = 240.0;
    CGFloat cellHeight = 56.0; // 与 cellHeightWithModel 保持一致
    
    // 计算"赠送"label宽度（固定显示）
    CGSize suffixSize = [self.suffixLabel sizeThatFits:CGSizeMake(MAXFLOAT, 20)];
    CGFloat suffixWidth = suffixSize.width;
    
    // 计算数量宽度（如果隐藏则为0）
    CGFloat numWidth = 0;
    if (!self.numLabel.hidden) {
        CGSize numSize = [self.numLabel sizeThatFits:CGSizeMake(MAXFLOAT, 20)];
        numWidth = numSize.width;
    }
    
    // 计算昵称可用宽度（总宽度 - "赠送" - 礼物图片 - 数量 - 间距）
    CGFloat availableWidthForNickName = maxContentWidth - suffixWidth - spacing - giftImageSize - spacing;
    if (numWidth > 0) {
        availableWidthForNickName -= spacing + numWidth;
    }
    
    // 设置昵称label的固定宽度，让其自动截断
    // 昵称label会使用 lineBreakMode 自动截断，宽度就是可用宽度
    CGFloat nickNameWidth = availableWidthForNickName;
    
    // 计算总宽度
    CGFloat totalWidth = nickNameWidth + spacing + suffixWidth + spacing + giftImageSize;
    if (numWidth > 0) {
        totalWidth += spacing + numWidth;
    }
    totalWidth = MIN(totalWidth, maxContentWidth);
    
    // 居中布局
    CGFloat startX = (self.cellWidth - totalWidth) / 2;
    CGFloat centerY = cellHeight / 2; // 垂直居中
    
    // 昵称label（垂直居中对齐）
    self.nickNameLabel.frame = CGRectMake(startX, centerY - 10, nickNameWidth, 20);
    
    // "赠送"label（紧跟在昵称后面）
    self.suffixLabel.frame = CGRectMake(CGRectGetMaxX(self.nickNameLabel.frame) + spacing, centerY - 10, suffixWidth, 20);
    
    // 礼物图片（垂直居中）
    self.giftImageView.frame = CGRectMake(CGRectGetMaxX(self.suffixLabel.frame) + spacing, centerY - giftImageSize / 2, giftImageSize, giftImageSize);
    
    // 数量label（垂直居中对齐，如果显示的话）
    if (!self.numLabel.hidden && numWidth > 0) {
        self.numLabel.frame = CGRectMake(CGRectGetMaxX(self.giftImageView.frame) + spacing, centerY - 10, numWidth, 20);
    }
}


#pragma mark - [ Public Method ]

- (void)updateWithModel:(PLVChatModel *)model cellWidth:(CGFloat)cellWidth {
    if (![PLVLCRewardMessageCell isModelValid:model] || cellWidth == 0) {
        self.cellWidth = 0;
        return;
    }

    self.cellWidth = cellWidth;
    self.model = model;
    PLVRewardMessage *message = (PLVRewardMessage *)self.model.message;
    
    NSString *nickName = [self.model.user getDisplayNickname:[PLVRoomDataManager sharedManager].roomData.menuInfo.hideViewerNicknameEnabled loginUserId:[PLVRoomDataManager sharedManager].roomData.roomUser.viewerId];
    
    self.nickNameLabel.text = nickName;
    self.nickNameLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    
    self.suffixLabel.text = PLVLocalizedString(@"赠送");
    
    if (message.goodNum.intValue > 1) {
        self.numLabel.text = [NSString stringWithFormat:@"x%@", message.goodNum];
        self.numLabel.hidden = NO;
    } else {
        self.numLabel.text = @"";
        self.numLabel.hidden = YES;
    }
    
    NSURL *imageURL = [PLVLCRewardMessageCell imageURLWithMessage:message];
    if (imageURL) {
        self.giftImageView.hidden = NO;
        UIImage *placeHolderImage = [PLVColorUtil createImageWithColor:[PLVColorUtil colorFromHexString:@"#777786"]];
        [PLVLCUtils setImageView:self.giftImageView url:imageURL placeholderImage:placeHolderImage options:SDWebImageRetryFailed];
    } else if (message.image) {
        self.giftImageView.hidden = NO;
        [self.giftImageView setImage:message.image];
    } else {
        self.giftImageView.hidden = YES;
    }
}

/// 获取图片URL
+ (NSURL *)imageURLWithMessage:(PLVRewardMessage *)message {
    NSString *imageUrl = message.gimg;
    if (!imageUrl || ![imageUrl isKindOfClass:[NSString class]] || imageUrl.length == 0) {
        return nil;
    }
    
    return [NSURL URLWithString:imageUrl];
}

+ (CGFloat)cellHeightWithModel:(PLVChatModel *)model cellWidth:(CGFloat)cellWidth {
    if (![PLVLCRewardMessageCell isModelValid:model] || cellWidth == 0) {
        return 0;
    }
    
    return 56;
}

/// 判断model是否为有效类型
+ (BOOL)isModelValid:(PLVChatModel *)model {
    if (!model || ![model isKindOfClass:[PLVChatModel class]]) {
        return NO;
    }
    
    id message = model.message;
    if (!message || ![message isKindOfClass:[PLVRewardMessage class]]) {
        return NO;
    }
    
    return YES;
}

#pragma mark - [ Private Method ]

- (void)initUI {
    self.backgroundColor = [UIColor clearColor];
    [self.contentView addSubview:self.nickNameLabel];
    [self.contentView addSubview:self.suffixLabel];
    [self.contentView addSubview:self.giftImageView];
    [self.contentView addSubview:self.numLabel];
}

#pragma mark  [ getter ]

- (UILabel *)nickNameLabel {
    if (!_nickNameLabel) {
        _nickNameLabel = [[UILabel alloc] init];
        _nickNameLabel.font = [UIFont systemFontOfSize:14.0];
        _nickNameLabel.textColor = [UIColor whiteColor];
        _nickNameLabel.textAlignment = NSTextAlignmentLeft;
        _nickNameLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        _nickNameLabel.numberOfLines = 1;
    }
    return _nickNameLabel;
}

- (UILabel *)suffixLabel {
    if (!_suffixLabel) {
        _suffixLabel = [[UILabel alloc] init];
        _suffixLabel.font = [UIFont systemFontOfSize:14.0];
        _suffixLabel.textColor = [UIColor whiteColor];
        _suffixLabel.textAlignment = NSTextAlignmentLeft;
    }
    return _suffixLabel;
}

#ifdef SDWebImageSDK5
- (SDAnimatedImageView *)giftImageView {
    if (!_giftImageView) {
        _giftImageView = [[SDAnimatedImageView alloc] init];
        _giftImageView.contentMode = UIViewContentModeScaleAspectFit;
        _giftImageView.hidden = YES;
    }
    return _giftImageView;
}
#else
- (UIImageView *)giftImageView {
    if (!_giftImageView) {
        _giftImageView = [[UIImageView alloc] init];
        _giftImageView.contentMode = UIViewContentModeScaleAspectFit;
        _giftImageView.hidden = YES;
    }
    return _giftImageView;
}
#endif

- (UILabel *)numLabel {
    if (!_numLabel) {
        _numLabel = [[UILabel alloc] init];
        _numLabel.font = [UIFont systemFontOfSize:14.0];
        _numLabel.textColor = [UIColor whiteColor];
        _numLabel.textAlignment = NSTextAlignmentLeft;
        _numLabel.hidden = YES;
    }
    return _numLabel;
}

@end
