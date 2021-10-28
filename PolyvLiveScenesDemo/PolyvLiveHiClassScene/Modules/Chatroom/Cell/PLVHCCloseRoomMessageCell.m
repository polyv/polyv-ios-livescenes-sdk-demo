//
//  PLVHCCloseRoomMessageCell.m
//  PolyvLiveScenesDemo
//
//  Created by lijingtong on 2021/7/7.
//  Copyright © 2021 polyv. All rights reserved.
//

#import "PLVHCCloseRoomMessageCell.h"

// 模块
#import "PLVChatModel.h"
#import "PLVCloseRoomModel.h"

@interface PLVHCCloseRoomMessageCell()

#pragma mark UI
@property (nonatomic, strong) UILabel *contentLabel; // 消息文本内容视图

@end

// cell高度
static int cellHeight = 17 + 8;
@implementation PLVHCCloseRoomMessageCell

#pragma mark - [ Life Cycle ]

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.allowReply = self.allowCopy = NO;
        
        [self.contentView addSubview:self.contentLabel];
        
    }
    return self;
}

- (void)layoutSubviews {
    self.contentLabel.frame = self.contentView.bounds;
}

#pragma mark - [ Override ]
#pragma mark 覆盖重写BaseMessageCell方法

+ (NSString *)reuseIdentifierWithUser:(PLVChatUser *)user {
    return @"PLVHCCloseRoomTipCell";;
}

/// 判断model是否为有效类型
+ (BOOL)isModelValid:(PLVChatModel *)model {
    if (!model || ![model isKindOfClass:[PLVChatModel class]]) {
        return NO;
    }
    
    id message = model.message;
    if (!message || ![message isKindOfClass:[PLVCloseRoomModel class]]) {
        return NO;
    }
    
    return YES;
}

#pragma mark - [ Public Method ]

- (void)updateWithModel:(PLVChatModel *)model {
    if (![PLVHCCloseRoomMessageCell isModelValid:model]) {
        return;
    }
   
    self.model = model;
    PLVCloseRoomModel *message = (PLVCloseRoomModel *)model.message;
    self.contentLabel.text = message.closeRoomString;
}

+ (CGFloat)cellHeightWithModel:(PLVChatModel *)model  {
    if (![PLVHCCloseRoomMessageCell isModelValid:model]) {
        return 0;
    }
    return cellHeight;
}

#pragma mark - [ Private Method ]

#pragma mark Getter

- (UILabel *)contentLabel {
    if (!_contentLabel) {
        _contentLabel = [[UILabel alloc] init];
        _contentLabel.font = [UIFont systemFontOfSize:12];
        _contentLabel.textColor = [PLVColorUtil colorFromHexString:@"#FDFEFF" alpha:0.5];
        _contentLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _contentLabel;
}

@end
