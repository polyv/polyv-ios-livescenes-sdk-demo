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

@property (nonatomic, assign) NSUInteger localLikeCount; // 本地点赞数量，用于区分自己的点赞还是别人的点赞，控制动画显示。

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
        self.likeCountLabel.frame = CGRectMake(0, CGRectGetMaxY(self.likeButton.frame) + 10, 46, 16);
        self.likeCountLabel.hidden = NO;
    }else{
        CGFloat viewWidth = CGRectGetWidth(self.bounds);
        self.likeButton.frame = CGRectMake(0, 0, viewWidth, viewWidth);
        self.likeCountLabel.hidden = YES;
    }
}

#pragma mark - [ Public Method ]
- (void)setupLikeAnimationWithCount:(NSInteger)likeCount {
    if (likeCount < 0) {
        return;
    }
    
    if (likeCount > self.localLikeCount) { // 其他人的点赞
        NSUInteger addLikeCount = MIN(likeCount - self.likeCount, 5); // 新增的点赞（最多显示5次点赞动画）
        CGFloat duration = addLikeCount > 1 ? 0.3 : 0.0; // 新增的点赞数量超过两个，设一个动画间隔
        __weak typeof(self) weakSelf = self;
        for (NSUInteger i = 1; i <= addLikeCount; i++) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(i * duration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [weakSelf likeAnimationWithLocalTouch:NO];
            });
        }
    }
    self.likeCount = likeCount; // 设置点赞数量
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
        _likeCountLabel.backgroundColor = [UIColor clearColor];
        _likeCountLabel.layer.cornerRadius = 8;
        _likeCountLabel.layer.masksToBounds = YES;
    }
    return _likeCountLabel;
}

- (void)setLikeCount:(NSUInteger)likeCount {
    _likeCount = likeCount;
    NSString *string = nil;
    if (likeCount < 0) {
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
    self.localLikeCount = [self.likeCountLabel.text integerValue] + 1;
    if (self.delegate && [self.delegate respondsToSelector:@selector(didTapLikeButton:)]) {
        [self.delegate didTapLikeButton:self];
    }
    [self likeAnimationWithLocalTouch:YES];
}

#pragma mark - Private Method

- (void)likeAnimationWithLocalTouch:(BOOL)localTouch {
    if (localTouch) { // 本地点击按钮动画
        // 旋转动画
        CABasicAnimation *rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
        // 旋转多少角度
        rotationAnimation.toValue = @(-0.2 * M_PI);
        
        //放大动画
        CABasicAnimation *scaleAnimation = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
        // 放大倍率
        scaleAnimation.toValue = @(1.5);
        
        // 动画组
        CAAnimationGroup *groupAnimation = [CAAnimationGroup animation];
        groupAnimation.duration = 0.1;
        scaleAnimation.repeatCount = 0;
        groupAnimation.autoreverses = YES;
        groupAnimation.animations = @[rotationAnimation, scaleAnimation];
        [self.likeButton.layer addAnimation:groupAnimation forKey:@"rotation-scale-animation"];
    }

    CGRect originRect = self.frame;
    NSArray *imageNames = @[@"plvlc_chatroom_like_icon1",@"plvlc_chatroom_like_icon2",@"plvlc_chatroom_like_icon3",
          @"plvlc_chatroom_like_icon4",@"plvlc_chatroom_like_icon5",@"plvlc_chatroom_like_icon6",
          @"plvlc_chatroom_like_icon7",@"plvlc_chatroom_like_icon8",@"plvlc_chatroom_like_icon9",@"plvlc_chatroom_like_icon10"];
    NSString *imageName = imageNames[rand() % imageNames.count];
    UIImage *image = [PLVLCUtils imageForChatroomResource:imageName];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
    imageView.frame = CGRectMake(originRect.origin.x + 3, originRect.origin.y, 20, 20);
    [self.superview insertSubview:imageView belowSubview:self];
    
    //放大动画
    CABasicAnimation *imageScaleAnimation = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    //结束时的倍率
    imageScaleAnimation.toValue = @(1.5);
    imageScaleAnimation.duration = 0.3;
    imageScaleAnimation.removedOnCompletion = NO;
    imageScaleAnimation.fillMode = kCAFillModeForwards;
    [imageView.layer addAnimation:imageScaleAnimation forKey:@"scale-animation"];
    
    //曲线动画
    CAKeyframeAnimation *curveAnimation = [CAKeyframeAnimation animationWithKeyPath:@"position"];
    curveAnimation.duration = 1.5;
    // 设置贝塞尔曲线路径
    CGFloat finishX = originRect.origin.x + CGRectGetWidth(originRect) - round(arc4random() % 130);
    CGFloat finishY = originRect.origin.y - 200;
    NSValue *startPoint = [NSValue valueWithCGPoint:CGPointMake(originRect.origin.x + 3, originRect.origin.y)];
    NSValue *endPoint = [NSValue valueWithCGPoint:CGPointMake(finishX, finishY)];
    curveAnimation.values = @[startPoint, endPoint];
    [imageView.layer addAnimation:curveAnimation forKey:@"curve-animation"];
    
    [UIView animateWithDuration:0.3 delay:1.2 options:UIViewAnimationOptionCurveLinear animations:^{
        imageView.alpha = 0.0;
    } completion:^(BOOL finished) {
        [imageView removeFromSuperview];
    }];
}

@end
