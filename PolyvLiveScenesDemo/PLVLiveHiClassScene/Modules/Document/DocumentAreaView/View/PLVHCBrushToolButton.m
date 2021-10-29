//
//  PLVHCBrushToolButton.m
//  PLVLiveScenesDemo
//
//  Created by lijingtong on 2021/7/20.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVHCBrushToolButton.h"

// 工具
#import "PLVHCUtils.h"

// 依赖库
#import <PLVFoundationSDK/PLVFoundationSDK.h>

@interface PLVHCBrushToolButton()

@property (nonatomic, strong) UIView *bgView;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIImageView *moreImageView;

@end

@implementation PLVHCBrushToolButton

#pragma mark - [ Life Cycle ]

- (instancetype)init {
    self = [super init];
    if (self) {
        [self.bgView addSubview:self.imageView];
        [self addSubview:self.bgView];
        [self addSubview:self.moreImageView];
        
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGesture)];
        [self addGestureRecognizer:tapGesture];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.bgView.frame = self.bounds;
    self.imageView.frame = self.bgView.bounds;
    self.moreImageView.frame = CGRectMake(self.bounds.size.width - 6, self.bounds.size.height - 6, 6, 6);
}

#pragma mark - [ Public Method ]

- (void)setImage:(UIImage *)image {
    self.imageView.image = image;
}

#pragma mark - [ Private Method ]
#pragma mark Getter

- (UIView *)bgView {
    if (!_bgView) {
        _bgView = [[UIView alloc] init];
        _bgView.backgroundColor = [PLVColorUtil colorFromHexString:@"#242940"];
        _bgView.layer.cornerRadius = 18;
        _bgView.layer.masksToBounds = YES;
    }
    return _bgView;
}

- (UIImageView *)imageView {
    if (!_imageView) {
        _imageView = [[UIImageView alloc] init];
    }
    return _imageView;
}

- (UIImageView *)moreImageView {
    if (!_moreImageView) {
        _moreImageView = [[UIImageView alloc] init];
        _moreImageView.image = [PLVHCUtils imageForDocumentResource:@"plvhc_brush_btn_more"];
    }
    return _moreImageView;
}

#pragma mark - [ Event ]
#pragma mark Gesture

- (void)tapGesture {
    if (self.didTapButton) {
        self.didTapButton();
    }
}

@end
