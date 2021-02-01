//
//  PLVECGiftView.m
//  PolyvLiveScenesDemo
//
//  Created by ftao on 2020/6/30.
//  Copyright © 2020 polyv. All rights reserved.
//

#import "PLVECGiftView.h"
#import "PLVECUtils.h"

@interface PLVECGiftView ()

@property (nonatomic, strong) UIImageView *backgroundImgView;

@property (nonatomic, strong) UILabel *nameLabel;

@property (nonatomic, strong) UILabel *messageLable;

@property (nonatomic, strong) UIImageView *giftImgView;

@property (nonatomic, assign) CGRect originViewFrame;

@end

@implementation PLVECGiftView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.originViewFrame = frame;
        
        UIImage *backImage = [PLVECUtils imageForWatchResource:@"plv_img_back_reward"];
        self.backgroundImgView = [[UIImageView alloc] initWithImage:backImage];
        [self addSubview:self.backgroundImgView];
        
        self.giftImgView = [[UIImageView alloc] init];
        [self addSubview:self.giftImgView];
        
        self.nameLabel = [[UILabel alloc] init];
        self.nameLabel.textColor = [UIColor colorWithRed:252/255.f green:242/255.f blue:166/255.f alpha:1];
        self.nameLabel.textAlignment = NSTextAlignmentLeft;
        if (@available(iOS 8.2, *)) {
            self.nameLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
        } else {
            self.nameLabel.font = [UIFont systemFontOfSize:14];
        }
        [self addSubview:self.nameLabel];
        
        self.messageLable = [[UILabel alloc] init];
        self.messageLable.textColor = UIColor.whiteColor;
        self.messageLable.textAlignment = NSTextAlignmentLeft;
        self.messageLable.font = [UIFont systemFontOfSize:10];
        [self addSubview:self.messageLable];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.backgroundImgView.frame = self.bounds;
    self.giftImgView.frame = CGRectMake(150, CGRectGetHeight(self.bounds)-56, 56, 56);
    self.nameLabel.frame = CGRectMake(16, 8, 124, 12);
    self.messageLable.frame = CGRectMake(16, 24, 100, 10);
}

- (void)showGiftAnimation:(NSString *)userName giftName:(NSString *)giftName giftType:(NSString *)giftType {
    if (self.hidden == NO) {
        [self dismiss];
    }
    self.hidden = NO;
    self.nameLabel.text = userName;
    self.messageLable.text = [NSString stringWithFormat:@"赠送 %@",giftName];
    NSString *giftImageStr = [NSString stringWithFormat:@"plv_gift_icon_%@",giftType];
    self.giftImgView.image = [PLVECUtils imageForWatchResource:giftImageStr];
    
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

- (void)dismiss {
    self.hidden = YES;
    self.frame = self.originViewFrame;
}

@end
