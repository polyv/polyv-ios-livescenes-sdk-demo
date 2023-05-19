//
//  PLVLSSignalButton.m
//  PLVLiveScenesDemo
//
//  Created by lijingtong on 2021/7/28.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVLSSignalButton.h"

@interface PLVLSSignalButton()

#pragma mark UI

@property (nonatomic, strong) UIImageView *imageView; // 主图片视图
@property (nonatomic, strong) UILabel *titleLabel; // 标题视图

@end

@implementation PLVLSSignalButton

#pragma mark - [ Life Cycle ]

- (instancetype)init {
    self = [super init];
    if (self) {
        self.backgroundColor = [UIColor colorWithRed:0x1b/255.0 green:0x20/255.0 blue:0x2d/255.0 alpha:0.2];
        self.layer.cornerRadius = 10;
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGesture)];
        [self addGestureRecognizer:tap];
        
        [self addSubview:self.imageView];
        [self addSubview:self.titleLabel];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGSize selfSize = self.bounds.size;
    
    CGSize imageSize = self.imageView.image.size;
    self.imageView.frame = CGRectMake(8, (selfSize.height - imageSize.height) / 2, imageSize.width, imageSize.height);
    
    CGFloat titleHeight = self.titleLabel.font.lineHeight;
    self.titleLabel.frame = CGRectMake(24, (selfSize.height - titleHeight) / 2, selfSize.width - 24, titleHeight);
}

#pragma mark - [ Public Method ]

- (void)setImage:(UIImage *)image {
    self.imageView.image = image;
}

- (void)enableWarningMode:(BOOL)warning {
    if (warning) {
        self.backgroundColor = [UIColor colorWithRed:0xff/255.0 green:0x63/255.0 blue:0x63/255.0 alpha:0.2];
        self.titleLabel.textColor = [UIColor colorWithRed:0xff/255.0 green:0x63/255.0 blue:0x63/255.0 alpha:1.0];
    } else {
        self.backgroundColor = [UIColor colorWithRed:0x1b/255.0 green:0x20/255.0 blue:0x2d/255.0 alpha:0.2];
        self.titleLabel.textColor = [UIColor colorWithRed:0xf0/255.0 green:0xf1/255.0 blue:0xf5/255.0 alpha:1];
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

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = [UIFont systemFontOfSize:12];
        _titleLabel.textColor = [UIColor colorWithRed:0xf0/255.0 green:0xf1/255.0 blue:0xf5/255.0 alpha:1];
        _titleLabel.text = @"检测中";
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

#pragma mark - [ Event ]
#pragma mark Gesture

- (void)tapGesture {
    if (self.didTapHandler) {
        self.didTapHandler();
    }
}

@end
