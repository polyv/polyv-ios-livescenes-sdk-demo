//
//  PLVLSChatroomToolbar.m
//  PLVLiveStreamerDemo
//
//  Created by MissYasiky on 2021/3/15.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVLSChatroomToolbar.h"

/// 工具类
#import "PLVLSUtils.h"

static CGFloat kToolbarWidth = 36.0;
static CGFloat kToolbarHeight = 36.0;

@interface PLVLSChatroomToolbar ()

/// UI
@property (nonatomic, strong) UIView *bgView; // 底部半透明圆角背景
@property (nonatomic, strong) UIButton *foldButton; // 左侧折叠/展开按钮
@property (nonatomic, strong) UIView *buttonsContainer; // 除折叠按钮外，其他按钮的父视图
@property (nonatomic, strong) UIButton *microphoneButton; // 麦克风开关按钮
@property (nonatomic, strong) UIButton *cameraButton; // 摄像头开关按钮
@property (nonatomic, strong) UIButton *cameraSwitchButton; // 摄像头切换按钮
@property (nonatomic, strong) UIButton *sendMsgButton; // 发送消息按钮

@end

@implementation PLVLSChatroomToolbar

#pragma mark - Life Cycle

- (instancetype)init {
    self = [super init];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        
        [self addSubview:self.bgView];
        [self addSubview:self.foldButton];
        [self addSubview:self.buttonsContainer];
        
        [self.buttonsContainer addSubview:self.microphoneButton];
        [self.buttonsContainer addSubview:self.cameraButton];
        [self.buttonsContainer addSubview:self.cameraSwitchButton];
        [self.buttonsContainer addSubview:self.sendMsgButton];
        
        [self foldButtonAction];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    if (self.foldButton.selected) {
        self.bgView.frame = self.bounds;
    } else {
        self.bgView.frame = CGRectMake(0, 0, kToolbarWidth, kToolbarHeight);
    }
    
    self.foldButton.frame = CGRectMake(0, 0, kToolbarWidth, kToolbarHeight);
    
    CGFloat originY = CGRectGetMaxX(self.foldButton.frame);
    self.buttonsContainer.frame = CGRectMake(originY, 0, self.bounds.size.width - originY, 36);
    self.microphoneButton.frame = CGRectMake(5, 0, kToolbarWidth, kToolbarHeight);
    self.cameraButton.frame = CGRectMake(CGRectGetMaxX(self.microphoneButton.frame), 0, kToolbarWidth, kToolbarHeight);
    self.cameraSwitchButton.frame = CGRectMake(CGRectGetMaxX(self.cameraButton.frame), 0, kToolbarWidth, kToolbarHeight);
    
    originY = CGRectGetMaxX(self.cameraSwitchButton.frame) + 5;
    self.sendMsgButton.frame = CGRectMake(originY, 0, self.buttonsContainer.frame.size.width - originY, kToolbarHeight);
}

#pragma mark - Getter

- (UIView *)bgView {
    if (!_bgView) {
        _bgView = [[UIView alloc] init];
        _bgView.backgroundColor = [UIColor colorWithRed:0x1b/255.0 green:0x20/255.0 blue:0x2d/255.0 alpha:0.4];
        _bgView.layer.cornerRadius = 18;
        _bgView.layer.masksToBounds = YES;
    }
    return _bgView;
}

- (UIButton *)foldButton {
    if (!_foldButton) {
        _foldButton = [UIButton buttonWithType:UIButtonTypeCustom];
        UIImage *normalImage = [PLVLSUtils imageForChatroomResource:@"plvls_chatroom_toolbar_btn"];
        [_foldButton setImage:normalImage forState:UIControlStateNormal];
        [_foldButton addTarget:self action:@selector(foldButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _foldButton;
}

- (UIView *)buttonsContainer {
    if (!_buttonsContainer) {
        _buttonsContainer = [[UIView alloc] init];
        
        UIView *leftLine = [[UIView alloc] initWithFrame:CGRectMake(0, 8, 1, 20)];
        leftLine.backgroundColor = [UIColor colorWithRed:0xf0/255.0 green:0xf1/255.0 blue:0xf5/255.0 alpha:0.08];
        [_buttonsContainer addSubview:leftLine];
        
        UIView *rightLine = [[UIView alloc] initWithFrame:CGRectMake(1 + 4 + kToolbarWidth * 3 + 4, 8, 1, 20)];
        rightLine.backgroundColor = [UIColor colorWithRed:0xf0/255.0 green:0xf1/255.0 blue:0xf5/255.0 alpha:0.08];
        [_buttonsContainer addSubview:rightLine];
        
        _buttonsContainer.hidden = YES;
    }
    return _buttonsContainer;
}

- (UIButton *)microphoneButton {
    if (!_microphoneButton) {
        _microphoneButton = [UIButton buttonWithType:UIButtonTypeCustom];
        UIImage *normalImage = [PLVLSUtils imageForChatroomResource:@"plvls_mic_open_btn"];
        UIImage *selectedImage = [PLVLSUtils imageForChatroomResource:@"plvls_mic_close_btn"];
        [_microphoneButton setImage:normalImage forState:UIControlStateNormal];
        [_microphoneButton setImage:selectedImage forState:UIControlStateSelected];
        [_microphoneButton addTarget:self action:@selector(microphoneButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _microphoneButton;
}

- (UIButton *)cameraButton {
    if (!_cameraButton) {
        _cameraButton = [UIButton buttonWithType:UIButtonTypeCustom];
        UIImage *normalImage = [PLVLSUtils imageForChatroomResource:@"plvls_camera_open_btn"];
        UIImage *selectedImage = [PLVLSUtils imageForChatroomResource:@"plvls_camera_close_btn"];
        [_cameraButton setImage:normalImage forState:UIControlStateNormal];
        [_cameraButton setImage:selectedImage forState:UIControlStateSelected];
        [_cameraButton addTarget:self action:@selector(cameraButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _cameraButton;
}

- (UIButton *)cameraSwitchButton {
    if (!_cameraSwitchButton) {
        _cameraSwitchButton = [UIButton buttonWithType:UIButtonTypeCustom];
        UIImage *normalImage = [PLVLSUtils imageForChatroomResource:@"plvls_camera_switch_open_btn"];
        UIImage *disabledImage = [PLVLSUtils imageForChatroomResource:@"plvls_camera_switch_close_btn"];
        [_cameraSwitchButton setImage:normalImage forState:UIControlStateNormal];
        [_cameraSwitchButton setImage:disabledImage forState:UIControlStateDisabled];
        [_cameraSwitchButton addTarget:self action:@selector(cameraSwitchButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _cameraSwitchButton;
}

- (UIButton *)sendMsgButton {
    if (!_sendMsgButton) {
        _sendMsgButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_sendMsgButton setTitle:@"有话要说..." forState:UIControlStateNormal];
        _sendMsgButton.titleLabel.font = [UIFont systemFontOfSize:14];
        UIColor *color = [UIColor colorWithRed:0xf0/255.0 green:0xf1/255.0 blue:0xf5/255.0 alpha:0.6];
        [_sendMsgButton setTitleColor:color forState:UIControlStateNormal];
        [_sendMsgButton addTarget:self action:@selector(sendMsgButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _sendMsgButton;
}

#pragma mark - Action

- (void)foldButtonAction {
    [self hideToolbarButton:self.foldButton.selected];
}

- (void)microphoneButtonAction:(id)sender {
    UIButton *button = (UIButton *)sender;
    button.selected = !button.selected;
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideButton) object:nil];
    [self performSelector:@selector(hideButton) withObject:nil afterDelay:3.0];
    
    if (self.didTapMicrophoneButton) {
        self.didTapMicrophoneButton(!button.selected);
    }
}

- (void)cameraButtonAction:(id)sender {
    UIButton *button = (UIButton *)sender;
    button.selected = !button.selected;
    
    self.cameraSwitchButton.enabled = !self.cameraButton.selected;
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideButton) object:nil];
    [self performSelector:@selector(hideButton) withObject:nil afterDelay:3.0];
    
    if (self.didTapCameraButton) {
        self.didTapCameraButton(!button.selected);
    }
}

- (void)cameraSwitchButtonAction:(id)sender {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideButton) object:nil];
    [self performSelector:@selector(hideButton) withObject:nil afterDelay:3.0];
    
    if (self.didTapCameraSwitchButton) {
        self.didTapCameraSwitchButton();
    }
}

- (void)sendMsgButtonAction:(id)sender {
    if (self.didTapSendMessageButton) {
        self.didTapSendMessageButton();
    }
}

#pragma mark - Public

- (void)microphoneButtonOpen:(BOOL)open {
    self.microphoneButton.selected = !open;
}

- (void)cameraButtonOpen:(BOOL)open {
    self.cameraButton.selected = !open;
    self.cameraSwitchButton.enabled = open;
}

- (void)cameraSwitchButtonFront:(BOOL)front{
    self.cameraSwitchButton.selected = !front;
}

- (void)hideButton {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideButton) object:nil];
    [self hideToolbarButton:YES];
}

#pragma mark - Private

- (void)hideToolbarButton:(BOOL)hide {
    self.foldButton.selected = !hide;
    
    if (hide) {
        self.bgView.frame = CGRectMake(0, 0, 36, 36);
    } else {
        self.bgView.frame = self.bounds;
    }
    self.buttonsContainer.hidden = hide;
    
    if (!hide) {
        [self performSelector:@selector(hideButton) withObject:nil afterDelay:3.0];
    }
}

@end
