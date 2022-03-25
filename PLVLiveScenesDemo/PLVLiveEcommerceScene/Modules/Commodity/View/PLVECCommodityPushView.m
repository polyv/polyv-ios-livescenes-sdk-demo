//
//  PLVECCommodityPushView.m
//  PLVLiveScenesDemo
//
//  Created by ftao on 2020/8/20.
//  Copyright © 2020 PLV. All rights reserved.
//  推送商品

#import "PLVECCommodityPushView.h"
#import <PLVFoundationSDK/PLVFdUtil.h>
#import "PLVECUtils.h"

@interface PLVECCommodityPushView ()

@property (nonatomic, strong) NSTimer *timer;

@property (nonatomic, assign) NSInteger timing;

@end

@implementation PLVECCommodityPushView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // 使用-drawLayer:画出带三角形的路径
        //self.backgroundColor = UIColor.whiteColor;
        //self.layer.cornerRadius = 10.f;
        //self.layer.masksToBounds = YES;
        
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
        [self.closeButton setImage:[PLVECUtils imageForWatchResource:@"plv_commodity_close_btn"] forState:UIControlStateNormal];
        [self.closeButton addTarget:self action:@selector(closeButtonAction) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.closeButton];
        
        self.jumpButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.jumpButton setImage:[PLVECUtils imageForWatchResource:@"plv_commodity_jump_btn"] forState:UIControlStateNormal];
        [self.jumpButton addTarget:self action:@selector(jumpButtonAction) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.jumpButton];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.closeButton.frame = CGRectMake(CGRectGetWidth(self.bounds)-20, 4, 16, 16);
    self.jumpButton.frame = CGRectMake(CGRectGetWidth(self.bounds)-46, CGRectGetHeight(self.bounds)-40, 24, 24);
    
    self.coverImageView.frame = CGRectMake(12, 12, 56, 56);
    CGFloat positionX = CGRectGetMaxX(self.coverImageView.frame) + 8;
    self.nameLabel.frame = CGRectMake(positionX, 14, CGRectGetWidth(self.bounds)-positionX-22, 20);
    self.realPriceLabel.frame = CGRectMake(positionX, CGRectGetHeight(self.bounds)-43, 150, 25);
    [self.realPriceLabel sizeToFit];
    CGFloat priceLabelX = CGRectGetMaxX(self.realPriceLabel.frame) + 4;
    self.priceLabel.frame = CGRectMake(priceLabelX, CGRectGetMinY(self.realPriceLabel.frame)+4, CGRectGetMinX(self.jumpButton.frame)-10-priceLabelX, 17);
    
    [self drawLayer];
}

#pragma mark - Private

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

#pragma mark - Setter

- (void)setModel:(PLVCommodityModel *)model {
    _model = model;
    if (!model) {
        return;
    }
    
    // 实际价格显示逻辑
    NSString *realPriceStr = [NSString stringWithFormat:@"¥ %@",model.realPrice];
    if ([model.realPrice isEqualToString:@"0"]) {
        realPriceStr = @"免费";
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
    
    self.hidden = NO;
    self.nameLabel.text = model.name;
    self.realPriceLabel.text = realPriceStr;
    self.priceLabel.attributedText = priceAtrrStr;
    self.showIdLabel.text = [NSString stringWithFormat:@"%ld",model.showId];
    
    [self.realPriceLabel sizeToFit];
    self.priceLabel.frame = CGRectMake(CGRectGetMaxX(self.realPriceLabel.frame)+4, CGRectGetMinY(self.realPriceLabel.frame)+4, 120, 17);
       
    self.coverImageView.image = nil;
    [PLVFdUtil setImageWithURL:coverUrl inImageView:self.coverImageView completed:^(UIImage *image, NSError *error, NSURL *imageURL) {
        if (error) {
            NSLog(@"-setCellModel:图片加载失败，%@",imageURL);
        }
    }];
    
    self.timing = 5;
    if (self.timer) {
        [self.timer setFireDate:NSDate.distantPast];
    } else {
        self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(timerTick:) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
    }
}

#pragma mark - Action

- (void)closeButtonAction {
    self.hidden = YES;
}

- (void)jumpButtonAction {
    NSURL *jumpLinkUrl;
    // 跳转地址
    if (10 == self.model.linkType) { // 通用链接
        jumpLinkUrl = [NSURL URLWithString:self.model.link];
    } else if (11 == self.model.linkType) { // 多平台链接
        jumpLinkUrl = [NSURL URLWithString:self.model.mobileAppLink];
    } else {
        jumpLinkUrl = nil;
    }
    if (jumpLinkUrl && !jumpLinkUrl.scheme) {
        jumpLinkUrl = [NSURL URLWithString:[@"http://" stringByAppendingString:jumpLinkUrl.absoluteString]];
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(jumpToGoodsDetail:)]) {
        [self.delegate jumpToGoodsDetail:jumpLinkUrl];
    }
}

- (void)timerTick:(NSTimer *)timer {
    if (0 >= self.timing --) {
        [timer setFireDate:NSDate.distantFuture];
        self.hidden = YES;
    }
}

#pragma mark - Public

- (void)destroy {
    if (self.timer) {
        [self.timer invalidate];
        self.timer = nil;
    }
}

@end
