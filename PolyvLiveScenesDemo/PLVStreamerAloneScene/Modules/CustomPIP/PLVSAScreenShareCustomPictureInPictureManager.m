//
//  PLVSACustomPictureInPictureManager.m
//  PolyvLiveScenesDemo
//
//  Created by Dhan on 2024/3/13.
//  Copyright © 2024 PLV. All rights reserved.
//

#import "PLVSAScreenShareCustomPictureInPictureManager.h"
#import "PLVSAScreenSharePipCustomView.h"
#import <AVKit/AVKit.h>
#import "PLVMultiLanguageManager.h"
#import "PLVSAUtils.h"
#import <PLVFoundationSDK/PLVFoundationSDK.h>

API_AVAILABLE(ios(15.0))
@interface PLVSAScreenShareCustomPictureInPictureManager () <AVPictureInPictureControllerDelegate,PLVSAScreenSharePipCustomViewDelegate>

@property (nonatomic, strong) AVPictureInPictureController *pipController;
@property (nonatomic, strong) PLVSAScreenSharePipCustomView *pipContentView;
@property (nonatomic, strong) UIView *displaySuperview;

@property (nonatomic, strong) UIImageView *backgroundView;
@property (nonatomic, strong) UIImageView *networkStateView;
@property (nonatomic, strong) UILabel *networkStateLabel;
@property (nonatomic, strong) UILabel *contentLabel;

@end

@implementation PLVSAScreenShareCustomPictureInPictureManager

#pragma mark - [ Life Cycle ]

- (instancetype)initWithDisplaySuperview:(UIView *)displaySuperview {
    if (self = [super init]) {
        [self setDisplaySuperview:displaySuperview];
    }
    return self;
}

- (void)dealloc {
    [self destroy];
}

#pragma mark - [ Public Method ]

- (void)setupDisplaySuperview:(UIView *)displaySuperview {
    if (displaySuperview && [displaySuperview isKindOfClass:[UIView class]]) {
        _displaySuperview = displaySuperview;
        self.pipContentView = [[PLVSAScreenSharePipCustomView alloc] init];
        self.pipContentView.delegate = self;
        
        [self.displaySuperview addSubview:self.pipContentView];
        // 设置约束
        [NSLayoutConstraint activateConstraints:@[
            [self.pipContentView.topAnchor constraintEqualToAnchor:self.displaySuperview.topAnchor],
            [self.pipContentView.bottomAnchor constraintEqualToAnchor:self.displaySuperview.bottomAnchor],
            [self.pipContentView.leadingAnchor constraintEqualToAnchor:self.displaySuperview.leadingAnchor],
            [self.pipContentView.trailingAnchor constraintEqualToAnchor:self.displaySuperview.trailingAnchor]
        ]];
        [self setupAudioSession];
        [self setupPipController];
        
        [self.displaySuperview setNeedsLayout];
        [self.displaySuperview layoutIfNeeded];
    }
}

- (void)startPictureInPicture {
    if (!self.pipController.isPictureInPictureActive) {
        [self.pipController startPictureInPicture];
    }
}

- (void)stopPictureInPicture {
    if (self.pipController.isPictureInPictureActive) {
        [self.pipController stopPictureInPicture];
    }
}

- (void)startPictureInPictureSource {
    BOOL delaySetPIP = NO;
    if (!self.pipContentView) {
        self.pipContentView = [[PLVSAScreenSharePipCustomView alloc] init];
        self.pipContentView.delegate = self;
        delaySetPIP = YES;
    }
    if (!self.pipContentView.superview) {
        [self.displaySuperview addSubview:self.pipContentView];
        // 设置约束
        [NSLayoutConstraint activateConstraints:@[
            [self.pipContentView.topAnchor constraintEqualToAnchor:self.displaySuperview.topAnchor],
            [self.pipContentView.bottomAnchor constraintEqualToAnchor:self.displaySuperview.bottomAnchor],
            [self.pipContentView.leadingAnchor constraintEqualToAnchor:self.displaySuperview.leadingAnchor],
            [self.pipContentView.trailingAnchor constraintEqualToAnchor:self.displaySuperview.trailingAnchor]
        ]];
        self.pipController.canStartPictureInPictureAutomaticallyFromInline = _autoEnterPictureInPicture;
    }
    if (delaySetPIP || !self.pipController) {
        [self setupPipController];
    }
    [self.pipContentView startDisplayLink];
}

- (void)stopPictureInPictureSource {
    [self.pipContentView stopDisplayLink];
    [self.pipContentView removeFromSuperview];
    self.pipController = nil;
}

- (void)destroy {
    [self.pipContentView stopDisplayLink];
    [self stopPictureInPicture];
    self.pipContentView = nil;
    self.pipController = nil;
    @try {
        NSError *error = nil;
        [[AVAudioSession sharedInstance] setActive:NO error:&error];
    } @catch (NSException *exception) {
        NSLog(@"AVAudioSession setActive error = %@", exception.description);
    }
}

- (void)updateContent:(NSAttributedString *)content networkState:(PLVBRTCNetworkQuality)networkState {
    if (!content) {
        content = self.noNewMessage;
    }
    self.contentLabel.attributedText = content;
    NSString *title = nil;
    NSString *imageName = nil;

    switch (networkState) {
        case PLVBRTCNetworkQuality_Unknown:
            title = PLVLocalizedString(@"未知");
            imageName = @"plvsa_statusbar_signal_icon_good";
            break;
        case PLVBRTCNetworkQuality_Down:
            title = PLVLocalizedString(@"网络断开");
            imageName = @"plvsa_statusbar_signal_icon_bad";
            break;
        case PLVBRTCNetworkQuality_VBad:
            title = PLVLocalizedString(@"网络很差");
            imageName = @"plvsa_statusbar_signal_icon_bad";
            break;
        case PLVBRTCNetworkQuality_Bad:
            title = PLVLocalizedString(@"网络较差");
            imageName = @"plvsa_statusbar_signal_icon_fine";
            break;
        case PLVBRTCNetworkQuality_Poor:
            title = PLVLocalizedString(@"网络一般");
            imageName = @"plvsa_statusbar_signal_icon_fine";
            break;
        case PLVBRTCNetworkQuality_Good:
            title = PLVLocalizedString(@"网络良好");
            imageName = @"plvsa_statusbar_signal_icon_good";
            break;
        case PLVBRTCNetworkQuality_Excellent:
            title = PLVLocalizedString(@"网络优秀");
            imageName = @"plvsa_statusbar_signal_icon_good";
            break;
    }
    self.networkStateLabel.text = title;
    [self.networkStateView setImage:[PLVSAUtils imageForStatusbarResource:imageName]];
}

- (BOOL)pictureInPictureActive {
    return self.pipController.isPictureInPictureActive;
}

#pragma mark - [ Private Method ]

- (void)setupAudioSession {
    @try {
        NSError *error = nil;
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:&error];
        [[AVAudioSession sharedInstance] setActive:YES withOptions:1 error:&error];
    } @catch (NSException *exception) {
        NSLog(@"AVAudioSession error = %@", exception.description);
    }
}

- (void)setupPipController {
    if (@available(iOS 15.0, *)) {
        AVPictureInPictureControllerContentSource *source = (AVPictureInPictureControllerContentSource *)[self.pipContentView pipContentSource];
        self.pipController = [[AVPictureInPictureController alloc] initWithContentSource:source];
        self.pipController.delegate = self;
        self.pipController.requiresLinearPlayback = YES;
        if (@available(iOS 14.2, *)) {
            self.pipController.canStartPictureInPictureAutomaticallyFromInline = _autoEnterPictureInPicture;
        }
        
        [self.pipController setValue:@(1) forKey:@"controlsStyle"];
    }
}

- (void)setAutoEnterPictureInPicture:(BOOL)autoEnterPictureInPicture {
    _autoEnterPictureInPicture = autoEnterPictureInPicture;
    if (@available(iOS 14.2, *)) {
        self.pipController.canStartPictureInPictureAutomaticallyFromInline = autoEnterPictureInPicture;
    }
}

#pragma mark - Getter & Setter

- (UIImageView *)backgroundView {
    if (!_backgroundView) {
        _backgroundView = [[UIImageView alloc] init];
        _backgroundView.image = [PLVSAUtils imageForLiveroomResource:@"plvsa_screen_share_pip_background"];
        _backgroundView.translatesAutoresizingMaskIntoConstraints = NO;
        _backgroundView.contentMode = UIViewContentModeScaleAspectFill;
    }
    return _backgroundView;
}

- (UIImageView *)networkStateView {
    if (!_networkStateView) {
        _networkStateView = [[UIImageView alloc] init];
        _networkStateView.image = [PLVSAUtils imageForStatusbarResource:@"plvsa_statusbar_signal_icon_good"];
        _networkStateView.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _networkStateView;
}

- (UILabel *)networkStateLabel {
    if (!_networkStateLabel) {
        _networkStateLabel = [[UILabel alloc] init];
        _networkStateLabel.text = PLVLocalizedString(@"未知");
        _networkStateLabel.textColor = [PLVColorUtil colorFromHexString:@"#FFFFFF"];
        _networkStateLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:12];
        _networkStateLabel.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _networkStateLabel;
}

- (UILabel *)contentLabel {
    if (!_contentLabel) {
        _contentLabel = [[UILabel alloc] init];
        _contentLabel.attributedText = self.noNewMessage;
        _contentLabel.textAlignment = NSTextAlignmentLeft;
        _contentLabel.numberOfLines = 1;
        _contentLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        _contentLabel.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _contentLabel;
}

- (NSAttributedString *)noNewMessage {
    NSString *string = PLVLocalizedString(@"暂无聊天消息");
    NSDictionary *attributes = @{NSForegroundColorAttributeName: [PLVColorUtil colorFromHexString:@"#FFFFFF" alpha:0.6], NSFontAttributeName: [UIFont fontWithName:@"PingFangSC-Regular" size:12]};
    return [[NSAttributedString alloc] initWithString:string attributes:attributes];
}

#pragma mark - AVPictureInPictureControllerDelegate

- (void)pictureInPictureControllerWillStartPictureInPicture:(AVPictureInPictureController *)pictureInPictureController {
    // 注意是 first window，不是 last window 也不是 key window
    UIWindow *firstWindow = [UIApplication sharedApplication].windows.firstObject;
    // 把自定义view放到画中画上
    [firstWindow addSubview:self.backgroundView];
    [firstWindow addSubview:self.networkStateView];
    [firstWindow addSubview:self.networkStateLabel];
    [firstWindow addSubview:self.contentLabel];
    
    // 设置 backgroundView 的约束，使其与父视图的 bounds 相同
    [NSLayoutConstraint activateConstraints:@[
        [self.backgroundView.leadingAnchor constraintEqualToAnchor:firstWindow.leadingAnchor],
        [self.backgroundView.trailingAnchor constraintEqualToAnchor:firstWindow.trailingAnchor],
        [self.backgroundView.topAnchor constraintEqualToAnchor:firstWindow.topAnchor],
        [self.backgroundView.bottomAnchor constraintEqualToAnchor:firstWindow.bottomAnchor]
    ]];

    // 设置 networkStateView 的约束
    [NSLayoutConstraint activateConstraints:@[
        [self.networkStateView.leadingAnchor constraintEqualToAnchor:firstWindow.leadingAnchor constant:36],
        [self.networkStateView.centerYAnchor constraintEqualToAnchor:self.networkStateLabel.centerYAnchor],
        [self.networkStateView.widthAnchor constraintEqualToConstant:12],
        [self.networkStateView.heightAnchor constraintEqualToConstant:12]
    ]];

    // 设置 networkStateLabel 的约束
    [NSLayoutConstraint activateConstraints:@[
        [self.networkStateLabel.leadingAnchor constraintEqualToAnchor:self.networkStateView.trailingAnchor constant:4],
        [self.networkStateLabel.topAnchor constraintEqualToAnchor:firstWindow.topAnchor constant:5],
        [self.networkStateLabel.trailingAnchor constraintEqualToAnchor:firstWindow.trailingAnchor],
        [self.networkStateLabel.bottomAnchor constraintEqualToAnchor:self.contentLabel.topAnchor constant:-5],
        [self.networkStateLabel.heightAnchor constraintEqualToAnchor:self.contentLabel.heightAnchor]
    ]];

    // 设置 contentLabel 的约束
    [NSLayoutConstraint activateConstraints:@[
        [self.contentLabel.leadingAnchor constraintEqualToAnchor:firstWindow.leadingAnchor constant:8],
        [self.contentLabel.topAnchor constraintEqualToAnchor:self.networkStateLabel.bottomAnchor constant:5],
        [self.contentLabel.bottomAnchor constraintEqualToAnchor:firstWindow.bottomAnchor constant:-12],
        [self.contentLabel.trailingAnchor constraintEqualToAnchor:firstWindow.trailingAnchor constant:-8]
    ]];
}

- (void)pictureInPictureControllerDidStartPictureInPicture:(AVPictureInPictureController *)pictureInPictureController {
    
}

- (void)pictureInPictureControllerDidStopPictureInPicture:(AVPictureInPictureController *)pictureInPictureController {
    if (@available(iOS 14.2, *)) {
        self.pipController.canStartPictureInPictureAutomaticallyFromInline = _autoEnterPictureInPicture;
    }
}

- (void)pictureInPictureController:(AVPictureInPictureController *)pictureInPictureController restoreUserInterfaceForPictureInPictureStopWithCompletionHandler:(void (^)(BOOL))completionHandler{
    if (@available(iOS 14.2, *)) {
        self.pipController.canStartPictureInPictureAutomaticallyFromInline = _autoEnterPictureInPicture;
    }
    completionHandler(YES);
}

- (void)pictureInPictureController:(AVPictureInPictureController *)pictureInPictureController failedToStartPictureInPictureWithError:(NSError *)error {
    
}

#pragma mark - PLVSAPipCustomViewDelegate
- (void)pipCustomViewContentWannaUpdate {
    if (self.delegate && [self.delegate respondsToSelector:@selector(PLVSAScreenShareCustomPictureInPictureManager_needUpdateContent)]) {
        [self.delegate PLVSAScreenShareCustomPictureInPictureManager_needUpdateContent];
    }
}

@end
