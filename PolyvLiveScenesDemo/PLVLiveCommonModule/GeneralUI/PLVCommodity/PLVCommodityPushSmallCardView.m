//
//  PLVCommodityPushSmallCardView.m
//  PolyvLiveScenesDemo
//
//  Created by Dhan on 2025/4/9.
//  Copyright © 2025 PLV. All rights reserved.
//

#import "PLVCommodityPushSmallCardView.h"
#import "PLVRoomData.h"
#import "PLVMultiLanguageManager.h"
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>
#import <PLVFoundationSDK/PLVFoundationSDK.h>
#import "PLVModel/PLVModel.h"

@interface PLVCommodityPushSmallCardView ()

@property (nonatomic, strong) UIView *backgroundView; // 背景

@property (nonatomic, strong) UIView *descBackgroundView; // 商品描述区域背景

@property (nonatomic, strong) UIImageView *descImageView; // 商品背景描述区域图片

@property (nonatomic, strong) UILabel *nameLabel; // 商品名称

@property (nonatomic, strong) UILabel *productDescLabel; // 商品描述

@property (nonatomic, strong) UIImageView * coverImageView; // 商品封面

@property (nonatomic, strong) UILabel *showIdLabel; // 商品序号

@property (nonatomic, strong) UIButton *closeButton; // 关闭按钮

@property (nonatomic, strong) UIButton *jumpTextButton; // 跳转按钮

@property (nonatomic, strong) UILabel *tagLabel; // 标签背景按钮

@property (nonatomic, strong) NSArray <UILabel *> *tagLabelArray; // 标签

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

@property (nonatomic, weak) PLVRoomData *roomData;

@property (nonatomic, strong) NSTimer *timer;

@property (nonatomic, assign) NSInteger timing;

@property (nonatomic, assign) CGRect initialFrame;

@property (nonatomic, assign) BOOL needShow; // 是否需要显示

@end

@implementation PLVCommodityPushSmallCardView

- (instancetype)init {
    self = [super init];
    if (self) {
        self.needShow = NO;
        [self setupUI];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    [self updateUI];
}

#pragma mark - [ Public Methods ]

- (void)showOnView:(UIView *)superView initialFrame:(CGRect)initialFrame {
    if (!self.needShow) {
        return;
    }
    
    [self removeFromSuperview];
    self.initialFrame = initialFrame;
    initialFrame = CGRectMake(superView.frame.size.width, initialFrame.origin.y, initialFrame.size.width, initialFrame.size.height);
    self.frame = initialFrame;
    [superView addSubview:self];
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:0.33 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        weakSelf.alpha = 1;
        weakSelf.frame = weakSelf.initialFrame;
    } completion:^(BOOL finished) {
        [weakSelf setProductHotEffectConfig];
        if (weakSelf.delegate && [weakSelf.delegate respondsToSelector:@selector(PLVCommodityPushSmallCardViewDidShow:)]) {
            [weakSelf.delegate PLVCommodityPushSmallCardViewDidShow:YES];
        }
    }];
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

- (void)reportSmallCardClickTrackEvent {
    if (!self.model || ![self.model.productPushRule isEqualToString:@"smallCard"]) {
        return;
    }
    
    NSString *productId = [NSString stringWithFormat:@"%zd", self.model.productId];
    NSDictionary *info = @{
        @"buyType" : self.model.buyType ?: @"",
        @"deliveryType" : self.model.deliveryType ?:@"",
        @"name": self.model.name ?: @"",
        @"productId" : productId,
        @"productType" : self.model.productType ?: @"",
        @"linkType" : @"mobile",
        @"productPushRule" : self.model.productPushRule ?: @""
    };
    [[PLVWLogReporterManager sharedManager] reportTrackWithEventId:@"product_click_button" eventType:@"click" specInformation:info];
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

    NSString *roomId = self.roomData.channelId;
    NSString *nickName = self.roomData.roomUser.viewerName;
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


#pragma mark - [ Private Methods ]

- (void)setupUI {
    [self addSubview:self.backgroundView];
    [self.backgroundView addSubview:self.descBackgroundView];
    
    [self.descBackgroundView addSubview:self.descImageView];
    [self.descBackgroundView addSubview:self.nameLabel];
    [self.descBackgroundView addSubview:self.productDescLabel];

    [self.descBackgroundView addSubview:self.jumpTextButton];
    [self.descBackgroundView addSubview:self.coverImageView];
    [self.descBackgroundView addSubview:self.tagLabel];
    
    [self.backgroundView addSubview:self.showIdLabel];
    [self.backgroundView addSubview:self.closeButton];
    
    [self addSubview:self.hotSaleTipView];
    [self.hotSaleTipView.layer addSublayer:self.tipShadowLayer];
    [self.hotSaleTipView addSubview:self.tipTitleLabel];
    [self.hotSaleTipView addSubview:self.tipImageView];
}

- (void)updateUI {
    // view最大是 172 + 8 + 24 悬浮条的高是24 宽度是104
    // 有图是172 无图是 122
    BOOL hasImage = !self.coverImageView.hidden;
    CGFloat width = self.frame.size.width;
    CGFloat height = self.frame.size.height;
    CGFloat backgroundViewHeight = hasImage ? 172 : 122;
    CGFloat descBackgroundViewHeight = hasImage ? 172 : 98;
    
    self.backgroundView.frame = CGRectMake(0, height - backgroundViewHeight, width, backgroundViewHeight);
    self.descBackgroundView.frame = CGRectMake(0, backgroundViewHeight - descBackgroundViewHeight, width, descBackgroundViewHeight);
    
    self.hotSaleTipView.frame = CGRectMake(0, CGRectGetMinY(self.backgroundView.frame) - 28, width, 24);
    self.tipShadowLayer.frame = self.hotSaleTipView.bounds;
    self.tipImageView.frame = CGRectMake(0, 6, 14, 14);
    self.tipTitleLabel.frame = CGRectMake(16, 0, CGRectGetWidth(self.hotSaleTipView.frame) - 16, CGRectGetHeight(self.hotSaleTipView.frame));
    
    CGFloat showIdLabelWidth = [self.showIdLabel sizeThatFits:CGSizeMake(CGFLOAT_MAX, 19)].width + 8;
    CGFloat showIdLabelOriginY = self.coverImageView.hidden ? 4 : 0;
    self.showIdLabel.frame = CGRectMake(0, showIdLabelOriginY, showIdLabelWidth, 19);
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:self.showIdLabel.bounds
                                               byRoundingCorners:UIRectCornerBottomRight
                                                     cornerRadii:CGSizeMake(6.0, 6.0)];
    CAShapeLayer *maskLayer = [CAShapeLayer layer];
    maskLayer.path = path.CGPath;
    self.showIdLabel.layer.mask = maskLayer;
    
    self.closeButton.frame = CGRectMake(width - 18, showIdLabelOriginY, 18, 18);
    
    self.coverImageView.frame = CGRectMake(2, 2, 100, 100);
    self.descImageView.frame = CGRectMake(width - 62, descBackgroundViewHeight - 84, 62, 62);
    
    self.jumpTextButton.frame = CGRectMake(4, descBackgroundViewHeight - 28, width - 8, 24);
    self.productDescLabel.frame = CGRectMake(4, CGRectGetMinY(self.jumpTextButton.frame) - 22, 96, 18);
    CGFloat tagLabelWidth = [self.tagLabel sizeThatFits:CGSizeMake(MAXFLOAT, 16)].width + 8;
    tagLabelWidth = MIN(tagLabelWidth, 96);
    if (hasImage) {
        self.nameLabel.frame = CGRectMake(4, CGRectGetMinY(self.productDescLabel.frame) - 18, 96, 18);
        self.tagLabel.frame = CGRectMake(4, CGRectGetMinY(self.nameLabel.frame) - 22, tagLabelWidth, 16);
    } else {
        self.tagLabel.frame = CGRectMake(4, 8, tagLabelWidth, 16);
        CGFloat nameLabelOriginY = self.tagLabel.hidden ? 8 : CGRectGetMaxY(self.tagLabel.frame);
        self.nameLabel.frame = CGRectMake(4, nameLabelOriginY, 96, 18);
    }
}

- (void)setProductHotEffectConfig {
    // 是否开启产品热卖特效
    PLVLiveVideoChannelMenuInfo *menuInfo = self.roomData.menuInfo;
    self.hotSaleTipView.hidden = !self.productHotEffectEnabled;
    if (self.productHotEffectEnabled) {
        _normalProductTips = PLV_SafeStringForDictKey(menuInfo.productHotEffectTips, @"normalProductTips");
        _financeProductTips = PLV_SafeStringForDictKey(menuInfo.productHotEffectTips, @"financeProductTips");
        _jobProductTips = PLV_SafeStringForDictKey(menuInfo.productHotEffectTips, @"jobProductTips");
    }
}

- (void)hide {
    if (self.alpha == 0) { return; }
    __weak typeof(self) weakSelf = self;
    self.hotSaleTipView.hidden = YES;
    [UIView animateWithDuration:0.33 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        weakSelf.alpha = 0;
        weakSelf.frame = CGRectMake(weakSelf.initialFrame.size.width, weakSelf.initialFrame.origin.y, weakSelf.initialFrame.size.width, weakSelf.initialFrame.size.height);;
    } completion:^(BOOL finished) {
        [weakSelf removeFromSuperview];
        weakSelf.needShow = NO;
        if (weakSelf.delegate && [weakSelf.delegate respondsToSelector:@selector(PLVCommodityPushSmallCardViewDidShow:)]) {
            [weakSelf.delegate PLVCommodityPushSmallCardViewDidShow:NO];
        }
    }];
}

- (BOOL)canEnableProductClickButton {
    if ([self.model.buyType isEqualToString:@"inner"]) {
        // 检查直接购买的条件
        return YES;
    } else if ([self.model.buyType isEqualToString:@"link"]) {
        // 检查外链购买的条件
        return [PLVFdUtil checkStringUseable:self.model.formattedLink];
    }

    return NO;
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


#pragma mark Getter or Setter

- (UIView *)backgroundView {
    if (!_backgroundView) {
        _backgroundView = [[UIView alloc] init];
        _backgroundView.backgroundColor = [PLVColorUtil colorFromHexString:@"#FF5252"];
        _backgroundView.layer.cornerRadius = 3;
        _backgroundView.layer.masksToBounds = YES;
    }
    return _backgroundView;
}

- (UIView *)descBackgroundView {
    if (!_descBackgroundView) {
        _descBackgroundView = [[UIView alloc] init];
        _descBackgroundView.backgroundColor = [PLVColorUtil colorFromHexString:@"#FFFFFF"];
        _descBackgroundView.layer.cornerRadius = 3;
        _descBackgroundView.layer.masksToBounds = YES;
    }
    return _descBackgroundView;
}

- (UIImageView *)descImageView {
    if (!_descImageView) {
        _descImageView = [[UIImageView alloc] init];
        _descImageView.image = [self imageForCommodityResource:@"plv_commodity_desc_icon"];
    }
    return _descImageView;
}

- (UILabel *)nameLabel {
    if (!_nameLabel) {
        _nameLabel = [[UILabel alloc] init];
        _nameLabel.textColor = [PLVColorUtil colorFromHexString:@"#3D3D3D"];
        _nameLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:12];
        _nameLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        _nameLabel.numberOfLines = 1;
    }
    return _nameLabel;
}

- (UILabel *)productDescLabel {
    if (!_productDescLabel) {
        _productDescLabel = [[UILabel alloc] init];
        _productDescLabel.textColor = [PLVColorUtil colorFromHexString:@"#FF5252"];
        _productDescLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:12];
        _productDescLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        _productDescLabel.numberOfLines = 1;
    }
    return _productDescLabel;
}

- (UIImageView *)coverImageView {
    if (!_coverImageView) {
        _coverImageView = [[UIImageView alloc] init];
        _coverImageView.layer.cornerRadius = 2.0;
        _coverImageView.layer.masksToBounds = YES;
    }
    return _coverImageView;
}

- (UILabel *)showIdLabel {
    if (!_showIdLabel) {
        _showIdLabel = [[UILabel alloc] init];
        _showIdLabel.textColor = [PLVColorUtil colorFromHexString:@"#FFFFFF"];
        _showIdLabel.font = [UIFont fontWithName:@"D-DIN-Bold" size:12];
        _showIdLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _showIdLabel;
}

- (UIButton *)closeButton {
    if (!_closeButton) {
        _closeButton = [[UIButton alloc] init];
        [_closeButton setImage:[self imageForCommodityResource:@"plv_commodity_webview_close_btn"] forState:UIControlStateNormal];
        [_closeButton addTarget:self action:@selector(closeButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _closeButton;
}


- (UIButton *)jumpTextButton {
    if (!_jumpTextButton) {
        _jumpTextButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _jumpTextButton.backgroundColor = [PLVColorUtil colorFromHexString:@"#FF5252"];
        _jumpTextButton.titleLabel.font = [UIFont systemFontOfSize:12];
        _jumpTextButton.layer.cornerRadius = 2;
        [_jumpTextButton setTitle:PLVLocalizedString(@"去购买") forState:UIControlStateNormal];
        [_jumpTextButton addTarget:self action:@selector(jumpButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _jumpTextButton;
}

- (UILabel *)tagLabel {
    if (!_tagLabel) {
        _tagLabel = [[UILabel alloc] init];
        _tagLabel.font = [UIFont fontWithName:@"PingFangSC-Medium" size:10];
        _tagLabel.layer.cornerRadius = 1.0;
        _tagLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _tagLabel;
}

- (UIView *)hotSaleTipView {
    if (!_hotSaleTipView) {
        _hotSaleTipView = [[UIView alloc] init];
        _hotSaleTipView.layer.masksToBounds = YES;
        _hotSaleTipView.layer.cornerRadius = 12;
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

- (BOOL)productHotEffectEnabled {
    return self.roomData.menuInfo.productHotEffectEnabled;
}

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
    self.hotSaleTipView.hidden = YES;

    // 实际价格显示逻辑
    NSString *realPriceStr;
    if ([model.productType isEqualToString:@"finance"]) { // 金融产品
        realPriceStr = [NSString stringWithFormat:@"%@", model.yield];
        self.currentProductTips = self.financeProductTips;
        self.tipImageView.image = [self imageForCommodityResource:@"plv_commodity_shopping_icon"];
        NSString *jumpBtnTitle = [PLVFdUtil checkStringUseable:model.btnShow] ? model.btnShow : PLVLocalizedString(@"立即了解");
        [self.jumpTextButton setTitle:jumpBtnTitle forState:UIControlStateNormal];
        self.productDescLabel.text = realPriceStr;
    } else if ([model.productType isEqualToString:@"position"]) { // 职位产品
        if ([PLVFdUtil checkDictionaryUseable:model.params]) {
            realPriceStr = PLV_SafeStringForDictKey(model.params, @"treatment");
        }
        NSString *jumpBtnTitle = [PLVFdUtil checkStringUseable:model.btnShow] ? model.btnShow : PLVLocalizedString(@"立即了解");
        [self.jumpTextButton setTitle:jumpBtnTitle forState:UIControlStateNormal];
        self.productDescLabel.text = realPriceStr;
        self.currentProductTips = self.jobProductTips;
        self.tipImageView.image = [self imageForCommodityResource:@"plv_commodity_delivering_icon"];
    } else { // 普通产品
        realPriceStr = [NSString stringWithFormat:@"¥ %@", model.realPrice];
        if ([model.priceType isEqualToString:@"CUSTOM"]) {
            realPriceStr = model.customPrice;
        } else if ([model.realPrice isEqualToString:@"0"]) {
            realPriceStr = PLVLocalizedString(@"免费");
        }
        self.currentProductTips = self.normalProductTips;
        self.productDescLabel.text = realPriceStr;
        self.tipImageView.image = [self imageForCommodityResource:@"plv_commodity_hotsale_icon"];
        NSString *jumpBtnTitle = [PLVFdUtil checkStringUseable:model.btnShow] ? model.btnShow : PLVLocalizedString(@"去购买");
        [self.jumpTextButton setTitle:jumpBtnTitle forState:UIControlStateNormal];
    }
    
    // 封面地址
    NSURL *coverUrl = nil;
    if ([model.cover hasPrefix:@"http"]) {
        coverUrl = [NSURL URLWithString:model.cover];
    } else if (model.cover) {
        coverUrl = [NSURL URLWithString:[@"https:" stringByAppendingString:model.cover]];
    }
    self.coverImageView.hidden = ![PLVFdUtil checkStringUseable:model.cover];
    
    self.nameLabel.text = model.name;
    self.showIdLabel.text = [NSString stringWithFormat:@"%ld",model.showId];
    
    self.tagLabel.hidden = YES;
    NSArray *featureArray = self.model.featureArray;
    if ([PLVFdUtil checkArrayUseable:featureArray]) {
        NSString *feature = featureArray[0];
        if ([PLVFdUtil checkStringUseable:feature]) {
            self.tagLabel.hidden = NO;
            self.tagLabel.text = feature;
        }
        
        if (self.coverImageView.hidden) {
            self.showIdLabel.backgroundColor = [UIColor clearColor];
            self.tagLabel.backgroundColor = [UIColor clearColor];
            self.tagLabel.textColor = [PLVColorUtil colorFromHexString:@"#FF5252"];
            self.tagLabel.layer.borderColor = [PLVColorUtil colorFromHexString:@"#FF5252" alpha:0.6].CGColor;
            self.tagLabel.layer.borderWidth = 0.5;
        } else {
            self.showIdLabel.backgroundColor = [PLVColorUtil colorFromHexString:@"#000000" alpha:0.6];
            self.tagLabel.backgroundColor = [PLVColorUtil colorFromHexString:@"#FF5252"];
            self.tagLabel.textColor = [PLVColorUtil colorFromHexString:@"#FFFFFF"];
            self.tagLabel.layer.borderColor = [PLVColorUtil colorFromHexString:@"#FF5252" alpha:0.6].CGColor;
            self.tagLabel.layer.borderWidth = 0;
        }
    }
    self.coverImageView.image = nil;
    [PLVFdUtil setImageWithURL:coverUrl inImageView:self.coverImageView completed:^(UIImage *image, NSError *error, NSURL *imageURL) {
        if (error) {
            PLV_LOG_DEBUG(PLVConsoleLogModuleTypeInteract, @"-setCellModel:图片加载失败，%@",imageURL);
        }
    }];
    
    self.jumpTextButton.enabled = [self canEnableProductClickButton];
    
    // 更新热度标签
    [self setTipTitleLabelContent:self.clickTimes animated:NO];
    plv_dispatch_main_async_safe(^{
        [self setNeedsLayout];
        [self layoutIfNeeded];
    })
}


- (CGFloat)visibleMinY {
    if (!self.hotSaleTipView.hidden) {
        return self.hotSaleTipView.frame.origin.y;
    }
    return self.backgroundView.frame.origin.y;
}

#pragma mark - Utils

- (UIImage *)imageForCommodityResource:(NSString *)imageName {
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSBundle *resourceBundle = [NSBundle bundleWithPath:[bundle pathForResource:@"PLVCommodity" ofType:@"bundle"]];
    return [UIImage imageNamed:imageName inBundle:resourceBundle compatibleWithTraitCollection:nil];
}

#pragma mark - Action

- (void)closeButtonAction {
    [self hide];
}

- (void)jumpButtonAction {
    if (![self canEnableProductClickButton]) {
        return;
    }
    
    if ([self.model.productType isEqualToString:@"position"]) {
        NSDictionary *data = [self.model plv_modelToJSONObject];
        if ([PLVFdUtil checkDictionaryUseable:data]) {
            if (self.delegate && [self.delegate respondsToSelector:@selector(PLVCommodityPushSmallCardViewDidShowJobDetail:)]) {
                [self.delegate PLVCommodityPushSmallCardViewDidShowJobDetail:data];
            }
        }
    } else {
        if (self.delegate && [self.delegate respondsToSelector:@selector(PLVCommodityPushSmallCardViewDidClickCommodityDetail:)]) {
            [self.delegate PLVCommodityPushSmallCardViewDidClickCommodityDetail:self.model];
        }
    }
    [self reportSmallCardClickTrackEvent];
}

- (void)timerTick:(NSTimer *)timer {
    if (0 >= self.timing --) {
        [timer setFireDate:NSDate.distantFuture];
        [self hide];
    }
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

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    for (NSInteger i = self.subviews.count - 1; i >= 0; i--) {
        UIView *childView = self.subviews[i];
        CGPoint childPoint = [self convertPoint:point toView:childView];
        UIView *fitView = [childView hitTest:childPoint withEvent:event];
        if (fitView) { // 寻找到响应事件的子控件
            return fitView;
        }
    }
    return nil;
}

@end
