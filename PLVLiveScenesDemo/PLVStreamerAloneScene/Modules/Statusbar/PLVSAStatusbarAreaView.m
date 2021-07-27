//
//  PLVSAStatusbarAreaView.m
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2021/5/19.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVSAStatusbarAreaView.h"

// 工具
#import "PLVSAUtils.h"

@interface PLVSAStatusbarAreaView()

/// view hierarchy
///
/// (UIView) superview
///  └── (PLVSAStatusbarAreaView) self (lowest)
///    ├── (UIButton) channelInfoButton
///    ├── (UIImageView) channelInfoImageView
///    ├── (UIButton) memberButton
///    ├──(UIView) timeDotView
///    ├── (UIButton) timeButton
///    ├── (UIView) teacherBgView
///         └── (UILabel) teacherNameLabel
///         └── (UIButton) teacherNameButton
///    ├── (UILabel) netSpeedLabel
///    └── (UIButton) signalButton
///
/// UI
@property (nonatomic, strong) UIButton *channelInfoButton; // 频道信息按钮
@property (nonatomic, strong) UIImageView *channelInfoImageView; // 频道信息右边图标
@property (nonatomic, strong) UIButton *memberButton; // 人员按钮
@property (nonatomic, strong) UIView *timeDotView; // 时间红点
@property (nonatomic, strong) UIButton *timeButton; // 时间按钮
@property (nonatomic, strong) UIView *teacherBgView; //讲师背景视图
@property (nonatomic, strong) UILabel *teacherNameLabel; // 讲师标题
@property (nonatomic, strong) UIButton *teacherNameButton; // 讲师按钮
@property (nonatomic, strong) UILabel *netSpeedLabel; // 网速视图
@property (nonatomic, strong) UIButton *signalButton; // 信号视图

/// 数据
@property (nonatomic, assign) BOOL inClass;

@end

@implementation PLVSAStatusbarAreaView

#pragma mark - [ Life Cycle ]

- (instancetype)init {
    self = [super init];
    if (self) {
        self.backgroundColor = [UIColor clearColor];

        [self addSubview:self.channelInfoButton];
        [self addSubview:self.channelInfoImageView];
        [self addSubview:self.memberButton];
        [self addSubview:self.timeButton];
        [self addSubview:self.timeDotView];
        [self addSubview:self.netSpeedLabel];
        [self addSubview:self.signalButton];
        
        [self addSubview:self.teacherBgView];
        [self.teacherBgView addSubview:self.teacherNameLabel];
        [self.teacherBgView addSubview:self.teacherNameButton];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat marginTop = 8;
    CGFloat marginX = 8;
    CGFloat padding = 8;
    
    self.channelInfoButton.frame = CGRectMake(marginX, marginTop, 106, 36);
    self.channelInfoButton.titleEdgeInsets = UIEdgeInsetsMake(0, 4, 0, 0);
    
    self.channelInfoImageView.frame = CGRectMake(CGRectGetMaxX(self.channelInfoButton.frame) - 12 - 3, 0, 7, 12);
    self.channelInfoImageView.center = CGPointMake(self.channelInfoImageView.center.x, self.channelInfoButton.center.y);
    
    self.memberButton.frame = CGRectMake(CGRectGetMaxX(self.channelInfoButton.frame) + padding, marginTop, 66, 36);
    self.memberButton.titleEdgeInsets = UIEdgeInsetsMake(0, 4, 0, 0);
    
    self.timeButton.frame = CGRectMake(CGRectGetMaxX(self.memberButton.frame) + 11, marginTop, 100, 36);
    self.timeButton.titleEdgeInsets = UIEdgeInsetsMake(0,  8, 0, 0);
    
    self.timeDotView.frame = CGRectMake(self.timeButton.frame.origin.x + 8, (36 - 10) / 2 + marginTop , 10, 10);
    
    CGFloat width = self.teacherBgView.frame.size.width;
    self.teacherBgView.frame = CGRectMake(marginX, CGRectGetMaxY(self.channelInfoButton.frame) + marginTop, width, 20);
    
    self.teacherNameButton.frame = CGRectMake(marginX, (20 - 12 ) / 2 , 12, 12);
    self.teacherNameLabel.frame = CGRectMake(CGRectGetMaxX(self.teacherNameButton.frame) + 5, 0, width - marginX * 2 - 8 - 5, 20);
    
    self.signalButton.frame = CGRectMake(self.bounds.size.width - 84 - 8, CGRectGetMaxY(self.channelInfoButton.frame) + marginTop, 84, 20);
    self.signalButton.titleEdgeInsets = UIEdgeInsetsMake(0, 0, 0, -10);
}

#pragma mark - [ Override ]

#pragma mark - Public Method

- (void)startClass:(BOOL)start {
    self.inClass = start;
    
    [self.timeButton setTitle:@"00:00:00" forState:UIControlStateNormal];
}

#pragma mark - [ Private Method ]

#pragma mark Getter

- (UIView *)teacherBgView {
    if (!_teacherBgView) {
        _teacherBgView = [[UIView alloc] init];
        _teacherBgView.layer.cornerRadius = 10;
        _teacherBgView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.2];
    }
    return _teacherBgView;
}
- (UILabel *)teacherNameLabel {
    if (!_teacherNameLabel) {
        _teacherNameLabel = [[UILabel alloc] init];
        _teacherNameLabel.font = [UIFont systemFontOfSize:12];
        _teacherNameLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        _teacherNameLabel.textColor = [UIColor whiteColor];
    }
    return _teacherNameLabel;
}

- (UIButton *)teacherNameButton {
    if (!_teacherNameButton) {
        _teacherNameButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_teacherNameButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_teacherNameButton setImage:[PLVSAUtils imageForStatusbarResource:@"plvsa_statusbar_btn_mic_00"] forState:UIControlStateNormal];
    }
    return _teacherNameButton;
}

- (UIButton *)channelInfoButton{
    if (!_channelInfoButton) {
        _channelInfoButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _channelInfoButton.titleLabel.font = [UIFont systemFontOfSize:14];
        _channelInfoButton.layer.cornerRadius = 18;
        _channelInfoButton.backgroundColor = [UIColor colorWithRed:0/255.0 green:0/255.0 blue:0/255.0 alpha:0.2];
        
        [_channelInfoButton setTitle:@"频道信息 " forState:UIControlStateNormal];
        [_channelInfoButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_channelInfoButton setImage:[PLVSAUtils imageForStatusbarResource:@"plvsa_statusbar_btn_channel"] forState:UIControlStateNormal];
        [_channelInfoButton addTarget:self action:@selector(channelInfoButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _channelInfoButton;
}

- (UIImageView *)channelInfoImageView {
    if (!_channelInfoImageView) {
        _channelInfoImageView = [[UIImageView alloc] init];
        _channelInfoImageView.image = [PLVSAUtils imageForStatusbarResource:@"plvsa_statusbar_btn_channel_right"];
    }
    return _channelInfoImageView;
}

- (UIButton *)memberButton{
    if (!_memberButton) {
        _memberButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _memberButton.titleLabel.font = [UIFont systemFontOfSize:14];
        _memberButton.layer.cornerRadius = 18;
        _memberButton.backgroundColor = [UIColor colorWithRed:0/255.0 green:0/255.0 blue:0/255.0 alpha:0.2];
        
        [_memberButton setTitle:@"" forState:UIControlStateNormal];
        [_memberButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_memberButton setImage:[PLVSAUtils imageForStatusbarResource:@"plvsa_statusbar_btn_member"] forState:UIControlStateNormal];
    }
    return _memberButton;
}


- (UIView *)timeDotView {
    if (!_timeDotView) {
        _timeDotView = [[UIView alloc] init];
        _timeDotView.layer.cornerRadius = 5;
        _timeDotView.backgroundColor = [UIColor colorWithRed:255/255.0 green:59/255.0 blue:48/255.0 alpha:1/1.0];
    }
    return _timeDotView;
}

- (UIButton *)timeButton {
    if (!_timeButton) {
        _timeButton = [[UIButton alloc] init];
        _timeButton.titleLabel.font = [UIFont systemFontOfSize:14];
        _timeButton.layer.cornerRadius = 18;
        _timeButton.backgroundColor = [UIColor colorWithRed:0/255.0 green:0/255.0 blue:0/255.0 alpha:0.2];
        [_timeButton setTitle:@"00:00:00" forState:UIControlStateNormal];
        [_timeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    }
    return _timeButton;
}


- (UILabel *)netSpeedLabel {
    if (!_netSpeedLabel) {
        _netSpeedLabel = [[UILabel alloc] init];
        _netSpeedLabel.font = [UIFont systemFontOfSize:12];
        _netSpeedLabel.textColor = [UIColor whiteColor];
        _netSpeedLabel.textAlignment = NSTextAlignmentCenter;
        _netSpeedLabel.text = @"";
    }
    return _netSpeedLabel;
}

- (UIButton *)signalButton {
    if (!_signalButton) {
        _signalButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _signalButton.layer.cornerRadius = 10;
        _signalButton.backgroundColor = [UIColor colorWithRed:0/255.0 green:0/255.0 blue:0/255.0 alpha:0.2];
        
        [_signalButton setTitle:@"检测中" forState:UIControlStateNormal];
        UIColor *color = [UIColor whiteColor];
        [_signalButton setTitleColor:color forState:UIControlStateNormal];
        _signalButton.titleLabel.font = [UIFont systemFontOfSize:12];
    }
    return _signalButton;
}

#pragma mark Setter

- (void)setDuration:(NSTimeInterval)duration {
    NSString *durTimeStr = [NSString stringWithFormat:@"%02ld:%02ld:%02ld",lround(floor(duration / 60 / 60)), lround(floor(duration / 60)) % 60, lround(floor(duration)) % 60];
    [self.timeButton setTitle:durTimeStr forState:UIControlStateNormal];
}

- (void)setNetSpeed:(NSString *)netSpeed {
    self.netSpeedLabel.text = netSpeed;
}

- (void)setTeacherName:(NSString *)teacherName {
    if (!teacherName ||
        ![teacherName isKindOfClass:[NSString class]] ||
        teacherName.length == 0) {
        return;
    }
    CGFloat iconWidth = 25 + 8;
    NSAttributedString *singleAttr = [[NSAttributedString alloc] initWithString:@"讲" attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:12]}];
    CGFloat singleWidth = ceilf([singleAttr boundingRectWithSize:CGSizeMake(MAXFLOAT, 12) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:nil].size.width);
    CGFloat maxNameWidth = singleWidth * 18 + iconWidth;
    
    teacherName = [NSString stringWithFormat:@"讲师-%@", teacherName];
    NSAttributedString *nameAttr = [[NSAttributedString alloc] initWithString:teacherName attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:12]}];
    CGFloat nameWidth = ceilf([nameAttr boundingRectWithSize:CGSizeMake(MAXFLOAT, 12) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:nil].size.width);
  
    CGFloat width = nameWidth + iconWidth;
    
    width = MIN(maxNameWidth, width);

    CGRect frame = self.teacherBgView.frame;
    frame.size.width = width;
    self.teacherBgView.frame = frame;
    
    self.teacherNameLabel.text = teacherName;
}

- (void)setOnlineNum:(NSUInteger)onlineNum {
    [self.memberButton setTitle:[NSString stringWithFormat:@"%lu", (unsigned long)onlineNum] forState:UIControlStateNormal];
}

- (void)setNetState:(PLVSAStatusBarNetworkQuality)netState {
    _netState = netState;
    
    NSString *title = nil;
    NSString *imageName = nil;

    switch (netState) {
        case PLVSAStatusBarNetworkQuality_Unknown:
            title = @"检测中";
            imageName = @"plvsa_statusbar_signal_icon_unknown";
            break;
        case PLVSAStatusBarNetworkQuality_Disconnect:
            title = @"网络异常";
            imageName = @"plvsa_statusbar_signal_icon_bad";
            break;
        case PLVSAStatusBarNetworkQuality_Bad:
            title = @"网络异常";
            imageName = @"plvsa_statusbar_signal_icon_bad";
            break;
        case PLVSAStatusBarNetworkQuality_Fine:
            title = @"网络一般";
            imageName = @"plvsa_statusbar_signal_icon_fine";
            break;
        case PLVSAStatusBarNetworkQuality_Good:
            title = @"网络良好";
            imageName = @"plvsa_statusbar_signal_icon_good";
            break;
    }
    
    [self.signalButton setTitle:title forState:UIControlStateNormal];
    [self.signalButton setImage:[PLVSAUtils imageForStatusbarResource:imageName] forState:UIControlStateNormal];
}

- (void)setCurrentMicOpen:(BOOL)currentMicOpen {
    if (currentMicOpen) {
        [self.teacherNameButton setImage:[PLVSAUtils imageForStatusbarResource:@"plvsa_statusbar_btn_mic_open"] forState:UIControlStateNormal];
    } else {
        [self.teacherNameButton setImage:[PLVSAUtils imageForStatusbarResource:@"plvsa_statusbar_btn_mic_close"] forState:UIControlStateNormal];
    }
}

- (void)setLocalMicVolume:(CGFloat)localMicVolume {
    localMicVolume *= 100;
    localMicVolume = roundf(localMicVolume);
    localMicVolume = roundf(localMicVolume / 10);
    NSString *imageName = [NSString stringWithFormat:@"plvsa_statusbar_btn_mic_%.0f0", localMicVolume];
    [self.teacherNameButton setImage:[PLVSAUtils imageForStatusbarResource:imageName] forState:UIControlStateNormal];
}

#pragma mark - Event

#pragma mark Action

- (void)channelInfoButtonAction {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(statusbarAreaViewDidTapChannelInfoButton:)]) {
        [self.delegate statusbarAreaViewDidTapChannelInfoButton:self];
    }
}

@end
