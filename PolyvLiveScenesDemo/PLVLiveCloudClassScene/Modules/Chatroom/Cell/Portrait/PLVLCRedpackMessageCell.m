//
//  PLVLCRedpackMessageCell.m
//  PolyvLiveScenesDemo
//
//  Created by MissYasiky on 2023/1/10.
//  Copyright © 2023 PLV. All rights reserved.
//

#import "PLVLCRedpackMessageCell.h"
#import "PLVLCUtils.h"

@interface PLVLCRedpackMessageCell ()

@property (nonatomic, strong) UIImageView *redpackImageView;

@end

@implementation PLVLCRedpackMessageCell

#pragma mark - Life Cycle

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self.contentView addSubview:self.redpackImageView];
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
    self.redpackImageView.frame = CGRectMake(originX, originY, 220.0, 87.0);
}

#pragma mark - [ Public Method ]

- (void)updateWithModel:(PLVChatModel *)model loginUserId:(NSString *)loginUserId cellWidth:(CGFloat)cellWidth {
    [super updateWithModel:model loginUserId:loginUserId cellWidth:cellWidth];
    
    PLVRedpackMessage *redpackMessage = (PLVRedpackMessage *)self.model.message;
    if (redpackMessage.type == PLVRedpackMessageTypeAliPassword) {
        UIImage *image = [PLVLCUtils imageForChatroomResource:@"plvlc_chatroom_password_redpack"];
        [self.redpackImageView setImage:image];
    }
    
    if (redpackMessage.state == PLVRedpackStateExpired ||
        redpackMessage.state == PLVRedpackStateReceive ||
        redpackMessage.state == PLVRedpackStateNoneRedpack) {
        self.redpackImageView.alpha = 0.6;
    } else {
        self.redpackImageView.alpha = 1.0;
    }
}

+ (CGFloat)cellHeightWithModel:(PLVChatModel *)model cellWidth:(CGFloat)cellWidth {
    if (cellWidth == 0 || ![PLVLCRedpackMessageCell isModelValid:model]) {
        return 0;
    }
    
    CGFloat originY = 28.0; // 64 为气泡初始y值
    CGFloat redpackHeight = 80.0;
    return originY + redpackHeight + 16; // 16为气泡底部外间距
}

+ (BOOL)isModelValid:(PLVChatModel *)model {
    if (!model || ![model isKindOfClass:[PLVChatModel class]]) {
        return NO;
    }
    
    id message = model.message;
    if (message &&
        [message isKindOfClass:[PLVRedpackMessage class]]) { // 目前移动端只支持支付宝口令红包
        PLVRedpackMessage *redpackMessage = (PLVRedpackMessage *)message;
        return redpackMessage.type == PLVRedpackMessageTypeAliPassword;
    }
    return NO;
}

#pragma mark - [ Private Method ]

#pragma mark Getter

- (UIImageView *)redpackImageView {
    if (!_redpackImageView) {
        _redpackImageView = [[UIImageView alloc] init];
        _redpackImageView.userInteractionEnabled = YES;
        
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapRedpackAction)];
        [_redpackImageView addGestureRecognizer:tapGesture];
    }
    return _redpackImageView;
}

#pragma mark - [ Event ]

#pragma mark Action

- (void)tapRedpackAction {
    if (self.tapRedpackHandler) {
        self.tapRedpackHandler(self.model);
    }
}

@end
