//
//  PLVLCMediaProgressView.m
//  PLVLiveScenesDemo
//
//  Created by Dhan on 2022/11/9.
//  Copyright © 2022 PLV. All rights reserved.
//

#import "PLVLCMediaProgressView.h"
#import <PLVFoundationSDK/PLVFoundationSDK.h>

@interface PLVLCMediaProgressView()

#pragma mark UI

@property (nonatomic, strong) UILabel *progressLabel;

@end

@implementation PLVLCMediaProgressView

#pragma mark - [ Life Period ]

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.progressLabel.frame = self.bounds;
}

#pragma mark - [ Public Methods ]

- (void)setAttributedText:(NSAttributedString *)attributedText {
    self.progressLabel.attributedText = attributedText;
    [self layoutIfNeeded];
}

#pragma mark - [ Private Methods ]
- (void)setupUI{
    self.backgroundColor = [UIColor clearColor];
    [self addSubview:self.progressLabel];
}

- (UILabel *)progressLabel {
    if (!_progressLabel) {
        _progressLabel = [[UILabel alloc] init];
        _progressLabel.attributedText = [[NSMutableAttributedString alloc]initWithString:@"00:00:00/00:00:00"];
        _progressLabel.textAlignment = NSTextAlignmentCenter;
        _progressLabel.font = [UIFont fontWithName:@"PingFang SC" size:14];
        _progressLabel.adjustsFontSizeToFitWidth = YES;
        _progressLabel.backgroundColor = PLV_UIColorFromRGBA(@"000000", 0.5);
        _progressLabel.layer.cornerRadius = 16.5;
        _progressLabel.layer.masksToBounds = YES;
    }
    return _progressLabel;
}


@end
