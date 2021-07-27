//
//  PLVSAChatroomGiftView.m
//  PLVLiveScenesDemo
//
//  Created by lijingtong on 2021/6/4.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVSAChatroomGiftView.h"

// 工具
#import "PLVSAUtils.h"

// 框架
#import <SDWebImage/UIImageView+WebCache.h>

@interface PLVSAChatroomGiftView ()

// UI
@property (nonatomic, strong) UIImageView *backgroundImgView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *messageLable;
@property (nonatomic, strong) UIImageView *giftImgView;
@property (nonatomic, strong) UILabel *numLabel;

// 数据
@property (nonatomic, assign) CGRect originViewFrame;

@end

@implementation PLVSAChatroomGiftView

#pragma mark - [ Life Cycle ]

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.originViewFrame = frame;
        
        [self addSubview:self.backgroundImgView];
        [self addSubview:self.giftImgView];
        [self addSubview:self.nameLabel];
        [self addSubview:self.messageLable];
        [self addSubview:self.numLabel];
    }
    return self;
}

#pragma mark - [ Override ]

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.backgroundImgView.frame = self.bounds;
    self.nameLabel.frame = CGRectMake(16, 8, 124, 12);
    self.messageLable.frame = CGRectMake(16, 24, 100, 10);
    self.giftImgView.frame = CGRectMake(150, CGRectGetHeight(self.bounds)-56, 56, 56);
    self.numLabel.frame = CGRectMake(CGRectGetMaxX(self.giftImgView.frame) + 4, 8, 64, 28);
}

#pragma mark - [ Public Method ]

- (void)showGiftAnimation:(NSString *)userName giftImageUrl:(NSString *)giftImageUrl giftNum:(NSInteger)giftNum giftContent:(NSString *)giftContent {
 
    if (self.hidden == NO) {
        [self dismiss];
    }
    self.hidden = NO;
    self.numLabel.hidden = NO;
    
    self.nameLabel.text = userName;
    self.messageLable.text = [NSString stringWithFormat:@"赠送 %@",giftContent];
    self.numLabel.text = [NSString stringWithFormat:@"x %zd", giftNum];
    // 设置礼物图片
    self.giftImgView.hidden = !giftImageUrl;
    if (giftImageUrl) {
        [self.giftImgView sd_setImageWithURL:[NSURL URLWithString:giftImageUrl]
                              placeholderImage:nil
                                       options:SDWebImageRetryFailed];
    }
    
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:0.5 animations:^{
        CGRect newFrame = weakSelf.frame;
        newFrame.origin.x = 0;
        weakSelf.frame = newFrame;
    }];
     
    SEL dissmissGiftView = @selector(dismiss);
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:dissmissGiftView object:nil];
    [self performSelector:dissmissGiftView withObject:nil afterDelay:2];
}

- (void)showGiftAnimation:(NSString *)userName cashGiftContent:(NSString *)cashGiftContent {
    if (self.hidden == NO) {
        [self dismiss];
    }
    self.hidden = NO;
    self.numLabel.hidden = YES;
    self.nameLabel.text = userName;
    self.messageLable.text = [NSString stringWithFormat:@"打赏 %@元",cashGiftContent];
    
    // 设置礼物图片
    self.giftImgView.image = [PLVSAUtils imageForChatroomResource:@"plvsa_chatroom_gift_icon_cash"];
    
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:0.5 animations:^{
        CGRect newFrame = weakSelf.frame;
        newFrame.origin.x = 0;
        weakSelf.frame = newFrame;
    }];
     
    SEL dissmissGiftView = @selector(dismiss);
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:dissmissGiftView object:nil];
    [self performSelector:dissmissGiftView withObject:nil afterDelay:2];
}

#pragma mark - [ Private Method ]

- (void)dismiss {
    self.hidden = YES;
    self.frame = self.originViewFrame;
}


#pragma mark Getter

- (UIImageView *)backgroundImgView {
    if (!_backgroundImgView) {
        _backgroundImgView = [[UIImageView alloc] init];
        UIImage *bgImage = [PLVSAUtils imageForChatroomResource:@"plvsa_chatroom_bg_reward"];
        _backgroundImgView.image = bgImage;
    }
    return _backgroundImgView;
}

- (UIImageView *)giftImgView {
    if (!_giftImgView) {
        _giftImgView = [[UIImageView alloc] init];
        _giftImgView.contentMode = UIViewContentModeScaleAspectFit;
    }
    return _giftImgView;
}

- (UILabel *)nameLabel {
    if (!_nameLabel) {
        _nameLabel = [[UILabel alloc] init];
        _nameLabel = [[UILabel alloc] init];
        _nameLabel.textColor = [UIColor colorWithRed:252/255.f green:242/255.f blue:166/255.f alpha:1];
        _nameLabel.textAlignment = NSTextAlignmentLeft;
        if (@available(iOS 8.2, *)) {
            _nameLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
        } else {
            _nameLabel.font = [UIFont systemFontOfSize:14];
        }
    }
    return _nameLabel;
}

- (UILabel *)messageLable {
    if (!_messageLable) {
        _messageLable = [[UILabel alloc] init];
        _messageLable.textColor = UIColor.whiteColor;
        _messageLable.textAlignment = NSTextAlignmentLeft;
        _messageLable.font = [UIFont systemFontOfSize:10];
    }
    return _messageLable;
}

- (UILabel *)numLabel {
    if (!_numLabel) {
        _numLabel = [[UILabel alloc] init];
        _numLabel.textAlignment = NSTextAlignmentLeft;
        _numLabel.textColor = [UIColor colorWithRed:245/255.0 green:124/255.0 blue:0/255.0 alpha:1/1.0];
        if (@available(iOS 8.2, *)) {
            _numLabel.font = [UIFont systemFontOfSize:20 weight:UIFontWeightBold];
        } else {
            _numLabel.font = [UIFont systemFontOfSize:20];
        }
        CGAffineTransform matrix = CGAffineTransformMake(1,
                                      0, tanf(-15 * (CGFloat)M_PI /
                                              180), 1,
                                      0, 0);
        _numLabel.transform = matrix;
    }
    return _numLabel;
}

@end
