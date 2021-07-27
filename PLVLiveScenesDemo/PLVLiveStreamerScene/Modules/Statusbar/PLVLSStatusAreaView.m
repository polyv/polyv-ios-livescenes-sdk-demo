//
//  PLVLSStatusAreaView.m
//  PLVLiveStreamerDemo
//
//  Created by MissYasiky on 2021/3/10.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVLSStatusAreaView.h"
#import "PLVLSLinkMicMenuPopup.h"
#import "PLVLSLinkMicApplyTipsView.h"

// 工具类
#import "PLVLSUtils.h"

static CGFloat kStatusBarHeight = 44;

@interface PLVLSStatusAreaView ()

/// UI
@property (nonatomic, strong) UILabel *channelInfoLabel;
@property (nonatomic, strong) UIButton *channelInfoButton;
@property (nonatomic, strong) UILabel *timeLabel;
@property (nonatomic, strong) UIButton *signalButton;
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
@property (nonatomic, strong) PLVLSLinkMicApplyTipsView *linkMicApplyView;

/// 数据
@property (nonatomic, assign) BOOL inClass;

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
//        [self addSubview:self.shareButton];
        [self addSubview:self.startPushButton];
        [self addSubview:self.stopPushButton];
        
        [self.memberButton addSubview:self.memberRedDot];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat originX = 0;
    self.channelInfoLabel.frame = CGRectMake(originX, (kStatusBarHeight - 28) / 2.0, 84, 28);
    self.channelInfoButton.frame = CGRectMake(originX, (kStatusBarHeight - 28) / 2.0, 84, 28);
    
    originX = CGRectGetMaxX(self.channelInfoButton.frame) + 12;
    self.timeLabel.frame = CGRectMake(originX, (kStatusBarHeight - 20) / 2.0, 55, 20);
    originX = self.timeLabel.hidden ? originX : originX + 50 + 12;
    self.signalButton.frame = CGRectMake(originX, 0, 70, 44);
    self.signalButton.titleEdgeInsets = UIEdgeInsetsMake(0, -1, 0, 0);
    self.signalButton.imageEdgeInsets = UIEdgeInsetsMake(0, -8, 0, 0);
    
    originX = self.bounds.size.width - 60;
    self.startPushButton.frame = CGRectMake(originX, (kStatusBarHeight - 28) / 2.0, 60, 28);
    self.stopPushButton.frame = CGRectMake(originX, (kStatusBarHeight - 28) / 2.0, 60, 28);
    originX -= 44 + 16;
//    self.shareButton.frame = CGRectMake(originX, 0, 44, 44);
//    originX -= 44;
    self.settingButton.frame = CGRectMake(originX, 0, 44, 44);
    originX -= 44;
    self.memberButton.frame = CGRectMake(originX, 0, 44, 44);
    self.memberRedDot.frame = CGRectMake(30, 10, 6, 6);
    originX -= 44;
    self.linkmicButton.frame = CGRectMake(originX, 0, 44, 44);
    originX -= 44;
    self.documentButton.frame = CGRectMake(originX, 0, 44, 44);
    originX -= 44;
    self.whiteboardButton.frame = CGRectMake(originX, 0, 44, 44);
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
        NSAttributedString *textAttributedString = [[NSAttributedString alloc] initWithString:@"频道信息" attributes:attributedDict];
        
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
        _timeLabel.textColor = [UIColor colorWithRed:0xff/255.0 green:0x63/255.0 blue:0x63/255.0 alpha:1];
        _timeLabel.text = @"00:00:00";
        _timeLabel.hidden = YES;
    }
    return _timeLabel;
}

- (UIButton *)signalButton {
    if (!_signalButton) {
        _signalButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_signalButton setTitle:@"检测中" forState:UIControlStateNormal];
        UIColor *color = [UIColor colorWithRed:0xf2/255.0 green:0x44/255.0 blue:0x53/255.0 alpha:1];
        [_signalButton setTitleColor:color forState:UIControlStateNormal];
        _signalButton.titleLabel.font = [UIFont systemFontOfSize:12];
        UIImage *image = [PLVLSUtils imageForStatusResource:@"plvls_status_signal_good_icon"];
        [_signalButton setImage:image forState:UIControlStateNormal];
        _signalButton.userInteractionEnabled = NO;
    }
    return _signalButton;
}

- (UIButton *)whiteboardButton {
    if (!_whiteboardButton) {
        _whiteboardButton = [UIButton buttonWithType:UIButtonTypeCustom];
        UIImage *normalImage = [PLVLSUtils imageForStatusResource:@"plvls_status_whiteboard_btn"];
        UIImage *highlightImage = [PLVLSUtils imageForStatusResource:@"plvls_status_whiteboard_btn_selected"];
        [_whiteboardButton setImage:normalImage forState:UIControlStateNormal];
        [_whiteboardButton setImage:highlightImage forState:UIControlStateHighlighted];
        [_whiteboardButton setImage:highlightImage forState:UIControlStateSelected];
        [_whiteboardButton addTarget:self action:@selector(whiteboardOrDocumentButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        _whiteboardButton.selected = YES;
    }
    return _whiteboardButton;
}

- (UIButton *)documentButton {
    if (!_documentButton) {
        _documentButton = [UIButton buttonWithType:UIButtonTypeCustom];
        UIImage *normalImage = [PLVLSUtils imageForStatusResource:@"plvls_status_document_btn"];
        UIImage *highlightImage = [PLVLSUtils imageForStatusResource:@"plvls_status_document_btn_selected"];
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
        UIImage *normalImage = [PLVLSUtils imageForStatusResource:@"plvls_status_linkmic_btn"];
        UIImage *highlightImage = [PLVLSUtils imageForStatusResource:@"plvls_status_linkmic_btn_selected"];
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
        [_startPushButton setTitle:@"上课" forState:UIControlStateNormal];
        [_startPushButton setTitle:@"下课" forState:UIControlStateSelected];
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
        [_stopPushButton setTitle:@"下课" forState:UIControlStateNormal];
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
        CGRect rect = CGRectMake(centerX - 106 / 2.0, originY, 106, 96);
        
        CGRect buttonRect = [self convertRect:self.linkmicButton.frame toView:self.superview];
        _linkMicMenu = [[PLVLSLinkMicMenuPopup alloc] initWithMenuFrame:rect buttonFrame:buttonRect];
        __weak typeof(self) weakSelf = self;
        _linkMicMenu.dismissHandler = ^{
            weakSelf.linkmicButton.selected = NO;
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

- (PLVLSLinkMicApplyTipsView *)linkMicApplyView {
    if (!_linkMicApplyView) {
        CGFloat centerX = self.memberButton.center.x;// 作为连麦选择弹层中心位置
        CGFloat originY = self.frame.origin.y + self.frame.size.height - 4.0;
        CGRect rect = CGRectMake(centerX - 136 / 2.0, originY, 136,  52);
        
        _linkMicApplyView = [[PLVLSLinkMicApplyTipsView alloc] initWithFrame:rect];
    }
    return _linkMicApplyView;
}

#pragma mark - Setter

- (void)setDuration:(NSTimeInterval)duration{
    NSString *durTimeStr = [NSString stringWithFormat:@"%02ld:%02ld:%02ld",lround(floor(duration / 60 / 60)), lround(floor(duration / 60)) % 60, lround(floor(duration)) % 60];
    self.timeLabel.text = durTimeStr;
}

- (void)setNetState:(PLVLSStatusBarNetworkQuality)netState {
    _netState = netState;
    
    UIColor *color = nil;
    NSString *title = nil;
    NSString *imageName = nil;
    UIColor *specialColor = [UIColor colorWithRed:0xf2/255.0 green:0x44/255.0 blue:0x53/255.0 alpha:1];
    
    switch (netState) {
        case PLVLSStatusBarNetworkQuality_Unknown:
            title = @"检测中";
            color = specialColor;
            imageName = @"plvls_status_signal_good_icon";
            break;
        case PLVLSStatusBarNetworkQuality_Disconnect:
            title = @"检测中";
            color = specialColor;
            imageName = @"plvls_status_signal_error_icon";
            break;
        case PLVLSStatusBarNetworkQuality_Bad:
            title = @"检测中";
            color = [UIColor clearColor];
            imageName = @"plvls_status_signal_bad_icon";
            break;
        case PLVLSStatusBarNetworkQuality_Fine:
            title = @"检测中";
            color = [UIColor clearColor];
            imageName = @"plvls_status_signal_fine_icon";
            break;
        case PLVLSStatusBarNetworkQuality_Good:
            title = @"检测中";
            color = [UIColor clearColor];
            imageName = @"plvls_status_signal_good_icon";
            break;
    }
    
    [self.signalButton setTitle:title forState:UIControlStateNormal];
    [self.signalButton setTitleColor:color forState:UIControlStateNormal];
    [self.signalButton setImage:[PLVLSUtils imageForStatusResource:imageName] forState:UIControlStateNormal];
}

#pragma mark - Action

- (void)channelInfoButtonAction {
    if (self.delegate) {
        [self.delegate statusAreaView_didTapChannelInfoButton];
    }
}

- (void)whiteboardOrDocumentButtonAction:(id)sender {
    UIButton *button = (UIButton *)sender;
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
    
    self.linkmicButton.selected = !self.linkmicButton.selected;
    if (self.linkmicButton.selected) {
        [self.linkMicMenu showAtView:self.superview];
    } else {
        [self.linkMicMenu dismiss];
    }
}

- (void)memberButtonAction {
    if (_linkMicApplyView) {
        [self.linkMicApplyView dismiss];
    }
    
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

#pragma mark - Public

- (void)startPushButtonEnable:(BOOL)enable {
    self.startPushButton.enabled = enable;
    self.startPushButton.alpha = enable ? 1.0 : 0.5;
}

- (void)startClass:(BOOL)start {
    self.inClass = start;
    self.startPushButton.hidden = start;
    self.stopPushButton.hidden = !start;
    
    self.timeLabel.text = @"00:00:00";
    self.timeLabel.hidden = !start;
    
    if (!start) {
        [self.linkMicMenu resetStatus];
    }
    
    [self layoutSubviews];
}

- (void)selectedWhiteboardOrDocument:(BOOL)whiteboard {
    UIButton *button = whiteboard ? self.whiteboardButton : self.documentButton;
    [self whiteboardOrDocumentButtonAction:button];
}

- (void)hasNewMember {
    self.memberRedDot.hidden = NO;
}

- (void)receivedNewJoinLinkMicRequest{
    [self.linkMicApplyView showAtView:self];
}

@end
