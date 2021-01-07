//
//  PLVECPlayerContolView.m
//  PolyvLiveEcommerceDemo
//
//  Created by ftao on 2020/5/21.
//  Copyright © 2020 polyv. All rights reserved.
//

#import "PLVECPlayerContolView.h"
#import "PLVECUtils.h"

@implementation PLVECPlayerContolView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.playButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.playButton setImage:[PLVECUtils imageForWatchResource:@"plv_player_play_btn"] forState:UIControlStateNormal];
        [self.playButton setImage:[PLVECUtils imageForWatchResource:@"plv_player_pause_btn"] forState:UIControlStateSelected];
        [self.playButton addTarget:self action:@selector(playButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.playButton];
        
        self.currentTimeLabel = [[UILabel alloc] init];
        self.currentTimeLabel.text = @"00:00";
        self.currentTimeLabel.textColor = UIColor.whiteColor;
        self.currentTimeLabel.textAlignment = NSTextAlignmentRight;
        self.currentTimeLabel.font = [UIFont systemFontOfSize:12];
        [self addSubview:self.currentTimeLabel];
        
        self.totalTimeLabel = [[UILabel alloc] init];
        self.totalTimeLabel.text = @"00:00";
        self.totalTimeLabel.textColor = UIColor.whiteColor;
        self.totalTimeLabel.textAlignment = NSTextAlignmentLeft;
        self.totalTimeLabel.font = [UIFont systemFontOfSize:12];
        [self addSubview:self.totalTimeLabel];
        
        self.progressSlider = [[UISlider alloc] init];
        self.progressSlider.minimumTrackTintColor = [UIColor colorWithRed:1 green:200/255.0 blue:21/255.0 alpha:1];
        self.progressSlider.maximumTrackTintColor = [UIColor colorWithWhite:1 alpha:0.4];
        [self.progressSlider setThumbImage:[PLVECUtils imageForWatchResource:@"plv_player_slider_img"] forState:UIControlStateNormal];
        [self.progressSlider addTarget:self action:@selector(sliderTouchDownAction:) forControlEvents:UIControlEventTouchDown | UIControlEventTouchDownRepeat | UIControlEventTouchDragInside | UIControlEventTouchDragOutside | UIControlEventTouchDragEnter | UIControlEventTouchDragExit];
        [self.progressSlider addTarget:self action:@selector(sliderTouchEndAction:) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside | UIControlEventTouchCancel];
        [self.progressSlider addTarget:self action:@selector(sliderValueChangedAction:) forControlEvents:UIControlEventValueChanged];
        [self addSubview:self.progressSlider];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat originY = 0;
    self.playButton.frame = CGRectMake(15, originY, 20, 20);
    
    CGFloat currentTimeWidth = [self getLabelTextWidth:self.currentTimeLabel];
    self.currentTimeLabel.frame = CGRectMake(CGRectGetMaxX(self.playButton.frame)+10, originY+4, currentTimeWidth, 12);
    
    CGFloat totalTimeWidth = [self getLabelTextWidth:self.totalTimeLabel];
    self.totalTimeLabel.frame = CGRectMake(CGRectGetWidth(self.bounds)-41, originY+4, totalTimeWidth, 12);
    
    self.progressSlider.frame = CGRectMake(CGRectGetMaxX(self.currentTimeLabel.frame)+4, originY+4, CGRectGetMinX(self.totalTimeLabel.frame)-CGRectGetMaxX(self.currentTimeLabel.frame)-8, 12);
}

- (CGFloat)getLabelTextWidth:(UILabel *)label {
    CGFloat minWidth = 41;
    CGFloat resultWidth = minWidth;
    if (label) {
        resultWidth = [label.text boundingRectWithSize:CGSizeMake(MAXFLOAT, 1)
                                               options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                            attributes:@{NSFontAttributeName:label.font}
                                               context:nil].size.width + 3;
        if (resultWidth < minWidth) {
            resultWidth = minWidth;
        }
    }
    
    return resultWidth;
}

#pragma mark - Actions

- (void)playButtonAction:(UIButton *)sender {
    sender.selected = !sender.isSelected;
    if ([self.delegate respondsToSelector:@selector(playerContolView:switchPause:)]) {
        [self.delegate playerContolView:self switchPause:!sender.isSelected];
    }
}

- (void)sliderTouchDownAction:(UISlider *)sender {
    self.sliderDragging = YES;
}

- (void)sliderTouchEndAction:(UISlider *)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(playerContolViewSeeking:)]) {
        [self.delegate playerContolViewSeeking:self];
    }
    self.sliderDragging = NO;
}

- (void)sliderValueChangedAction:(UISlider *)sender {
    if (self.duration == 0.0) {
        sender.value = 0.0;
    }
}

@end
