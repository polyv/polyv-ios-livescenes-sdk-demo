//
//  PLVLSChannelInfoTopView.m
//  PLVLiveStreamerDemo
//
//  Created by MissYasiky on 2021/3/4.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVLSChannelInfoTopView.h"
#import "PLVLSUtils.h"

@interface PLVLSChannelInfoTopView ()

@property (nonatomic, strong) UIImageView *titleIcon;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIImageView *dateIcon;
@property (nonatomic, strong) UILabel *dateLabel;
@property (nonatomic, strong) UIImageView *channelIdIcon;
@property (nonatomic, strong) UILabel *channelIdLabel;
@property (nonatomic, strong) UIImageView *detailIcon;
@property (nonatomic, strong) UILabel *detailLabel;

@end

@implementation PLVLSChannelInfoTopView

#pragma mark - Life Cycle

- (instancetype)init {
    self = [super init];
    if (self) {
        [self addSubview:self.titleIcon];
        [self addSubview:self.titleLabel];
        [self addSubview:self.dateIcon];
        [self addSubview:self.dateLabel];
        [self addSubview:self.channelIdIcon];
        [self addSubview:self.channelIdLabel];
        [self addSubview:self.detailIcon];
        [self addSubview:self.detailLabel];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat originX = 0.0;
    self.titleIcon.frame = CGRectMake(originX, 16 + 2, 16, 16);
    self.dateIcon.frame = CGRectMake(originX, CGRectGetMaxY(self.titleIcon.frame) + 16, 16, 16);
    self.detailIcon.frame = CGRectMake(originX, CGRectGetMaxY(self.dateIcon.frame) + 16, 16, 16);
    
    originX += 24.0;
    self.titleLabel.frame = CGRectMake(originX, 16, self.bounds.size.width - originX - 8, 20);
    self.dateLabel.frame = CGRectMake(originX, CGRectGetMaxY(self.titleLabel.frame) + 12, 150, 20);
    self.detailLabel.frame = CGRectMake(originX, CGRectGetMaxY(self.dateLabel.frame) + 12, 150, 20);
    
    self.channelIdLabel.frame = CGRectMake(CGRectGetMaxX(self.dateLabel.frame) + 24, self.dateLabel.frame.origin.y, 100, 20);
    self.channelIdIcon.frame = CGRectMake(CGRectGetMinX(self.channelIdLabel.frame) - 16 - 8, self.dateIcon.frame.origin.y, 16, 16);
}

#pragma mark - Getter

- (UIImageView *)titleIcon {
    if (!_titleIcon) {
        _titleIcon = [[UIImageView alloc] init];
        _titleIcon.image = [PLVLSUtils imageForStatusResource:@"plvls_status_channelInfo_title_icon"];
    }
    return _titleIcon;
}

- (UIImageView *)dateIcon {
    if (!_dateIcon) {
        _dateIcon = [[UIImageView alloc] init];
        _dateIcon.image = [PLVLSUtils imageForStatusResource:@"plvls_status_channelInfo_date_icon"];
    }
    return _dateIcon;
}

- (UIImageView *)channelIdIcon {
    if (!_channelIdIcon) {
        _channelIdIcon = [[UIImageView alloc] init];
        _channelIdIcon.image = [PLVLSUtils imageForStatusResource:@"plvls_status_channelInfo_ID_icon"];
    }
    return _channelIdIcon;
}

- (UIImageView *)detailIcon {
    if (!_detailIcon) {
        _detailIcon = [[UIImageView alloc] init];
        _detailIcon.image = [PLVLSUtils imageForStatusResource:@"plvls_status_channelInfo_detail_icon"];
    }
    return _detailIcon;
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.textColor = [UIColor colorWithRed:0xf0/255.0 green:0xf1/255.0 blue:0xf5/255.0 alpha:1];
        _titleLabel.font = [UIFont systemFontOfSize:14];
    }
    return _titleLabel;
}

- (UILabel *)dateLabel {
    if (!_dateLabel) {
        _dateLabel = [[UILabel alloc] init];
        _dateLabel.textColor = [UIColor colorWithRed:0xf0/255.0 green:0xf1/255.0 blue:0xf5/255.0 alpha:1];
        _dateLabel.font = [UIFont systemFontOfSize:14];
    }
    return _dateLabel;
}

- (UILabel *)channelIdLabel {
    if (!_channelIdLabel) {
        _channelIdLabel = [[UILabel alloc] init];
        _channelIdLabel.textColor = [UIColor colorWithRed:0xf0/255.0 green:0xf1/255.0 blue:0xf5/255.0 alpha:1];
        _channelIdLabel.font = [UIFont systemFontOfSize:14];
    }
    return _channelIdLabel;
}

- (UILabel *)detailLabel {
    if (!_detailLabel) {
        _detailLabel = [[UILabel alloc] init];
        _detailLabel.textColor = [UIColor colorWithRed:0xf0/255.0 green:0xf1/255.0 blue:0xf5/255.0 alpha:1];
        _detailLabel.font = [UIFont systemFontOfSize:14];
        _detailLabel.text = @"直播介绍";
    }
    return _detailLabel;
}

#pragma mark - Public Method

- (void)setTitle:(NSString *)titleString date:(NSString *)dateString channelId:(NSString *)channelIdString {
    if (!titleString || ![titleString isKindOfClass:[NSString class]]) {
        titleString = @"";
    }
    if (!dateString || ![dateString isKindOfClass:[NSString class]]) {
        dateString = @"";
    }
    if (!channelIdString || ![channelIdString isKindOfClass:[NSString class]]) {
        channelIdString = @"";
    }
    self.titleLabel.text = titleString;
    self.dateLabel.text = dateString;
    self.channelIdLabel.text = channelIdString;
}

@end
