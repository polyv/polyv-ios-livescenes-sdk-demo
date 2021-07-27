//
//  PLVSAProhibitWordTipView.m
//  PLVLiveScenesDemo
//
//  Created by lijingtong on 2021/6/6.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVSAProhibitWordTipView.h"

//utils
#import "PLVSAUtils.h"

// SDK
#import <PLVFoundationSDK/PLVFoundationSDK.h>

@interface PLVSAProhibitWordTipView()

// UI
@property (nonatomic, strong) UIView *menuView;
@property (nonatomic, strong) UILabel *tipLabel; //提示

// 数据
@property (nonatomic, assign) CGSize menuSize;
@property (nonatomic, assign) PLVSAProhibitWordTipType tipType;
@end

@implementation PLVSAProhibitWordTipView

#pragma mark - [ Life Cycle ]

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        [self addSubview:self.menuView];
        [self.menuView addSubview:self.tipLabel];
    
    }
    return self;
}

#pragma mark - [ Override ]

- (void)layoutSubviews{
    [super layoutSubviews];
    CGRect frame = self.bounds;
    
    self.menuSize = frame.size;
    self.menuView.frame = frame;
    
    frame.origin.y = 4;
    self.tipLabel.frame = frame;
    
    UIBezierPath *bezierPath = [self BezierPathWithSize:self.menuSize];
    CAShapeLayer* shapeLayer = [CAShapeLayer layer];
    shapeLayer.path = bezierPath.CGPath;
    _menuView.layer.mask = shapeLayer;
}
#pragma mark - [ Public Method ]
/// 显示视图
- (void)show {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(dismiss) object:nil];

    [self performSelector:@selector(dismiss) withObject:nil afterDelay:3.0];
}

/// 关闭menu
- (void)dismiss {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(dismiss) object:nil];
    [self removeFromSuperview];
    if (self.dismissBlock) {
        self.dismissBlock();
    }
}

#pragma mark - [ Private Method ]

#pragma mark Getter

- (UIView *)menuView {
    if (!_menuView) {
        _menuView = [[UIView alloc] init];
        _menuView.backgroundColor = [PLVColorUtil colorFromHexString:@"#313540"];
        _menuView.layer.masksToBounds = YES;
    }
    return _menuView;
}

- (UILabel *)tipLabel {
    if (!_tipLabel) {
        _tipLabel = [[UILabel alloc] init];
        _tipLabel.font = [UIFont systemFontOfSize:12];
        _tipLabel.textColor = [UIColor whiteColor];
        _tipLabel.text = @"";
        _tipLabel.textAlignment = NSTextAlignmentCenter;
        _tipLabel.numberOfLines = 0;
    }
    return _tipLabel;
}


- (UIBezierPath *)BezierPathWithSize:(CGSize)size {
    CGFloat conner = 8.0;
    CGFloat trangleHeight = 8.0;
    CGFloat trangleWidth = 6.0;
    
    UIBezierPath *bezierPath = [UIBezierPath bezierPath];
    // 起点
    [bezierPath moveToPoint:CGPointMake(conner, trangleHeight)];
    if (self.tipType == PLVSAProhibitWordTipTypeImage) {
        [bezierPath addLineToPoint:CGPointMake(size.width /2 -  trangleWidth * 2 , trangleHeight)];
        [bezierPath addLineToPoint:CGPointMake(size.width /2 - trangleWidth, 0)];
        [bezierPath addLineToPoint:CGPointMake(size.width /2, trangleHeight)];
    } else {
        [bezierPath addLineToPoint:CGPointMake(size.width - 25 - trangleWidth * 2 , trangleHeight)];
        [bezierPath addLineToPoint:CGPointMake(size.width - 25 - trangleWidth, 0)];
        [bezierPath addLineToPoint:CGPointMake(size.width - 25, trangleHeight)];
    }
    
    [bezierPath addLineToPoint:CGPointMake(size.width - conner, trangleHeight)];
    [bezierPath addQuadCurveToPoint:CGPointMake(size.width, conner + trangleHeight) controlPoint:CGPointMake(size.width, trangleHeight)];
    [bezierPath addLineToPoint:CGPointMake(size.width, size.height-conner)];
    [bezierPath addQuadCurveToPoint:CGPointMake(size.width-conner, size.height) controlPoint:CGPointMake(size.width, size.height)];
    [bezierPath addLineToPoint:CGPointMake(conner, size.height)];
    [bezierPath addQuadCurveToPoint:CGPointMake(0, size.height-conner) controlPoint:CGPointMake(0, size.height)];
    [bezierPath addLineToPoint:CGPointMake(0, conner + trangleHeight)];
    [bezierPath addQuadCurveToPoint:CGPointMake(conner, trangleHeight) controlPoint:CGPointMake(0, trangleHeight)];
    [bezierPath closePath];
    return bezierPath;
}

#pragma mark Setter

- (void)setTipType:(PLVSAProhibitWordTipType)tipType prohibitWord:(NSString * _Nullable)prohibitWord {
    self.tipType = tipType;
    
    NSString *text = @"";
    
    if (tipType ==     PLVSAProhibitWordTipTypeText) {
        text = [NSString stringWithFormat:@"你的聊天信息中含有违规词：%@", prohibitWord];
    } else {
        text = @"图片不合法";
    }
    self.tipLabel.text = text;
}

@end
