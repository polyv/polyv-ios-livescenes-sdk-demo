//
//  PLVLCLikeButtonView.m
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2020/10/10.
//  Copyright © 2020 PLV. All rights reserved.
//

#import "PLVLCLikeButtonView.h"
#import "PLVLCUtils.h"
#import <PLVFoundationSDK/PLVColorUtil.h>

@interface PLVLCLikeButtonView ()

@property (nonatomic, strong) UIButton *likeButton;

@property (nonatomic, strong) UILabel *likeCountLabel;

@end

@implementation PLVLCLikeButtonView

#pragma mark - Life Cycle

- (instancetype)init {
    self = [super init];
    if (self) {
        [self addSubview:self.likeButton];
        [self addSubview:self.likeCountLabel];
    }
    return self;
}

- (void)layoutSubviews {
    BOOL fullScreen = [UIScreen mainScreen].bounds.size.width > [UIScreen mainScreen].bounds.size.height;
    if (!fullScreen) {
        self.likeButton.frame = CGRectMake(0, 0, 46, 46);
        self.likeCountLabel.frame = CGRectMake(0, CGRectGetMaxY(self.likeButton.frame) + 2, 46, 16);
        self.likeCountLabel.hidden = NO;
    }else{
        CGFloat viewWidth = CGRectGetWidth(self.bounds);
        self.likeButton.frame = CGRectMake(0, 0, viewWidth, viewWidth);
        self.likeCountLabel.hidden = YES;
    }
}

#pragma mark - Getter & Setter

- (UIButton *)likeButton {
    if (!_likeButton) {
        _likeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_likeButton addTarget:self action:@selector(likeAction:) forControlEvents:UIControlEventTouchUpInside];
        UIImage *image = [PLVLCUtils imageForChatroomResource:@"plvlc_chatroom_like"];
        [_likeButton setImage:image forState:UIControlStateNormal];
    }
    return _likeButton;
}

- (UILabel *)likeCountLabel {
    if (!_likeCountLabel) {
        _likeCountLabel = [[UILabel alloc] init];
        _likeCountLabel.textAlignment = NSTextAlignmentCenter;
        _likeCountLabel.textColor = [UIColor colorWithRed:0xad/255.0 green:0xad/255.0 blue:0xc0/255.0 alpha:1];
        _likeCountLabel.font = [UIFont systemFontOfSize:14];
        _likeCountLabel.backgroundColor = [PLVColorUtil colorFromHexString:@"#202127"];
        _likeCountLabel.layer.cornerRadius = 8;
        _likeCountLabel.layer.masksToBounds = YES;
    }
    return _likeCountLabel;
}

- (void)setLikeCount:(NSUInteger)likeCount {
    _likeCount = likeCount;
    NSString *string = nil;
    if (likeCount <= 0) {
        string = @"";
    } else if (likeCount > 9999) {
        string = [NSString stringWithFormat:@"%.1fw", likeCount/10000.0];
    } else {
        string = [NSString stringWithFormat:@"%zd", likeCount];
    }
    self.likeCountLabel.text = string;
}

#pragma mark - Action

- (void)likeAction:(id)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(didTapLikeButton:)]) {
        [self.delegate didTapLikeButton:self];
    }
    [self likeAnimation];
}

#pragma mark - Private Method

- (void)likeAnimation {
    NSArray *colors = @[PLV_UIColorFromRGB(@"9D86D2"), PLV_UIColorFromRGB(@"F25268"), PLV_UIColorFromRGB(@"5890FF"), PLV_UIColorFromRGB(@"FCBC71")];
    
    CGRect originRect = self.frame;
    UIImage *image = [PLVLCUtils imageForChatroomResource:@"plvlc_chatroom_like_icon"];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
    imageView.frame = CGRectMake(originRect.origin.x + 3, originRect.origin.y, 40, 40);
    imageView.backgroundColor = colors[rand()%4];
    [imageView setContentMode:UIViewContentModeCenter];
    imageView.clipsToBounds = YES;
    imageView.layer.cornerRadius = 20.0;
    [self.superview addSubview:imageView];
    
    CGFloat finishX = originRect.origin.x + CGRectGetWidth(originRect) - round(arc4random() % 130);
    CGFloat speed = 1.0 / round(arc4random() % 900) + 0.6;
    NSTimeInterval duration = 4.0 * speed;
    if (duration == INFINITY) {
        duration = 2.412346;
    }
    
    [UIView animateWithDuration:duration animations:^{
        imageView.alpha = 0.0;
        imageView.frame = CGRectMake(finishX, originRect.origin.y - 156, 40.0, 40.0);
    } completion:^(BOOL finished) {
        [imageView removeFromSuperview];
    }];
}

@end
