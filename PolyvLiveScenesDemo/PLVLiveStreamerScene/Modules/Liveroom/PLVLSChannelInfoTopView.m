//
//  PLVLSChannelInfoTopView.m
//  PLVLiveStreamerDemo
//
//  Created by MissYasiky on 2021/3/4.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVLSChannelInfoTopView.h"
#import "PLVLSUtils.h"
#import "PLVMultiLanguageManager.h"

@interface PLVLSChannelInfoTopView ()

@property (nonatomic, strong) UIImageView *titleIcon;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIImageView *dateIcon;
@property (nonatomic, strong) UILabel *dateLabel;
@property (nonatomic, strong) UIImageView *channelIdIcon;
@property (nonatomic, strong) UILabel *channelIdLabel;
@property (nonatomic, strong) UIImageView *sipIcon;
@property (nonatomic, strong) UILabel *sipLabel;
@property (nonatomic, strong) UIImageView *detailIcon;
@property (nonatomic, strong) UILabel *detailLabel;
@property (nonatomic, strong) UIButton *sipCopyButton;
@property (nonatomic, copy) NSString *sipPasswordString;


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
        [self addSubview:self.sipIcon];
        [self addSubview:self.sipLabel];
        [self addSubview:self.detailIcon];
        [self addSubview:self.detailLabel];
        [self addSubview:self.sipCopyButton];
        self.sipPasswordString = @"";
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self updateUI];
}

#pragma mark - Private Method

- (void)updateUI {
    CGFloat originX = 0.0;
    self.titleIcon.frame = CGRectMake(originX, 16 + 2, 16, 16);
    self.dateIcon.frame = CGRectMake(originX, CGRectGetMaxY(self.titleIcon.frame) + 16, 16, 16);
    self.sipIcon.frame = CGRectMake(originX, CGRectGetMaxY(self.dateIcon.frame) + 16, 16, 16);
    self.detailIcon.frame = CGRectMake(originX, CGRectGetMaxY(self.sipIcon.frame) + 16, 16, 16);
    
    originX += 24.0;
    self.titleLabel.frame = CGRectMake(originX, 16, self.bounds.size.width - originX - 8, 20);
    self.dateLabel.frame = CGRectMake(originX, CGRectGetMaxY(self.titleLabel.frame) + 12, 230, 20);
    
    CGFloat sipLabelWidth = [self.sipLabel sizeThatFits:CGSizeMake(20, MAXFLOAT)].width + 5;
    self.sipLabel.frame = CGRectMake(originX, CGRectGetMaxY(self.dateLabel.frame) + 12, sipLabelWidth, 20);
    self.detailLabel.frame = self.sipLabel.hidden ? CGRectMake(originX, CGRectGetMaxY(self.dateLabel.frame) + 12, 150, 20) : CGRectMake(originX, CGRectGetMaxY(self.sipLabel.frame) + 12, 150, 20);
    
    self.channelIdLabel.frame = CGRectMake(CGRectGetMaxX(self.dateLabel.frame) + 24, self.dateLabel.frame.origin.y, 150, 20);
    self.channelIdIcon.frame = CGRectMake(CGRectGetMinX(self.channelIdLabel.frame) - 16 - 8, self.dateIcon.frame.origin.y, 16, 16);
    self.sipCopyButton.frame = CGRectMake(CGRectGetMaxX(self.sipLabel.frame) + 8, CGRectGetMinY(self.sipIcon.frame), 28, 17);
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

- (UIImageView *)sipIcon {
    if (!_sipIcon) {
        _sipIcon = [[UIImageView alloc] init];
        _sipIcon.image = [PLVLSUtils imageForStatusResource:@"plvls_status_sip_icon"];
    }
    return _sipIcon;
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

- (UILabel *)sipLabel {
    if (!_sipLabel) {
        _sipLabel = [[UILabel alloc] init];
        _sipLabel.textColor = [UIColor colorWithRed:0xf0/255.0 green:0xf1/255.0 blue:0xf5/255.0 alpha:1];
        _sipLabel.font = [UIFont systemFontOfSize:14];
        _sipLabel.text = PLVLocalizedString(@"入会号码");
    }
    return _sipLabel;
}

- (UILabel *)detailLabel {
    if (!_detailLabel) {
        _detailLabel = [[UILabel alloc] init];
        _detailLabel.textColor = [UIColor colorWithRed:0xf0/255.0 green:0xf1/255.0 blue:0xf5/255.0 alpha:1];
        _detailLabel.font = [UIFont systemFontOfSize:14];
        _detailLabel.text = PLVLocalizedString(@"直播介绍");
    }
    return _detailLabel;
}

- (UIButton *)sipCopyButton {
    if (!_sipCopyButton) {
        _sipCopyButton = [[UIButton alloc] init];
        [_sipCopyButton setTitle:PLVLocalizedString(@"复制") forState:UIControlStateNormal];
        [_sipCopyButton setTitleColor:[UIColor colorWithRed:44/255.0 green:150/255.0 blue:255/255.0 alpha:1] forState:UIControlStateNormal];
        _sipCopyButton.titleLabel.font = [UIFont systemFontOfSize:12];
        [_sipCopyButton addTarget:self action:@selector(sipCopyButtonClickAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _sipCopyButton;
}

#pragma mark - Public Method

- (void)setTitle:(NSString *)titleString date:(NSString *)dateString channelId:(NSString *)channelIdString sipNumber:(NSString *)sipNumberString sipPassword:(NSString *)sipPasswordString {
    if (!titleString || ![titleString isKindOfClass:[NSString class]]) {
        titleString = @"";
    }
    if (!dateString || ![dateString isKindOfClass:[NSString class]]) {
        dateString = @"";
    }
    if (!channelIdString || ![channelIdString isKindOfClass:[NSString class]]) {
        channelIdString = @"";
    }
    if (!sipNumberString || ![sipNumberString isKindOfClass:[NSString class]]) {
        sipNumberString = @"";
    }
    if (!sipPasswordString || ![sipPasswordString isKindOfClass:[NSString class]]) {
        sipPasswordString = @"";
    }
    self.titleLabel.text = titleString;
    self.dateLabel.text = [NSString stringWithFormat:PLVLocalizedString(@"直播时间 %@"), dateString];
    self.channelIdLabel.text = [NSString stringWithFormat:PLVLocalizedString(@"频道号 %@"), channelIdString];
    
    BOOL hideSip = [sipNumberString isEqualToString:@""] || [sipNumberString isEqualToString:PLVLocalizedString(@"暂无")];
    self.sipLabel.hidden = hideSip;
    self.sipCopyButton.hidden = hideSip;
    
    self.sipLabel.text = [NSString stringWithFormat:PLVLocalizedString(@"入会号码 %@"), sipNumberString];
    self.sipPasswordString = sipPasswordString;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateUI];
    });
}

#pragma mark - [ Event ]
#pragma mark Action
- (void)sipCopyButtonClickAction:(UIButton *)button {
    NSString *sipNumberString = [NSString stringWithFormat:PLVLocalizedString(@"%@，入会密码 %@"), self.sipLabel.text, self.sipPasswordString];
    if (sipNumberString > 0) {
        [UIPasteboard generalPasteboard].string = sipNumberString;
        [PLVLSUtils showToastInHomeVCWithMessage:PLVLocalizedString(@"复制入会号码成功")];
    }
}

@end
