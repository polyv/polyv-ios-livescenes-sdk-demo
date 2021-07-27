//
//  PLVECAudioAnimalView.m
//  PLVLiveEcommerceDemo
//
//  Created by ftao on 2020/6/2.
//  Copyright © 2020 PLV. All rights reserved.
//

#import "PLVECAudioAnimalView.h"
#import "PLVECUtils.h"

@interface PLVECAudioAnimalView ()

@property (nonatomic, strong) UIImageView *animationImageView;

@property (nonatomic, strong) UILabel *contentLable;

@end

@implementation PLVECAudioAnimalView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.userInteractionEnabled = NO;
        self.backgroundColor = [UIColor blackColor];
        
        UIImage *image1 = [PLVECUtils imageForWatchResource:@"plv_audio_animal_img1"];
        UIImage *image2 = [PLVECUtils imageForWatchResource:@"plv_audio_animal_img2"];
        UIImage *image3 = [PLVECUtils imageForWatchResource:@"plv_audio_animal_img3"];
        
        self.animationImageView = [[UIImageView alloc] init];
        if (image1 && image2 && image3) {
            self.animationImageView.animationDuration = 1.0;
            self.animationImageView.animationImages = @[image1,image2,image3];
        }
        [self addSubview:self.animationImageView];
        
        self.contentLable = [[UILabel alloc] init];
        self.contentLable.textColor = UIColor.whiteColor;
        self.contentLable.font = [UIFont systemFontOfSize:14];
        self.contentLable.textAlignment = NSTextAlignmentCenter;
        self.contentLable.text = @"音频直播中";
        [self addSubview:self.contentLable];
    }
    return self;
}

- (void)layoutSubviews {
    CGSize imageSize = CGSizeMake(48.0, 120.0);
    CGSize scaleImageSize = CGSizeMake(self.bounds.size.height * 48.0 / 120.0, self.bounds.size.height);
    if (self.bounds.size.height < 120.0) {
        self.animationImageView.frame = CGRectMake((self.bounds.size.width - scaleImageSize.width) / 2.0, 0, scaleImageSize.width, scaleImageSize.height);
        self.contentLable.frame = CGRectZero;
    } else {
        self.animationImageView.frame = CGRectMake((self.bounds.size.width - imageSize.width) / 2.0, (self.bounds.size.height - imageSize.height) / 2.0, imageSize.width, imageSize.height);
        self.contentLable.frame = CGRectMake(0, CGRectGetMaxY(self.animationImageView.frame) + 15, CGRectGetWidth(self.bounds), 16);
    }
}

- (void)startAnimating {
    self.hidden = NO;
    [self.animationImageView startAnimating];
}

- (void)stopAnimating {
    self.hidden = YES;
    [self.animationImageView stopAnimating];
}

@end
