//
//  PLVSALinkMicLayoutSwitchGuideView.m
//  PLVLiveScenesDemo
//
//  Created by Sakya on 2021/11/10.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVSALinkMicLayoutSwitchGuideView.h"

// 工具
#import "PLVSAUtils.h"
#import "PLVMultiLanguageManager.h"

// 框架
#import <PLVFoundationSDK/PLVFoundationSDK.h>

@interface  PLVSALinkMicLayoutSwitchGuideView()

/// UI
@property (nonatomic, strong) UIImageView *guideImageView;
@property (nonatomic, strong) UILabel *tipLabel;

@end

@implementation PLVSALinkMicLayoutSwitchGuideView

#pragma mark - [ Life Cycle ]

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        [self addSubview:self.guideImageView];
        [self.guideImageView addSubview:self.tipLabel];
    }
    return self;
}

#pragma mark - [ Override ]

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.guideImageView.frame = self.bounds;
    self.tipLabel.frame = self.bounds;
}

#pragma mark - [ Public Method ]

- (void)showLinkMicLayoutSwitchGuide:(BOOL)show {
    self.hidden = !show;
}

- (CGSize)viewSize {
    CGSize tipLabelSize = [self.tipLabel sizeThatFits:CGSizeMake(MAXFLOAT, 62)];
    return CGSizeMake(tipLabelSize.width + 22, 62);
}

#pragma mark - [ Private Method ]

#pragma mark Getter

- (UIImageView *)guideImageView {
    if (!_guideImageView) {
        _guideImageView = [[UIImageView alloc] init];
        UIImage *backgroundImage = [PLVSAUtils imageForLiveroomResource:@"plvsa_liveroom_layoutswitch_guide_icon"];
        // 指定中间不可拉伸的区域（这里假设左右各有10个像素不可拉伸）
        UIEdgeInsets capInsets = UIEdgeInsetsMake(0, 30, 0, 30);
        // 创建可拉伸的图片
        UIImage *resizableImage = [backgroundImage resizableImageWithCapInsets:capInsets resizingMode:UIImageResizingModeStretch];
        _guideImageView.image = resizableImage;
    }
    return _guideImageView;
}

- (UILabel *)tipLabel {
    if (!_tipLabel) {
        _tipLabel = [[UILabel alloc] init];
        _tipLabel.font = [UIFont boldSystemFontOfSize:14];
        _tipLabel.textColor = [UIColor whiteColor];
        _tipLabel.text = PLVLocalizedString(@"点击切换布局");
        _tipLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _tipLabel;
}

@end
