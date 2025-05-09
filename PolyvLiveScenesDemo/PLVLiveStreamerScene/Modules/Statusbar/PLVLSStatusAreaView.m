//
//  PLVLSStatusAreaView.m
//  PLVLiveStreamerDemo
//
//  Created by MissYasiky on 2021/3/10.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVLSStatusAreaView.h"
#import "PLVLSLinkMicMenuPopup.h"
#import "PLVLSLinkMicGuestMenuPopup.h"
#import "PLVLSNetworkStatePopup.h"
#import "PLVLSLinkMicApplyTipsView.h"
#import "PLVRoomDataManager.h"

// 工具类
#import "PLVLSUtils.h"
#import "PLVMultiLanguageManager.h"

// 模块
#import "PLVRoomDataManager.h"
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>

static CGFloat kStatusBarHeight = 44;
static NSString *kGustDefaultTintColor  = @"0x888888";
static NSInteger kPLVLSLinkMicRequestExpiredTime = 30; // 连麦邀请等待时间(秒)

typedef NS_ENUM(NSUInteger, PLVLSStatusLinkMicButtonStatus) {
    PLVLSStatusLinkMicButtonStatus_Default = 0, // 默认状态
    PLVLSStatusLinkMicButtonStatus_HandUp = 2, // 等待讲师应答中（举手中）
    PLVLSStatusLinkMicButtonStatus_Joined  = 4,// 已加入连麦（连麦中）
};

@interface PLVLSStatusAreaView ()

/// UI
@property (nonatomic, strong) UILabel *channelInfoLabel;
@property (nonatomic, strong) UIButton *channelInfoButton;
@property (nonatomic, strong) UILabel *timeLabel;
@property (nonatomic, strong) PLVLSSignalButton *signalButton;
@property (nonatomic, strong) UIButton *whiteboardButton;
@property (nonatomic, strong) UIButton *documentButton;
@property (nonatomic, strong) UIButton *linkmicButton;
@property (nonatomic, strong) UIButton *memberButton;
@property (nonatomic, strong) UIView *memberRedDot;
@property (nonatomic, strong) UIButton *settingButton;
@property (nonatomic, strong) UIButton *shareButton;
@property (nonatomic, strong) UIButton *startPushButton;
@property (nonatomic, strong) UIButton *stopPushButton;
@property (nonatomic, strong) PLVLSLinkMicMenuPopup *linkMicMenu;
@property (nonatomic, strong) PLVLSLinkMicGuestMenuPopup *guestLinkMicMenu;
@property (nonatomic, strong) PLVLSLinkMicApplyTipsView *linkMicApplyView;
@property (nonatomic, strong) PLVLSNetworkStatePopup *networkStatePopup;

/// 数据
@property (nonatomic, assign) BOOL inClass;
@property (nonatomic, assign) BOOL hasNewMemberState;
@property (nonatomic, assign, getter=isSpeaker) BOOL speaker; // 是否为主讲
@property (nonatomic, assign, getter=isGuest) BOOL guest; // 是否为嘉宾
@property (nonatomic, assign, getter=isTeacher) BOOL teacher; // 是否为讲师
@property (nonatomic, assign) BOOL whiteboardSelected; // 白板是否已选中
@property (nonatomic, assign) PLVLSStatusLinkMicButtonStatus linkMicButtonStatus; // 连麦按钮状态
@property (nonatomic, strong) NSTimer *requestLinkMicTimer; // 申请连麦计时器
@property (nonatomic, assign) NSTimeInterval requestLinkMicLimitTs; // 请求连麦的限制时间
@property (nonatomic, assign) NSTimeInterval linkMicBtnLastTimeInterval; // 连麦按钮上一次点击的时间戳

@end

@implementation PLVLSStatusAreaView

#pragma mark - Life Cycle

- (instancetype)init {
    self = [super init];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        
        [self addSubview:self.channelInfoLabel];
        [self addSubview:self.channelInfoButton];
        [self addSubview:self.timeLabel];
        [self addSubview:self.signalButton];
        [self addSubview:self.whiteboardButton];
        [self addSubview:self.documentButton];
        [self addSubview:self.linkmicButton];
        [self addSubview:self.memberButton];
        [self addSubview:self.settingButton];
        [self addSubview:self.startPushButton];
        [self addSubview:self.stopPushButton];
        
        [self.memberButton addSubview:self.memberRedDot];
        self.linkMicBtnLastTimeInterval = 0.0;
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    /// 得知当前外部所需显示的控件
    PLVLSStatusBarControls controlsInDemand = (PLVLSStatusBarControls_ChannelInfo | PLVLSStatusBarControls_TimeLabel | PLVLSStatusBarControls_SignalButton | PLVLSStatusBarControls_WhiteboardButton | PLVLSStatusBarControls_DocumentButton | PLVLSStatusBarControls_LinkmicButton | PLVLSStatusBarControls_MemberButton | PLVLSStatusBarControls_SettingButton | PLVLSStatusBarControls_ShareButton | PLVLSStatusBarControls_PushButton);
    if ([self.delegate respondsToSelector:@selector(statusAreaView_selectControlsInDemand)]) {
        PLVLSStatusBarControls returnValue = [self.delegate statusAreaView_selectControlsInDemand];
        if (returnValue != -1) { controlsInDemand = returnValue; }
    }
    
    /// 左侧控件
    CGFloat originX = 0;
    self.channelInfoLabel.hidden = YES;
    self.channelInfoButton.hidden = YES;
    if (controlsInDemand & PLVLSStatusBarControls_ChannelInfo) {
        self.channelInfoLabel.hidden = NO;
        self.channelInfoButton.hidden = NO;
        self.channelInfoLabel.frame = CGRectMake(originX, (kStatusBarHeight - 28) / 2.0, 90, 28);
        self.channelInfoButton.frame = CGRectMake(originX, (kStatusBarHeight - 28) / 2.0, 90, 28);
    }
    
    originX = self.channelInfoLabel.hidden ? originX : CGRectGetMaxX(self.channelInfoButton.frame) + 12;
    self.timeLabel.hidden = YES;
    if (controlsInDemand & PLVLSStatusBarControls_TimeLabel) {
        self.timeLabel.hidden = !self.inClass;
        self.timeLabel.frame = CGRectMake(originX, (kStatusBarHeight - 20) / 2.0, 55, 20);
    }
    
    originX = self.timeLabel.hidden ? originX : (CGRectGetMaxX(self.timeLabel.frame) - 5 + 12);
    self.signalButton.hidden = YES;
    CGRect signalButtonFrame = self.signalButton.frame;
    if (controlsInDemand & PLVLSStatusBarControls_SignalButton) {
        self.signalButton.hidden = NO;
        signalButtonFrame = CGRectMake(originX, 12, self.signalButton.buttonCalWidth, 20);
        if (self.signalButton.superview == self) {
            self.signalButton.frame = signalButtonFrame;
        }
    }
    
    /// 右侧控件
    originX = self.bounds.size.width;
    self.startPushButton.hidden = YES;
    self.stopPushButton.hidden = YES;
    if (controlsInDemand & PLVLSStatusBarControls_PushButton) {
        originX = self.bounds.size.width - 80;
        self.startPushButton.hidden = self.inClass;
        self.stopPushButton.hidden = !self.inClass;
        self.startPushButton.frame = CGRectMake(originX, (kStatusBarHeight - 28) / 2.0, 80, 28);
        if (self.stopPushButton.superview == self) {
            self.stopPushButton.frame = CGRectMake(originX, (kStatusBarHeight - 28) / 2.0, 80, 28);
        }
    }
    
    self.settingButton.hidden = YES;
    if (controlsInDemand & PLVLSStatusBarControls_SettingButton) {
        originX = (self.startPushButton.hidden && self.stopPushButton.hidden) ? (originX - 44) : originX - (44 + 16);
        self.settingButton.hidden = NO;
        self.settingButton.frame = CGRectMake(originX, 0, 44, 44);
    }
    
    self.memberButton.hidden = YES;
    self.memberRedDot.hidden = YES;
    if (controlsInDemand & PLVLSStatusBarControls_MemberButton) {
        originX -= 44;
        self.memberButton.hidden = NO;
        self.memberRedDot.hidden = !self.hasNewMemberState;
        self.memberButton.frame = CGRectMake(originX, 0, 44, 44);
        self.memberRedDot.frame = CGRectMake(30, 10, 6, 6);
    }
    
    self.linkmicButton.hidden = YES;
    if (controlsInDemand & PLVLSStatusBarControls_LinkmicButton) {
        originX -= 44;
        self.linkmicButton.hidden = NO;
        self.linkmicButton.frame = CGRectMake(originX, 0, 44, 44);
    }
    
    self.documentButton.hidden = YES;
    if (controlsInDemand & PLVLSStatusBarControls_DocumentButton) {
        originX -= 44;
        self.documentButton.hidden = NO;
        self.documentButton.frame = CGRectMake(originX, 0, 44, 44);
    }
    
    self.whiteboardButton.hidden = YES;
    if (controlsInDemand & PLVLSStatusBarControls_WhiteboardButton) {
        originX -= 44;
        self.whiteboardButton.hidden = NO;
        self.whiteboardButton.frame = CGRectMake(originX, 0, 44, 44);
    }
    ///连麦弹出层
    if(_linkMicMenu) {
        CGFloat centerX = self.frame.origin.x + self.linkmicButton.frame.origin.x + self.linkmicButton.frame.size.width / 2.0; // 作为连麦选择弹层中心位置
        CGFloat originY = self.frame.origin.y + self.frame.size.height - 4.0;
        CGRect rect = CGRectMake(centerX - 106 / 2.0, originY, 106, 96);
        
        CGRect buttonRect = [self convertRect:self.linkmicButton.frame toView:self.superview];
        [_linkMicMenu refreshWithMenuFrame:rect buttonFrame:buttonRect];
    }
    
    if (_networkStatePopup) {
        CGFloat width = self.networkStatePopup.bubbleSize.width;
        CGFloat height = self.networkStatePopup.bubbleSize.height;
        CGFloat originX = MAX(0, self.frame.origin.x + signalButtonFrame.origin.x + signalButtonFrame.size.width - width); // 弹层与按钮右侧对齐
        CGFloat originY = self.frame.origin.y + self.frame.size.height - 4.0;
        CGRect rect = CGRectMake(originX, originY, width, height);
        CGRect buttonRect = [self convertRect:signalButtonFrame toView:self.superview];
        
        [self.networkStatePopup refreshWithBubbleFrame:rect buttonFrame:buttonRect];
        if (self.networkStatePopup.showing) {
            [self.networkStatePopup dismiss];
        }
    }
}

#pragma mark - [ Private Methods ]
- (void)createRequestLinkMicTimer {
    if (_requestLinkMicTimer) {
        [self destroyRequestLinkMicTimer];
    }
    self.requestLinkMicLimitTs = kPLVLSLinkMicRequestExpiredTime;
    _requestLinkMicTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:[PLVFWeakProxy proxyWithTarget:self] selector:@selector(requestLinkMicTimerAction) userInfo:nil repeats:YES];
}

- (void)destroyRequestLinkMicTimer {
    if (_requestLinkMicTimer) {
        [_requestLinkMicTimer invalidate];
        _requestLinkMicTimer = nil;
    }
}

#pragma mark - Getter

- (UILabel *)channelInfoLabel {
    if (!_channelInfoLabel) {
        _channelInfoLabel = [[UILabel alloc] init];
        _channelInfoLabel.textAlignment = NSTextAlignmentCenter;
        
        UIImage *image = [PLVLSUtils imageForStatusResource:@"plvs_status_info_next_icon"];
        NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
        attachment.image = image;
        NSAttributedString *iconAttributedString = [NSAttributedString attributedStringWithAttachment:attachment];
        attachment.bounds = CGRectMake(1, -2, image.size.width, image.size.height);
        
        NSDictionary *attributedDict = @{NSFontAttributeName: [UIFont systemFontOfSize:12],
                                         NSForegroundColorAttributeName:[UIColor colorWithRed:0xf0/255.0 green:0xf1/255.0 blue:0xf5/255.0 alpha:1]
        };
        NSAttributedString *textAttributedString = [[NSAttributedString alloc] initWithString:PLVLocalizedString(@"频道信息") attributes:attributedDict];
        
        NSMutableAttributedString *muString = [[NSMutableAttributedString alloc] init];
        [muString appendAttributedString:textAttributedString];
        [muString appendAttributedString:iconAttributedString];
        _channelInfoLabel.attributedText = [muString copy];
    }
    return _channelInfoLabel;
}

- (UIButton *)channelInfoButton {
    if (!_channelInfoButton) {
        _channelInfoButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _channelInfoButton.layer.cornerRadius = 14;
        _channelInfoButton.layer.borderWidth = 1;
        _channelInfoButton.layer.borderColor = [UIColor colorWithRed:0xf0/255.0 green:0xf1/255.0 blue:0xf5/255.0 alpha:0.4].CGColor;
        [_channelInfoButton addTarget:self action:@selector(channelInfoButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _channelInfoButton;
}

- (UILabel *)timeLabel {
    if (!_timeLabel) {
        _timeLabel = [[UILabel alloc] init];
        _timeLabel.font = [UIFont systemFontOfSize:12];
        _timeLabel.adjustsFontSizeToFitWidth = YES;
        _timeLabel.textColor = [UIColor colorWithRed:0xff/255.0 green:0x63/255.0 blue:0x63/255.0 alpha:1];
        _timeLabel.text = @"00:00:00";
        _timeLabel.hidden = YES;
    }
    return _timeLabel;
}

- (PLVLSSignalButton *)signalButton {
    if (!_signalButton) {
        _signalButton = [[PLVLSSignalButton alloc] init];
        _signalButton.hidden = YES;
        [_signalButton setImage:[PLVLSUtils imageForStatusResource:@"plvls_status_signal_good_icon"]];
        __weak typeof(self) weakSelf = self;
        [_signalButton setDidTapHandler:^{
            if (weakSelf.networkStatePopup.showing) {
                [weakSelf.networkStatePopup dismiss];
            } else {
                [weakSelf.networkStatePopup showAtView:weakSelf.superview];
            }
        }];
    }
    return _signalButton;
}

- (UIButton *)whiteboardButton {
    if (!_whiteboardButton) {
        _whiteboardButton = [UIButton buttonWithType:UIButtonTypeCustom];
        UIImage *normalImage = [PLVLSUtils imageForStatusResource:@"plvls_status_whiteboard_btn"];
        UIImage *highlightImage = [PLVLSUtils imageForStatusResource:@"plvls_status_whiteboard_btn_selected"];
        
        if (self.isGuest) {
            normalImage = [normalImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            _whiteboardButton.tintColor = [PLVColorUtil colorFromHexString:kGustDefaultTintColor];
        } else {
            _whiteboardButton.selected = YES;
        }
        
        [_whiteboardButton setImage:normalImage forState:UIControlStateNormal];
        [_whiteboardButton setImage:highlightImage forState:UIControlStateHighlighted];
        [_whiteboardButton setImage:highlightImage forState:UIControlStateSelected];
        [_whiteboardButton addTarget:self action:@selector(whiteboardOrDocumentButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        
    }
    return _whiteboardButton;
}

- (UIButton *)documentButton {
    if (!_documentButton) {
        _documentButton = [UIButton buttonWithType:UIButtonTypeCustom];
        UIImage *normalImage = [PLVLSUtils imageForStatusResource:@"plvls_status_document_btn"];
        UIImage *highlightImage = [PLVLSUtils imageForStatusResource:@"plvls_status_document_btn_selected"];
        
        if (self.isGuest) {
            normalImage = [normalImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            _documentButton.tintColor = [PLVColorUtil colorFromHexString:kGustDefaultTintColor];
        }
        
        [_documentButton setImage:normalImage forState:UIControlStateNormal];
        [_documentButton setImage:highlightImage forState:UIControlStateHighlighted];
        [_documentButton setImage:highlightImage forState:UIControlStateSelected];
        [_documentButton addTarget:self action:@selector(whiteboardOrDocumentButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        
        
    }
    return _documentButton;
}

- (UIButton *)linkmicButton {
    if (!_linkmicButton) {
        _linkmicButton = [UIButton buttonWithType:UIButtonTypeCustom];
        BOOL newStrategy = self.isTeacher && [PLVRoomDataManager sharedManager].roomData.linkmicNewStrategyEnabled && [PLVRoomDataManager sharedManager].roomData.interactNumLimit > 0;
        UIImage *normalImage;
        UIImage *highlightImage;
        if (!newStrategy) {
            normalImage = [PLVLSUtils imageForStatusResource:@"plvls_status_linkmic_btn"];
            highlightImage = [PLVLSUtils imageForStatusResource:@"plvls_status_linkmic_btn_selected"];
        } else {
            normalImage = [PLVLSUtils imageForStatusResource:@"plvls_status_audience_raise_hand_btn"];
            highlightImage = [PLVLSUtils imageForStatusResource:@"plvls_status_audience_raise_hand_btn_selected"];
        }
        [_linkmicButton setImage:normalImage forState:UIControlStateNormal];
        [_linkmicButton setImage:highlightImage forState:UIControlStateHighlighted];
        [_linkmicButton setImage:highlightImage forState:UIControlStateSelected];
        [_linkmicButton addTarget:self action:@selector(linkmicButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _linkmicButton;
}

- (UIButton *)memberButton {
    if (!_memberButton) {
        _memberButton = [UIButton buttonWithType:UIButtonTypeCustom];
        UIImage *normalImage = [PLVLSUtils imageForStatusResource:@"plvls_status_member_btn"];
        UIImage *highlightImage = [PLVLSUtils imageForStatusResource:@"plvls_status_member_btn_selected"];
        [_memberButton setImage:normalImage forState:UIControlStateNormal];
        [_memberButton setImage:highlightImage forState:UIControlStateHighlighted];
        [_memberButton addTarget:self action:@selector(memberButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _memberButton;
}

- (UIView *)memberRedDot {
    if (!_memberRedDot) {
        _memberRedDot = [[UIView alloc] init];
        _memberRedDot.backgroundColor = [UIColor colorWithRed:0xff/255.0 green:0x63/255.0 blue:0x63/255.0 alpha:1];
        _memberRedDot.layer.masksToBounds = YES;
        _memberRedDot.layer.cornerRadius = 3;
        _memberRedDot.hidden = YES;
    }
    return _memberRedDot;
}

- (UIButton *)settingButton {
    if (!_settingButton) {
        _settingButton = [UIButton buttonWithType:UIButtonTypeCustom];
        UIImage *normalImage = [PLVLSUtils imageForStatusResource:@"plvls_status_setting_btn"];
        UIImage *highlightImage = [PLVLSUtils imageForStatusResource:@"plvls_status_setting_btn_selected"];
        [_settingButton setImage:normalImage forState:UIControlStateNormal];
        [_settingButton setImage:highlightImage forState:UIControlStateHighlighted];
        [_settingButton addTarget:self action:@selector(settingButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _settingButton;
}

- (UIButton *)shareButton {
    if (!_shareButton) {
        _shareButton = [UIButton buttonWithType:UIButtonTypeCustom];
        UIImage *normalImage = [PLVLSUtils imageForStatusResource:@"plvls_status_share_btn"];
        UIImage *highlightImage = [PLVLSUtils imageForStatusResource:@"plvls_status_share_btn_selected"];
        [_shareButton setImage:normalImage forState:UIControlStateNormal];
        [_shareButton setImage:highlightImage forState:UIControlStateHighlighted];
        [_shareButton addTarget:self action:@selector(shareButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _shareButton;
}

- (UIButton *)startPushButton {
    if (!_startPushButton) {
        _startPushButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _startPushButton.layer.cornerRadius = 14;
        _startPushButton.layer.borderWidth = 1;
        UIColor *normalColor = [UIColor colorWithRed:0x43/255.0 green:0x99/255.0 blue:0xff/255.0 alpha:1];
        _startPushButton.layer.borderColor = normalColor.CGColor;
        _startPushButton.titleLabel.font = [UIFont systemFontOfSize:14];
        [_startPushButton setTitle:PLVLocalizedString(@"上课") forState:UIControlStateNormal];
        [_startPushButton setTitle:PLVLocalizedString(@"下课") forState:UIControlStateSelected];
        [_startPushButton setTitleColor:normalColor forState:UIControlStateNormal];
        [_startPushButton addTarget:self action:@selector(startPushButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _startPushButton;
}

- (UIButton *)stopPushButton {
    if (!_stopPushButton) {
        _stopPushButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _stopPushButton.layer.cornerRadius = 14;
        _stopPushButton.layer.borderWidth = 1;
        UIColor *normalColor = [UIColor colorWithRed:0xff/255.0 green:0x63/255.0 blue:0x63/255.0 alpha:1];
        _stopPushButton.layer.borderColor = normalColor.CGColor;
        _stopPushButton.titleLabel.font = [UIFont systemFontOfSize:14];
        [_stopPushButton setTitle:PLVLocalizedString(@"下课") forState:UIControlStateNormal];
        [_stopPushButton setTitleColor:normalColor forState:UIControlStateNormal];
        [_stopPushButton addTarget:self action:@selector(stopPushButtonAction) forControlEvents:UIControlEventTouchUpInside];
        _stopPushButton.hidden = YES;
    }
    return _stopPushButton;
}

- (PLVLSLinkMicMenuPopup *)linkMicMenu {
    if (!_linkMicMenu) {
        CGFloat centerX = self.frame.origin.x + self.linkmicButton.frame.origin.x + self.linkmicButton.frame.size.width / 2.0; // 作为连麦选择弹层中心位置
        CGFloat originY = self.frame.origin.y + self.frame.size.height - 4.0;
        CGRect rect = CGRectZero;
        if ([PLVRoomDataManager sharedManager].roomData.isOnlyAudio) {
            rect = CGRectMake(centerX - 106 / 2.0, originY, 106, 48);
        } else {
            rect = CGRectMake(centerX - 106 / 2.0, originY, 106, 96);
        }
        CGRect buttonRect = [self convertRect:self.linkmicButton.frame toView:self.superview];
        _linkMicMenu = [[PLVLSLinkMicMenuPopup alloc] initWithMenuFrame:rect buttonFrame:buttonRect];
        __weak typeof(self) weakSelf = self;
        _linkMicMenu.dismissHandler = ^{
            weakSelf.linkmicButton.selected = [PLVRoomDataManager sharedManager].roomData.channelLinkMicMediaType != PLVChannelLinkMicMediaType_Unknown;
        };
        
        _linkMicMenu.videoLinkMicButtonHandler = ^BOOL(BOOL start) {
            if (weakSelf.delegate && [weakSelf.delegate respondsToSelector:@selector(statusAreaView_didTapVideoLinkMicButton:)]) {
                return [weakSelf.delegate statusAreaView_didTapVideoLinkMicButton:start];
            }else{
                return NO;
            }
        };
        
        _linkMicMenu.audioLinkMicButtonHandler = ^BOOL(BOOL start) {
            if (weakSelf.delegate && [weakSelf.delegate respondsToSelector:@selector(statusAreaView_didTapAudioLinkMicButton:)]) {
                return [weakSelf.delegate statusAreaView_didTapAudioLinkMicButton:start];
            }else{
                return NO;
            }
        };
    }
    return _linkMicMenu;
}

- (PLVLSLinkMicGuestMenuPopup *)guestLinkMicMenu {
    if (!_guestLinkMicMenu) {
        CGFloat centerX = self.frame.origin.x + self.linkmicButton.frame.origin.x + self.linkmicButton.frame.size.width / 2.0; // 作为连麦选择弹层中心位置
        CGFloat originY = self.frame.origin.y + self.frame.size.height - 4.0;
        CGRect rect = CGRectMake(centerX - 106 / 2.0, originY, 106, 48);
        CGRect buttonRect = [self convertRect:self.linkmicButton.frame toView:self.superview];
        _guestLinkMicMenu = [[PLVLSLinkMicGuestMenuPopup alloc] initWithMenuFrame:rect buttonFrame:buttonRect];
        __weak typeof(self) weakSelf = self;
        _guestLinkMicMenu.dismissHandler = ^{
            weakSelf.linkmicButton.selected = NO;
        };
        _guestLinkMicMenu.cancelRequestLinkMicButtonHandler = ^{
            [weakSelf setCurrentLinkMicButtonStatus:PLVLSStatusLinkMicButtonStatus_Default];
            [weakSelf callbackForRequestJoinLinkMic:NO];
        };
        _guestLinkMicMenu.closeLinkMicButtonHandler = ^{
            if (weakSelf.delegate && [weakSelf.delegate respondsToSelector:@selector(statusAreaView_didTapCloseLinkMicButton)]) {
                [weakSelf.delegate statusAreaView_didTapCloseLinkMicButton];
            }
        };
    }
    return _guestLinkMicMenu;
}
    
- (PLVLSLinkMicApplyTipsView *)linkMicApplyView {
    if (!_linkMicApplyView) {
        _linkMicApplyView = [[PLVLSLinkMicApplyTipsView alloc] init];
        CGFloat centerX = self.memberButton.center.x;// 作为连麦选择弹层中心位置
        CGFloat originY = self.frame.origin.y + self.frame.size.height - 4.0;
        // iPad需要减去头部状态栏的安全距离
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            originY -= PLVLSUtils.safeTopPad;
        }
        CGRect rect = CGRectMake(centerX - _linkMicApplyView.viewWidth / 2.0, originY, _linkMicApplyView.viewWidth,  52);
        _linkMicApplyView.frame = rect;
    }
    return _linkMicApplyView;
}

- (PLVLSNetworkStatePopup *)networkStatePopup {
    if (!_networkStatePopup) {
        _networkStatePopup = [[PLVLSNetworkStatePopup alloc] init];
        CGFloat width = _networkStatePopup.bubbleSize.width;
        CGFloat height = _networkStatePopup.bubbleSize.height;
        CGFloat originX = MAX(0, self.frame.origin.x + self.signalButton.frame.origin.x + self.signalButton.frame.size.width - width); // 弹层与按钮右侧对齐
        CGFloat originY = self.frame.origin.y + self.frame.size.height - 4.0;
        CGRect rect = CGRectMake(originX, originY, width, height);
        CGRect buttonRect = [self convertRect:self.signalButton.frame toView:self.superview];
        [_networkStatePopup setupBubbleFrame:rect buttonFrame:buttonRect];
    }
    return _networkStatePopup;
}

#pragma mark - Setter

- (void)setDuration:(NSTimeInterval)duration{
    NSString *durTimeStr = [NSString stringWithFormat:@"%02ld:%02ld:%02ld",lround(floor(duration / 60 / 60)), lround(floor(duration / 60)) % 60, lround(floor(duration)) % 60];
    self.timeLabel.text = durTimeStr;
}

- (void)setNetState:(PLVLSStatusBarNetworkQuality)netState {
    _netState = netState;
    
    NSString *title = nil;
    NSString *imageName = nil;
    
    switch (netState) {
        case PLVLSStatusBarNetworkQuality_Unknown:
            title = PLVLocalizedString(@"检测中");
            imageName = @"plvls_status_signal_good_icon";
            break;
        case PLVLSStatusBarNetworkQuality_Down:
            title = PLVLocalizedString(@"网络断开");
            imageName = @"plvls_status_signal_bad_icon";
            break;
        case PLVLSStatusBarNetworkQuality_VBad:
            title = PLVLocalizedString(@"网络很差");
            imageName = @"plvls_status_signal_bad_icon";
            break;
        case PLVLSStatusBarNetworkQuality_Poor:
            title = PLVLocalizedString(@"网络较差");
            imageName = @"plvls_status_signal_fine_icon";
            break;
        case PLVLSStatusBarNetworkQuality_Bad:
            title = PLVLocalizedString(@"网络一般");
            imageName = @"plvls_status_signal_fine_icon";
            break;
        case PLVLSStatusBarNetworkQuality_Good:
            title = PLVLocalizedString(@"网络良好");
            imageName = @"plvls_status_signal_good_icon";
            break;
        case PLVLSStatusBarNetworkQuality_Excellent:
            title = PLVLocalizedString(@"网络优秀");
            imageName = @"plvls_status_signal_good_icon";
            break;
    }
    
    self.signalButton.text = title;
    [self.signalButton setImage:[PLVLSUtils imageForStatusResource:imageName]];
    [self.signalButton enableWarningMode:netState == PLVLSStatusBarNetworkQuality_Down];
    self.signalButton.frame = CGRectMake(self.signalButton.frame.origin.x, self.signalButton.frame.origin.y, self.signalButton.buttonCalWidth, 20);
}

- (void)setCurrentLinkMicButtonStatus:(PLVLSStatusLinkMicButtonStatus)linkMicButtonStatus {
    if (!self.isGuest) {  return; }
    
    _linkMicButtonStatus = linkMicButtonStatus;
    // 销毁计时器
    if (linkMicButtonStatus == PLVLSStatusLinkMicButtonStatus_HandUp) {
        [self createRequestLinkMicTimer];
    } else {
        [self destroyRequestLinkMicTimer];
    }
    
    // 更新pop菜单
    if (self.linkmicButton.isSelected) {
        [self.guestLinkMicMenu updateMenuPopupInLinkMic:linkMicButtonStatus == PLVLSStatusLinkMicButtonStatus_Joined];
    }
    
    // 更新连麦按钮状态
    UIImageView *buttonImageView = self.linkmicButton.imageView;
    if (buttonImageView.isAnimating) {
        [buttonImageView stopAnimating];
    }
    buttonImageView.animationImages = nil;
    if (_linkMicButtonStatus == PLVLSStatusLinkMicButtonStatus_HandUp) {
        UIImageView *buttonImageView = self.linkmicButton.imageView;
        NSMutableArray *imageArray = [NSMutableArray arrayWithCapacity:3];
        for (NSInteger i = 0; i < 3; i ++) {
            [imageArray addObject:[PLVLSUtils imageForStatusResource:[NSString stringWithFormat:@"plvls_status_linkmic_wait_icon_0%ld.png", i]]];
        }
        [buttonImageView setAnimationImages:[imageArray copy]];
        [buttonImageView setAnimationDuration:1];
        [buttonImageView startAnimating];
    } else {
        UIImage *normalImage = [PLVLSUtils imageForStatusResource:@"plvls_status_linkmic_btn"];
        UIImage *highlightImage = [PLVLSUtils imageForStatusResource:@"plvls_status_linkmic_btn_selected"];
        if (_linkMicButtonStatus == PLVLSStatusLinkMicButtonStatus_Joined) {
            normalImage = [PLVLSUtils imageForStatusResource:@"plvls_status_linkmicjoined_btn"];
            highlightImage = normalImage;
        }
        [self.linkmicButton setImage:normalImage forState:UIControlStateNormal];
        [self.linkmicButton setImage:highlightImage forState:UIControlStateHighlighted];
        [self.linkmicButton setImage:highlightImage forState:UIControlStateSelected];
    }
}

#pragma mark 判断是否有连麦管理权限
/// 讲师、助教、管理员可以管理连麦操作
- (BOOL)canManagerLinkMic {
    PLVRoomUserType userType = [PLVRoomDataManager sharedManager].roomData.roomUser.viewerType;
    if (userType == PLVRoomUserTypeTeacher ||
        userType == PLVRoomUserTypeAssistant ||
        userType == PLVRoomUserTypeManager) {
        return YES;
    } else {
        return NO;
    }
}

- (BOOL)isGuest {
    PLVRoomUserType userType = [PLVRoomDataManager sharedManager].roomData.roomUser.viewerType;
    return userType == PLVRoomUserTypeGuest;
}

- (BOOL)isTeacher {
    PLVRoomUserType userType = [PLVRoomDataManager sharedManager].roomData.roomUser.viewerType;
    return userType == PLVRoomUserTypeTeacher;
}

#pragma mark - Action

- (void)channelInfoButtonAction {
    if (self.delegate) {
        [self.delegate statusAreaView_didTapChannelInfoButton];
    }
}

- (void)whiteboardOrDocumentButtonAction:(id)sender {
    UIButton *button = (UIButton *)sender;
    if (self.isGuest &&
        !self.isSpeaker) {
        if (button == self.documentButton) {
            [PLVLSUtils showToastInHomeVCWithMessage:PLVLocalizedString(@"被授权后才可以使用课件功能")];
        }
        return;
    }
    
    BOOL whiteboard = (button == self.whiteboardButton);
    self.whiteboardButton.selected = whiteboard;
    self.documentButton.selected = !whiteboard;
    if (self.delegate) {
        [self.delegate statusAreaView_didTapWhiteboardOrDocumentButton:whiteboard];
    }
}

- (void)linkmicButtonAction {
    if (_linkMicApplyView) {
        [self.linkMicApplyView dismiss];
    }
    
    if (self.isGuest) {
        self.linkmicButton.selected = !self.linkmicButton.selected;
        if (!self.inClass) {
            self.linkmicButton.selected = !self.linkmicButton.selected;
            [PLVLSUtils showToastInHomeVCWithMessage:PLVLocalizedString(@"上课前无法发起连麦")];
            return;
        }
        
        if (self.linkmicButton.selected) {
            if (self.linkMicButtonStatus == PLVLSStatusLinkMicButtonStatus_Default) {
                self.linkmicButton.selected = !self.linkmicButton.selected;
                [self setCurrentLinkMicButtonStatus:PLVLSStatusLinkMicButtonStatus_HandUp];
                [self callbackForRequestJoinLinkMic:YES];
            } else {
                [self.guestLinkMicMenu updateMenuPopupInLinkMic:self.linkMicButtonStatus == PLVLSStatusLinkMicButtonStatus_Joined];
                [self.guestLinkMicMenu showAtView:self.superview];
            }
        } else {
            [self.guestLinkMicMenu dismiss];
        }
    } else {
        if([PLVRoomDataManager sharedManager].roomData.linkmicNewStrategyEnabled && [PLVRoomDataManager sharedManager].roomData.interactNumLimit > 0) {
            // 防止短时间内重复点击，1s间隔内的点击会直接忽略
            NSTimeInterval curTimeInterval = [PLVFdUtil curTimeInterval];
            if (curTimeInterval - self.linkMicBtnLastTimeInterval > 1000) {
                if (self.delegate && [self.delegate respondsToSelector:@selector(statusAreaView_didTapAudienceRaiseHandButton:)]) {
                    [self.delegate statusAreaView_didTapAudienceRaiseHandButton:!self.linkmicButton.selected];
                }
            }
            self.linkMicBtnLastTimeInterval = curTimeInterval;

        } else if (self.linkMicMenu.superview) {
            [self.linkMicMenu dismiss];
        } else {
            [self.linkMicMenu showAtView:self.superview];
        }
    }
}

- (void)memberButtonAction {
    if (_linkMicApplyView) {
        [self.linkMicApplyView dismiss];
    }
    
    self.memberButton.selected = YES;
    self.hasNewMemberState = NO;
    self.memberRedDot.hidden = YES;
    if (self.delegate) {
        [self.delegate statusAreaView_didTapMemberButton];
    }
}

- (void)settingButtonAction {
    if (self.delegate) {
        [self.delegate statusAreaView_didTapSettingButton];
    }
}

- (void)shareButtonAction {
    if (self.delegate) {
        [self.delegate statusAreaView_didTapShareButton];
    }
}

- (void)startPushButtonAction {
    if (self.delegate) {
        BOOL needChange = [self.delegate statusAreaView_didTapStartPushOrStopPushButton:YES];
        [self startPushButtonEnable:!needChange];
    }
}

- (void)stopPushButtonAction {
    if (self.delegate) {
        [self.delegate statusAreaView_didTapStartPushOrStopPushButton:NO];
    }
}

#pragma mark Timer
- (void)requestLinkMicTimerAction {
    self.requestLinkMicLimitTs -= 1;
    if (self.requestLinkMicLimitTs <= 0) {
        [self setCurrentLinkMicButtonStatus:PLVLSStatusLinkMicButtonStatus_Default];
        [self callbackForRequestJoinLinkMic:NO];
        [self destroyRequestLinkMicTimer];
    }
}

#pragma mark Callback
- (void)callbackForRequestJoinLinkMic:(BOOL)requestJoin {
    if (self.delegate && [self.delegate respondsToSelector:@selector(statusAreaView_didRequestJoinLinkMic:)]) {
        [self.delegate statusAreaView_didRequestJoinLinkMic:requestJoin];
    }
}

#pragma mark - Public

- (void)startPushButtonEnable:(BOOL)enable {
    self.startPushButton.enabled = enable;
    self.startPushButton.alpha = enable ? 1.0 : 0.5;
}

- (void)startClass:(BOOL)start {
    self.inClass = start;
    
    self.signalButton.userInteractionEnabled = self.inClass;
    self.timeLabel.text = @"00:00:00";
    
    PLVRoomData *roomData = [PLVRoomDataManager sharedManager].roomData;
    if (!start) {
        [self.linkMicMenu resetStatus];
        [self setCurrentLinkMicButtonStatus:PLVLSStatusLinkMicButtonStatus_Default];
    } else if (roomData.roomUser.viewerType == PLVRoomUserTypeTeacher && [PLVFdUtil checkStringUseable:roomData.userDefaultOpenMicLinkEnabled] && !roomData.linkmicNewStrategyEnabled) {
        if ([roomData.userDefaultOpenMicLinkEnabled isEqualToString:@"audio"]) {
            [self.linkMicMenu audioLinkMicBtnAction];
        } else if ([roomData.userDefaultOpenMicLinkEnabled isEqualToString:@"video"]) {
            [self.linkMicMenu videoLinkMicBtnAction];
        }
    }
    
    [self layoutSubviews];
}

- (void)selectedWhiteboardOrDocument:(BOOL)whiteboard {
    UIButton *button = whiteboard ? self.whiteboardButton : self.documentButton;
    [self whiteboardOrDocumentButtonAction:button];
}

- (void)syncSelectedWhiteboardOrDocument:(BOOL)whiteboard {
    self.whiteboardSelected = whiteboard;
    if ((self.isGuest && self.speaker) || self.isTeacher) {
        self.whiteboardButton.selected = whiteboard;
        self.documentButton.selected = !whiteboard;
    }
}

- (void)hasNewMember {
    self.hasNewMemberState = YES;
    if (!self.memberButton.hidden) {
        self.memberRedDot.hidden = NO;
    }
}

- (void)receivedNewJoinLinkMicRequest{
    if ([self canManagerLinkMic]) {
        [self.linkMicApplyView showAtView:self];
        if (!self.memberButton.selected) {
            [self hasNewMember];
        }
    }
}

- (void)updateDocumentSpeakerAuth:(BOOL)auth {
    self.speaker = auth;
    
    if (!auth &&
        self.documentButton.selected) {
        self.documentButton.selected = NO;
    }
    
    if (auth) {
        self.whiteboardButton.tintColor = [UIColor whiteColor];
        self.documentButton.tintColor = [UIColor whiteColor];
        
        self.whiteboardButton.selected = self.whiteboardSelected;
        self.documentButton.selected = !self.whiteboardSelected;
        
    } else {
        self.whiteboardButton.tintColor = [PLVColorUtil colorFromHexString:kGustDefaultTintColor];
        self.documentButton.tintColor = [PLVColorUtil colorFromHexString:kGustDefaultTintColor];
        self.whiteboardButton.selected = NO;
        self.documentButton.selected = NO;
    }
}

- (void)updateStatusViewLinkMicStatus:(PLVLinkMicUserLinkMicStatus)status {
    PLVLSStatusLinkMicButtonStatus linkMicButtonStatus = PLVLSStatusLinkMicButtonStatus_Default;
    if (status == PLVLinkMicUserLinkMicStatus_HandUp) {
        linkMicButtonStatus = PLVLSStatusLinkMicButtonStatus_HandUp;
    } else if (status == PLVLinkMicUserLinkMicStatus_Joined) {
        linkMicButtonStatus = PLVLSStatusLinkMicButtonStatus_Joined;
    }
    if (self.linkMicButtonStatus != linkMicButtonStatus) {
        [self setCurrentLinkMicButtonStatus:linkMicButtonStatus];
    }
}

- (void)updateStatistics:(PLVRTCStatistics *)statistics {
    [self.networkStatePopup updateRTT:statistics.rtt upLoss:statistics.upLoss downLoss:statistics.downLoss];
}

- (void)changeMemberButtonSelectedState:(BOOL)selected {
    self.memberButton.selected = selected;
}

- (void)changeLinkmicButtonSelectedState:(BOOL)selected {
    self.linkmicButton.selected = selected;
}

@end
