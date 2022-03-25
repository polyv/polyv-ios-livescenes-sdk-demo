//
//  PLVWatermark.m
//  PLVLiveScenesDemo
//
//  Created by jiaweihuang on 2021/12/14.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVWatermarkView.h"


@interface PLVWatermarkLabel : UILabel


@end

@implementation PLVWatermarkLabel


- (void)drawTextInRect:(CGRect)rect {
   CGSize shadowOffset = self.shadowOffset;
   UIColor *textColor = self.textColor;
 
   CGContextRef c = UIGraphicsGetCurrentContext();
   CGContextSetLineWidth(c, 1);
   CGContextSetLineJoin(c, kCGLineJoinRound);
 
   CGContextSetTextDrawingMode(c, kCGTextStroke);
   self.textColor = [UIColor whiteColor];
   [super drawTextInRect:rect];
 
   CGContextSetTextDrawingMode(c, kCGTextFill);
   self.textColor = textColor;
   self.shadowOffset = CGSizeMake(0, 0);
   [super drawTextInRect:rect];

   self.shadowOffset = shadowOffset;
}

@end


/**
 水印文字大小
 */
static NSInteger const PLVWatermarkSmallFontSize  = 15;

static NSInteger const PLVWatermarkMiddleFontSize = 19;

static NSInteger const PLVWatermarkLargeFontSize  = 23;

/**
 水印高度
 */
static NSInteger const PLVWatermarkSmallHeight  = 22;

static NSInteger const PLVWatermarkMiddleHeight = 27;

static NSInteger const PLVWatermarkLargeHeight  = 30;


@interface PLVWatermarkView()

#pragma mark 数据
@property (nonatomic, strong) PLVWatermarkModel *model;

@property (nonatomic, assign) NSInteger fontSize;

@property (nonatomic, assign) CGFloat watermarkWidth;

@property (nonatomic, assign) CGFloat watermarkHeight;

@end

@implementation PLVWatermarkView

#pragma mark - [ Life Period ]

- (instancetype)initWithWatermarkModel:(PLVWatermarkModel *)model {
    self = [super init];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.userInteractionEnabled = NO;
        self.clipsToBounds = YES;
        
        self.model = model;
        [self calcWatermarkWidth];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self updateUI];
}

#pragma mark - [ Private Method ]

- (void)clearWatermark {
    for (UIView *view in self.subviews) {
        if ([view isKindOfClass:UILabel.class]){
            [view removeFromSuperview];
        }
    }
}

- (void)calcWatermarkWidth {
    UILabel *lable = [[UILabel alloc] init];
    lable.font = [UIFont systemFontOfSize:self.fontSize];
    lable.text = self.model.content;
    self.watermarkWidth = [lable sizeThatFits:CGSizeMake(MAXFLOAT, self.watermarkHeight)].width;
}

- (void)updateUI {
    if (!self.watermarkWidth) {
        return;
    }

    [self clearWatermark];
    CGFloat xPadding = self.fontSize;
    CGFloat yPadding = 30;
    CGFloat selfWidth = CGRectGetWidth(self.frame);
    CGFloat selfHeight = CGRectGetHeight(self.frame);
    /// 计算X轴能容纳的水印数量
    NSInteger rowNum = selfWidth / self.watermarkWidth;
    NSInteger finalRowNum;
    if (selfWidth < self.watermarkWidth) {
        finalRowNum = 1;
    } else {
        CGFloat rowOffset = (rowNum - 1) * xPadding;
        finalRowNum = ceil((selfWidth - rowOffset) / self.watermarkWidth);
        if (rowNum > finalRowNum) {
            NSInteger offsetWidth = (rowNum - finalRowNum - 1) * xPadding;
            finalRowNum = ceil((selfWidth - rowOffset + offsetWidth) / self.watermarkWidth);
        }
    }

    /// 计算Y轴能容纳的水印数量
    NSInteger columnNum = selfHeight / self.watermarkHeight;
    CGFloat columnOffset = (columnNum - 1) * yPadding;
    NSInteger finalColunmNum = ceil((selfHeight - columnOffset) / self.watermarkHeight);
    if (columnNum > finalColunmNum) {
        NSInteger offsetHeight = (columnNum - finalColunmNum - 1) * yPadding;
        finalColunmNum = ceil((selfHeight - columnOffset + offsetHeight) / self.watermarkHeight);
    }
    
    /// 总数量
    NSInteger total = finalRowNum * finalColunmNum;
    for (int i = 0; i < total; i++) {
        PLVWatermarkLabel *label = [[PLVWatermarkLabel alloc] init];
        label.text = self.model.content;
        label.font = [UIFont systemFontOfSize:self.fontSize];
        label.alpha = (CGFloat)(100 - self.model.opacity) / 100;
        CGFloat width = self.watermarkWidth;
        CGFloat height = self.watermarkHeight;
        int row = i % finalRowNum;
        int section = i / finalRowNum;
        float x = row * width + xPadding * row;
        float y = section * height + section * yPadding;
        label.frame = CGRectMake(x, y, width, height);
        label.transform = CGAffineTransformMakeRotation(-0.3);
        [self addSubview:label];
    }
}

#pragma mark [ Setter ]

- (void)setModel:(PLVWatermarkModel *)model {
    _model = model;
    if (model.fontSize == PLVChannelWatermarkFontSize_Small) {
        self.fontSize = PLVWatermarkSmallFontSize;
        self.watermarkHeight = PLVWatermarkSmallHeight;
    } else if (model.fontSize == PLVChannelWatermarkFontSize_Middle) {
        self.fontSize = PLVWatermarkMiddleFontSize;
        self.watermarkHeight = PLVWatermarkMiddleHeight;
    } else if (model.fontSize == PLVChannelWatermarkFontSize_Large) {
        self.fontSize = PLVWatermarkLargeFontSize;
        self.watermarkHeight = PLVWatermarkLargeHeight;
    }
}


@end
