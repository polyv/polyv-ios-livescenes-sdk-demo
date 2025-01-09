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
#import "PLVMultiLanguageManager.h"

// 模块
#import "PLVRoomDataManager.h"

// UI
#import "PLVSAStatusBarButton.h"
#import "PLVSANetworkStatePopup.h"

@interface PLVSAStatusbarAreaView()

#pragma mark UI
/// view hierarchy
///
/// (UIView) superview
///  └── (PLVSAStatusbarAreaView) self (lowest)
///    ├── (PLVSAStatusBarButton) channelInfoButton
///    ├── (PLVSAStatusBarButton) memberButton
///    ├── (UIView) memberBadgeView
///    ├── (PLVSAStatusBarButton) timeButton
///    ├── (PLVSAStatusBarButton) teacherNameButton
///    └── (PLVSAStatusBarButton) signalButton
///

@property (nonatomic, strong) PLVSAStatusBarButton *channelInfoButton; // 频道信息按钮
@property (nonatomic, strong) PLVSAStatusBarButton *memberButton; // 人员按钮
@property (nonatomic, strong) UIView *memberBadgeView; // 等待连麦提示红点
@property (nonatomic, strong) PLVSAStatusBarButton *timeButton; // 时间按钮
@property (nonatomic, strong) PLVSAStatusBarButton *teacherNameButton; // 讲师按钮
@property (nonatomic, strong) PLVSAStatusBarButton *signalButton; // 信号视图
@property (nonatomic, strong) PLVSANetworkStatePopup *networkStatePopup;

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
        [self addSubview:self.timeButton];
        [self addSubview:self.memberButton];
        [self addSubview:self.memberBadgeView];
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
    
    self.channelInfoButton.frame = CGRectMake(marginX, marginTop, self.channelInfoButton.buttonCalWidth, 36);
    
    self.timeButton.frame = CGRectMake(CGRectGetMaxX(self.channelInfoButton.frame) + padding, marginTop, 100, 36);
    
    CGFloat width = self.memberButton.frame.size.width;
    self.memberButton.frame = CGRectMake(CGRectGetMaxX(self.timeButton.frame) + padding, marginTop, width, 36);
    
    self.memberBadgeView.frame = CGRectMake(CGRectGetMaxX(self.memberButton.frame) - 10, 10, 6, 6);

    width = self.teacherNameButton.frame.size.width;
    self.teacherNameButton.frame = CGRectMake(marginX, CGRectGetMaxY(self.channelInfoButton.frame) + padding, width, 20);
        
    if (landscape) {
        signalControlX = self.bounds.size.width - 32 - marginX - 14 - self.signalButton.buttonCalWidth;
        signalControlY = 22;
    } else {
        signalControlX = self.bounds.size.width - self.signalButton.buttonCalWidth - marginX;
        signalControlY = CGRectGetMaxY(self.channelInfoButton.frame) + padding;
    }
    
    CGRect signalButtonFrame = CGRectMake(signalControlX, signalControlY, self.signalButton.buttonCalWidth, 20);
    if (self.signalButton.superview == self) {
        self.signalButton.frame = signalButtonFrame;
    }
    
    
    if (_networkStatePopup) {
        CGFloat width = self.networkStatePopup.bubbleSize.width;
        CGFloat height = self.networkStatePopup.bubbleSize.height;
        CGFloat originX = MAX(0, self.frame.origin.x + CGRectGetMaxX(signalButtonFrame) - width); // 弹层与按钮右侧对齐
        CGFloat originY = self.frame.origin.y + CGRectGetMaxY(signalButtonFrame) + 4.0;
        CGRect rect = CGRectMake(originX, originY, width, height);
        CGRect buttonRect = [self convertRect:signalButtonFrame toView:self.superview];
        
        [self.networkStatePopup refreshWithBubbleFrame:rect buttonFrame:buttonRect];
        if (self.networkStatePopup.showing) {
            [self.networkStatePopup dismiss];
        }
    }
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
    self.signalButton.userInteractionEnabled = start;
}

- (void)updateRTT:(NSInteger)rtt upLoss:(NSInteger)upLoss downLoss:(NSInteger)downLoss {
    [self.networkStatePopup updateRTT:rtt upLoss:upLoss downLoss:downLoss];
}

- (void)showMemberBadge:(BOOL)show{
    self.memberBadgeView.hidden = !show;
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
        _channelInfoButton.text = PLVLocalizedString(@"频道信息");
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
        
        __weak typeof(self) weakSelf = self;
        _memberButton.didTapHandler = ^{
            [weakSelf memberButtonAction];
        };
    }
    return _memberButton;
}

- (UIView *)memberBadgeView {
    if (!_memberBadgeView) {
        _memberBadgeView = [[UIView alloc] init];
        _memberBadgeView.backgroundColor = [UIColor redColor];
        _memberBadgeView.layer.cornerRadius = 3;
        _memberBadgeView.hidden = YES;
    }
    return _memberBadgeView;
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
        _signalButton.userInteractionEnabled = NO;
        _signalButton.layer.cornerRadius = 10;
        _signalButton.titlePaddingX = 6;
        _signalButton.text = PLVLocalizedString(@"检测中");
        _signalButton.font = [UIFont systemFontOfSize:12];
        _signalButton.hidden = YES;
        [_signalButton setImage:[PLVSAUtils imageForStatusbarResource:@"plvsa_statusbar_signal_icon_good"]];
        __weak typeof(self) weakSelf = self;
        [_signalButton setDidTapHandler:^{
            if (weakSelf.networkStatePopup.showing) {
                [weakSelf.networkStatePopup dismiss];
            } else {
                if (weakSelf == weakSelf.signalButton.superview) {
                    [weakSelf.networkStatePopup showAtView:weakSelf.superview];
                } else {
                    [weakSelf.networkStatePopup showAtView:weakSelf.signalButton.superview];
                }
            }
        }];
    }
    return _signalButton;
}

- (PLVSANetworkStatePopup *)networkStatePopup {
    if (!_networkStatePopup) {
        _networkStatePopup = [[PLVSANetworkStatePopup alloc] init];
        CGFloat width = _networkStatePopup.bubbleSize.width;
        CGFloat height = _networkStatePopup.bubbleSize.height;
        CGFloat originX = MAX(0, self.frame.origin.x + CGRectGetMaxX(self.signalButton.frame) - width); // 弹层与按钮右侧对齐
        CGFloat originY = self.frame.origin.y + CGRectGetMaxY(self.signalButton.frame) + 4.0;
        CGRect rect = CGRectMake(originX, originY, width, height);
        CGRect buttonRect = [self convertRect:self.signalButton.frame toView:self.superview];
        [_networkStatePopup setupBubbleFrame:rect buttonFrame:buttonRect];
    }
    return _networkStatePopup;
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
        teacherName = [NSString stringWithFormat:PLVLocalizedString(@"讲师-%@"), teacherName];
    } else if (viewerType == PLVRoomUserTypeGuest) {
        teacherName = [NSString stringWithFormat:PLVLocalizedString(@"嘉宾-%@"), teacherName];
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
            title = PLVLocalizedString(@"检测中");
            imageName = @"plvsa_statusbar_signal_icon_good";
            break;
        case PLVSAStatusBarNetworkQuality_Down:
            title = PLVLocalizedString(@"网络断开");
            imageName = @"plvsa_statusbar_signal_icon_bad";
            break;
        case PLVSAStatusBarNetworkQuality_VBad:
            title = PLVLocalizedString(@"网络很差");
            imageName = @"plvsa_statusbar_signal_icon_bad";
            break;
        case PLVSAStatusBarNetworkQuality_Poor:
            title = PLVLocalizedString(@"网络较差");
            imageName = @"plvsa_statusbar_signal_icon_fine";
            break;
        case PLVSAStatusBarNetworkQuality_Bad:
            title = PLVLocalizedString(@"网络一般");
            imageName = @"plvsa_statusbar_signal_icon_fine";
            break;
        case PLVSAStatusBarNetworkQuality_Good:
            title = PLVLocalizedString(@"网络良好");
            imageName = @"plvsa_statusbar_signal_icon_good";
            break;
        case PLVSAStatusBarNetworkQuality_Excellent:
            title = PLVLocalizedString(@"网络优秀");
            imageName = @"plvsa_statusbar_signal_icon_good";
            break;
    }
    self.signalButton.text = title;
    [self.signalButton setImage:[PLVSAUtils imageForStatusbarResource:imageName]];
    [self.signalButton enableWarningMode:netState == PLVSAStatusBarNetworkQuality_Down];
    self.signalButton.frame = CGRectMake(CGRectGetMaxX(self.signalButton.frame) - self.signalButton.buttonCalWidth, CGRectGetMinY(self.signalButton.frame), self.signalButton.buttonCalWidth, 20);
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
    
    NSAttributedString *singleAttr = [[NSAttributedString alloc] initWithString:PLVLocalizedString(@"讲") attributes:@{NSFontAttributeName:font}];
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

- (void)memberButtonAction {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(statusbarAreaViewDidTapMemberButton:)]) {
        [self.delegate statusbarAreaViewDidTapMemberButton:self];
    }
}

@end
