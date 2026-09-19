//
//  PLVLCLocalSystemMessageCell.m
//  PolyvLiveScenesDemo
//
//  Copyright © 2026 PLV. All rights reserved.
//

#import "PLVLCLocalSystemMessageCell.h"
#import "PLVChatModel.h"
#import "PLVMultiLanguageManager.h"
#import <PLVLiveScenesSDK/PLVLocalSystemMessage.h>
#import <PLVFoundationSDK/PLVFoundationSDK.h>

@interface PLVLCLocalSystemMessageCell ()

@property (nonatomic, strong) UIView *bubbleView;
@property (nonatomic, strong) UILabel *labelView;
@property (nonatomic, strong) UILabel *contentLabel;
@property (nonatomic, assign) CGFloat cellWidth;

+ (CGFloat)systemLabelWidth;

@end

@implementation PLVLCLocalSystemMessageCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        [self.contentView addSubview:self.bubbleView];
        [self.bubbleView addSubview:self.labelView];
        [self.bubbleView addSubview:self.contentLabel];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    if (self.cellWidth <= 0) {
        return;
    }

    CGFloat xPadding = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad ? 20.0 : 16.0;
    CGFloat originY = 8.0;
    CGFloat maxWidth = self.cellWidth - xPadding * 2;

    CGFloat labelWidth = [PLVLCLocalSystemMessageCell systemLabelWidth];
    CGFloat labelHeight = MAX(ceil(CGRectGetHeight(self.labelView.bounds)), 16.0);

    CGFloat contentMaxWidth = maxWidth - 8.0 * 2 - labelWidth - 4.0;
    CGSize contentSize = [self.contentLabel sizeThatFits:CGSizeMake(contentMaxWidth, CGFLOAT_MAX)];
    CGFloat contentWidth = ceil(contentSize.width);
    CGFloat contentHeight = ceil(contentSize.height);

    CGFloat bubbleHeight = MAX(labelHeight, contentHeight) + 8.0;
    CGFloat bubbleWidth = MIN(8.0 + labelWidth + 4.0 + contentWidth + 8.0, maxWidth);

    self.bubbleView.frame = CGRectMake(xPadding, originY, bubbleWidth, bubbleHeight);
    self.labelView.frame = CGRectMake(8.0, (bubbleHeight - labelHeight) / 2.0, labelWidth, labelHeight);
    self.contentLabel.frame = CGRectMake(CGRectGetMaxX(self.labelView.frame) + 4.0,
                                         (bubbleHeight - contentHeight) / 2.0,
                                         contentWidth,
                                         contentHeight);
}

- (void)updateWithModel:(PLVChatModel *)model cellWidth:(CGFloat)cellWidth {
    if (cellWidth <= 0 || ![PLVLCLocalSystemMessageCell isModelValid:model]) {
        self.cellWidth = 0;
        return;
    }
    self.cellWidth = cellWidth;
    PLVLocalSystemMessage *message = (PLVLocalSystemMessage *)model.message;
    self.contentLabel.text = message.content ?: @"";
    [self setNeedsLayout];
}

+ (CGFloat)cellHeightWithModel:(PLVChatModel *)model cellWidth:(CGFloat)cellWidth {
    if (cellWidth <= 0 || ![PLVLCLocalSystemMessageCell isModelValid:model]) {
        return 0;
    }
    PLVLocalSystemMessage *message = (PLVLocalSystemMessage *)model.message;
    CGFloat xPadding = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad ? 20.0 : 16.0;
    CGFloat maxWidth = cellWidth - xPadding * 2;
    CGFloat labelWidth = [PLVLCLocalSystemMessageCell systemLabelWidth];
    CGFloat contentMaxWidth = maxWidth - 8.0 * 2 - labelWidth - 4.0;
    CGRect contentRect = [message.content boundingRectWithSize:CGSizeMake(contentMaxWidth, CGFLOAT_MAX)
                                                       options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                                    attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:14.0]}
                                                       context:nil];
    return MAX(ceil(contentRect.size.height), 16.0) + 8.0 + 8.0;
}

+ (CGFloat)systemLabelWidth {
    UIFont *font = [UIFont systemFontOfSize:10.0];
    CGSize size = [PLVLocalizedString(@"系统消息") sizeWithAttributes:@{NSFontAttributeName : font}];
    return ceil(size.width) + 12.0;
}

+ (BOOL)isModelValid:(PLVChatModel *)model {
    if (!model || ![model isKindOfClass:[PLVChatModel class]]) {
        return NO;
    }
    return [model.message isKindOfClass:[PLVLocalSystemMessage class]] &&
           [PLVFdUtil checkStringUseable:((PLVLocalSystemMessage *)model.message).content];
}

#pragma mark - Getter

- (UIView *)bubbleView {
    if (!_bubbleView) {
        _bubbleView = [[UIView alloc] init];
        _bubbleView.backgroundColor = [PLVColorUtil colorFromHexString:@"#F5F5F5"];
        _bubbleView.layer.cornerRadius = 10.0;
        _bubbleView.clipsToBounds = YES;
    }
    return _bubbleView;
}

- (UILabel *)labelView {
    if (!_labelView) {
        _labelView = [[UILabel alloc] init];
        _labelView.font = [UIFont systemFontOfSize:10.0];
        _labelView.textColor = [PLVColorUtil colorFromHexString:@"#666666"];
        _labelView.textAlignment = NSTextAlignmentCenter;
        _labelView.backgroundColor = [PLVColorUtil colorFromHexString:@"#E0E0E0"];
        _labelView.layer.cornerRadius = 5.0;
        _labelView.clipsToBounds = YES;
        _labelView.text = PLVLocalizedString(@"系统消息");
    }
    return _labelView;
}

- (UILabel *)contentLabel {
    if (!_contentLabel) {
        _contentLabel = [[UILabel alloc] init];
        _contentLabel.font = [UIFont systemFontOfSize:14.0];
        _contentLabel.textColor = [PLVColorUtil colorFromHexString:@"#333333"];
        _contentLabel.numberOfLines = 0;
    }
    return _contentLabel;
}

@end
