//
//  PLVECPalybackHomePageView.m
//  PolyvLiveEcommerceDemo
//
//  Created by ftao on 2020/5/21.
//  Copyright © 2020 polyv. All rights reserved.
//

#import "PLVECPalybackHomePageView.h"
#import <PLVLiveScenesSDK/PLVSocketWrapper.h>
#import <PolyvFoundationSDK/PLVFdUtil.h>
#import "PLVECLiveRoomInfoView.h"
#import "PLVECSwitchView.h"
#import "PLVECBulletinView.h"
#import "PLVECPlayerContolView.h"
#import "PLVECUtils.h"

@interface PLVECPalybackHomePageView () <PLVPlayerContolViewDelegate, PLVPlayerSwitchViewDelegate, PLVSocketLoginManagerDelegate, PLVSocketListenerProtocol>

@property (nonatomic, weak) id<PLVPalybackHomePageViewDelegate> delegate;
@property (nonatomic, strong) PLVLiveRoomData *roomData;
@property (nonatomic, strong) PLVECLiveRoomInfoView *liveRoomInfoView;
@property (nonatomic, strong) PLVECPlayerContolView *playerContolView;
@property (nonatomic, strong) PLVECSwitchView *switchView;
@property (nonatomic, strong) UIButton *moreButton;

/// 回放视频时长
@property (nonatomic, assign) NSTimeInterval duration;

@property (nonatomic, strong) PLVSocketLoginManager *socketLoginManager;

@end

@implementation PLVECPalybackHomePageView

- (instancetype)initWithDelegate:(id<PLVPalybackHomePageViewDelegate>)delegate roomData:(PLVLiveRoomData *)roomData {
    self = [super init];
    if (self) {
        self.delegate = delegate;
        self.roomData = roomData;
        
        [self setupUI];
        
        // Socket 登陆管理
        self.socketLoginManager = [[PLVSocketLoginManager alloc] initWithDelegate:self roomData:self.roomData];
        [self.socketLoginManager loginSocketServer];
        
        [[PLVSocketWrapper sharedSocketWrapper] addListener:self];
    }
    return self;
}

- (void)setupUI {
    self.liveRoomInfoView = [[PLVECLiveRoomInfoView alloc] initWithFrame:CGRectMake(15, 10, 118, 36)];
    [self addSubview:self.liveRoomInfoView];
    
    self.playerContolView = [[PLVECPlayerContolView alloc] init];
    self.playerContolView.delegate = self;
    [self addSubview:self.playerContolView];
    
    self.moreButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.moreButton.bounds = CGRectMake(0, 0, 32.0, 32.0);
    [self.moreButton setImage:[PLVECUtils imageForWatchResource:@"plv_more_btn"] forState:UIControlStateNormal];
    [self.moreButton addTarget:self action:@selector(moreButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.moreButton];
        
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat buttonWidth = 32.f;
    self.moreButton.frame = CGRectMake(CGRectGetWidth(self.bounds)-buttonWidth-15, CGRectGetHeight(self.bounds)-buttonWidth-15-P_SafeAreaBottomEdgeInsets(), buttonWidth, buttonWidth);
    self.playerContolView.frame = CGRectMake(0, CGRectGetHeight(self.bounds)-41-P_SafeAreaBottomEdgeInsets(), CGRectGetMinX(self.moreButton.frame)-8, 41);
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if (_switchView && !_switchView.hidden) {
        _switchView.hidden = YES;
    }
}

#pragma mark - Getter

- (PLVECSwitchView *)switchView {
    if (!_switchView) {
        CGFloat height = 130 + P_SafeAreaBottomEdgeInsets();
        CGRect switchViewFrame = CGRectMake(0, CGRectGetHeight(self.bounds)-height, CGRectGetWidth(self.bounds), height);
        
        _switchView = [[PLVECSwitchView alloc] initWithFrame:switchViewFrame];
        _switchView.titleLable.text = @"播放速度";
        _switchView.selectedIndex = 1;
        _switchView.items = @[@"0.5x", @"1.0x", @"1.25x", @"1.5x", @"2.0x"];
        _switchView.delegate = self;
        [self addSubview:_switchView];
        
        [_switchView setCloseButtonActionBlock:^(PLVECBottomView * _Nonnull view) {
            [view setHidden:YES];
        }];
    }
    return _switchView;
}

#pragma mark - Public

- (void)updateChannelInfo:(NSString *)publisher coverImage:(NSString *)coverImage {
    self.liveRoomInfoView.publisherLB.text = publisher;
    [PLVFdUtil setImageWithURL:[NSURL URLWithString:coverImage] inImageView:self.liveRoomInfoView.coverImageView completed:^(UIImage *image, NSError *error, NSURL *imageURL) {
        if (error) {
            NSLog(@"设置头像失败：%@\n%@",imageURL,error.localizedDescription);
        }
    }];
}

- (void)updateWatchViewCount:(NSUInteger)watchViewCount {
    self.liveRoomInfoView.pageViewLB.text = [NSString stringWithFormat:@"%lu",(unsigned long)watchViewCount];
}

- (void)updateVideoDuration:(NSTimeInterval)duration {
    self.duration = duration;
    if (duration >= 0) {
        self.playerContolView.duration = duration;
    }
}

- (void)updatePlayButtonState:(BOOL)playing {
    if (!self.playerContolView.sliderDragging) {
        self.playerContolView.playButton.selected = playing;
    }
}

- (void)updateDowloadProgress:(CGFloat)dowloadProgress playedProgress:(CGFloat)playedProgress currentPlaybackTime:(NSString *)currentPlaybackTime duration:(NSString *)duration {
    self.playerContolView.currentTimeLabel.text = currentPlaybackTime;
    
    if (! [self.playerContolView.totalTimeLabel.text isEqualToString:duration]) {
        self.playerContolView.totalTimeLabel.text = duration;
        [self.playerContolView setNeedsLayout];
    }
    
    if (!self.playerContolView.sliderDragging) {
        self.playerContolView.progressSlider.value = playedProgress;
    }
}

#pragma mark - Action

- (void)moreButtonAction:(UIButton *)button {
    self.switchView.hidden = NO;
}

#pragma mark - <PLVSocketLoginManagerDelegate>

- (void)socketLoginManager:(PLVSocketLoginManager *)socketLoginManager authorizationVerificationFailed:(PLVLiveRoomErrorReason)reason message:(NSString *)message {
}

- (void)socketLoginManager_loginSuccess:(PLVSocketLoginManager *)socketLoginManager {
    // [PLVLiveUtil showHUDWithTitle:@"登陆成功" detail:@"" view:self.view];
}

#pragma mark - PLVSocketListener Protocol

- (void)socket:(id<PLVSocketIOProtocol>)socket didReceiveMessage:(nonnull NSString *)string jsonDict:(nonnull NSDictionary *)jsonDict {
    NSString *subEvent = PLV_SafeStringForDictKey(jsonDict, @"EVENT");
    if ([subEvent isEqualToString:@"BULLETIN"]) { //
        [self bulletinEvent:jsonDict];
    } else if ([subEvent isEqualToString:@"REMOVE_BULLETIN"]) { //
        [self removeBulletinEvent:jsonDict];
    }
}

- (void)bulletinEvent:(NSDictionary *)jsonDict {
    NSString *content = PLV_SafeStringForDictKey(jsonDict, @"content");
    PLVECBulletinView *bulletinView = [[PLVECBulletinView alloc] init];
    bulletinView.frame = CGRectMake(15, CGRectGetMaxY(self.liveRoomInfoView.frame)+15, CGRectGetWidth(self.bounds)-30, 24);
    [bulletinView showBulletinView:content duration:5.0];
    [self addSubview:bulletinView];
    
    if ([self.delegate respondsToSelector: @selector(palyback_homePageView:receiveBulletinMessage:open:)]) {
        [self.delegate palyback_homePageView:self receiveBulletinMessage:content open:1];
    }
}

- (void)removeBulletinEvent:(NSDictionary *)jsonDict {
    if ([self.delegate respondsToSelector: @selector(palyback_homePageView:receiveBulletinMessage:open:)]) {
        [self.delegate palyback_homePageView:self receiveBulletinMessage:nil open:0];
    }
}

#pragma mark - <PLVPlayerContolViewDelegate>

- (void)playerContolView:(PLVECPlayerContolView *)playerContolView switchPause:(BOOL)pause {
    if ([self.delegate respondsToSelector:@selector(homePageView:switchPause:)]) {
        [self.delegate homePageView:self switchPause:pause];
    }
}

- (void)playerContolViewSeeking:(PLVECPlayerContolView *)playerContolView {
    NSTimeInterval interval = self.duration * playerContolView.progressSlider.value;
    
    // 拖动进度条后，同步当前进度时间
    [self updateDowloadProgress:0
                 playedProgress:playerContolView.progressSlider.value
            currentPlaybackTime:[PLVFdUtil secondsToString:interval]
                       duration:self.playerContolView.totalTimeLabel.text];
    
    if ([self.delegate respondsToSelector:@selector(homePageView:seekToTime:)]) {
        [self.delegate homePageView:self seekToTime:interval];
    }
}

#pragma mark - <PLVPlayerSwitchViewDelegate>

- (void)playerSwitchView:(PLVECSwitchView *)playerSwitchView didSelectItem:(NSString *)item {
    [playerSwitchView setHidden:YES];
    CGFloat speed = [[item substringToIndex:item.length] floatValue];
    speed = MIN(2.0, MAX(0.5, speed));
    if ([self.delegate respondsToSelector:@selector(homePageView:switchSpeed:)]) {
        [self.delegate homePageView:self switchSpeed:speed];
    }
}

@end
