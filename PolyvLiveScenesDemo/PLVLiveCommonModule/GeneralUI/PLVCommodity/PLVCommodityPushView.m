//
//  PLVCommodityPushView.m
//  PLVLiveScenesDemo
//
//  Created by ftao on 2020/8/20.
//  Copyright © 2020 PLV. All rights reserved.
//  推送商品

#import "PLVCommodityPushView.h"
#import <PLVFoundationSDK/PLVFoundationSDK.h>

@interface PLVCommodityPushView ()

@property (nonatomic, strong) UIImageView *coverImageView;

@property (nonatomic, strong) UILabel *showIdLabel;

@property (nonatomic, strong) UILabel *nameLabel;

@property (nonatomic, strong) UILabel *realPriceLabel;

@property (nonatomic, strong) UILabel *priceLabel;
/// 标签
@property (nonatomic, strong) UILabel *firstTagLabel;

@property (nonatomic, strong) UILabel *secondTagLabel;
/// 商品描述
@property (nonatomic, strong) UILabel *productDescLabel;

@property (nonatomic, strong) UIButton *closeButton;

@property (nonatomic, strong) UIButton *jumpButton;

@property (nonatomic, strong) NSTimer *timer;

@property (nonatomic, assign) NSInteger timing;

@property (nonatomic, assign) CGRect initialFrame;

@property (nonatomic, assign) PLVCommodityPushViewType type;

@end

@implementation PLVCommodityPushView

#pragma mark - [ Life Cycle ]

- (instancetype)initWithType:(PLVCommodityPushViewType)type {
    self = [super init];
    if (self) {
        // 使用-drawLayer:画出带三角形的路径
        //self.backgroundColor = UIColor.whiteColor;
        //self.layer.cornerRadius = 10.f;
        //self.layer.masksToBounds = YES;
        self.type = type;
        
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureAction)];
        [self addGestureRecognizer:tapGesture];
        
        self.coverImageView = [[UIImageView alloc] init];
        self.coverImageView.layer.cornerRadius = 10.0;
        self.coverImageView.layer.masksToBounds = YES;
        self.coverImageView.contentMode = UIViewContentModeScaleAspectFill;
        [self addSubview:self.coverImageView];
        
        self.showIdLabel = [[UILabel alloc] init];
        self.showIdLabel.frame = CGRectMake(0, 0, 27, 16);
        self.showIdLabel.textColor = UIColor.whiteColor;
        self.showIdLabel.font = [UIFont systemFontOfSize:12];
        self.showIdLabel.textAlignment = NSTextAlignmentCenter;
        self.showIdLabel.backgroundColor = [UIColor colorWithWhite:0 alpha:0.35f];
        [self.coverImageView addSubview:self.showIdLabel];
        
        self.nameLabel = [[UILabel alloc] init];
        self.nameLabel.textColor = [UIColor colorWithWhite:51/255.f alpha:1];
        self.nameLabel.font = [UIFont systemFontOfSize:14];
        [self addSubview:self.nameLabel];
        
        self.firstTagLabel = [self productTagsLabel];
        self.secondTagLabel = [self productTagsLabel];
        [self addSubview:self.firstTagLabel];
        [self addSubview:self.secondTagLabel];
        [self addSubview:self.productDescLabel];

        self.realPriceLabel = [[UILabel alloc] init];
        self.realPriceLabel.textColor = [UIColor colorWithRed:1 green:71/255.f blue:58/255.f alpha:1];
        self.realPriceLabel.textAlignment = NSTextAlignmentLeft;
        if (@available(iOS 8.2, *)) {
            self.realPriceLabel.font = [UIFont systemFontOfSize:18.0 weight:UIFontWeightSemibold];
        } else {
            self.realPriceLabel.font = [UIFont systemFontOfSize:18.0];
        }
        [self addSubview:self.realPriceLabel];
        
        self.priceLabel = [[UILabel alloc] init];
        self.priceLabel.textAlignment = NSTextAlignmentLeft;
        [self addSubview:self.priceLabel];
        
        self.closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.closeButton setImage:[self imageForCommodityResource:@"plv_commodity_close_btn"] forState:UIControlStateNormal];
        [self.closeButton addTarget:self action:@selector(closeButtonAction) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.closeButton];
        
        self.jumpButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.jumpButton setImage:[self imageForCommodityResource:@"plv_commodity_jump_btn"] forState:UIControlStateNormal];
        [self.jumpButton setImage:[self imageForCommodityResource:@"plv_commodity_jump_btn_disabled"] forState:UIControlStateDisabled];
        [self.jumpButton addTarget:self action:@selector(jumpButtonAction) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.jumpButton];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.closeButton.frame = CGRectMake(CGRectGetWidth(self.bounds)-20, 4, 16, 16);
    self.jumpButton.frame = CGRectMake(CGRectGetWidth(self.bounds)-46, CGRectGetHeight(self.bounds)-40, 24, 24);
    
    CGFloat coverImageViewHeight = CGRectGetHeight(self.bounds) - 12 * 2;
    self.coverImageView.frame = CGRectMake(12, 12, coverImageViewHeight, coverImageViewHeight);
    CGFloat positionX = CGRectGetMaxX(self.coverImageView.frame) + 8;
    CGFloat positionY = 12;
    self.nameLabel.frame = CGRectMake(positionX, positionY, CGRectGetWidth(self.bounds)-positionX-22, 20);
    
    positionY = CGRectGetMaxY(self.nameLabel.frame) + 4;
    self.firstTagLabel.frame = CGRectMake(positionX, positionY, CGRectGetWidth(self.firstTagLabel.bounds) + 8, 16);
    self.secondTagLabel.frame = CGRectMake((self.firstTagLabel.isHidden ? positionX : CGRectGetMaxX(self.firstTagLabel.frame)+4), positionY, CGRectGetWidth(self.secondTagLabel.bounds) + 8, 16);
    
    positionY = (self.firstTagLabel.isHidden && self.secondTagLabel.isHidden) ? positionY : positionY + 16 + 4;
    self.productDescLabel.frame = CGRectMake(positionX, positionY, CGRectGetWidth(self.nameLabel.frame), 18);
    
    self.realPriceLabel.frame = CGRectMake(positionX, CGRectGetHeight(self.bounds)- 12 - 25, 150, 25);
    [self.realPriceLabel sizeToFit];
    CGFloat priceLabelX = CGRectGetMaxX(self.realPriceLabel.frame) + 4;
    self.priceLabel.frame = CGRectMake(priceLabelX, CGRectGetMinY(self.realPriceLabel.frame)+4, CGRectGetMinX(self.jumpButton.frame)-10-priceLabelX, 17);
    
    if (self.type == PLVCommodityPushViewTypeEC) {
        [self drawLayer];
    }
}

- (void)dealloc {
    [self destroy];
}

#pragma mark - [ Private Method ]

- (void)drawLayer {
    CGFloat midX = CGRectGetMidX(self.jumpButton.frame);
    CGFloat maxY = CGRectGetHeight(self.bounds);
    
    UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds)-6) cornerRadius:10];
    // triangle
    [maskPath moveToPoint:CGPointMake(midX,maxY)];
    [maskPath addLineToPoint:CGPointMake(midX-6, maxY-6)];
    [maskPath addLineToPoint:CGPointMake(midX+6, maxY-6)];
    [maskPath closePath];
    
    CAShapeLayer *shapeLayer = [[CAShapeLayer alloc] init];
    shapeLayer.frame = self.bounds;
    shapeLayer.fillColor = UIColor.whiteColor.CGColor;
    shapeLayer.path = maskPath.CGPath;
    [self.layer insertSublayer:shapeLayer atIndex:0];
}

- (void)hide {
    if (self.alpha == 0) { return; }
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:0.33 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        weakSelf.alpha = 0;
        weakSelf.frame = weakSelf.initialFrame;
    } completion:^(BOOL finished) {
        [weakSelf removeFromSuperview];
    }];
}

- (NSString *)getJumpLinkURLString {
    NSString *linkURLString = nil;
    // 跳转地址
    if (10 == self.model.linkType) { // 通用链接
        linkURLString = self.model.link;
    } else if (11 == self.model.linkType) { // 多平台链接
        linkURLString = self.model.mobileAppLink;
    }
    
    return linkURLString;
}

- (void)addCountdownTimer {
    self.timing = 5;
    if (self.timer) {
        [self.timer setFireDate:NSDate.distantPast];
    } else {
        self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:[PLVFWeakProxy proxyWithTarget:self] selector:@selector(timerTick:) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
    }
}

- (void)updateProductTagsLabel {
    self.firstTagLabel.hidden = YES;
    self.secondTagLabel.hidden = YES;
    NSArray *featureArray = self.model.featureArray;
    if (![PLVFdUtil checkArrayUseable:featureArray]) {
        return;
    }
    
    for (NSInteger index = 0; index < featureArray.count; index ++) {
        NSString *feature = featureArray[index];
        UILabel *featureLabel = index == 0 ? self.firstTagLabel : self.secondTagLabel;
        if ([PLVFdUtil checkStringUseable:feature]) {
            featureLabel.hidden = NO;
            featureLabel.text = feature;
            CGSize size = [featureLabel sizeThatFits:CGSizeMake(MAXFLOAT, 16)];
            featureLabel.frame = CGRectMake(0, 0, size.width, 16);
        } else {
            featureLabel.frame = CGRectZero;
        }
    }
}

- (UILabel *)productTagsLabel {
    UILabel *tagsLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    tagsLabel.backgroundColor = [PLVColorUtil colorFromHexString:@"#FF8F11" alpha:0.08];
    tagsLabel.textColor = [PLVColorUtil colorFromHexString:@"#FF8F11"];
    tagsLabel.font = [UIFont systemFontOfSize:10];
    tagsLabel.textAlignment = NSTextAlignmentCenter;
    tagsLabel.numberOfLines = 0;
    tagsLabel.layer.cornerRadius = 4.0;
    tagsLabel.layer.masksToBounds = YES;
    tagsLabel.hidden = YES;
    return tagsLabel;
}

- (void)destroy {
    if (self.timer) {
        [self.timer invalidate];
        self.timer = nil;
    }
}

#pragma mark - Utils

- (UIImage *)imageForCommodityResource:(NSString *)imageName {
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSBundle *resourceBundle = [NSBundle bundleWithPath:[bundle pathForResource:@"PLVCommodity" ofType:@"bundle"]];
    return [UIImage imageNamed:imageName inBundle:resourceBundle compatibleWithTraitCollection:nil];
}

#pragma mark -  Getter

- (UILabel *)productDescLabel {
    if (!_productDescLabel) {
        _productDescLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _productDescLabel.textColor = [PLVColorUtil colorFromHexString:@"#333333" alpha:0.6];
        _productDescLabel.font = [UIFont systemFontOfSize:12];
    }
    return _productDescLabel;
}

#pragma mark - Setter

- (void)setModel:(PLVCommodityModel *)model {
    _model = model;
    if (!model) {
        return;
    }
    
    // 实际价格显示逻辑
    NSString *realPriceStr;
    if ([model.productType isEqualToString:@"finance"]) {
        realPriceStr = [NSString stringWithFormat:@"%@", model.yield];
    } else {
        realPriceStr = [NSString stringWithFormat:@"¥ %@", model.realPrice];
        if ([model.realPrice isEqualToString:@"0"]) {
            realPriceStr = @"免费";
        }
    }
    
    // 原价格显示逻辑
    NSAttributedString *priceAtrrStr = nil;
    if (model.realPrice && ![model.price isEqualToString:@"0"]) {
        UIColor *grayColor = [UIColor colorWithRed:173/255.f green:173/255.f blue:192/255.f alpha:1];
        NSDictionary *attrParams = @{NSForegroundColorAttributeName:grayColor,
                                     NSFontAttributeName:[UIFont systemFontOfSize:12],
                                     NSStrikethroughStyleAttributeName:@(NSUnderlineStyleSingle),
                                     NSStrikethroughColorAttributeName:grayColor,
                                     NSBaselineOffsetAttributeName:@(0)};
        priceAtrrStr = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"¥ %@",model.price] attributes:attrParams];
    }
    
    // 封面地址
    NSURL *coverUrl;
    if ([model.cover hasPrefix:@"http"]) {
        coverUrl = [NSURL URLWithString:model.cover];
    } else if (model.cover) {
        coverUrl = [NSURL URLWithString:[@"https:" stringByAppendingString:model.cover]];
    }
    
    self.nameLabel.text = model.name;
    self.productDescLabel.text = model.productDesc;
    self.realPriceLabel.text = realPriceStr;
    self.priceLabel.attributedText = priceAtrrStr;
    self.showIdLabel.text = [NSString stringWithFormat:@"%ld",model.showId];
    
    // 产品标签
    [self updateProductTagsLabel];
    
    [self.realPriceLabel sizeToFit];
    self.priceLabel.frame = CGRectMake(CGRectGetMaxX(self.realPriceLabel.frame)+4, CGRectGetMinY(self.realPriceLabel.frame)+4, 120, 17);
       
    self.coverImageView.image = nil;
    [PLVFdUtil setImageWithURL:coverUrl inImageView:self.coverImageView completed:^(UIImage *image, NSError *error, NSURL *imageURL) {
        if (error) {
            NSLog(@"-setCellModel:图片加载失败，%@",imageURL);
        }
    }];
    
    NSString *linkString = [self getJumpLinkURLString];
    self.jumpButton.enabled = [PLVFdUtil checkStringUseable:linkString];
    
    if (self.type == PLVCommodityPushViewTypeEC) {
        [self addCountdownTimer];
    }
}

#pragma mark - Action

- (void)closeButtonAction {
    [self hide];
}

- (void)jumpButtonAction {
    NSString *linkString = [self getJumpLinkURLString];
    if (![PLVFdUtil checkStringUseable:linkString]) {
        return;
    }
    
    NSURL *jumpLinkUrl = [NSURL URLWithString:linkString];
    if (jumpLinkUrl && !jumpLinkUrl.scheme) {
        jumpLinkUrl = [NSURL URLWithString:[@"http://" stringByAppendingString:jumpLinkUrl.absoluteString]];
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(plvCommodityPushViewJumpToCommodityDetail:)]) {
        [self.delegate plvCommodityPushViewJumpToCommodityDetail:jumpLinkUrl];
    }
}

- (void)timerTick:(NSTimer *)timer {
    if (0 >= self.timing --) {
        [timer setFireDate:NSDate.distantFuture];
        [self hide];
    }
}

- (void)tapGestureAction {
    [self jumpButtonAction];
}

#pragma mark - Public

- (void)showOnView:(UIView *)superView initialFrame:(CGRect)initialFrame {
    self.initialFrame = initialFrame;
    self.frame = initialFrame;
    [superView addSubview:self];
    CGFloat endX = self.type == PLVCommodityPushViewTypeLC ? 8 : 16;
    
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:0.33 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        weakSelf.alpha = 1;
        weakSelf.frame = CGRectMake(endX, initialFrame.origin.y, initialFrame.size.width, initialFrame.size.height);
    } completion:nil];
}

@end
