//
//  PLVLCMultiMeetingViewCell.m
//  PolyvLiveScenesDemo
//
//  Created by Dhan on 2024/9/25.
//  Copyright © 2024 PLV. All rights reserved.
//

#import "PLVLCMultiMeetingViewCell.h"
#import <PLVFoundationSDK/PLVFoundationSDK.h>
#import "PLVLCUtils.h"
#import "PLVMultiLanguageManager.h"

@interface PLVLCMultiMeetingViewCell ()

@property (nonatomic, strong) UIImageView *splashImageView;
@property (nonatomic, strong) UIButton *liveStatusButton;
@property (nonatomic, strong) CAGradientLayer *gradientLayer;
@property (nonatomic, strong) UILabel *multiMeetingNameLabel;
@property (nonatomic, strong) UILabel *startTimeLabel;
@property (nonatomic, strong) UIImageView *playtimeImageView;
@property (nonatomic, strong) UILabel *playtimesLabel;
@property (nonatomic, strong) UIView *liveStatusView;
@property (nonatomic, strong) UIButton *selectedButton;

@end

@implementation PLVLCMultiMeetingViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.contentView.backgroundColor = [UIColor clearColor];
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        [self.contentView addSubview:self.splashImageView];
        [self.splashImageView addSubview:self.liveStatusButton];
        [self.contentView addSubview:self.multiMeetingNameLabel];
        [self.contentView addSubview:self.startTimeLabel];
        [self.contentView addSubview:self.playtimeImageView];
        [self.contentView addSubview:self.playtimesLabel];
        [self.contentView addSubview:self.selectedButton];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat cellWidth = CGRectGetWidth(self.bounds);
    CGFloat cellHeight = CGRectGetHeight(self.bounds);
    CGFloat marginWidth = 16;
    CGFloat marginHeight = 20;
    CGFloat padding = 12;
    CGFloat titleLabelHeight = 17;
    CGFloat splashImageViewWidth = 144;
    
    self.splashImageView.frame = CGRectMake(marginWidth, 0, splashImageViewWidth, cellHeight - marginHeight);
    CGSize liveStatusButtonSize = [self.liveStatusButton.titleLabel sizeThatFits:CGSizeMake(CGFLOAT_MAX, titleLabelHeight)];
    self.liveStatusButton.frame = CGRectMake(0, 0, liveStatusButtonSize.width + 8, titleLabelHeight);
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:self.liveStatusButton.bounds
                                               byRoundingCorners:UIRectCornerBottomRight
                                                     cornerRadii:CGSizeMake(8, 8)];
    CAShapeLayer *maskLayer = [CAShapeLayer layer];
    maskLayer.path = path.CGPath;
    self.liveStatusButton.layer.mask = maskLayer;
    self.gradientLayer.frame = self.liveStatusButton.bounds;
    
    self.multiMeetingNameLabel.frame = CGRectMake(marginWidth + splashImageViewWidth + padding, 0, cellWidth - marginWidth * 2 - padding - splashImageViewWidth, titleLabelHeight);
    self.startTimeLabel.frame = CGRectMake(CGRectGetMinX(self.multiMeetingNameLabel.frame), CGRectGetMaxY(self.multiMeetingNameLabel.frame), CGRectGetWidth(self.multiMeetingNameLabel.frame), titleLabelHeight);
    self.playtimeImageView.frame = CGRectMake(CGRectGetMinX(self.multiMeetingNameLabel.frame), CGRectGetMaxY(self.splashImageView.frame) - titleLabelHeight, titleLabelHeight, titleLabelHeight);
    self.playtimesLabel.frame = CGRectMake(CGRectGetMaxX(self.playtimeImageView.frame) + 4, CGRectGetMinY(self.playtimeImageView.frame), splashImageViewWidth, titleLabelHeight);
    CGPoint splashCenter = CGPointMake(CGRectGetMidX(self.splashImageView.frame), CGRectGetMidY(self.splashImageView.frame));

    self.selectedButton.frame = CGRectMake(
        splashCenter.x - 50, splashCenter.y - 18, 100, 36);
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    self.selectedButton.alpha = selected ? 0.9 : 0.0;
    self.splashImageView.layer.borderColor = selected ? PLV_UIColorFromRGB(@"#1e80ff").CGColor : [UIColor clearColor].CGColor;
    self.splashImageView.layer.borderWidth = selected ? 1.0 : 0.0;
}

#pragma mark public Method

- (void)setModel:(PLVMultiMeetingModel *)model {
    _model = model;
    [self.liveStatusButton setTitle:PLVLocalizedString(model.liveStatusDesc) forState:UIControlStateNormal];
    self.multiMeetingNameLabel.text = model.multiMeetingName;
    
    [PLVLCUtils setImageView:self.splashImageView url:[NSURL URLWithString:model.splashImgUrl]];
    
    NSInteger pv = [model.pv integerValue];
    NSString *pvString = [NSString stringWithFormat:@"%ld",pv];
    if ([PLVMultiLanguageManager sharedManager].currentLanguage == PLVMultiLanguageModeZH && pv > 10000) {
        pvString = [NSString stringWithFormat:@"%0.1fw", pv / 10000.0];
    } else if ([PLVMultiLanguageManager sharedManager].currentLanguage == PLVMultiLanguageModeEN && pv > 1000) {
        pvString = [NSString stringWithFormat:@"%0.1fk", pv / 1000.0];
    }
    self.playtimesLabel.text = pvString;
    
    if (model.liveStatusType == PLVMultiMeetingLiveStatus_End || model.liveStatusType == PLVMultiMeetingLiveStatus_UnStart) {
        self.gradientLayer.colors = @[(__bridge id)PLV_UIColorFromRGB(@"#ABAFBC").CGColor, (__bridge id)PLV_UIColorFromRGB(@"#737784").CGColor];
    } else if (model.liveStatusType == PLVMultiMeetingLiveStatus_Live) {
        self.gradientLayer.colors = @[(__bridge id)PLV_UIColorFromRGB(@"#F06E6E").CGColor, (__bridge id)PLV_UIColorFromRGB(@"#E63A3A").CGColor];
    } else {
        self.gradientLayer.colors = @[(__bridge id)PLV_UIColorFromRGB(@"#5BA3FF").CGColor, (__bridge id)PLV_UIColorFromRGB(@"#3082FE").CGColor];
    }
    
    self.startTimeLabel.text = [self timeStringWithTimeInterval:model.startTime];
    
    if (model.liveStatusType == PLVMultiMeetingLiveStatus_Live || model.liveStatusType == PLVMultiMeetingLiveStatus_Playback) {
        [self.selectedButton setTitle:PLVLocalizedString(@"播放中") forState:UIControlStateNormal];
        [self.selectedButton setImage:[PLVLCUtils imageForMenuResource:@"plvlc_menu_playback_playing"]
                     forState:UIControlStateNormal];
    } else {
        [self.selectedButton setTitle:PLVLocalizedString(@"直播未开始") forState:UIControlStateNormal];
        [self.selectedButton setImage:nil forState:UIControlStateNormal];
    }
}

#pragma mark Private Method

- (NSString *)timeStringWithTimeInterval:(NSTimeInterval)timeInterval {
    if (timeInterval <= 0) {
        return @"- -";
    }
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy/MM/dd HH:mm"];
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:timeInterval / 1000];
    return [dateFormatter stringFromDate:date];
}

#pragma mark Getter && Setter

- (UIImageView *)splashImageView {
    if (!_splashImageView) {
        _splashImageView = [[UIImageView alloc] initWithImage:[PLVLCUtils imageForMediaResource:@"plvlc_media_video_placeholder"]];
        [PLVLCUtils setImageView:_splashImageView url:[NSURL URLWithString:kPLVMultiMeetingSplashImgURLString]];
        _splashImageView.backgroundColor = [UIColor clearColor];
        _splashImageView.clipsToBounds = YES;
        _splashImageView.layer.cornerRadius = 8;
    }
    return _splashImageView;
}

- (UIButton *)liveStatusButton {
    if (!_liveStatusButton) {
        _liveStatusButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _liveStatusButton.layer.masksToBounds = YES;
        [_liveStatusButton setTitle:PLVLocalizedString(@"未开始") forState:UIControlStateNormal];
        _liveStatusButton.enabled = NO;
        _liveStatusButton.titleLabel.textColor = PLV_UIColorFromRGB(@"#FFFFFF");
        _liveStatusButton.titleLabel.font = [UIFont fontWithName:@"PingFang SC" size:12];
        [_liveStatusButton.layer insertSublayer:self.gradientLayer atIndex:0];
    }
    return _liveStatusButton;
}

- (CAGradientLayer *)gradientLayer {
    if (!_gradientLayer) {
        _gradientLayer = [CAGradientLayer layer];
        _gradientLayer.colors = @[(__bridge id)PLV_UIColorFromRGB(@"#ABAFBC").CGColor, (__bridge id)PLV_UIColorFromRGB(@"#737784").CGColor];
        _gradientLayer.locations = @[@0.5, @1.0];
        _gradientLayer.startPoint = CGPointMake(0, 0);
        _gradientLayer.endPoint = CGPointMake(1.0, 0);
    }
    return _gradientLayer;
}

- (UILabel *)multiMeetingNameLabel{
    if (!_multiMeetingNameLabel) {
        _multiMeetingNameLabel = [[UILabel alloc] init];
        _multiMeetingNameLabel.text = PLVLocalizedString(@"主会场");
        _multiMeetingNameLabel.textAlignment = NSTextAlignmentLeft;
        _multiMeetingNameLabel.textColor = [UIColor whiteColor];
        _multiMeetingNameLabel.font = [UIFont fontWithName:@"PingFang SC" size:14];
    }
    return _multiMeetingNameLabel;
}


- (UILabel *)startTimeLabel{
    if (!_startTimeLabel) {
        _startTimeLabel = [[UILabel alloc] init];
        _startTimeLabel.text = @"- -";
        _startTimeLabel.textColor = PLV_UIColorFromRGB(@"#FFFFFF");
        _startTimeLabel.font = [UIFont fontWithName:@"PingFang SC" size:12];
    }
    return _startTimeLabel;
}

- (UIImageView *)playtimeImageView {
    if (!_playtimeImageView) {
        _playtimeImageView = [[UIImageView alloc] initWithImage:[PLVLCUtils imageForLiveRoomResource:@"plv_watch_img"]];
        _playtimeImageView.backgroundColor = [UIColor clearColor];
    }
    return _playtimeImageView;
}

- (UILabel *)playtimesLabel{
    if (!_playtimesLabel) {
        _playtimesLabel = [[UILabel alloc] init];
        _playtimesLabel.text = (@"0");
        _playtimesLabel.textColor = PLV_UIColorFromRGB(@"#FFFFFF");
        _playtimesLabel.font = [UIFont fontWithName:@"PingFang SC" size:12];
    }
    return _playtimesLabel;
}

- (UIButton *)selectedButton {
    if (!_selectedButton) {
        _selectedButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_selectedButton setContentVerticalAlignment:UIControlContentVerticalAlignmentCenter];
        _selectedButton.layer.masksToBounds = YES;
        _selectedButton.layer.cornerRadius = 18;
        [_selectedButton setTitle:PLVLocalizedString(@"直播未开始") forState:UIControlStateNormal];
        _selectedButton.enabled = NO;
        _selectedButton.titleLabel.textColor = PLV_UIColorFromRGB(@"#FFFFFF");
        _selectedButton.titleLabel.font = [UIFont fontWithName:@"PingFang SC" size:12];
        _selectedButton.backgroundColor = PLV_UIColorFromRGBA(@"#000000", 0.6);
    }
    return _selectedButton;
}


@end
