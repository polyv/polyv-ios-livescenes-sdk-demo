//
//  PLVLCPlaybackListViewCell.m
//  PLVLiveScenesDemo
//
//  Created by Dhan on 2021/11/30.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVLCPlaybackListViewCell.h"
#import "PLVRoomDataManager.h"
#import <PLVFoundationSDK/PLVFoundationSDK.h>
#import "PLVLCUtils.h"

@interface PLVLCPlaybackListViewCell ()

@property (nonatomic ,strong) UIImageView *coverImageView;
@property (nonatomic ,strong) UILabel *titleLabel;
@property (nonatomic ,strong) UILabel *durationLabel;
@property (nonatomic ,strong) UIButton *playButton;
@property (nonatomic ,strong) UILabel *startTimeLabel;

@end

@implementation PLVLCPlaybackListViewCell

#pragma mark - Life Cycle

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)layoutSubviews{
    [super layoutSubviews];
    CGFloat cellWidth = CGRectGetWidth(self.bounds);
    CGFloat cellHeight = CGRectGetHeight(self.bounds);
    CGFloat marginWidth = 16;
    CGFloat marginHeight = 20;
    CGFloat padding = 12;
    CGFloat titleLabelHeight = 17;
    CGFloat coverImageViewWidth =  127;
    
    self.coverImageView.frame = CGRectMake(marginWidth, marginHeight, coverImageViewWidth, cellHeight - marginHeight);
    self.titleLabel.frame = CGRectMake(marginWidth + coverImageViewWidth + padding, marginHeight, cellWidth - marginWidth * 2 - padding - coverImageViewWidth, 40);
    self.durationLabel.frame = CGRectMake(marginWidth + 8, cellHeight - titleLabelHeight, coverImageViewWidth - 8, titleLabelHeight);
    self.startTimeLabel.frame = CGRectMake(CGRectGetMinX(self.titleLabel.frame), CGRectGetMaxY(self.titleLabel.frame) + 4, CGRectGetWidth(self.titleLabel.frame), titleLabelHeight);
    
    CGFloat playButtonWidth = 82;
    CGFloat playButtonHeight = 32;
    self.playButton.frame = CGRectMake(CGRectGetMidX(self.coverImageView.frame) - playButtonWidth * 0.5, CGRectGetMidY(self.coverImageView.frame) - playButtonHeight * 0.5, playButtonWidth, playButtonHeight);
    UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:self.playButton.bounds byRoundingCorners:UIRectCornerAllCorners cornerRadii:CGSizeMake(28,28)];
    CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
    maskLayer.frame = self.contentView.bounds;
    maskLayer.path = maskPath.CGPath;
    maskLayer.borderColor = PLV_UIColorFromRGBA(@"#000000", 0.3f).CGColor;
    self.playButton.layer.mask = maskLayer;
}


- (void)awakeFromNib {
    [super awakeFromNib];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    self.playButton.alpha = selected ? 0.9 : 0;
}

#pragma mark - Getter && Setter

- (UIImageView *)coverImageView {
    if (!_coverImageView) {
        _coverImageView = [[UIImageView alloc] initWithImage:[PLVLCUtils imageForMediaResource:@"plvlc_media_video_placeholder"]];
        _coverImageView.backgroundColor = [UIColor clearColor];
    }
    return _coverImageView;
}

- (UILabel *)durationLabel{
    if (!_durationLabel) {
        _durationLabel = [[UILabel alloc]init];
        _durationLabel.text = @"00:00:00";
        _durationLabel.textColor = PLV_UIColorFromRGB(@"#FFFFFF");
        _durationLabel.font = [UIFont fontWithName:@"PingFang SC" size:12];
    }
    return _durationLabel;
}

- (UILabel *)titleLabel{
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc]init];
        _titleLabel.text = @"标题";
        _titleLabel.numberOfLines = 2;
        _titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        _titleLabel.highlightedTextColor = PLV_UIColorFromRGB(@"#78A7ED");
        _titleLabel.textColor = PLV_UIColorFromRGB(@"#ADADC0");
        _titleLabel.font = [UIFont fontWithName:@"PingFang SC" size:14];
    }
    return _titleLabel;
}

- (UIButton *)playButton{
    if (!_playButton) {
        _playButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_playButton setContentVerticalAlignment:UIControlContentVerticalAlignmentCenter];
        [_playButton setImage:[PLVLCUtils imageForMenuResource:@"plvlc_menu_playback_playing"]
                     forState:UIControlStateNormal];
        _playButton.imageView.frame = CGRectMake(10, 8, 16, 16);
        [_playButton setTitle:@"播放中" forState:UIControlStateNormal];
        
        _playButton.titleLabel.font = [UIFont fontWithName:@"PingFang SC" size:16];;
        [_playButton setBackgroundColor:PLV_UIColorFromRGB(@"#3082FE")];
        _playButton.titleLabel.frame = CGRectMake(30, 8, 37, 16);
        _playButton.userInteractionEnabled = NO;

    }
    return _playButton;
}

- (UILabel *)startTimeLabel{
    if (!_startTimeLabel) {
        _startTimeLabel = [[UILabel alloc]init];
        _startTimeLabel.text = @"开始时间：";
        _startTimeLabel.numberOfLines = 1;
        _startTimeLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        _startTimeLabel.highlightedTextColor = PLV_UIColorFromRGB(@"#78A7ED");
        _startTimeLabel.textColor = PLV_UIColorFromRGB(@"#ADADC0");
        _startTimeLabel.font = [UIFont fontWithName:@"PingFang SC" size:12];
    }
    return _startTimeLabel;
}

- (NSString *)startTimeExchangeWithString:(NSString *)string {
    NSString *startTimeText = @"开始时间：";
    if ([PLVFdUtil checkStringUseable:string] && string.length >= 12) {
        NSString *year = [string substringWithRange:NSMakeRange(0, 4)];
        NSString *month = [string substringWithRange:NSMakeRange(4, 2)];
        NSString *day = [string substringWithRange:NSMakeRange(6, 2)];
        NSString *hour = [string substringWithRange:NSMakeRange(8, 2)];
        NSString *min = [string substringWithRange:NSMakeRange(10, 2)];
        startTimeText = [NSString stringWithFormat:@"%@%@-%@-%@ %@:%@", startTimeText, year,month,day,hour,min];
    }
    return startTimeText;
}

- (void)setPlaybackVideo:(PLVPlaybackVideoModel *)playbackVideo {
    _playbackVideo = playbackVideo;
    self.titleLabel.text = playbackVideo.title;
    self.durationLabel.text = playbackVideo.duration;
    self.startTimeLabel.text = [self startTimeExchangeWithString:playbackVideo.startTime];
    if ([PLVFdUtil checkStringUseable:playbackVideo.firstImage]) {
        NSString *url = [PLVFdUtil packageURLStringWithHTTPS:playbackVideo.firstImage];
        [PLVLCUtils setImageView:self.coverImageView url:[NSURL URLWithString:url]];
    }
    
}

#pragma mark UI

- (void)setupUI{
    // 添加 视图
    self.selectedBackgroundView = [[UIView alloc] initWithFrame:self.frame];
    self.selectedBackgroundView.backgroundColor = PLV_UIColorFromRGB(@"#202127");
    [self.contentView addSubview:self.coverImageView];
    [self.contentView addSubview:self.durationLabel];
    [self.contentView addSubview:self.titleLabel];
    [self.contentView addSubview:self.startTimeLabel];
    [self.contentView addSubview:self.playButton];
}

@end
