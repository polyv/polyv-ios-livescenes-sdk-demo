//
//  PLVRedpackReceiveCell.m
//  PolyvLiveScenesDemo
//
//  Created by MissYasiky on 2023/1/10.
//  Copyright © 2023 PLV. All rights reserved.
//

#import "PLVLCRedpackResultCell.h"
#import "PLVRedpackResult.h"
#import "PLVLCUtils.h"

@interface PLVLCRedpackResultCell ()

// UI
@property (nonatomic, strong) UIView *bgView;
@property (nonatomic, strong) UILabel *contentLabel;
@property (nonatomic, assign) CGFloat cellWidth;

// 数据
@property (nonatomic, strong) PLVRedpackResult *message;
@property (nonatomic, strong) NSString *content;

@end

@implementation PLVLCRedpackResultCell

#pragma mark - [ Life cycle ]

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self.contentView addSubview:self.bgView];
        [self.bgView addSubview:self.contentLabel];
    }
    return self;
}

- (void)layoutSubviews {
    CGFloat minXPadding = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad ? 20.0 : 16.0; // bgView 的外部最小间隔
    CGFloat innerXPadding = 16.0; // contentLabel 与 bgView 的内部间隔
    CGFloat maxContenttLabelWidth = self.cellWidth - (minXPadding + innerXPadding) * 2; // contentLabel 最大可用长度
    
    CGFloat titLabelWidth = [self.content boundingRectWithSize:CGSizeMake(maxContenttLabelWidth - 14, 24)
                                                       options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                                    attributes:@{ NSFontAttributeName : [UIFont systemFontOfSize:12] }
                                                       context:nil].size.width;
    
    CGFloat labelWidth = titLabelWidth + 14;
    CGFloat bgWidth = labelWidth + innerXPadding * 2;
    CGFloat bgOriginX = (self.cellWidth - bgWidth) / 2.0;
    self.bgView.frame = CGRectMake(bgOriginX, 0, bgWidth, 24);
    self.contentLabel.frame = CGRectMake(innerXPadding, 0, CGRectGetWidth(self.bgView.frame) - innerXPadding * 2, CGRectGetHeight(self.bgView.frame));
}

#pragma mark - [ Public Method ]

- (void)updateWithModel:(PLVChatModel *)model cellWidth:(CGFloat)cellWidth {
    if (cellWidth == 0 || ![PLVLCRedpackResultCell isModelValid:model]) {
        return;
    }
    
    self.message = (PLVRedpackResult *)model.message;
    self.cellWidth = cellWidth;
    
    // 红包icon
    UIImage *image = [PLVLCUtils imageForChatroomResource:@"plvlc_chatroom_redpack_icon"];
    NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
    attachment.image = image;
    attachment.bounds = CGRectMake(0, 0, 14, 14);
    
    // 白色文本
    NSString *redpackTypeString = @"";
    if (self.message.type == PLVRedpackMessageTypeAliPassword) {
        redpackTypeString = @"口令";
    }
    NSString *contentString = [NSString stringWithFormat:@" %@ 从%@红包中获得", self.message.nick, redpackTypeString];
    NSDictionary *attributeDict = @{NSFontAttributeName:[UIFont systemFontOfSize:12],
                                    NSForegroundColorAttributeName:[PLVColorUtil colorFromHexString:@"#ADADC0"],
                                    NSBaselineOffsetAttributeName:@(2.0)};
    NSAttributedString *string = [[NSAttributedString alloc] initWithString:contentString attributes:attributeDict];
    
    // 红色文本
    NSDictionary *redAttributeDict = @{NSFontAttributeName:[UIFont systemFontOfSize:12],
                                       NSForegroundColorAttributeName:[PLVColorUtil colorFromHexString:@"#FF5959"],
                                       NSBaselineOffsetAttributeName:@(2.0)};
    NSAttributedString *redString = [[NSAttributedString alloc] initWithString:@"红包" attributes:redAttributeDict];
    
    NSMutableAttributedString *muString = [[NSMutableAttributedString alloc] init];
    [muString appendAttributedString:[NSAttributedString attributedStringWithAttachment:attachment]];
    [muString appendAttributedString:string];
    [muString appendAttributedString:redString];
    self.contentLabel.attributedText = [muString copy];
    
    self.content = [NSString stringWithFormat:@"%@红包", contentString];
}

+ (CGFloat)cellHeightWithModel:(PLVChatModel *)model cellWidth:(CGFloat)cellWidth {
    if (cellWidth == 0 || ![PLVLCRedpackResultCell isModelValid:model]) {
        return 0;
    }
    
    return 24 + 8; // 8为底部外间距
}

+ (BOOL)isModelValid:(PLVChatModel *)model {
    if (!model || ![model isKindOfClass:[PLVChatModel class]]) {
        return NO;
    }
    
    id message = model.message;
    if (message &&
        [message isKindOfClass:[PLVRedpackResult class]]) {
        return YES;
    }
    return NO;
}

#pragma mark - [ Private Method ]

#pragma mark Getter

- (UIView *)bgView {
    if (!_bgView) {
        _bgView = [[UIView alloc] init];
        _bgView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.3];
        _bgView.layer.cornerRadius = 4.0;
        _bgView.layer.masksToBounds = YES;
    }
    return _bgView;
}

- (UILabel *)contentLabel {
    if (!_contentLabel) {
        _contentLabel = [[UILabel alloc] init];
    }
    return _contentLabel;
}

@end
