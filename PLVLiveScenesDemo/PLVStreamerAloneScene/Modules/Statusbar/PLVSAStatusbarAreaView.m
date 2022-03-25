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

// 模块
#import "PLVRoomDataManager.h"

// UI
#import "PLVSAStatusBarButton.h"

@interface PLVSAStatusbarAreaView()

#pragma mark UI
/// view hierarchy
///
/// (UIView) superview
///  └── (PLVSAStatusbarAreaView) self (lowest)
///    ├── (PLVSAStatusBarButton) channelInfoButton
///    ├── (PLVSAStatusBarButton) memberButton
///    ├── (PLVSAStatusBarButton) timeButton
///    ├── (PLVSAStatusBarButton) teacherNameButton
///    └── (PLVSAStatusBarButton) signalButton
///

@property (nonatomic, strong) PLVSAStatusBarButton *channelInfoButton; // 频道信息按钮
@property (nonatomic, strong) PLVSAStatusBarButton *memberButton; // 人员按钮
@property (nonatomic, strong) PLVSAStatusBarButton *timeButton; // 时间按钮
@property (nonatomic, strong) PLVSAStatusBarButton *teacherNameButton; // 讲师按钮
@property (nonatomic, strong) PLVSAStatusBarButton *signalButton; // 信号视图

#pragma mark 数据
@property (nonatomic, assign) BOOL inClass;

@end

@implementation PLVSAStatusbarAreaView

#pragma mark - [ Life Cycle ]

- (instancetype)init {
    self = [super init];
    if (self) {
        self.backgroundColor = [UIColor clearColor];

        [self addSubview:self.channelInfoButton];
        [self addSubview:self.memberButton];
        [self addSubview:self.timeButton];
        [self addSubview:self.signalButton];
        [self addSubview:self.teacherNameButton];
    }
    return self;
}

#pragma mark - [ Override ]

- (void)layoutSubviews {
    [super layoutSubviews];
    BOOL isPad = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
    BOOL landscape = [PLVSAUtils sharedUtils].landscape;
    
    CGFloat marginTop = landscape ? 16 : 8;
    CGFloat marginX = landscape ? 36 : 8;
    CGFloat padding = 8;
    CGFloat signalControlX = 0.0;
    CGFloat signalControlY = 0.0;

    if (isPad) {
        marginTop = 16;
        marginX = 24;
    }
    self.channelInfoButton.frame = CGRectMake(marginX, marginTop, 106, 36);
    
    CGFloat width = self.memberButton.frame.size.width;
    self.memberButton.frame = CGRectMake(CGRectGetMaxX(self.channelInfoButton.frame) + padding, marginTop, width, 36);
    
    self.timeButton.frame = CGRectMake(CGRectGetMaxX(self.memberButton.frame) + padding, marginTop, 100, 36);

    width = self.teacherNameButton.frame.size.width;
    self.teacherNameButton.frame = CGRectMake(marginX, CGRectGetMaxY(self.channelInfoButton.frame) + padding, width, 20);
        
    if (landscape) {
        signalControlX = self.bounds.size.width - 32 - marginX - 14 - 84;
        signalControlY = 22;
    } else {
        signalControlX = self.bounds.size.width - 84 - marginX;
        signalControlY = CGRectGetMaxY(self.channelInfoButton.frame) + padding;
    }
    self.signalButton.frame = CGRectMake(signalControlX, signalControlY, 84, 20);
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *hitView = [super hitTest:point withEvent:event];
    for (NSInteger i = 0; i < self.subviews.count; i++) {
        if (hitView == self.subviews[i]) {
            return hitView; //事件发生在子视图上，则子视图进行处理
        }
    }
    return nil; //将事件传递给下一级视图
}

#pragma mark - [ Public Method ]

- (void)startClass:(BOOL)start {
    self.timeButton.hidden = !start;
    self.signalButton.hidden = !start;
    self.inClass = start;
    self.timeButton.text = @"00:00:00";
}

#pragma mark - [ Private Method ]

#pragma mark Getter

- (PLVSAStatusBarButton *)teacherNameButton {
    if (!_teacherNameButton) {
        _teacherNameButton = [[PLVSAStatusBarButton alloc] init];
        _teacherNameButton.layer.cornerRadius = 10;
        
        _teacherNameButton.font = [UIFont systemFontOfSize:12];
        [_teacherNameButton setImage:[PLVSAUtils imageForStatusbarResource:@"plvsa_statusbar_btn_mic_00"]];
    }
    return _teacherNameButton;
}

- (PLVSAStatusBarButton *)channelInfoButton {
    if (!_channelInfoButton) {
        _channelInfoButton = [[PLVSAStatusBarButton alloc] init];
        _channelInfoButton.layer.cornerRadius = 18;
        
        _channelInfoButton.text = @"频道信息";
        _channelInfoButton.font = [UIFont systemFontOfSize:14];
        [_channelInfoButton setImage:[PLVSAUtils imageForStatusbarResource:@"plvsa_statusbar_btn_channel"] indicatorImage:[PLVSAUtils imageForStatusbarResource:@"plvsa_statusbar_btn_channel_right"]];
        
        __weak typeof(self) weakSelf = self;
        _channelInfoButton.didTapHandler = ^{
            [weakSelf channelInfoButtonAction];
        };
    }
    return _channelInfoButton;
}

- (PLVSAStatusBarButton *)memberButton{
    if (!_memberButton) {
        _memberButton = [[PLVSAStatusBarButton alloc] init];
        _memberButton.layer.cornerRadius = 18;
        
        [_memberButton setImage:[PLVSAUtils imageForStatusbarResource:@"plvsa_statusbar_btn_member"]];
        if (@available(iOS 8.2, *)) {
            _memberButton.font = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
        } else {
            _memberButton.font = [UIFont systemFontOfSize:14];
        }
    }
    return _memberButton;
}

- (PLVSAStatusBarButton *)timeButton {
    if (!_timeButton) {
        _timeButton = [[PLVSAStatusBarButton alloc] init];
        _timeButton.layer.cornerRadius = 18;
        _timeButton.titlePaddingX = 6;
        _timeButton.text = @"00:00:00";
        _timeButton.hidden = YES;
        [_timeButton setImage:[PLVSAUtils imageForStatusbarResource:@"plvsa_statusbar_btn_dot"] indicatorImage:nil];
        if (@available(iOS 8.2, *)) {
            _timeButton.font = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
        } else {
            _timeButton.font = [UIFont systemFontOfSize:14];
        }
    }
    return _timeButton;
}

- (PLVSAStatusBarButton *)signalButton {
    if (!_signalButton) {
        _signalButton = [[PLVSAStatusBarButton alloc] init];
        _signalButton.layer.cornerRadius = 10;
        _signalButton.titlePaddingX = 8;
        _signalButton.text = @"检测中";
        _signalButton.font = [UIFont systemFontOfSize:12];
        _signalButton.hidden = YES;
        [_signalButton setImage:[PLVSAUtils imageForStatusbarResource:@"plvsa_statusbar_signal_icon_unknown"]];
    }
    return _signalButton;
}

#pragma mark Setter

- (void)setDuration:(NSTimeInterval)duration {
    NSString *durTimeStr = [NSString stringWithFormat:@"%02ld:%02ld:%02ld",lround(floor(duration / 60 / 60)), lround(floor(duration / 60)) % 60, lround(floor(duration)) % 60];
    durTimeStr = self.inClass ? durTimeStr : @"00:00:00";
    self.timeButton.text = durTimeStr;
}

- (void)setTeacherName:(NSString *)teacherName {
    if (!teacherName ||
        ![teacherName isKindOfClass:[NSString class]] ||
        teacherName.length == 0) {
        return;
    }
    
    PLVRoomUserType viewerType = [PLVRoomDataManager sharedManager].roomData.roomUser.viewerType;
    if (viewerType == PLVRoomUserTypeTeacher) {
        teacherName = [NSString stringWithFormat:@"讲师-%@", teacherName];
    } else if (viewerType == PLVRoomUserTypeGuest) {
        teacherName = [NSString stringWithFormat:@"嘉宾-%@", teacherName];
    }
    self.teacherNameButton.text = teacherName;
    
    [self updateTeacherNameButtonFrameWithteacherName:teacherName];
}

- (void)setOnlineNum:(NSUInteger)onlineNum {
    NSString *onlineNumString = [NSString stringWithFormat:@"%lu", (unsigned long)onlineNum];
    self.memberButton.text = onlineNumString;
    [self updateMemberButtonFrameWithOnlineNumString:onlineNumString];
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
    self.signalButton.text = title;
    [self.signalButton setImage:[PLVSAUtils imageForStatusbarResource:imageName]];
}

- (void)setCurrentMicOpen:(BOOL)currentMicOpen {
    if (currentMicOpen) {
        [self.teacherNameButton setImage:[PLVSAUtils imageForStatusbarResource:@"plvsa_statusbar_btn_mic_open"]];
    } else {
        [self.teacherNameButton setImage:[PLVSAUtils imageForStatusbarResource:@"plvsa_statusbar_btn_mic_close"]];
    }
}

- (void)setLocalMicVolume:(CGFloat)localMicVolume {
    localMicVolume *= 100;
    localMicVolume = roundf(localMicVolume);
    localMicVolume = roundf(localMicVolume / 10);
    NSString *imageName = [NSString stringWithFormat:@"plvsa_statusbar_btn_mic_%.0f0", localMicVolume];
    [self.teacherNameButton setImage:[PLVSAUtils imageForStatusbarResource:imageName]];
}

#pragma mark 更新UI

- (void)updateMemberButtonFrameWithOnlineNumString:(NSString *)onlineNumString {

    UIFont *font = self.memberButton.font;
    NSAttributedString *nameAttr = [[NSAttributedString alloc] initWithString:onlineNumString attributes:@{NSFontAttributeName:font}];
    CGFloat numWidth = ceilf([nameAttr boundingRectWithSize:CGSizeMake(MAXFLOAT, font.lineHeight) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:nil].size.width);
    
    CGFloat iconWidth = 20;
    CGFloat padding = 8;
    CGFloat titlePadding = 2;
    CGFloat width = iconWidth + titlePadding + numWidth + padding * 2;
    width = MIN(width, 91);
    
    CGRect frame = self.memberButton.frame;
    frame.size.width = width;
    self.memberButton.frame = frame;
}

- (void)updateTeacherNameButtonFrameWithteacherName:(NSString *)teacherName {
    CGFloat padding = 8;
    CGFloat iconWidth = 25 + padding * 2;
    CGFloat maxTextNum = 17.5; // '讲师-' + '最多15字昵称'
    UIFont *font = self.teacherNameButton.font;
    CGFloat maxNameWidth;
    CGFloat nameWidth;
    
    NSAttributedString *singleAttr = [[NSAttributedString alloc] initWithString:@"讲" attributes:@{NSFontAttributeName:font}];
    CGFloat singleWidth = ceilf([singleAttr boundingRectWithSize:CGSizeMake(MAXFLOAT, font.lineHeight) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:nil].size.width);
    maxNameWidth = singleWidth * maxTextNum + iconWidth;
    
    NSAttributedString *nameAttr = [[NSAttributedString alloc] initWithString:teacherName attributes:@{NSFontAttributeName:font}];
    nameWidth = ceilf([nameAttr boundingRectWithSize:CGSizeMake(MAXFLOAT, font.lineHeight) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:nil].size.width);
   
    CGFloat width = nameWidth + iconWidth;
    width = MIN(maxNameWidth, width);
   
    CGRect frame = self.teacherNameButton.frame;
    frame.size.width = width;
    self.teacherNameButton.frame = frame;
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
