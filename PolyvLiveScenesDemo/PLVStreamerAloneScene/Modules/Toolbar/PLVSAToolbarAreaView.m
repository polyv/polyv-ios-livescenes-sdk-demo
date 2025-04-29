//
//  PLVSAToolbarAreaView.m
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2021/5/19.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVSAToolbarAreaView.h"
#import <PLVFoundationSDK/PLVFoundationSDK.h>

/// util
#import "PLVSAUtils.h"
#import "PLVMultiLanguageManager.h"

/// UI
#import "PLVSASendMessageView.h"
#import "PLVSALinkMicMenuPopup.h"

/// 模块
#import "PLVSAChatroomViewModel.h"
#import "PLVRoomDataManager.h"

/// 依赖库
#import <PLVFoundationSDK/PLVFoundationSDK.h>

@interface PLVSAToolbarAreaView()

/// view hierarchy
///
/// (UIView) superview
///  └── (PLVSAToolbarAreaView) self (lowest)
///    ├── (UIButton) chatButton
///    ├── (UIButton) linkMicButton
///    ├── (UIButton) commodityButton
///    ├── (UIButton) moreButton
///    ├── (PLVSASendMessageView) sendMessageView
///
// UI
@property (nonatomic, strong) UIButton *chatButton; // 聊天按钮（点击显示sendMessageView）
@property (nonatomic, strong) UIButton *layoutSwitchButton; // 连麦布局切换(默认平铺，选中为主讲模式)
@property (nonatomic, strong) UIButton *linkMicButton; // 连麦按钮
@property (nonatomic, strong) UIButton *memberButton; // 人员列表
@property (nonatomic, strong) UIView *memberBadgeView; // 等待连麦提示红点
@property (nonatomic, strong) UIButton *commodityButton; // 商品库按钮
@property (nonatomic, strong) UIButton *moreButton; // 更多弹层按钮

@property (nonatomic, strong) PLVSASendMessageView *sendMessageView; // 输入文字、图片、emoji标签视图
@property (nonatomic, strong) PLVSALinkMicMenuPopup *linkMicMenu;

/// 数据
@property (nonatomic, assign) PLVSAToolbarLinkMicButtonStatus linkMicButtonStatus;
@property (nonatomic, assign, readonly) BOOL isGuest; // 是否为嘉宾

@end

@implementation PLVSAToolbarAreaView

#pragma mark - [ Life Cycle ]
- (instancetype)init {
    self = [super init];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        
        [self addSubview:self.chatButton];
        [self addSubview:self.layoutSwitchButton];
        PLVRoomData *roomData = [PLVRoomDataManager sharedManager].roomData;
        if (!roomData.linkmicNewStrategyEnabled && roomData.interactNumLimit > 0 && roomData.roomUser.viewerType != PLVRoomUserTypeTeacher) {
            [self addSubview:self.linkMicButton];
        }
        [self addSubview:self.commodityButton];
        [self addSubview:self.moreButton];
    }
    return self;
}

#pragma mark - [ Override ]
- (void)layoutSubviews {
    [super layoutSubviews];
    
    BOOL isPad = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
    BOOL landscape = [PLVSAUtils sharedUtils].landscape;
    CGSize chatButtonSize = [self.chatButton.titleLabel sizeThatFits:CGSizeMake(MAXFLOAT, 32)];
    
    CGFloat marginLeft = landscape ? 36 : 8;
    CGFloat chatButtonWidth = landscape ? 150 : chatButtonSize.width + 53;
    CGFloat chatButtonTop = 8;
    
    if (isPad) {
        marginLeft = 24;
        chatButtonWidth = 220;
        chatButtonTop = 16;
    }
    
    self.chatButton.frame = CGRectMake(marginLeft, chatButtonTop, chatButtonWidth, 32);
    
    self.chatButton.imageEdgeInsets = UIEdgeInsetsMake(0, 8.5, 0, 0);
    
    self.chatButton.titleEdgeInsets = UIEdgeInsetsMake(0, 15, 0, 0);
    
    self.moreButton.frame = CGRectMake(self.bounds.size.width - 36 - marginLeft, 8, 36, 36);

    self.commodityButton.frame = CGRectMake(CGRectGetMinX(self.moreButton.frame) - 12 - 36, 8, 36, 36);
    
    CGFloat originX = [self canManageCommodity] ? CGRectGetMinX(self.commodityButton.frame) : CGRectGetMinX(self.moreButton.frame);
    self.linkMicButton.frame = CGRectMake(originX - 12 - 36, 8, 36, 36);
    originX = self.linkMicButton.isHidden || !self.linkMicButton.superview ? originX : CGRectGetMinX(self.linkMicButton.frame);
    self.layoutSwitchButton.frame = CGRectMake(originX - 12 - 36, 8, 36, 36);
}

#pragma mark - [ Public Method ]

- (void)setChannelLinkMicOpen:(BOOL)channelLinkMicOpen {
    _channelLinkMicOpen = channelLinkMicOpen;
    plv_dispatch_main_async_safe(^{
        self.linkMicButton.selected = channelLinkMicOpen;
        self.linkMicButton.enabled = YES;
    })
}

- (void)updateOnlineUserCount:(NSInteger)onlineUserCount {
    self.layoutSwitchButton.hidden = (onlineUserCount <= 1);
}

- (void)updateLinkMicButtonStatus:(PLVSAToolbarLinkMicButtonStatus)status {
    if (!self.isGuest) { return; }

    _linkMicButtonStatus = status;
    self.linkMicButton.hidden = NO;
    self.linkMicButton.selected = NO;
    self.linkMicButton.alpha = 1.0;
    UIImageView *buttonImageView = self.linkMicButton.imageView;
    if (buttonImageView.isAnimating) {
        [buttonImageView stopAnimating];
    }
    buttonImageView.animationImages = nil;
    if (_linkMicButtonStatus == PLVSAToolbarLinkMicButtonStatus_HandUp) {
        UIImageView *buttonImageView = self.linkMicButton.imageView;
        NSMutableArray *imageArray = [NSMutableArray arrayWithCapacity:3];
        for (NSInteger i = 0; i < 3; i ++) {
            [imageArray addObject:[PLVSAUtils imageForMemberResource:[NSString stringWithFormat:@"plvsa_member_linkmic_wait_icon_0%ld.png", i]]];
        }
        [buttonImageView setAnimationImages:[imageArray copy]];
        [buttonImageView setAnimationDuration:1];
        [buttonImageView startAnimating];
    } else {
        [self.linkMicButton setImage:[PLVSAUtils imageForMemberResource:@"plvsa_member_join_request"] forState:UIControlStateNormal];
        if (_linkMicButtonStatus == PLVSAToolbarLinkMicButtonStatus_NotLive) {
            self.linkMicButton.alpha = 0.6f;
        } else if (_linkMicButtonStatus == PLVSAToolbarLinkMicButtonStatus_Joined) {
            self.linkMicButton.selected = YES;
        }
    }
    
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

- (void)autoOpenMicLinkIfNeed {
    PLVRoomData *roomData = [PLVRoomDataManager sharedManager].roomData;
    if (roomData.roomUser.viewerType == PLVRoomUserTypeTeacher && [PLVFdUtil checkStringUseable:roomData.userDefaultOpenMicLinkEnabled]) {
        if ([roomData.userDefaultOpenMicLinkEnabled isEqualToString:@"audio"]) {
            [self.linkMicMenu audioLinkMicBtnAction];
        } else if ([roomData.userDefaultOpenMicLinkEnabled isEqualToString:@"video"]) {
            [self.linkMicMenu videoLinkMicBtnAction];
        }
    }
}

#pragma mark - [ Private Method ]

#pragma mark Getter
- (UIButton *)chatButton {
    if (!_chatButton) {
        _chatButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _chatButton.backgroundColor = [UIColor colorWithWhite:0 alpha:0.2];
        _chatButton.layer.cornerRadius = 16;
        _chatButton.layer.masksToBounds = YES;
        _chatButton.titleLabel.font = [UIFont systemFontOfSize:14];
        [_chatButton setTitleColor:[PLVColorUtil colorFromHexString:@"#FFFFFF" alpha:0.6] forState:UIControlStateNormal];
        [_chatButton setContentHorizontalAlignment:UIControlContentHorizontalAlignmentLeft];
        [_chatButton setImage:[PLVSAUtils imageForToolbarResource:@"plvsa_toolbar_btn_chat"] forState:UIControlStateNormal];
        [_chatButton setTitle:PLVLocalizedString(@"一起聊聊") forState:UIControlStateNormal];
        [_chatButton addTarget:self action:@selector(chatButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _chatButton;
}

- (UIButton *)layoutSwitchButton {
    if (!_layoutSwitchButton) {
        _layoutSwitchButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _layoutSwitchButton.hidden = YES;
        [_layoutSwitchButton setImage:[PLVSAUtils imageForToolbarResource:@"plvsa_toolbar_btn_speaker_switch"] forState:UIControlStateNormal];
        [_layoutSwitchButton setImage:[PLVSAUtils imageForToolbarResource:@"plvsa_toolbar_btn_tiled_switch"] forState:UIControlStateSelected];
        [_layoutSwitchButton addTarget:self action:@selector(layoutSwitchButtonAction) forControlEvents:UIControlEventTouchUpInside];
        _layoutSwitchButton.hidden = YES;
    }
    return _layoutSwitchButton;
}

- (UIButton *)linkMicButton {
    if (!_linkMicButton) {
        _linkMicButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_linkMicButton setImage:[PLVSAUtils imageForMemberResource:@"plvsa_member_join_request"] forState:UIControlStateNormal];
        [_linkMicButton setImage:[PLVSAUtils imageForMemberResource:@"plvsa_member_join_leave"] forState:UIControlStateSelected];
        [_linkMicButton addTarget:self action:@selector(linkMicButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        _linkMicButton.hidden = self.isGuest;
    }
    return _linkMicButton;
}

- (UIButton *)moreButton {
    if (!_moreButton) {
        _moreButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_moreButton setImage:[PLVSAUtils imageForToolbarResource:@"plvsa_toolbar_btn_more"] forState:UIControlStateNormal];
        [_moreButton addTarget:self action:@selector(moreButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _moreButton;
}

- (UIButton *)commodityButton {
    if (!_commodityButton) {
        _commodityButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _commodityButton.hidden = ![self canManageCommodity];
        [_commodityButton setImage:[PLVSAUtils imageForToolbarResource:@"plvsa_toolbar_btn_commodity"] forState:UIControlStateNormal];
        [_commodityButton addTarget:self action:@selector(commodityButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _commodityButton;
}

- (PLVSASendMessageView *)sendMessageView {
    if (!_sendMessageView) {
        _sendMessageView = [[PLVSASendMessageView alloc] init];
        _sendMessageView.imageEmotionArray =  [PLVSAChatroomViewModel sharedViewModel].imageEmotionArray;
    }
    return _sendMessageView;
}

- (PLVSALinkMicMenuPopup *)linkMicMenu {
    if (!_linkMicMenu) {
        CGFloat centerX = self.frame.origin.x + self.linkMicButton.frame.origin.x + self.linkMicButton.frame.size.width / 2.0; // 作为连麦选择弹层中心位置
        CGFloat originY = self.frame.origin.y - 96;
        CGRect rect = CGRectMake(centerX - 106 / 2.0, originY, 106, 96);
        CGRect buttonRect = [self convertRect:self.linkMicButton.frame toView:self.superview];
        _linkMicMenu = [[PLVSALinkMicMenuPopup alloc] initWithMenuFrame:rect buttonFrame:buttonRect];
        
        __weak typeof(self) weakSelf = self;
        _linkMicMenu.dismissHandler = ^{
            weakSelf.linkMicButton.enabled = YES;
        };
        
        _linkMicMenu.videoLinkMicButtonHandler = ^{
            if (weakSelf.delegate &&
                [weakSelf.delegate respondsToSelector:@selector(toolbarAreaViewDidTapVideoLinkMicButton:linkMicButtonSelected:)]) {
                [weakSelf.delegate toolbarAreaViewDidTapVideoLinkMicButton:weakSelf linkMicButtonSelected:weakSelf.linkMicButton.selected];
            }
        };
        
        _linkMicMenu.audioLinkMicButtonHandler = ^{
            if (weakSelf.delegate &&
                [weakSelf.delegate respondsToSelector:@selector(toolbarAreaViewDidTapAudioLinkMicButton:linkMicButtonSelected:)]) {
                [weakSelf.delegate toolbarAreaViewDidTapAudioLinkMicButton:weakSelf linkMicButtonSelected:weakSelf.linkMicButton.selected];
            }
        };
    }
    return _linkMicMenu;
}

- (BOOL)canManageCommodity {
    // 响应超管开关
    BOOL enableManageCommodity = [PLVRoomDataManager sharedManager].roomData.menuInfo.mobileAnchorProductEnabled;
    if (enableManageCommodity && [PLVRoomDataManager sharedManager].roomData.roomUser.viewerType == PLVRoomUserTypeTeacher) {
        return YES;
    }
    return NO;
}

- (BOOL)isGuest {
    PLVRoomUserType userType = [PLVRoomDataManager sharedManager].roomData.roomUser.viewerType;
    return userType == PLVRoomUserTypeGuest;;
}

#pragma mark Setter

#pragma mark Data Mode
#pragma mark Net Request

#pragma mark - Event

#pragma mark Action
- (void)chatButtonAction {
    [self.sendMessageView show];
    if (!self.sendMessageView.imageEmotionArray) {
        ///图片表情数据
        self.sendMessageView.imageEmotionArray = [PLVSAChatroomViewModel sharedViewModel].imageEmotionArray;
    }
}

- (void)layoutSwitchButtonAction {
    self.layoutSwitchButton.selected = !self.layoutSwitchButton.isSelected;
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(toolbarAreaViewDidLinkMicLayoutSwitchButton:layoutSwitchButtonSelected:)]) {
        [self.delegate toolbarAreaViewDidLinkMicLayoutSwitchButton:self layoutSwitchButtonSelected:self.layoutSwitchButton.isSelected];
    }
}

- (void)linkMicButtonAction:(UIButton *)sender {
    sender.enabled = NO;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(300 * NSEC_PER_MSEC)), dispatch_get_main_queue(), ^{
        sender.enabled = YES;
    });
    if (self.linkMicButton.selected || self.isGuest) {
        if (self.delegate &&
            [self.delegate respondsToSelector:@selector(toolbarAreaViewDidTapLinkMicButton:linkMicButtonSelected:)]) {
            [self.delegate toolbarAreaViewDidTapLinkMicButton:self linkMicButtonSelected:self.linkMicButton.selected];
        }
    } else {
        self.linkMicButton.enabled = NO;
        [self.linkMicMenu showAtView:self.superview];
    }
}


- (void)commodityButtonAction {
    if (self.delegate && [self.delegate respondsToSelector:@selector(toolbarAreaViewDidTapCommodityButton:)]) {
        [self.delegate toolbarAreaViewDidTapCommodityButton:self];
    }
}

- (void)moreButtonAction {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(toolbarAreaViewDidTapMoreButton:)]) {
        [self.delegate toolbarAreaViewDidTapMoreButton:self];
    }
}

@end
