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

/// UI
#import "PLVSASendMessageView.h"

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
///    ├── (UIButton) memberButton
///    ├── (UIView) memberBadgeView
///    ├── (UIButton) moreButton
///    ├── (PLVSASendMessageView) sendMessageView
///
// UI
@property (nonatomic, strong) UIButton *chatButton; // 聊天按钮（点击显示sendMessageView）
@property (nonatomic, strong) UIButton *layoutSwitchButton; // 连麦布局切换(默认平铺，选中为主讲模式)
@property (nonatomic, strong) UIButton *linkMicButton; // 连麦按钮
@property (nonatomic, strong) UIButton *memberButton; // 人员列表
@property (nonatomic, strong) UIView *memberBadgeView; // 等待连麦提示红点
@property (nonatomic, strong) UIButton *moreButton; // 更多弹层按钮

@property (nonatomic, strong) PLVSASendMessageView *sendMessageView; // 输入文字、图片、emoji标签视图

@end

@implementation PLVSAToolbarAreaView

#pragma mark - [ Life Cycle ]
- (instancetype)init {
    self = [super init];
    if (self) {
        self.backgroundColor = [UIColor clearColor];

        [self addSubview:self.chatButton];
        [self addSubview:self.layoutSwitchButton];
        [self addSubview:self.linkMicButton];
        [self addSubview:self.memberButton];
        [self addSubview:self.memberBadgeView];
        [self addSubview:self.moreButton];
        
    }
    return self;
}

#pragma mark - [ Override ]
- (void)layoutSubviews {
    [super layoutSubviews];
    
    BOOL isPad = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
    BOOL landscape = [PLVSAUtils sharedUtils].landscape;
    
    CGFloat marginLeft = landscape ? 36 : 8;
    CGFloat chatButtonWidth = 150;
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
    
    self.memberButton.frame = CGRectMake(CGRectGetMinX(self.moreButton.frame) - 12 - 36, 8, 36, 36);
    
    self.memberBadgeView.frame = CGRectMake(CGRectGetMaxX(self.memberButton.frame) - 10, 8, 10, 10);
    
    if ([PLVRoomDataManager sharedManager].roomData.roomUser.viewerType == PLVRoomUserTypeGuest) {
        self.linkMicButton.hidden = YES;
        self.layoutSwitchButton.hidden = YES;
    } else {
        self.linkMicButton.frame = CGRectMake(CGRectGetMinX(self.memberButton.frame) - 12 - 36, 8, 36, 36);
        
        self.layoutSwitchButton.frame = CGRectMake(CGRectGetMinX(self.linkMicButton.frame) - 12 - 36, 8, 36, 36);
    }
}

#pragma mark - [ Public Method ]

- (void)showMemberBadge:(BOOL)show{
    self.memberBadgeView.hidden = !show;
}

- (void)setChannelLinkMicOpen:(BOOL)channelLinkMicOpen {
    _channelLinkMicOpen = channelLinkMicOpen;
    plv_dispatch_main_async_safe(^{
        self.linkMicButton.selected = channelLinkMicOpen;
        self.linkMicButton.enabled = YES;
    })
}

- (void)updateOnlineUserCount:(NSInteger)onlineUserCount { self.layoutSwitchButton.hidden = (onlineUserCount <= 1);
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
        [_chatButton setTitle:@"来聊点什么吧~" forState:UIControlStateNormal];
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
    }
    return _layoutSwitchButton;
}

- (UIButton *)linkMicButton {
    if (!_linkMicButton) {
        _linkMicButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_linkMicButton setImage:[PLVSAUtils imageForMemberResource:@"plvsa_member_join_request"] forState:UIControlStateNormal];
        [_linkMicButton setImage:[PLVSAUtils imageForMemberResource:@"plvsa_member_join_leave"] forState:UIControlStateSelected];
        [_linkMicButton addTarget:self action:@selector(linkMicButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _linkMicButton;
}

- (UIButton *)memberButton {
    if (!_memberButton) {
        _memberButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_memberButton setImage:[PLVSAUtils imageForToolbarResource:@"plvsa_toolbar_btn_member"] forState:UIControlStateNormal];
        [_memberButton addTarget:self action:@selector(memberButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _memberButton;
}

- (UIView *)memberBadgeView {
    if (!_memberBadgeView) {
        _memberBadgeView = [[UIView alloc] init];
        _memberBadgeView.backgroundColor = [UIColor redColor];
        _memberBadgeView.layer.cornerRadius = 5;
        _memberBadgeView.hidden = YES;
    }
    return _memberBadgeView;
}

- (UIButton *)moreButton {
    if (!_moreButton) {
        _moreButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_moreButton setImage:[PLVSAUtils imageForToolbarResource:@"plvsa_toolbar_btn_more"] forState:UIControlStateNormal];
        [_moreButton addTarget:self action:@selector(moreButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _moreButton;
}

- (PLVSASendMessageView *)sendMessageView {
    if (!_sendMessageView) {
        _sendMessageView = [[PLVSASendMessageView alloc] init];
        _sendMessageView.imageEmotionArray =  [PLVSAChatroomViewModel sharedViewModel].imageEmotionArray;
    }
    return _sendMessageView;
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

- (void)linkMicButtonAction {
    self.linkMicButton.enabled = NO;
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(toolbarAreaViewDidTapLinkMicButton:linkMicButtonSelected:)]) {
        [self.delegate toolbarAreaViewDidTapLinkMicButton:self linkMicButtonSelected:self.linkMicButton.selected];
    }
}

- (void)memberButtonAction {
    self.memberBadgeView.hidden = YES;
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(toolbarAreaViewDidTapMemberButton:)]) {
        [self.delegate toolbarAreaViewDidTapMemberButton:self];
    }
}

- (void)moreButtonAction {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(toolbarAreaViewDidTapMoreButton:)]) {
        [self.delegate toolbarAreaViewDidTapMoreButton:self];
    }
}

@end