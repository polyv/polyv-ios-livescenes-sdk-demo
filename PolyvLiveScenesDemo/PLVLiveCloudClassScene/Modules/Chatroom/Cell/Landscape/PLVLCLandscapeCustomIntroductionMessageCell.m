//
//  PLVLCLandscapeCustomIntroductionMessageCell.m
//  PolyvLiveScenesDemo
//
//  Created by Dhan on 2025/07/25.
//  Copyright © 2025 PLV. All rights reserved.
//

#import "PLVLCLandscapeCustomIntroductionMessageCell.h"
#import "PLVChatTextView.h"
#import "PLVMultiLanguageManager.h"
#import <PLVLiveScenesSDK/PLVCustomIntroductionMessage.h>
#import <PLVFoundationSDK/PLVFoundationSDK.h>

@interface PLVLCLandscapeCustomIntroductionMessageCell ()

#pragma mark 数据

/// 消息数据模型
@property (nonatomic, strong) PLVCustomIntroductionMessage *customIntroductionMessage;

#pragma mark UI

/// 通知内容视图
@property (nonatomic, strong) PLVChatTextView *textView;

@end


@implementation PLVLCLandscapeCustomIntroductionMessageCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // 设置bubbleView的属性（覆盖基类的默认样式）
        self.bubbleView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
        
        [self.contentView addSubview:self.textView];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    if (self.cellWidth == 0) {
        return;
    }

    CGFloat xPadding = 12.0;
    CGFloat yPadding = -4.0;
    CGFloat maxTextViewWidth = self.cellWidth - xPadding * 2;
    CGSize textViewSize = [self.textView sizeThatFits:CGSizeMake(maxTextViewWidth, MAXFLOAT)];
    self.textView.frame = CGRectMake(xPadding, yPadding, textViewSize.width, textViewSize.height);
    CGSize bubbleSize = CGSizeMake(textViewSize.width + xPadding * 2, textViewSize.height + yPadding * 2);
    self.bubbleView.frame = CGRectMake(0, 0, bubbleSize.width, bubbleSize.height);
    self.bubbleView.layer.cornerRadius = 8;
    self.bubbleView.clipsToBounds = YES;
}

#pragma mark - Getter

- (PLVChatTextView *)textView {
    if (!_textView) {
        _textView = [[PLVChatTextView alloc] init];
        _textView.textContainer.maximumNumberOfLines = 0;
        _textView.textContainer.lineBreakMode = NSLineBreakByWordWrapping;
    }
    return _textView;
}



#pragma mark - UI

- (void)updateWithModel:(PLVChatModel *)model loginUserId:(NSString *)loginUserId cellWidth:(CGFloat)cellWidth {
    if (cellWidth == 0 || ![PLVLCLandscapeCustomIntroductionMessageCell isModelValid:model]) {
        self.cellWidth = 0;
        return;
    }
    
    self.cellWidth = cellWidth;
    self.customIntroductionMessage = model.message;
    
    NSMutableAttributedString *contentLabelString;
    if (model.landscapeAttributeString) { // 如果在 model 中已经存在计算好的 消息多属性文本 ，那么 就直接使用；
        contentLabelString = model.landscapeAttributeString;
    } else {
        contentLabelString = [PLVLCLandscapeCustomIntroductionMessageCell contentLabelAttributedStringWithMessage:model.message
                                                                                    ];
        model.landscapeAttributeString = contentLabelString;
    }
    [self.textView setContent:contentLabelString showUrl:NO];
    [self setNeedsLayout];
}

#pragma mark UI - ViewModel

/// 生成消息多属性文本
+ (NSMutableAttributedString *)contentLabelAttributedStringWithMessage:(id)message {
    NSString *content = @"";
    if ([message isKindOfClass:[PLVCustomIntroductionMessage class]]) {
        PLVCustomIntroductionMessage *customIntroductionMessage = (PLVCustomIntroductionMessage *)message;
        content = customIntroductionMessage.content ?: @"";
    } else {
        content = (NSString *)message;
    }
    // 创建内容的富文本
    UIFont *contentFont = [UIFont fontWithName:@"PingFangSC-Regular" size:14.0];
    UIColor *contentColor = [UIColor whiteColor];
    NSDictionary *contentAttributeDict = @{
                                           NSFontAttributeName: contentFont,
                                           NSForegroundColorAttributeName: contentColor
    };
    NSAttributedString *contentString = [[NSAttributedString alloc] initWithString:content attributes:contentAttributeDict];
    
    // 组合通知标签和内容
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] init];
    
    // 添加通知标签图片
    UIImage *notificationImage = [PLVLCLandscapeCustomIntroductionMessageCell notificationImage];
    if (notificationImage) {
        NSTextAttachment *attach = [[NSTextAttachment alloc] init];
        CGFloat paddingTop = round(contentFont.capHeight - notificationImage.size.height)/2.0;
        attach.bounds = CGRectMake(0, paddingTop, notificationImage.size.width, notificationImage.size.height);
        attach.image = notificationImage;
        NSAttributedString *imageStr = [NSAttributedString attributedStringWithAttachment:attach];
        [attributedString appendAttributedString:imageStr];
        [attributedString appendAttributedString:[[NSAttributedString alloc] initWithString:@" "]];
    }
    
    [attributedString appendAttributedString:contentString];
    
    return attributedString;
}

#pragma mark - 高度计算

+ (CGFloat)cellHeightWithModel:(PLVChatModel *)model loginUserId:(NSString *)loginUserId cellWidth:(CGFloat)cellWidth {
    if (![PLVLCLandscapeCustomIntroductionMessageCell isModelValid:model] || cellWidth == 0) {
        return 0;
    }
    CGFloat xPadding = 12.0;
    CGFloat yPadding = -4.0;
    CGFloat maxTextViewWidth = cellWidth - xPadding * 2;
    NSMutableAttributedString *attributedString = [PLVLCLandscapeCustomIntroductionMessageCell contentLabelAttributedStringWithMessage:model.message];
    PLVChatTextView *tmpTextView = [[PLVChatTextView alloc] init];
    tmpTextView.textContainer.maximumNumberOfLines = 0;
    tmpTextView.textContainer.lineBreakMode = NSLineBreakByWordWrapping;
    [tmpTextView setContent:attributedString showUrl:NO];
    CGSize textSize = [tmpTextView sizeThatFits:CGSizeMake(maxTextViewWidth, CGFLOAT_MAX)];
    CGFloat bubbleHeight = textSize.height + yPadding * 2;
    return bubbleHeight + 1;
}

#pragma mark - Utils

+ (BOOL)isModelValid:(PLVChatModel *)model {
    if (!model || ![model isKindOfClass:[PLVChatModel class]]) {
        return NO;
    }
    
    id message = model.message;
    if (!message || ![message isKindOfClass:[PLVCustomIntroductionMessage class]]) {
        return NO;
    }
    return YES;
}

/// 生成通知标签图片
+ (UIImage *)notificationImage {
    UILabel *label = [[UILabel alloc] init];
    label.font = [UIFont boldSystemFontOfSize:10];
    label.textColor = [UIColor whiteColor];
    label.textAlignment = NSTextAlignmentCenter;
    label.layer.cornerRadius = 7;
    label.layer.masksToBounds = YES;
    label.text = PLVLocalizedString(@"通知");
    label.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.2];
    
    NSString *notificationText = PLVLocalizedString(@"通知");
    CGSize size;
    if (notificationText &&
        [notificationText isKindOfClass:[NSString class]] &&
        notificationText.length > 0) {
        NSAttributedString *attr = [[NSAttributedString alloc] initWithString:notificationText attributes:@{NSFontAttributeName: [UIFont boldSystemFontOfSize:10]}];
        size = [attr boundingRectWithSize:CGSizeMake(100, 14) options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading context:nil].size;
        size.width += 10;
    }
    label.frame = CGRectMake(0, 0, size.width, 14);
    
    // 使用PLVImageUtil生成图片
    UIImage *image = [PLVImageUtil imageFromUIView:label opaque:NO scale:[UIScreen mainScreen].scale];
    
    return image;
}

@end 
