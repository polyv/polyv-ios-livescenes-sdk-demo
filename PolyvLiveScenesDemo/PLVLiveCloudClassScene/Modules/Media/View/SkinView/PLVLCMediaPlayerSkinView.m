//
//  PLVLCMediaPlayerSkinView.m
//  PLVLiveScenesDemo
//
//  Created by Lincal on 2020/9/16.
//  Copyright © 2020 PLV. All rights reserved.
//

#import "PLVLCMediaPlayerSkinView.h"
#import <PLVLiveScenesSDK/PLVConsoleLogger.h>

@interface PLVLCMediaPlayerSkinView ()

@end

@implementation PLVLCMediaPlayerSkinView

@synthesize skinViewLiveStatus = _skinViewLiveStatus;

#pragma mark - [ Life Period ]
- (void)dealloc{
    PLV_LOG_INFO(PLVConsoleLogModuleTypePlayer,@"%s",__FUNCTION__);
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
        CGFloat leftPadding = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad ? 10.0 : 2.0;
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
        [self refreshProgressViewFrame];
        
        CGFloat rightPadding = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad ? 10.0 : 2.0;
        self.moreButton.frame = CGRectMake(viewWidth - rightPadding - backButtonSize.width, toppadding, backButtonSize.width, backButtonSize.height);
        self.castButton.frame = CGRectMake(CGRectGetMinX(self.moreButton.frame) - 44 - 5, toppadding, backButtonSize.width, backButtonSize.height + 5);
        if (self.castButton.hidden) {
            self.pictureInPictureButton.frame = CGRectMake(self.moreButton.frame.origin.x - backButtonSize.width, toppadding, backButtonSize.width, backButtonSize.height);
        } else {
            self.pictureInPictureButton.frame = CGRectMake(self.castButton.frame.origin.x - backButtonSize.width, toppadding, backButtonSize.width, backButtonSize.height);
        }
        
        [self refreshPictureInPictureButtonFrame];
        
        // 底部UI
        CGFloat bottomShadowLayerHeight = 70.0;
        self.bottomShadowLayer.frame = CGRectMake(0, viewHeight - bottomShadowLayerHeight, viewWidth, bottomShadowLayerHeight);
        
        self.playButton.frame = CGRectMake(leftPadding, viewHeight - bottomPadding - commonHeight, backButtonSize.width, commonHeight);
        
        [self refreshRefreshButtonFrame];
        
        self.fullScreenButton.frame = CGRectMake(CGRectGetMinX(self.moreButton.frame), CGRectGetMinY(self.playButton.frame), backButtonSize.width, commonHeight);
        self.paintButton.frame = CGRectMake(CGRectGetMaxX(self.fullScreenButton.frame) - backButtonSize.width - 8, CGRectGetMinY(self.fullScreenButton.frame) - 8 - backButtonSize.height, backButtonSize.width, backButtonSize.height);
        
        // 精彩看点按钮布局 - 只在回放场景显示，位于右侧，底部工具栏上方
        if (self.skinViewType >= PLVLCBasePlayerSkinViewType_AlonePlayback) {
            [self refreshKeyMomentsButtonFrame];
        }
                
        [self refreshFloatViewShowButtonFrame];
        
        CGFloat timeLabelWidth = [self getLabelTextWidth:self.currentTimeLabel];
        self.currentTimeLabel.frame = CGRectMake(CGRectGetMaxX(self.playButton.frame) + 10, CGRectGetMinY(self.playButton.frame), timeLabelWidth, commonHeight);
        
        self.diagonalsLabel.frame = CGRectMake(CGRectGetMaxX(self.currentTimeLabel.frame), CGRectGetMinY(self.currentTimeLabel.frame), 5, commonHeight);
        
        timeLabelWidth = [self getLabelTextWidth:self.durationLabel];
        self.durationLabel.frame = CGRectMake(CGRectGetMaxX(self.diagonalsLabel.frame), CGRectGetMinY(self.currentTimeLabel.frame), timeLabelWidth, commonHeight);
        
        UIButton *progressSliderNextButton = self.floatViewShowButton ?: self.fullScreenButton;
        CGFloat progressSliderLeftRightPadding = 16;
        CGFloat progressSliderWidth = viewWidth - CGRectGetMaxX(self.durationLabel.frame) - progressSliderLeftRightPadding - (viewWidth - CGRectGetMinX(progressSliderNextButton.frame)) - progressSliderLeftRightPadding;
        self.progressSlider.frame = CGRectMake(CGRectGetMaxX(self.durationLabel.frame) + progressSliderLeftRightPadding, CGRectGetMinY(self.currentTimeLabel.frame), progressSliderWidth, 21);
        
        // 翻页视图
        CGFloat documentToolViewWidht = self.documentToolView.viewWidth;
        CGFloat documentToolHeight = 36;
        CGFloat documentToolPadding = 3;
        self.documentToolView.frame = CGRectMake((viewWidth - documentToolViewWidht) / 2, CGRectGetMinY(self.fullScreenButton.frame) - documentToolHeight - documentToolPadding, documentToolViewWidht , documentToolHeight);
        // 自动隐藏皮肤
        [self autoHideSkinView]; 
    }else{
        self.hidden = YES;
    }
}

- (void)refreshPictureInPictureButtonFrame {
    CGFloat toppadding;
    if (@available(iOS 11.0, *)) {
        toppadding = self.safeAreaInsets.top;
    } else {
        toppadding = 20;
    }
    toppadding += 4; /// 顶部距离增加间隙值
    CGSize buttonSize = CGSizeMake(40.0, 40.0);
    CGFloat viewWidth = CGRectGetWidth(self.bounds);
    CGFloat rightPadding = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad ? 10.0 : 2.0;
    CGFloat buttonInterval = 5.0; // 按钮之间的间距
    CGFloat moreBtnFrameX = viewWidth - rightPadding - buttonSize.width;
    CGFloat pipFrameX;
    
    // 计算画中画按钮位置：从右到左依次是 moreButton -> castButton -> pictureInPictureButton
    if (!self.castButton.hidden && self.castButton.frame.size.width > 0) {
        // 如果投屏按钮显示，画中画按钮应该在投屏按钮左侧，保持间距
        pipFrameX = self.castButton.frame.origin.x - buttonSize.width - buttonInterval;
    } else if (!self.moreButton.hidden) {
        // 如果投屏按钮隐藏，画中画按钮应该在更多按钮左侧，保持间距
        pipFrameX = self.moreButton.frame.origin.x - buttonSize.width - buttonInterval;
    } else {
        // 如果更多按钮也隐藏，画中画按钮在最右侧
        pipFrameX = moreBtnFrameX;
    }
    
    self.pictureInPictureButton.frame = CGRectMake(pipFrameX, toppadding, buttonSize.width, buttonSize.height);
}

#pragma mark - [ Father Public Methods ]
- (void)showFloatViewShowButtonTipsLabelAnimation:(BOOL)showTips{
    if (showTips == !self.floatViewShowButtonTipsLabel.hidden) { return; }
    if (self.floatViewShowButtonTipsLabelHadShown && showTips) { return; }
    
    CGFloat viewWidth = CGRectGetWidth(self.bounds);

    CGFloat labelHeight = 25.0;
    CGFloat rightPadding = 12.0;
    CGSize labelSize = [self.floatViewShowButtonTipsLabel sizeThatFits:CGSizeMake(MAXFLOAT, labelHeight)];
    CGFloat labelWidth = labelSize.width + 16;
    
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

- (void)refreshProgressViewFrame {
    CGFloat toppadding;
    if (@available(iOS 11.0, *)) {
        toppadding = self.safeAreaInsets.top;
    } else {
        toppadding = 20;
    }
    self.progressView.frame = CGRectMake(self.frame.size.width / 2 - 73.5, self.frame.size.height / 2 - 16, 147, 32);
}

- (void)switchSkinViewLiveStatusTo:(PLVLCBasePlayerSkinViewLiveStatus)skinViewLiveStatus{
    [super switchSkinViewLiveStatusTo:skinViewLiveStatus];
    
    if (_skinViewLiveStatus == skinViewLiveStatus) { return; }

    _skinViewLiveStatus = skinViewLiveStatus;
    
    [self refreshPictureInPictureButtonFrame];
    if (self.skinViewType >= PLVLCBasePlayerSkinViewType_AlonePlayback) {
        [self refreshKeyMomentsButtonFrame];
    }
        
    if (self.skinViewType < PLVLCBasePlayerSkinViewType_AlonePlayback) {
        [self refreshRefreshButtonFrame];
    }else{
        PLV_LOG_ERROR(PLVConsoleLogModuleTypePlayer,@"PLVLCMediaPlayerSkinView - skinViewLiveStatusSwitchTo failed, skin view type illegal:%ld",self.skinViewType);
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

- (void)refreshFloatViewShowButtonFrame {
    CGSize backButtonSize = CGSizeMake(40.0, 40.0);
    CGFloat commonHeight = 20.0;
    CGFloat originX = CGRectGetMinX(self.moreButton.frame);
    
    if (!self.fullScreenButton.hidden && self.fullScreenButton.superview) {
        originX = CGRectGetMinX(self.fullScreenButton.frame) - backButtonSize.width - 5;
    }

    self.floatViewShowButton.frame = CGRectMake(originX, CGRectGetMinY(self.playButton.frame), backButtonSize.width, commonHeight);
}

- (void)refreshMoreButtonHiddenOrRestore:(BOOL)hidden {
    [super refreshMoreButtonHiddenOrRestore:hidden];
    [self refreshPictureInPictureButtonFrame];
}

- (void)refreshPaintButtonShow:(BOOL)show {
    self.paintButton.hidden = !show;
}

- (void)refreshKeyMomentsButtonFrame {
    if (!self.keyMomentsButton || self.keyMomentsButton.hidden) {
        return;
    }
    
    CGFloat viewWidth = CGRectGetWidth(self.bounds);
    CGFloat viewHeight = CGRectGetHeight(self.bounds);
    
    // 按钮尺寸
    CGFloat buttonWidth = 80.0;  // 适合显示"精彩看点"文字
    CGFloat buttonHeight = 32.0;
    
    // 右侧边距
    CGFloat rightPadding = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad ? 16.0 : 12.0;
    
    // 底部工具栏高度和间距
    CGFloat bottomToolbarHeight = 70.0;  // 与bottomShadowLayer高度一致
    CGFloat bottomSpacing = 16.0;  // 与底部工具栏的间距
    
    // 计算位置：右侧，底部工具栏上方
    CGFloat buttonX = viewWidth - rightPadding - buttonWidth;
    CGFloat buttonY = viewHeight - bottomToolbarHeight - bottomSpacing - buttonHeight;
    
    self.keyMomentsButton.frame = CGRectMake(buttonX, buttonY, buttonWidth, buttonHeight);
}

- (void)setShowCastButton:(BOOL)showCastButton{
    self.castButton.hidden = showCastButton ? NO: YES;
    [self refreshPictureInPictureButtonFrame];
}

@end
