//
//  PLVSAStatusBarButton.m
//  PLVLiveScenesDemo
//
//  Created by lijingtong on 2021/7/28.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVSAStatusBarButton.h"

@interface PLVSAStatusBarButton()

#pragma mark UI

@property (nonatomic, strong) UIImageView *imageView; // 主图片视图
@property (nonatomic, strong) UILabel *titleLabel; // 标题视图
@property (nonatomic, strong) UIImageView *indicatorImageView; // 指示图片视图

@end

@implementation PLVSAStatusBarButton

#pragma mark - [ Life Cycle ]

- (instancetype)init {
    self = [super init];
    if (self) {
        self.backgroundColor = [UIColor colorWithRed:0/255.0 green:0/255.0 blue:0/255.0 alpha:0.2];
        _titlePaddingX = 2;
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGesture)];
        [self addGestureRecognizer:tap];
        
        [self addSubview:self.imageView];
        [self addSubview:self.titleLabel];
        [self addSubview:self.indicatorImageView];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGSize selfSize = self.bounds.size;
    CGFloat paddingX = 8;
    CGFloat titlePaddingX = self.titlePaddingX;
    
    CGSize imageSize = self.imageView.image.size;
    self.imageView.frame = CGRectMake(paddingX, (selfSize.height - imageSize.height) / 2, imageSize.width, imageSize.height);
    
    CGSize indicatorSize = self.indicatorImageView.image.size;
    self.indicatorImageView.frame = CGRectMake(selfSize.width - indicatorSize.width - paddingX, (selfSize.height - indicatorSize.height) / 2, indicatorSize.width, indicatorSize.height);
    
    CGSize titleSize = CGSizeMake(selfSize.width - CGRectGetMaxX(self.imageView.frame) - indicatorSize.width - paddingX - titlePaddingX, self.titleLabel.font.lineHeight);
    self.titleLabel.frame = CGRectMake(CGRectGetMaxX(self.imageView.frame) + titlePaddingX, (selfSize.height - titleSize.height) / 2, titleSize.width, titleSize.height);
}

#pragma mark - [ Public Method ]

- (void)setImage:(UIImage *)image {
    self.imageView.image = image;
}

- (void)setImage:(UIImage *)image indicatorImage:(UIImage *)indicatorImage {
    self.imageView.image = image;
    self.indicatorImageView.image = indicatorImage;
}

- (void)enableWarningMode:(BOOL)warning {
    if (warning) {
        self.backgroundColor = [UIColor colorWithRed:0xff/255.0 green:0x63/255.0 blue:0x63/255.0 alpha:0.2];
        self.titleLabel.textColor = [UIColor colorWithRed:0xff/255.0 green:0x63/255.0 blue:0x63/255.0 alpha:1.0];
    } else {
        self.backgroundColor = [UIColor colorWithRed:0/255.0 green:0/255.0 blue:0/255.0 alpha:0.2];
        self.titleLabel.textColor = [UIColor whiteColor];
    }
}

#pragma mark - [ Private Method ]
#pragma mark Getter

- (UIImageView *)imageView {
    if (!_imageView) {
        _imageView = [[UIImageView alloc] init];
    }
    return _imageView;
}

- (UIImageView *)indicatorImageView {
    if (!_indicatorImageView) {
        _indicatorImageView = [[UIImageView alloc] init];
    }
    return _indicatorImageView;
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = [UIFont systemFontOfSize:12];
        _titleLabel.textColor = [UIColor whiteColor];
    }
    return _titleLabel;
}

#pragma mark Setter

- (void)setText:(NSString *)text {
    if (!text ||
        ![text isKindOfClass:[NSString class]] ||
        text.length == 0) {
        text = @"";
    }
    _text = text;
    self.titleLabel.text = text;
}

- (void)setTextColor:(UIColor *)textColor {
    if (!textColor ||
        ![textColor isKindOfClass:[UIColor class]]) {
        textColor = [UIColor whiteColor];
    }
    _textColor = textColor;
    self.titleLabel.textColor = textColor;
}

- (void)setFont:(UIFont *)font {
    if (!font ||
        ![font isKindOfClass:[UIFont class]]) {
        font = [UIFont systemFontOfSize:12];
    }
    _font = font;
    self.titleLabel.font = font;
}

#pragma mark - [ Event ]
#pragma mark Gesture

- (void)tapGesture {
    if (self.didTapHandler) {
        self.didTapHandler();
    }
}

@end
