//
//  PLVSABeautyMaskView.m
//  PolyvLiveScenesDemo
//
//  Created by JTom on 2022/4/15.
//  Copyright © 2022 PLV. All rights reserved.
//

#import "PLVSABeautyMaskView.h"
// 工具类
#import "PLVSAUtils.h"

// 依赖库
#import <PLVFoundationSDK/PLVFoundationSDK.h>

@implementation PLVSABeautyMaskView

#pragma mark - [ Life Cycle ]

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self addSubview:self.maskImageView];
        self.layer.cornerRadius = 8;
        
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.maskImageView.frame = CGRectMake((self.bounds.size.width - 28) / 2, 22, 28, 10);
}

#pragma mark - [ Public Method ]
- (void)beautyOpen:(BOOL)open {
    self.maskImageView.hidden = !open;
    if (open) {
        self.backgroundColor = [PLVColorUtil colorFromHexString:@"#4399FF" alpha:0.4];
        self.layer.borderColor = [PLVColorUtil colorFromHexString:@"#4399FF"].CGColor;
        self.layer.borderWidth = 2;
    } else {
        self.backgroundColor = [PLVColorUtil colorFromHexString:@"#000000" alpha:0.4];
        self.layer.borderColor = [UIColor clearColor].CGColor;
    }
}

- (UIImageView *)maskImageView {
    if (!_maskImageView) {
        _maskImageView = [[UIImageView alloc] init];
        _maskImageView.contentMode = UIViewContentModeScaleAspectFit;
        _maskImageView.image = [PLVSAUtils imageForBeautyResource:@"plvsa_beauty_cell_mask"];
    }
    return _maskImageView;
}

@end
