//
//  PLVGiveRewardGoodsButton.m
//  PolyvCloudClassDemo
//
//  Created by Lincal on 2019/12/4.
//  Copyright © 2019 polyv. All rights reserved.
//

#import "PLVGiveRewardGoodsButton.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import <SDWebImage/SDWebImageDownloader.h>

@interface PLVGiveRewardGoodsButton ()

@property (nonatomic, strong) UIImageView * prizeImageView;
@property (nonatomic, strong) UILabel * prizeNameLabel;
@property (nonatomic, strong) UILabel * prizePointsLabel;

@end

@implementation PLVGiveRewardGoodsButton

#pragma mark - [ Init ]
- (instancetype)initWithFrame:(CGRect)frame{
    if ([super initWithFrame:frame]) {
        [self initUI];
    }
    return self;
}

- (void)initUI{
    self.layer.cornerRadius = 8;
    [self addSubview:self.prizeImageView];
    [self addSubview:self.prizeNameLabel];
    [self addSubview:self.prizePointsLabel];
}

- (void)layoutSubviews {
    BOOL fullScreen = [UIScreen mainScreen].bounds.size.width > [UIScreen mainScreen].bounds.size.height;
    if (fullScreen) {
        self.prizeImageView.frame = CGRectMake((CGRectGetWidth(self.frame) - 60) / 2, 10, 60, 60);
        self.prizeNameLabel.frame = CGRectMake((CGRectGetWidth(self.frame) - 50) / 2, 78, 50, 17);
        self.prizePointsLabel.frame = CGRectMake((CGRectGetWidth(self.frame) - 50) / 2, 98, 50, 14);
    } else {
        self.prizeImageView.frame = CGRectMake((CGRectGetWidth(self.frame) - 48) / 2, 8, 48, 48);
        self.prizeNameLabel.frame = CGRectMake((CGRectGetWidth(self.frame) - 50) / 2, 61, 50, 17);
        self.prizePointsLabel.frame = CGRectMake((CGRectGetWidth(self.frame) - 50) / 2, 78, 50, 14);
    }
}


#pragma mark - [ Public Methods ]
- (void)setModel:(PLVRewardGoodsModel *)model pointUnit:(NSString *)pointUnit{
    if (model) {
        [self.prizeImageView sd_setImageWithURL: [NSURL URLWithString:model.goodImgFullURL]];
        self.prizeNameLabel.text = model.goodName;
        if (model.cashReward) {
            self.prizePointsLabel.text = @"免费";
        } else {
            self.prizePointsLabel.text = [NSString stringWithFormat:@"%.0lf%@",model.goodPrice,pointUnit];
        }
    }
}


#pragma mark - [ Super Methods ]
- (void)setSelected:(BOOL)selected{
    [super setSelected:selected];
    if (selected) {
        self.backgroundColor = [UIColor colorWithRed:62/255.0 green:62/255.0 blue:78/255.0 alpha:1.0];
    } else {
        self.backgroundColor = [UIColor clearColor];
    }
}


#pragma mark - [ Private Methods ]
#pragma mark Getter
- (UIImageView *)prizeImageView{
    if (!_prizeImageView) {
        _prizeImageView = [[UIImageView alloc]init];
    }
    return _prizeImageView;
}

- (UILabel *)prizeNameLabel{
    if (!_prizeNameLabel) {
        _prizeNameLabel = [[UILabel alloc]init];
        _prizeNameLabel.font = [UIFont fontWithName:@"PingFang SC" size:12];
        _prizeNameLabel.textColor = [UIColor colorWithRed:208/255.0 green:208/255.0 blue:208/255.0 alpha:1.0];
        _prizeNameLabel.text = @"礼物";
        _prizeNameLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _prizeNameLabel;
}

- (UILabel *)prizePointsLabel{
    if (!_prizePointsLabel) {
        _prizePointsLabel = [[UILabel alloc]init];
        _prizePointsLabel.font = [UIFont fontWithName:@"PingFang SC" size:10];
        _prizePointsLabel.textColor = [UIColor colorWithRed:173/255.0 green:173/255.0 blue:192/255.0 alpha:1.0];
        _prizePointsLabel.textAlignment = NSTextAlignmentCenter;
        _prizePointsLabel.text = @"0点";
    }
    return _prizePointsLabel;
}

@end


