//
//  PLVCommodityPushView.m
//  PLVLiveScenesDemo
//
//  Created by ftao on 2020/8/20.
//  Copyright © 2020 PLV. All rights reserved.
//  推送商品

#import "PLVCommodityPushView.h"
#import "PLVRoomDataManager.h"
#import "PLVMultiLanguageManager.h"
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>
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
@property (nonatomic, strong) UIButton *jumpTextButton;

@property (nonatomic, strong) NSTimer *timer;

@property (nonatomic, assign) NSInteger timing;

@property (nonatomic, assign) CGRect initialFrame;

@property (nonatomic, assign) PLVCommodityPushViewType type;

@property (nonatomic, assign) BOOL needShow; // 是否需要显示

@property (nonatomic, strong) CAShapeLayer *shapeLayer;

@property (nonatomic, strong) UIView *hotSaleTipView; // 热卖商品提示视图
@property (nonatomic, strong) UIImageView *tipImageView; // 提示的图片视图
@property (nonatomic, strong) UILabel *tipTitleLabel;
@property (nonatomic, strong) CAGradientLayer *tipShadowLayer;

@property (nonatomic, assign) NSInteger clickTimes; // 热卖商品点击次数
@property (nonatomic, assign) NSInteger clickProductId; // 热卖商品的id
@property (nonatomic, assign) BOOL productHotEffectEnabled; // 商品热卖特效开关是否开启
@property (nonatomic, copy) NSString *currentProductTips; // 当前产品tip文案
@property (nonatomic, copy) NSString *normalProductTips; // 普通产品tip文案
@property (nonatomic, copy) NSString *financeProductTips; // 金融产品tip文案
@property (nonatomic, copy) NSString *jobProductTips; // 职位产品tip文案
@property (nonatomic, strong) CADisplayLink *displayLink; // 次数更新动画
@property (nonatomic, assign) NSInteger unincreaseTimes; // 增长前的点击次数
@property (nonatomic, assign) CFTimeInterval animatStartTime;

@end

@implementation PLVCommodityPushView

#pragma mark - [ Life Cycle ]

- (instancetype)initWithType:(PLVCommodityPushViewType)type {
    self = [super init];
    if (self) {
        self.type = type;
        self.needShow = NO;
        
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureAction)];
        [self addGestureRecognizer:tapGesture];
        
        self.coverImageView = [[UIImageView alloc] init];
        self.coverImageView.layer.cornerRadius = 10.0;
        self.coverImageView.layer.masksToBounds = YES;
        self.coverImageView.contentMode = UIViewContentModeScaleAspectFill;
        [self addSubview:self.coverImageView];
        
        self.showIdLabel = [[UILabel alloc] init];
        self.showIdLabel.layer.cornerRadius = 2.0;
        self.showIdLabel.layer.masksToBounds = YES;
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
        if (type == PLVCommodityPushViewTypeLC) {
            [self.jumpButton setImage:[self imageForCommodityResource:@"plv_commodity_jump_normal_btn"] forState:UIControlStateNormal];
        } else {
            [self.jumpButton setImage:[self imageForCommodityResource:@"plv_commodity_jump_btn"] forState:UIControlStateNormal];
        }
        [self.jumpButton setImage:[self imageForCommodityResource:@"plv_commodity_jump_btn_disabled"] forState:UIControlStateDisabled];
        [self.jumpButton addTarget:self action:@selector(jumpButtonAction) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.jumpButton];
        [self addSubview:self.jumpTextButton];

        [self.coverImageView addSubview:self.hotSaleTipView];
        [self.hotSaleTipView.layer addSublayer:self.tipShadowLayer];
        [self.hotSaleTipView addSubview:self.tipTitleLabel];
        [self.hotSaleTipView addSubview:self.tipImageView];
        
        [self setProductHotEffectConfig];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.closeButton.frame = CGRectMake(CGRectGetWidth(self.bounds)-20, 4, 16, 16);
    self.jumpButton.frame = CGRectMake(CGRectGetWidth(self.bounds)-46, CGRectGetHeight(self.bounds)-40, 24, 24);
    
    CGFloat coverImageViewHeight = CGRectGetHeight(self.bounds) - 12 * 2;
    self.coverImageView.frame = CGRectMake(12, 12, coverImageViewHeight, coverImageViewHeight);
    if (!self.hotSaleTipView.hidden) {
        self.hotSaleTipView.frame = CGRectMake(0, 0, coverImageViewHeight, 24);
        self.tipShadowLayer.frame = self.hotSaleTipView.bounds;
        self.tipImageView.frame = CGRectMake(0, 6, 14, 14);
        self.tipTitleLabel.frame = CGRectMake(16, 0, CGRectGetWidth(self.hotSaleTipView.frame) - 16, CGRectGetHeight(self.hotSaleTipView.frame));
    }
    CGFloat positionX = CGRectGetMaxX(self.coverImageView.frame) + 8;
    CGFloat positionY = 12;
    self.nameLabel.frame = CGRectMake(positionX, positionY, CGRectGetWidth(self.bounds)-positionX-22, 20);
    
    positionY = CGRectGetMaxY(self.nameLabel.frame) + 4;
    CGSize firstLabelSize = [self.firstTagLabel sizeThatFits:CGSizeMake(MAXFLOAT, 16)];
    self.firstTagLabel.frame = CGRectMake(positionX, positionY, firstLabelSize.width + 8, 16);
    CGSize secondLabelSize = [self.secondTagLabel sizeThatFits:CGSizeMake(MAXFLOAT, 16)];
    self.secondTagLabel.frame = CGRectMake((self.firstTagLabel.isHidden ? positionX : CGRectGetMaxX(self.firstTagLabel.frame)+4), positionY, secondLabelSize.width + 8, 16);
    
    positionY = (self.firstTagLabel.isHidden && self.secondTagLabel.isHidden) ? positionY : positionY + 16 + 4;
    self.productDescLabel.frame = CGRectMake(positionX, positionY, CGRectGetWidth(self.nameLabel.frame), 18);
    
    if ([self.model.productType isEqualToString:@"position"] &&
        ![PLVFdUtil checkStringUseable:self.model.cover]) { // 职位产品
        self.realPriceLabel.frame = CGRectMake(12, CGRectGetHeight(self.bounds)- 12 - 25, 150, 25);
    } else {
        self.realPriceLabel.frame = CGRectMake(positionX, CGRectGetHeight(self.bounds)- 12 - 25, 150, 25);
    }
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

- (void)setProductHotEffectConfig {
    // 是否开启产品热卖特效
    PLVLiveVideoChannelMenuInfo *menuInfo = [PLVRoomDataManager sharedManager].roomData.menuInfo;
    self.hotSaleTipView.hidden = !self.productHotEffectEnabled;
    if (self.productHotEffectEnabled) {
        _normalProductTips = PLV_SafeStringForDictKey(menuInfo.productHotEffectTips, @"normalProductTips");
        _financeProductTips = PLV_SafeStringForDictKey(menuInfo.productHotEffectTips, @"financeProductTips");
        _jobProductTips = PLV_SafeStringForDictKey(menuInfo.productHotEffectTips, @"jobProductTips");
    }
}

- (void)drawLayer {
    if (_shapeLayer.superlayer) {
        [_shapeLayer removeFromSuperlayer];
        _shapeLayer = nil;
    }
    
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
    _shapeLayer = shapeLayer;
    [self.layer insertSublayer:_shapeLayer atIndex:0];
}

- (void)hide {
    if (self.alpha == 0) { return; }
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:0.33 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        weakSelf.alpha = 0;
        weakSelf.frame = weakSelf.initialFrame;
    } completion:^(BOOL finished) {
        [weakSelf removeFromSuperview];
        weakSelf.needShow = NO;
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

- (void)startTipTitleLabelAnimate {
    if (_displayLink) { return; }
    
    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateTipNumber)];
    self.displayLink.preferredFramesPerSecond = 30; // 每秒调用 30 次
    [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    
    // 记录开始时间
    self.animatStartTime = CACurrentMediaTime();
}

- (void)setTipTitleLabelContent:(NSInteger)number animated:(BOOL)animated {
    NSString *titleString = PLVLocalizedString(self.currentProductTips);
    NSString *numString = number > 9999 ? @"9999+" : [NSString stringWithFormat:@"%ld", number];
    NSString *string = [NSString stringWithFormat:@"%@x%@",titleString, numString];
    
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:string];
    NSDictionary *titleAttributes = @{NSFontAttributeName:[UIFont systemFontOfSize:12],
                                          NSForegroundColorAttributeName:[UIColor whiteColor]};
    [attributedString addAttributes:titleAttributes range:NSMakeRange(0, titleString.length)];
    [attributedString addAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:10],NSForegroundColorAttributeName:[UIColor whiteColor]} range:NSMakeRange(titleString.length, 1)];
    UIFont *numFont = [UIFont systemFontOfSize:(animated ? 16 : 14) weight:500];
    [attributedString addAttributes:@{NSFontAttributeName:numFont,NSForegroundColorAttributeName:[UIColor whiteColor]} range:NSMakeRange(titleString.length + 1, numString.length)];
    self.tipTitleLabel.attributedText = attributedString;
}

- (void)destroy {
    if (self.timer) {
        [self.timer invalidate];
        self.timer = nil;
    }
    
    if (_displayLink) {
        [self.displayLink invalidate];
        self.displayLink = nil;
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

- (UIView *)hotSaleTipView {
    if (!_hotSaleTipView) {
        _hotSaleTipView = [[UIView alloc] init];
        _hotSaleTipView.layer.masksToBounds = YES;
        _hotSaleTipView.hidden = YES;
    }
    return _hotSaleTipView;
}

- (UIImageView *)tipImageView {
    if (!_tipImageView) {
        _tipImageView = [[UIImageView alloc] init];
        _tipImageView.image = [self imageForCommodityResource:@"plv_commodity_hotsale_icon"];
    }
    return _tipImageView;
}

- (UILabel *)tipTitleLabel {
    if (!_tipTitleLabel) {
        _tipTitleLabel = [[UILabel alloc] init];
        _tipTitleLabel.lineBreakMode = NSLineBreakByClipping;
    }
    return _tipTitleLabel;
}

- (CAGradientLayer *)tipShadowLayer{
    if (!_tipShadowLayer) {
        _tipShadowLayer = [CAGradientLayer layer];
        _tipShadowLayer.startPoint = CGPointMake(0, 0);
        _tipShadowLayer.endPoint = CGPointMake(1, 0);
        _tipShadowLayer.colors = @[(__bridge id)[PLVColorUtil colorFromHexString:@"#FFAF0F" alpha:1.0f].CGColor, (__bridge id)[PLVColorUtil colorFromHexString:@"#FFAF0F" alpha:0.8f].CGColor, (__bridge id)[PLVColorUtil colorFromHexString:@"#FFAF0F" alpha:0.0f].CGColor];
        _tipShadowLayer.locations = @[@(0), @(0.7), @(1.0f)];
    }
    return _tipShadowLayer;
}

- (UIButton *)jumpTextButton {
    if (!_jumpTextButton) {
        _jumpTextButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _jumpTextButton.backgroundColor = [PLVColorUtil colorFromHexString:@"#F15D5D"];
        _jumpTextButton.titleLabel.font = [UIFont systemFontOfSize:12];
        _jumpTextButton.layer.cornerRadius = 12.0f;
        _jumpTextButton.hidden = YES;
        [_jumpTextButton setTitle:PLVLocalizedString(@"立即投递") forState:UIControlStateNormal];
        [_jumpTextButton addTarget:self action:@selector(jumpButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _jumpTextButton;
}

- (BOOL)productHotEffectEnabled {
    return [PLVRoomDataManager sharedManager].roomData.menuInfo.productHotEffectEnabled;
}

#pragma mark - Setter

- (void)setModel:(PLVCommodityModel *)model {
    _model = model;
    if (!model) {
        return;
    }
    
    self.needShow = YES;
    self.clickTimes = 0;
    self.unincreaseTimes = 0;
    self.clickProductId = model.productId;
    self.productDescLabel.text = model.productDesc;

    // 实际价格显示逻辑
    NSString *realPriceStr;
    if ([model.productType isEqualToString:@"finance"]) { // 金融产品
        realPriceStr = [NSString stringWithFormat:@"%@", model.yield];
        self.currentProductTips = self.financeProductTips;
        self.tipImageView.image = [self imageForCommodityResource:@"plv_commodity_shopping_icon"];
    } else if ([model.productType isEqualToString:@"position"]) { // 职位产品
        if ([PLVFdUtil checkDictionaryUseable:model.params]) {
            realPriceStr = PLV_SafeStringForDictKey(model.params, @"treatment");
        }
        self.productDescLabel.text = nil;
        self.currentProductTips = self.jobProductTips;
        self.tipImageView.image = [self imageForCommodityResource:@"plv_commodity_delivering_icon"];
    } else { // 普通产品
        realPriceStr = [NSString stringWithFormat:@"¥ %@", model.realPrice];
        if ([model.realPrice isEqualToString:@"0"]) {
            realPriceStr = PLVLocalizedString(@"免费");
        }
        self.currentProductTips = self.normalProductTips;
        self.tipImageView.image = [self imageForCommodityResource:@"plv_commodity_hotsale_icon"];
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
    
    // 更新热度标签
    [self setTipTitleLabelContent:self.clickTimes animated:NO];
    [self setNeedsLayout];
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
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(plvCommodityPushViewJumpToCommodityDetail:commodity:)]) {
        [self.delegate plvCommodityPushViewJumpToCommodityDetail:jumpLinkUrl commodity:self.model];
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

- (void)updateTipNumber {
    CFTimeInterval elapsedTime = CACurrentMediaTime() - self.animatStartTime;
    if (elapsedTime > 0.2) {
        // 确保在0.2秒后停止
        elapsedTime = 0.2;
        [self.displayLink invalidate];
        self.displayLink = nil;
    }
    
    // 根据经过的时间计算当前数字
    NSInteger num = (NSInteger)(elapsedTime / 0.2 * (self.clickTimes - self.unincreaseTimes));
    num += self.unincreaseTimes;
    if (num >= self.clickTimes) {
        self.unincreaseTimes = num;
    }
    [self setTipTitleLabelContent:num animated:(num < self.clickTimes)];
}

#pragma mark - Public

- (void)showOnView:(UIView *)superView initialFrame:(CGRect)initialFrame {
    if (!self.needShow) {
        return;
    }
    
    [self removeFromSuperview];
    self.initialFrame = initialFrame;
    self.frame = initialFrame;
    [superView addSubview:self];

    CGFloat endX = 0.0;
    BOOL fullScreen = [UIScreen mainScreen].bounds.size.width > [UIScreen mainScreen].bounds.size.height;
    BOOL isPad = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
    if (fullScreen && self.type == PLVCommodityPushViewTypeLC) {
        [superView sendSubviewToBack:self];
    }
    if (self.type == PLVCommodityPushViewTypeLC) {
        endX = fullScreen ? (P_SafeAreaLeftEdgeInsets() + (isPad ? 30 : 16)) : 8;
    } else {
        endX = 16;
    }
    
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:0.33 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        weakSelf.alpha = 1;
        weakSelf.frame = CGRectMake(endX, initialFrame.origin.y, initialFrame.size.width, initialFrame.size.height);
    } completion:nil];
}

- (void)reportTrackEvent {
    if (!self.model) {
        return;
    }
    
    NSTimeInterval interval = [[NSDate date] timeIntervalSince1970];
    NSString *productId = [NSString stringWithFormat:@"%zd", self.model.productId];
    NSDictionary *info = @{
        @"exposureTime" : @(lround(interval)),
        @"name": self.model.name ?: @"",
        @"productId" : productId,
        @"realPrice" : @([self.model.realPrice doubleValue]),
        @"price" : @([self.model.price doubleValue]),
        @"productType" : self.model.productType ?: @"",
        @"linkType" : @"mobile",
        @"pushId" : self.model.logId ?: @""
    };
    [[PLVWLogReporterManager sharedManager] reportTrackWithEventId:@"product_push_item_view" eventType:@"show" specInformation:info];
}

- (void)updateProductClickTimes:(NSDictionary *)dict {
    if (!self.model || ![PLVFdUtil checkDictionaryUseable:dict] ||
        !self.productHotEffectEnabled) {
        return;
    }
    
    NSInteger productId = PLV_SafeIntegerForDictKey(dict, @"productId");
    if (productId == self.model.productId) {
        self.unincreaseTimes = self.clickTimes;
        self.clickTimes = PLV_SafeIntegerForDictKey(dict, @"times");
        plv_dispatch_main_async_safe(^{
            [self startTipTitleLabelAnimate];
        })
    }
}

- (void)sendProductClickedEvent:(PLVCommodityModel *)model {
    if (!model) {  return; }

    NSString *roomId = [PLVRoomDataManager sharedManager].roomData.channelId;
    NSString *nickName = [PLVRoomDataManager sharedManager].roomData.roomUser.viewerName;
    NSMutableDictionary *jsonDict = [NSMutableDictionary dictionary];
    jsonDict[@"EVENT"] = @"PRODUCT_CLICK";
    jsonDict[@"roomId"] = [NSString stringWithFormat:@"%@", roomId];
    jsonDict[@"data"] = @{
        @"nickName" : [PLVFdUtil checkStringUseable:nickName] ? nickName : @"",
        @"positionName" : model.name ?: @"",
        @"type" : model.productType ?: @"",
        @"productId" : @(model.productId)
    };
    [[PLVSocketManager sharedManager] emitEvent:PLVSocketProduct_product_key content:jsonDict];
}

@end
