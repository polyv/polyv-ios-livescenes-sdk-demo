//
//  PLVRewardDisplayView.m
//  PolyvCloudClassDemo
//
//  Created by Lincal on 2019/12/5.
//  Copyright © 2019 polyv. All rights reserved.
//

#import "PLVRewardDisplayView.h"
#import "PLVMultiLanguageManager.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import <SDWebImage/SDWebImageDownloader.h>
#if __has_include(<SDWebImage/SDAnimatedImageView.h>)
    #import <SDWebImage/SDAnimatedImageView.h>
    #define SDWebImageSDK5
#endif

@interface PLVRewardDisplayView ()

@property (nonatomic, strong) UIView * bgView;
@property (nonatomic, strong) UIView * gradientBgView;
@property (nonatomic, strong) CAGradientLayer * gradientBgLayer;
@property (nonatomic, strong) UILabel * nameLabel;
@property (nonatomic, strong) UILabel * prizeNameLabel;
#ifdef SDWebImageSDK5
@property (nonatomic, strong) SDAnimatedImageView * prizeImageView;
#else
@property (nonatomic, strong) UIImageView * prizeImageView;
#endif
@property (nonatomic, strong) UIView * animationBgView;
@property (nonatomic, strong) PLVStrokeBorderLabel * xSymbolLabel;
@property (nonatomic, strong) PLVStrokeBorderLabel * numLabel;

@property (nonatomic, strong) PLVRewardGoodsModel * model;

@end

@implementation PLVRewardDisplayView

- (void)layoutSubviews{
    self.gradientBgLayer.frame = self.gradientBgView.bounds;
}

#pragma mark - [ Init ]
- (instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        [self initUI];
    }
    return self;
}


- (void)initUI{
    self.clipsToBounds = YES;

    [self addSubview:self.bgView];
    [self.bgView addSubview:self.gradientBgView];
    [self.gradientBgView.layer addSublayer:self.gradientBgLayer];
    [self.bgView addSubview:self.nameLabel];
    [self.bgView addSubview:self.prizeNameLabel];

    [self.bgView addSubview:self.prizeImageView];
    [self.bgView addSubview:self.animationBgView];
    [self.animationBgView addSubview:self.xSymbolLabel];
    [self.animationBgView addSubview:self.numLabel];

    /// layout
    self.bgView.frame = CGRectMake(0, 0, PLVDisplayViewWidth, PLVDisplayViewHeight);

    self.gradientBgView.frame = CGRectMake(0, 11, CGRectGetWidth(self.bgView.frame), CGRectGetHeight(self.bgView.frame) - 11);

    self.nameLabel.frame = CGRectMake(12, CGRectGetMinY(self.gradientBgView.frame) + 4, 140, 20);

    self.prizeNameLabel.frame = CGRectMake(13, CGRectGetMaxY(self.gradientBgView.frame) - 20, 140, 20);

    self.prizeImageView.frame = CGRectMake(155, 0, 48, 48);

    self.animationBgView.frame = CGRectMake(CGRectGetMaxX(self.prizeImageView.frame), 11, 80, CGRectGetHeight(self.bgView.frame) - 11);

    self.xSymbolLabel.frame = CGRectMake(0, CGRectGetHeight(self.animationBgView.frame) - 22, 20, 20);

    self.numLabel.frame = CGRectMake(CGRectGetMaxX(self.xSymbolLabel.frame), CGRectGetMinY(self.xSymbolLabel.frame) - 5, 60, 25);

}


#pragma mark - [ Private Methods ]
#pragma mark Getter
- (UIView *)bgView{
    if (!_bgView) {
        _bgView = [[UIView alloc]init];
    }
    return _bgView;
}

- (UIView *)gradientBgView{
    if (!_gradientBgView) {
        _gradientBgView = [[UIView alloc]init];
    }
    return _gradientBgView;
}

- (CAGradientLayer *)gradientBgLayer{
    if (!_gradientBgLayer) {
        _gradientBgLayer = [CAGradientLayer layer];
        _gradientBgLayer.startPoint = CGPointMake(0.5, 0.5);
        _gradientBgLayer.endPoint = CGPointMake(1.0, 0.5);
        _gradientBgLayer.colors = @[(__bridge id)[UIColor colorWithRed:235/255.0 green:81/255.0 blue:69/255.0 alpha:1.0].CGColor, (__bridge id)[UIColor colorWithWhite:1 alpha:0].CGColor];
        _gradientBgLayer.locations = @[@(0), @(1.0f)];
    }
    return _gradientBgLayer;
}

- (UILabel *)nameLabel{
    if (!_nameLabel) {
        _nameLabel = [[UILabel alloc]init];
        _nameLabel.textAlignment = NSTextAlignmentLeft;
        _nameLabel.textColor = [UIColor colorWithRed:252/255.0 green:242/255.0 blue:166/255.0 alpha:1.0];
        _nameLabel.font = [UIFont fontWithName:@"PingFangSC-Medium" size:14];
        _nameLabel.text = PLVLocalizedString(@"观众名");
    }
    return _nameLabel;
}

- (UILabel *)prizeNameLabel{
    if (!_prizeNameLabel) {
        _prizeNameLabel = [[UILabel alloc]init];
        _prizeNameLabel.textAlignment = NSTextAlignmentLeft;
        _prizeNameLabel.textColor = [UIColor whiteColor];
        _prizeNameLabel.font = [UIFont fontWithName:@"PingFang SC" size:10];
        _prizeNameLabel.text = PLVLocalizedString(@"赠送    礼物");
    }
    return _prizeNameLabel;
}

#ifdef SDWebImageSDK5
- (SDAnimatedImageView *)prizeImageView{
    if (!_prizeImageView) {
        _prizeImageView = [[SDAnimatedImageView alloc]init];
        
    }
    return _prizeImageView;
}
#else
- (UIImageView *)prizeImageView{
    if (!_prizeImageView) {
        _prizeImageView = [[UIImageView alloc]init];
        
    }
    return _prizeImageView;
}
#endif

- (UIView *)animationBgView{
    if (!_animationBgView) {
        _animationBgView = [[UIView alloc]init];
    }
    return _animationBgView;
}

- (PLVStrokeBorderLabel *)xSymbolLabel{
    if (!_xSymbolLabel) {
        _xSymbolLabel = [[PLVStrokeBorderLabel alloc]init];
        _xSymbolLabel.text = @"x";
        _xSymbolLabel.textAlignment = NSTextAlignmentCenter;
        _xSymbolLabel.textColor = [UIColor colorWithRed:245/255.0 green:124/255.0 blue:0/255.0 alpha:1.0];
        CGAffineTransform matrix = CGAffineTransformMake(1, 0, tanf(5 * (CGFloat)M_PI / 180), 1, 0, 0);
        UIFontDescriptor * fontDesc = [UIFontDescriptor fontDescriptorWithName:@"PingFangSC-Semibold" matrix:matrix];
        _xSymbolLabel.font = [UIFont fontWithDescriptor:fontDesc size:20];
    }
    return _xSymbolLabel;
}

- (PLVStrokeBorderLabel *)numLabel{
    if (!_numLabel) {
        _numLabel = [[PLVStrokeBorderLabel alloc]init];
        _numLabel.text = @"x 1";
        _numLabel.textAlignment = NSTextAlignmentLeft;
        _numLabel.textColor = [UIColor colorWithRed:245/255.0 green:124/255.0 blue:0/255.0 alpha:1.0];
        CGAffineTransform matrix = CGAffineTransformMake(1, 0, tanf(5 * (CGFloat)M_PI / 180), 1, 0, 0);
        UIFontDescriptor * fontDesc = [UIFontDescriptor fontDescriptorWithName:@"PingFangSC-Semibold" matrix:matrix];
        _numLabel.font = [UIFont fontWithDescriptor:fontDesc size:28];
    }
    return _numLabel;
}


#pragma mark - [ Public Methods ]
+ (instancetype)displayViewWithModel:(PLVRewardGoodsModel *)model
                            goodsNum:(NSInteger)goodsNum
                          personName:(NSString *)personName{
    if ([model isKindOfClass:PLVRewardGoodsModel.class]) {
        PLVRewardDisplayView * view = [[PLVRewardDisplayView alloc]init];
        [view.prizeImageView sd_setImageWithURL:[NSURL URLWithString:model.goodImgFullURL]];
        view.prizeNameLabel.text = [NSString stringWithFormat:PLVLocalizedString(@"赠送  %@"),model.goodName];
        
        view.nameLabel.text = personName;
        view.numLabel.text = [NSString stringWithFormat:@"%ld",goodsNum];
        
        if (goodsNum > 1) {
            view.animationBgView.hidden = NO;
        }else{
            view.animationBgView.hidden = YES;
        }
        
        view.model = model;
        return view;
    }else{
        return nil;
    }
}

- (void)showNumAnimation{
    if ([self.numLabel.text integerValue] > 1) {
        [self showZoomAnimationWithLayer:self.animationBgView.layer];
    }
    
    __weak typeof(self) weakSelf = self;
    float delayTime = 0.12 + 0.15 + 0.15 + 1;
    [UIView animateWithDuration:0.1 delay:delayTime options:UIViewAnimationOptionCurveEaseInOut animations:^{
        weakSelf.bgView.alpha = 0.2;
    } completion:^(BOOL finished) {
        [weakSelf removeFromSuperview];
        if (weakSelf.willRemoveBlock) { weakSelf.willRemoveBlock(); }
    }];
}

- (void)showZoomAnimationWithLayer:(CALayer *)layer{
    float toTime = 0.12;
    CABasicAnimation * animation = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    animation.fromValue = [NSNumber numberWithFloat:1.0];
    animation.toValue = [NSNumber numberWithFloat:1.5];
    animation.duration = toTime;
    animation.autoreverses = NO;
    animation.repeatCount = 0;
    animation.removedOnCompletion = NO;
    animation.fillMode = kCAFillModeForwards;
    [layer addAnimation:animation forKey:@"zoom"];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(toTime + 0.15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        CABasicAnimation * animationBack = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
        animationBack.fromValue = [NSNumber numberWithFloat:1.5];
        animationBack.toValue = [NSNumber numberWithFloat:1.0];
        animationBack.duration = 0.15;
        animationBack.autoreverses = NO;
        animationBack.repeatCount = 0;
        animationBack.removedOnCompletion = NO;
        animationBack.fillMode = kCAFillModeForwards;
        [layer addAnimation:animationBack forKey:@"zoom"];
    });
}

@end

@implementation PLVStrokeBorderLabel

- (void)drawTextInRect:(CGRect)rect
{
    // 描边
    CGContextRef c = UIGraphicsGetCurrentContext ();
    CGContextSetLineWidth (c, 3);
    CGContextSetLineJoin (c, kCGLineJoinRound);
    CGContextSetTextDrawingMode (c, kCGTextStroke);

    // 描边颜色
    UIColor * originColor = self.textColor;
    self.textColor = [UIColor whiteColor];
    [super drawTextInRect:rect];

    // 文字颜色
    self.textColor = originColor;
    CGContextSetTextDrawingMode (c, kCGTextFill);
    [super drawTextInRect:rect];
}

@end
