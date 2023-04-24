//
//  PLVLCRewardCellTableViewCell.m
//  PolyvLiveScenesDemo
//
//  Created by jiaweihuang on 2021/3/1.
//  Copyright © 2021 polyv. All rights reserved.
//

#import "PLVLCRewardMessageCell.h"
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>
#import <SDWebImage/UIImageView+WebCache.h>
#import <SDWebImage/SDWebImageDownloader.h>
#import "PLVChatTextView.h"

@interface PLVLCRewardMessageCell()

#pragma mark 数据
@property (nonatomic, strong) PLVChatModel *model; /// 消息数据模型

#pragma mark UI
@property (nonatomic, assign) CGFloat cellWidth;

@property (nonatomic, strong) PLVChatTextView *textView;

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
    CGFloat maxTextViewWidth = 240.0;
    CGSize textViewSize = [self.textView sizeThatFits:CGSizeMake(maxTextViewWidth, 48)];
    CGFloat x = (self.cellWidth - textViewSize.width) / 2;
    self.textView.frame = CGRectMake(x, 0, textViewSize.width, textViewSize.height);
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
    self.textView.attributedText = [self contentAttributedStringWithMessage:message];
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
    [self.contentView addSubview:self.textView];
}

/// 获取消息多属性文本
- (NSMutableAttributedString *)contentAttributedStringWithMessage:(PLVRewardMessage *)message {
    UIFont *font = [UIFont systemFontOfSize:14.0];
    UIColor *textColor = [UIColor whiteColor];
    NSDictionary *textAttDict = @{NSFontAttributeName:font,
                                     NSForegroundColorAttributeName:textColor};
    
    NSString *nickName = message.unick;
    if (nickName.length > 8) {
        nickName = [nickName substringWithRange:NSMakeRange(0, 8)];
        nickName = [nickName stringByAppendingString:@"..."];
    }
    
    NSAttributedString *nickNameString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@赠送",nickName]attributes:textAttDict];
    
    NSString *rewardNum = @"";
    if (message.goodNum.intValue > 1) {
        rewardNum = [NSString stringWithFormat:@"x%@", message.goodNum];
    }
    NSAttributedString *numString = [[NSAttributedString alloc] initWithString:rewardNum attributes:textAttDict];
    
    NSTextAttachment *attachment = [[NSTextAttachment alloc]init];
    attachment.bounds = CGRectMake(0, -14, 40, 40);
    NSAttributedString *imageAttributeString = [NSAttributedString attributedStringWithAttachment:attachment];
    if (!message.image) {
        [[SDWebImageDownloader sharedDownloader] downloadImageWithURL:[PLVLCRewardMessageCell imageURLWithMessage:message] options:SDWebImageDownloaderUseNSURLCache progress:nil completed:^(UIImage *image, NSData *data, NSError *error, BOOL finished) {
            attachment.image = message.image = image;
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.textView.layoutManager invalidateDisplayForCharacterRange:NSMakeRange(0, imageAttributeString.length)];
            });
        }];
    } else {
        attachment.image = message.image;
    }

    NSMutableAttributedString *contentString = [[NSMutableAttributedString alloc] init];
    [contentString appendAttributedString:nickNameString];
    [contentString appendAttributedString:imageAttributeString];
    [contentString appendAttributedString:numString];
            
    return contentString;
}


#pragma mark  [ getter ]

- (PLVChatTextView *)textView {
    if (!_textView) {
        _textView = [[PLVChatTextView alloc]init];
    }
    return _textView;
}

@end
