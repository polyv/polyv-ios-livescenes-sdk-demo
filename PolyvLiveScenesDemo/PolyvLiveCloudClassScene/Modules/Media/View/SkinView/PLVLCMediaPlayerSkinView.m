//
//  PLVLCMediaPlayerSkinView.m
//  PolyvLiveScenesDemo
//
//  Created by Lincal on 2020/9/16.
//  Copyright © 2020 polyv. All rights reserved.
//

#import "PLVLCMediaPlayerSkinView.h"

@interface PLVLCMediaPlayerSkinView ()

@end

@implementation PLVLCMediaPlayerSkinView

@synthesize skinViewLiveStatus = _skinViewLiveStatus;

#pragma mark - [ Life Period ]
- (void)dealloc{
    NSLog(@"%s",__FUNCTION__);
}

- (void)layoutSubviews{
    BOOL fullScreen = [UIScreen mainScreen].bounds.size.width > [UIScreen mainScreen].bounds.size.height;

    CGFloat viewWidth = CGRectGetWidth(self.bounds);
    CGFloat viewHeight = CGRectGetHeight(self.bounds);
    
    CGFloat toppadding;
    if (@available(iOS 11.0, *)) {
        toppadding = self.safeAreaInsets.top;
    } else {
        toppadding = 20;
    }
    toppadding += 4; /// 顶部距离增加间隙值
            
    if (!fullScreen) {
        // 竖屏布局
        self.hidden = NO;
        [self controlsSwitchShowStatusWithAnimation:YES];

        // 基础数据
        CGFloat leftPadding = 2.0;
        CGFloat bottomPadding = 12.0;
        CGFloat commonHeight = 20.0;
        
        // 顶部UI
        CGFloat topShadowLayerHeight = 83.0;
        self.topShadowLayer.frame = CGRectMake(0, 0, viewWidth, topShadowLayerHeight);
        
        CGSize backButtonSize = CGSizeMake(40.0, 40.0);
        self.backButton.frame = CGRectMake(leftPadding, toppadding, backButtonSize.width, backButtonSize.height);
        self.backButton.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 20, 0);
        
        CGFloat countdownTimeViewHeigh = 32.0;
        self.countdownTimeView.frame = CGRectMake(0, toppadding - (countdownTimeViewHeigh - commonHeight) / 2.0f,
                                                  viewWidth, countdownTimeViewHeigh);
        
        CGFloat titleLabelWidthScale = 200.0 / 375.0;
        CGFloat titleLabelWidth = viewWidth * titleLabelWidthScale;
        self.titleLabel.frame = CGRectMake(CGRectGetMaxX(self.backButton.frame), CGRectGetMinY(self.backButton.frame), titleLabelWidth, commonHeight);
        
        [self refreshPlayTimesLabelFrame];
        
        CGFloat rightPadding = 2.0;
        self.moreButton.frame = CGRectMake(viewWidth - rightPadding - backButtonSize.width, toppadding, backButtonSize.width, commonHeight);
        
        // 底部UI
        CGFloat bottomShadowLayerHeight = 70.0;
        self.bottomShadowLayer.frame = CGRectMake(0, viewHeight - bottomShadowLayerHeight, viewWidth, bottomShadowLayerHeight);
        
        self.playButton.frame = CGRectMake(leftPadding, viewHeight - bottomPadding - commonHeight, backButtonSize.width, commonHeight);
        
        [self refreshRefreshButtonFrame];
        
        self.fullScreenButton.frame = CGRectMake(CGRectGetMinX(self.moreButton.frame), CGRectGetMinY(self.playButton.frame), backButtonSize.width, commonHeight);
        
        self.floatViewShowButton.frame = CGRectMake(CGRectGetMinX(self.fullScreenButton.frame) - backButtonSize.width, CGRectGetMinY(self.playButton.frame), backButtonSize.width, commonHeight);
        
        CGFloat timeLabelWidth = [self getLabelTextWidth:self.currentTimeLabel];
        self.currentTimeLabel.frame = CGRectMake(CGRectGetMaxX(self.playButton.frame) + 10, CGRectGetMinY(self.playButton.frame), timeLabelWidth, commonHeight);
        
        self.diagonalsLabel.frame = CGRectMake(CGRectGetMaxX(self.currentTimeLabel.frame), CGRectGetMinY(self.currentTimeLabel.frame), 5, commonHeight);
        
        timeLabelWidth = [self getLabelTextWidth:self.durationLabel];
        self.durationLabel.frame = CGRectMake(CGRectGetMaxX(self.diagonalsLabel.frame), CGRectGetMinY(self.currentTimeLabel.frame), timeLabelWidth, commonHeight);
        
        UIButton *progressSliderNextButton = self.floatViewShowButton ?: self.fullScreenButton;
        CGFloat progressSliderLeftRightPadding = 16;
        CGFloat progressSliderWidth = viewWidth - CGRectGetMaxX(self.durationLabel.frame) - progressSliderLeftRightPadding - (viewWidth - CGRectGetMinX(progressSliderNextButton.frame)) - progressSliderLeftRightPadding;
        self.progressSlider.frame = CGRectMake(CGRectGetMaxX(self.durationLabel.frame) + progressSliderLeftRightPadding, CGRectGetMinY(self.currentTimeLabel.frame), progressSliderWidth, 21);
        
    }else{
        self.hidden = YES;
    }
}


#pragma mark - [ Father Public Methods ]
- (void)showFloatViewShowButtonTipsLabelAnimation:(BOOL)showTips{
    if (showTips == !self.floatViewShowButtonTipsLabel.hidden) { return; }
    if (self.floatViewShowButtonTipsLabelHadShown && showTips) { return; }
    
    CGFloat viewWidth = CGRectGetWidth(self.bounds);

    CGFloat labelWidth = 136.0;
    CGFloat labelHeight = 25.0;
    CGFloat rightPadding = 12.0;
    
    CGFloat targetY = showTips ? (CGRectGetMinY(self.floatViewShowButton.frame) - labelHeight - 8) : (CGRectGetMinY(self.floatViewShowButton.frame) - labelHeight * 2 - 8);
    
    if (showTips) {
        /// 重置至起始位及起始状态
        CGFloat startY = CGRectGetMinY(self.floatViewShowButton.frame) - 8;
        CGRect oriRect = CGRectMake(viewWidth - rightPadding - labelWidth, startY, labelWidth, labelHeight);
        self.floatViewShowButtonTipsLabel.frame = oriRect;
        self.floatViewShowButtonTipsLabel.alpha = 0;
        self.floatViewShowButtonTipsLabel.hidden = NO;
        
        self.floatViewShowButtonTipsLabelHadShown = YES;
    }
    CGRect targetRect = CGRectMake(viewWidth - rightPadding - labelWidth, targetY, labelWidth, labelHeight);

    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        weakSelf.floatViewShowButtonTipsLabel.frame = targetRect;
        weakSelf.floatViewShowButtonTipsLabel.alpha = showTips ? 1.0 : 0.0;
    } completion:^(BOOL finished) {
        if (!showTips) {
            weakSelf.floatViewShowButtonTipsLabel.hidden = YES;
        }
    }];
}

- (void)refreshPlayTimesLabelFrame{
    CGSize playTimesLabelFitSize = [self.playTimesLabel sizeThatFits:CGSizeMake(150, 18)];
    self.playTimesLabel.frame = CGRectMake(CGRectGetMinX(self.titleLabel.frame), CGRectGetMaxY(self.titleLabel.frame) + 1, playTimesLabelFitSize.width + 8, 18);
}

- (void)switchSkinViewLiveStatusTo:(PLVLCBasePlayerSkinViewLiveStatus)skinViewLiveStatus{
    [super switchSkinViewLiveStatusTo:skinViewLiveStatus];
    
    if (_skinViewLiveStatus == skinViewLiveStatus) { return; }

    _skinViewLiveStatus = skinViewLiveStatus;
        
    if (self.skinViewType < PLVLCBasePlayerSkinViewType_AlonePlayback) {
        [self refreshRefreshButtonFrame];
    }else{
        NSLog(@"PLVLCMediaPlayerSkinView - skinViewLiveStatusSwitchTo failed, skin view type illegal:%ld",self.skinViewType);
    }
}

- (void)refreshRefreshButtonFrame {
    CGSize buttonSize = CGSizeMake(40.0, 20.0);
    CGFloat originX = CGRectGetMinX(self.playButton.frame);
    if (!self.playButton.hidden && self.playButton.superview) {
        originX += CGRectGetWidth(self.playButton.frame) + 5;
    }
    self.refreshButton.frame = CGRectMake(originX, CGRectGetMinY(self.playButton.frame), buttonSize.width, buttonSize.height);
}

@end
