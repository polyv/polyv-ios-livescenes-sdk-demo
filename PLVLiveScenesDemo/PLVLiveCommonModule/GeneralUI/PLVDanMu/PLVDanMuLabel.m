//
//  PLVDanMuLabel.m
//  PLVLiveScenesDemo
//
//  Created by lijingtong on 2021/4/13.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVDanMuLabel.h"
#import "PLVDanMuDefine.h"

@interface PLVDanMuLabel ()

@property (nonatomic, assign) CGRect superFrame;
@property (nonatomic, assign) CGFloat animateDuration;

@end

@implementation PLVDanMuLabel

/* 创建 */
+ (instancetype)dmInitDML:(NSMutableAttributedString *)content dmlOriginY:(CGFloat)dmlOriginY superFrame:(CGRect)superFrame style:(PLVDMLStyle)style
{
    PLVDanMuLabel *dmLabel = [[PLVDanMuLabel alloc] init];
    [dmLabel makeup:content dmlOriginY:dmlOriginY superFrame:superFrame style:style];
    
    return dmLabel;
}

- (void)makeup:(NSMutableAttributedString *)content dmlOriginY:(CGFloat)dmlOriginY superFrame:(CGRect)superFrame style:(PLVDMLStyle)style {
    self.superFrame = superFrame;
    self.plvDMLStyle = style;
    
    [self dmInitWithContent:content dmlOriginY:dmlOriginY];
}

/* 初始化 */
- (void)dmInitWithContent:(NSMutableAttributedString *)content dmlOriginY:(CGFloat)dmlOriginY
{
    self.textColor = [UIColor whiteColor];
    self.font = [UIFont systemFontOfSize:14];
    self.attributedText = content;
    
    CGSize size = [self countString:content size:CGSizeMake(MAXFLOAT, KPLVDMHEIGHT) font:self.font];
    
    // 当文字显示大于一屏时，自动调整为滚动显示
    if (size.width > self.superFrame.size.width - 90) {
        self.plvDMLStyle = PLVDMLRoll;
    }
    
    if (self.plvDMLStyle == PLVDMLRoll) {
        self.frame = CGRectMake(self.superFrame.size.width, dmlOriginY, size.width, size.height);
    } else {
        self.frame = CGRectMake(0, 0, size.width, size.height);
        self.center = CGPointMake(self.superFrame.size.width/2 - 30 + arc4random_uniform(60), dmlOriginY + size.height/2);
        self.alpha = 0.0f;
    }
}

/* 开始弹幕动画 */
- (void)dmBeginAnimation
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        self.plvDMLState = PLVDMLStateRunning;
        self.startTime = [NSDate date];
        
        if (self.plvDMLStyle == PLVDMLRoll) {
            int scale = self.frame.size.width / [UIScreen mainScreen].bounds.size.width;
            scale = sqrt(scale) * 2.0;
            if (scale == 0) {
                scale = 1;
            }
            self.animateDuration = KPLVDMLROLLANIMATION * scale;
            [UIView animateWithDuration:self.animateDuration delay:0.0f options:UIViewAnimationOptionCurveLinear animations:^{
                
                CGRect frame = self.frame;
                frame.origin.x = - self.frame.size.width;
                self.frame = frame;
                
            } completion:^(BOOL finished) {
                
                if (finished) {
                    [self removeDanmu];
                }
                
            }];
            
        } else {
            
            [UIView animateWithDuration:1.0f delay:0.0f options:UIViewAnimationOptionCurveLinear animations:^{
                
                self.alpha = 1.0f;
                
            } completion:^(BOOL finished) {
                
                [UIView animateWithDuration:1.0f delay:KPLVDMLFADEANIMATION options:UIViewAnimationOptionCurveLinear animations:^{
                    
                    self.alpha = 0.2f;
                    
                } completion:^(BOOL finished) {
                    
                    if (finished) {
                        [self removeDanmu];
                    }
                    
                }];
                
            }];
        }
        
    });
}

/* 移除弹幕 */
- (void)removeDanmu {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.plvDMLState = PLVDMLStateFinish;
        [self.layer removeAllAnimations];
        [self removeFromSuperview];
        if (self.delegate && [self.delegate respondsToSelector:@selector(endScrollAnimation:)]) {
            [self.delegate endScrollAnimation:self];
        }
    });
}

/** 动态计算文本高度 **/
- (CGSize)countString:(NSMutableAttributedString *)content size:(CGSize)size font:(UIFont *)font
{
    CGSize expectedLabelSize = [self sizeThatFits:size];
    
    return CGSizeMake(ceil(expectedLabelSize.width), ceil(expectedLabelSize.height));
}

#pragma mark - GET
- (CGFloat)dmlSpeed
{
    return (self.frame.size.width + self.superFrame.size.width) / self.animateDuration;
}

- (CGFloat)dmlFadeTime
{
    return 1.0f + 1.0f + KPLVDMLFADEANIMATION;
}

@end
