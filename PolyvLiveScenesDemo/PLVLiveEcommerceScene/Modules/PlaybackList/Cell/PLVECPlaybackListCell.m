//
//  PLVECPlaybackListCell.m
//  PLVLiveScenesDemo
//
//  Created by Dhan on 2021/12/9.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVECPlaybackListCell.h"
#import <PLVFoundationSDK/PLVFoundationSDK.h>
#import "PLVECUtils.h"

@interface PLVECPlaybackListCell ()

#pragma mark 数据
@property (nonatomic, weak) PLVPlaybackVideoModel * videoModel;

#pragma mark UI
@property (nonatomic, strong) UIView * contentBackgroudView;
@property (nonatomic, strong) UIImageView * firstImageView;
@property (nonatomic, strong) UILabel * timeLabel;
@property (nonatomic, strong) UILabel * titleLabel;
@property (nonatomic, strong) UIButton * playButton;


@end

@implementation PLVECPlaybackListCell

- (instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        [self setupUI];
    }
    return self;
}

- (void)layoutSubviews{
    [super layoutSubviews];
    CGFloat cellWidth = CGRectGetWidth(self.bounds);
    CGFloat cellHeight = CGRectGetHeight(self.bounds);
    
    self.contentBackgroudView.frame = self.contentView.bounds;
    self.contentBackgroudView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    CGFloat titleLabelHeight = 17.0;
    self.titleLabel.frame = CGRectMake(0, cellHeight - titleLabelHeight, cellWidth, titleLabelHeight);
    self.firstImageView.frame = CGRectMake(0, 0, cellWidth, cellWidth * 0.56);
    UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:self.firstImageView.bounds byRoundingCorners:UIRectCornerAllCorners cornerRadii:CGSizeMake(10,10)];
    CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
    maskLayer.frame = self.contentView.bounds;
    maskLayer.path = maskPath.CGPath;
    self.firstImageView.layer.mask = maskLayer;
    self.timeLabel.frame = CGRectMake(8, CGRectGetMaxY(self.firstImageView.frame)-20, 64, 12);
    
    CGFloat playButtonWidth = 82;
    CGFloat playButtonHeight = 32;
    self.playButton.frame = CGRectMake(CGRectGetMidX(self.firstImageView.frame) - playButtonWidth * 0.5, CGRectGetMidY(self.firstImageView.frame) - playButtonHeight * 0.5, playButtonWidth, playButtonHeight);
    UIBezierPath *playButtonMaskPath = [UIBezierPath bezierPathWithRoundedRect:self.playButton.bounds byRoundingCorners:UIRectCornerAllCorners cornerRadii:CGSizeMake(28,28)];
    CAShapeLayer *playButtonMaskLayer = [[CAShapeLayer alloc] init];
    playButtonMaskLayer.frame = self.contentView.bounds;
    playButtonMaskLayer.path = playButtonMaskPath.CGPath;
    playButtonMaskLayer.borderColor = PLV_UIColorFromRGBA(@"#000000", 0.3f).CGColor;
    self.playButton.layer.mask = playButtonMaskLayer;
    
    self.titleLabel.frame = CGRectMake(0, CGRectGetMaxY(self.firstImageView.frame) + 8, cellWidth, cellHeight -  CGRectGetMaxY(self.firstImageView.frame) - 8);
    [self.titleLabel sizeToFit];
}

#pragma mark - [ Public Methods ]
- (void)setModel:(PLVPlaybackVideoModel *)videoModel {
    self.videoModel = videoModel;
    self.timeLabel.text = videoModel.duration;
    self.titleLabel.text = videoModel.title;
    if ([PLVFdUtil checkStringUseable:videoModel.firstImage]) {
        [PLVECUtils setImageView:self.firstImageView url:[NSURL URLWithString:videoModel.firstImage]];
    }

}

- (void)setSelected:(BOOL)selected{
    [super setSelected:selected];
    self.playButton.alpha = selected ? 0.9 : 0;
}

#pragma mark UI

- (void)setupUI{
    // 添加 视图
    [self.contentView addSubview:self.contentBackgroudView];
    [self.contentView addSubview:self.firstImageView];
    [self.contentView addSubview:self.timeLabel];
    [self.contentView addSubview:self.titleLabel];
    [self.contentView addSubview:self.playButton];
}

#pragma mark Getter

- (UIView *)contentBackgroudView{
    if (!_contentBackgroudView) {
        _contentBackgroudView = [[UIView alloc]init];
        _contentBackgroudView.clipsToBounds = YES;
    }
    return _contentBackgroudView;
}

- (UIImageView *)firstImageView {
    if (!_firstImageView) {
        _firstImageView = [[UIImageView alloc] initWithImage:[PLVECUtils imageForWatchResource:@"plv_chatroom_thumbnail_imag"]];
        _firstImageView.backgroundColor = [UIColor clearColor];
    }
    return _firstImageView;
}

- (UILabel *)timeLabel{
    if (!_timeLabel) {
        _timeLabel = [[UILabel alloc]init];
        _timeLabel.text = @"00:00:00";
        _timeLabel.textColor = PLV_UIColorFromRGB(@"#FFFFFF");
        _timeLabel.font = [UIFont fontWithName:@"PingFang SC" size:12];
    }
    return _timeLabel;
}

- (UILabel *)titleLabel{
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc]init];
        _titleLabel.text = @"标题";
        _titleLabel.numberOfLines = 2;
        _titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        _titleLabel.highlightedTextColor = PLV_UIColorFromRGB(@"#FFD16B");
        _titleLabel.textColor = PLV_UIColorFromRGBA(@"#FFFFFF",0.8f);
        _titleLabel.font = [UIFont fontWithName:@"PingFang SC" size:14];
    }
    return _titleLabel;
}

- (UIButton *)playButton{
    if (!_playButton) {
        _playButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_playButton setContentVerticalAlignment:UIControlContentVerticalAlignmentCenter];
        [_playButton setImage:[PLVECUtils imageForWatchResource:@"plv_playback_playing"]
                     forState:UIControlStateNormal];
        _playButton.imageView.frame = CGRectMake(12, 8, 16, 16);
        _playButton.imageView.contentMode = UIViewContentModeScaleAspectFill;
        [_playButton setTitle:@"播放中" forState:UIControlStateNormal];
        
        _playButton.titleLabel.font = [UIFont fontWithName:@"PingFang SC" size:16];;
        [_playButton setBackgroundColor:PLV_UIColorFromRGB(@"#FFA611")];
        _playButton.titleLabel.frame = CGRectMake(32, 8, 43, 16);
        _playButton.userInteractionEnabled = NO;
        _playButton.alpha = 0;
    }
    return _playButton;
}


@end
