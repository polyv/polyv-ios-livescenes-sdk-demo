//
//  PLVECPlayerBackgroundView.m
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2020/12/3.
//  Copyright © 2020 PLV. All rights reserved.
//

#import "PLVECPlayerBackgroundView.h"
#import "PLVECUtils.h"

@interface PLVECPlayerBackgroundView ()

@property (nonatomic, strong) UIImageView *imageView;

@property (nonatomic, strong) UILabel *label;

@end

@implementation PLVECPlayerBackgroundView

- (instancetype)init {
    self = [super init];
    if (self) {
        self.backgroundColor = [UIColor blackColor];
        
        [self addSubview:self.imageView];
        [self addSubview:self.label];
    }
    return self;
}

- (void)layoutSubviews {
    CGSize imageSize = CGSizeMake(150.0, 115.0);
    CGSize scaleImageSize = CGSizeMake(self.bounds.size.height * 150.0 / 115.0, self.bounds.size.height);
    
    if (self.bounds.size.height < 115.0) {
        self.imageView.frame = CGRectMake((self.bounds.size.width - scaleImageSize.width) / 2.0, 0, scaleImageSize.width, scaleImageSize.height);
        self.label.frame = CGRectZero;
    } else {
        CGFloat originY = (self.bounds.size.height - imageSize.height) / 2.0 - 16;
        self.imageView.frame = CGRectMake((self.bounds.size.width - imageSize.width) / 2.0, originY, imageSize.width, imageSize.height);
        self.label.frame = CGRectMake(0, CGRectGetMaxY(self.imageView.frame) + 18, self.bounds.size.width, 16);
    }
}

- (UIImageView *)imageView {
    if (!_imageView) {
        UIImage *image = [PLVECUtils imageForWatchResource:@"plv_skin_player_background"];
        _imageView = [[UIImageView alloc] initWithImage:image];
        _imageView.contentMode = UIViewContentModeScaleAspectFit;
    }
    return _imageView;
}

- (UILabel *)label {
    if (!_label) {
        _label = [[UILabel alloc] init];
        _label.text = @"暂无直播";
        _label.textColor = UIColor.whiteColor;
        _label.textAlignment = NSTextAlignmentCenter;
        _label.font = [UIFont systemFontOfSize:14.0];
    }
    return _label;
}

@end
