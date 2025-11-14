//
//  PLVSAAICardWidgetView.m
//  PolyvLiveScenesDemo
//
//  Created by Dhan on 2025/11/04.
//  Copyright © 2025 PLV. All rights reserved.
//

#import "PLVSAAICardWidgetView.h"
#import "PLVSAUtils.h"
#import "PLVMultiLanguageManager.h"
#import "PLVRoomDataManager.h"
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>
#import <SDWebImage/UIImageView+WebCache.h>

@interface PLVSAAICardWidgetView ()

@property (nonatomic, assign) CGSize widgetSize;

#pragma mark UI
@property (nonatomic, strong) UIImageView *aiCardImageView;
@property (nonatomic, strong) UILabel *titleLabel;

@end

@implementation PLVSAAICardWidgetView

#pragma mark - [ Life Cycle ]

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.aiCardImageView.frame = CGRectMake(0, 0, CGRectGetWidth(self.bounds), CGRectGetWidth(self.bounds));
    self.titleLabel.frame = CGRectMake(2, CGRectGetMaxY(self.aiCardImageView.frame) - 14, 32, 12);
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.hidden = YES;
        self.widgetSize = CGSizeMake(36, 36);
        [self addSubview:self.aiCardImageView];
        [self addSubview:self.titleLabel];
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(widgetTapAction)];
        [self addGestureRecognizer:tap];
    }
    return self;
}

#pragma mark - [ Private Method ]


#pragma mark Getter
- (UIImageView *)aiCardImageView {
    if (!_aiCardImageView) {
        _aiCardImageView = [[UIImageView alloc] init];
        _aiCardImageView.contentMode = UIViewContentModeScaleAspectFit;
        UIImage *image = [PLVSAUtils imageForLiveroomResource:@"plvsa_streamer_ai_card_widget_icon"];
        [_aiCardImageView setImage:image];
    }
    return _aiCardImageView;
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = [UIFont fontWithName:@"PingFangSC-Medium" size:8];
        _titleLabel.text = PLVLocalizedString(@"AI手卡");
        _titleLabel.textColor = [PLVColorUtil colorFromHexString:@"#FF5252"];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.backgroundColor = [PLVColorUtil colorFromHexString:@"#FFF5F7"];
        _titleLabel.layer.masksToBounds = YES;
        _titleLabel.layer.cornerRadius = 6;
    }
    return _titleLabel;
}

#pragma mark - [ Event ]
#pragma mark Action
- (void)widgetTapAction {
    if (self.delegate && [self.delegate respondsToSelector:@selector(aiCardWidgetViewDidClickAction:)]) {
        [self.delegate aiCardWidgetViewDidClickAction:self];
    }
}

@end

