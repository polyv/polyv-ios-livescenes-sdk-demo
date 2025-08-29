//
//  PLVLCLinkMicWindowCell.m
//  PLVLiveScenesDemo
//
//  Created by Lincal on 2020/8/6.
//  Copyright © 2020 PLV. All rights reserved.
//

#import "PLVLCLinkMicWindowCell.h"

#import "PLVLCUtils.h"
#import "PLVMultiLanguageManager.h"
#import "PLVLinkMicOnlineUser+LC.h"
#import <PLVFoundationSDK/PLVFoundationSDK.h>
#import <PLVLiveScenesSDK/PLVConsoleLogger.h>
#import "PLVRoomDataManager.h"

@interface PLVLCLinkMicWindowCell ()

#pragma mark 状态
@property (nonatomic, assign) PLVLCLinkMicWindowCellLayoutType layoutType;

#pragma mark 数据
@property (nonatomic, weak) PLVLinkMicOnlineUser * userModel;

#pragma mark UI
/// view hierarchy
///
/// 状态一 显示RTC画面
/// (PLVLCLinkMicWindowCell) self
/// └── (UIView) contentView
///    └── (UIView) contentBackgroudView (lowest)
///      └── (PLVLCLinkMicWindowCellContentView) mediaView (top)
///          ├── (UIView) contentBackgroudView (lowest)
///            └── (PLVLCLinkMicCanvasView) canvasView
///          │
///          ├── (CAGradientLayer) shadowLayerLeft
///          ├── (CAGradientLayer) shadowLayer
///          ├── (UIButton) micButton
///          └── (UILabel) nicknameLabel
///
/// 状态二 (显示PPT画面时；contentBackgroudView 将移至最上层，并承载一个未知具体类型的外部view):
/// (PLVLCLinkMicWindowCell) self
/// └── (UIView) contentView
///    └── (UIView) contentBackgroudView (lowest)
///      └── (UIView) unknown external View (top)
@property (nonatomic, strong) UIView * contentBackgroudView;      // 内容背景视图 (负责承载 不同类型的内容画面[RTC画面、PPT画面]；直接决定了’内容画面‘在Cell中的布局、图层、圆角)
@property (nonatomic, strong) PLVLCLinkMicWindowCellContentView *rtcContentView; // 负责展示rtc、各种控件的视图

@end

@implementation PLVLCLinkMicWindowCell

#pragma mark - [ Life Period ]
- (void)dealloc{
    PLV_LOG_INFO(PLVConsoleLogModuleTypeLinkMic,@"%s",__FUNCTION__);
}

- (instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        [self setupUI];
    }
    return self;
}

- (void)layoutSubviews{
    [super layoutSubviews];
    
    self.contentBackgroudView.frame = self.contentView.bounds;
    if ([self.rtcContentView.superview isEqual:self.contentBackgroudView]) {
        self.rtcContentView.frame = self.contentBackgroudView.bounds;
    }
}

#pragma mark - [ Public Methods ]
- (void)setModel:(PLVLinkMicOnlineUser *)userModel{
    /// 设置 数据模型
    self.userModel = userModel;
    [self.rtcContentView setModel:userModel];
}

/// 切换至 显示默认内容视图
- (void)switchToShowDefaultRtcContentView{
    // 移除 contentBackgroudView 上的外部视图
    [self removeSubview:self.contentBackgroudView];
    
    // contentBackgroudView 承载 rtcContentView
    [self contentBackgroudViewAddView:self.rtcContentView];
    
    self.layoutType = PLVLCLinkMicWindowCellLayoutType_Default;
    
    self.userModel.canvasView.logoImageView.userInteractionEnabled = NO;
    self.rtcContentView.showInWindowCell = YES;
}

/// 切换至 显示外部内容视图
- (void)switchToShowExternalContentView:(UIView *)externalContentView{
    // contentBackgroudView 承载外部未知具体类型的视图
    [self contentBackgroudViewAddView:externalContentView];

    self.layoutType = PLVLCLinkMicWindowCellLayoutType_External;
    
    self.userModel.canvasView.logoImageView.userInteractionEnabled = YES;
    self.rtcContentView.showInWindowCell = NO;
}

#pragma mark - [ Private Methods ]
- (void)removeSubview:(UIView *)superview{
    for (UIView * subview in superview.subviews) { [subview removeFromSuperview]; }
}

- (void)contentBackgroudViewAddView:(UIView *)contentView{
    contentView.frame = self.contentBackgroudView.bounds;
    contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.contentBackgroudView addSubview:contentView];
}

#pragma mark UI
- (void)setupUI{
    // 添加 视图
    [self.contentView addSubview:self.contentBackgroudView];
    // 默认rtc视图
    [self.contentBackgroudView addSubview:self.rtcContentView];
}

#pragma mark Getter
- (PLVLCLinkMicWindowCellContentView *)rtcContentView{
    if (!_rtcContentView) {
        _rtcContentView = [[PLVLCLinkMicWindowCellContentView alloc] init];
        _rtcContentView.clipsToBounds = YES;
        _rtcContentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }
    return _rtcContentView;
}

- (UIView *)contentBackgroudView{
    if (!_contentBackgroudView) {
        _contentBackgroudView = [[UIView alloc]init];
        _contentBackgroudView.clipsToBounds = YES;
    }
    return _contentBackgroudView;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    // 如果当前视图的透明度为 0，则不接收触摸事件
    if (self.alpha < 0.01 || !self.userInteractionEnabled) {
        return nil;
    }

    // 检查触摸点是否在当前视图内
    if ([self pointInside:point withEvent:event]) {
        return self; // 返回当前视图
    }

    return nil; // 如果不在当前视图内，返回 nil
}

@end

@interface PLVLCLinkMicWindowCellContentView ()

#pragma mark 数据
@property (nonatomic, weak) PLVLinkMicOnlineUser * userModel;
@property (nonatomic, assign, readonly) BOOL isOnlyAudio;

#pragma mark UI
@property (nonatomic, strong) UIView * contentBackgroudView;      // 内容背景视图 (负责承载 RTC画面；直接决定了’内容画面‘在Cell中的布局、图层、圆角)
@property (nonatomic, strong) CAGradientLayer * shadowLayerLeft;  // 左边阴影背景 (负责展示 阴影背景)
@property (nonatomic, strong) CAGradientLayer * shadowLayer;      // 阴影背景   (负责展示 阴影背景)
@property (nonatomic, strong) UIButton * micButton;               // 麦克风按钮 (负责展示 不同状态下的麦克风图标)
@property (nonatomic, strong) UILabel * nicknameLabel;            // 昵称文本框 (负责展示 用户昵称)

@end

@implementation PLVLCLinkMicWindowCellContentView

#pragma mark - [ Life Period ]
- (void)dealloc{
    NSLog(@"%s",__FUNCTION__);
}

- (instancetype)init {
    if (self = [super init]) {
        [self setupUI];
        self.showInWindowCell = YES;
    }
    return self;
}

- (void)layoutSubviews{
    [super layoutSubviews];
    CGFloat cellWidth = CGRectGetWidth(self.bounds);
    CGFloat cellHeight = CGRectGetHeight(self.bounds);
    
    self.contentBackgroudView.frame = self.bounds;
    self.contentBackgroudView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    CGFloat shadowLayerLeftWidth = 16.0;
    self.shadowLayerLeft.frame = CGRectMake(0, 0, shadowLayerLeftWidth, cellHeight);
    
    CGFloat shadowLayerHeight = 24.0;
    self.shadowLayer.frame = CGRectMake(0, cellHeight - shadowLayerHeight, cellWidth, shadowLayerHeight);
    
    CGFloat micButtonHeight = 14.0;
    self.micButton.frame = CGRectMake(4, cellHeight - 3 - micButtonHeight, micButtonHeight, micButtonHeight);
    
    CGFloat nicknameLabelHeight = 17.0;
    self.nicknameLabel.frame = CGRectMake(CGRectGetMaxX(self.micButton.frame) + 2,
                                          cellHeight - 2 - nicknameLabelHeight,
                                          cellWidth - 20 - 8,
                                          nicknameLabelHeight);

    BOOL fullScreen = [UIScreen mainScreen].bounds.size.width > [UIScreen mainScreen].bounds.size.height;
    [self windowCellCornerShow:fullScreen];
}

#pragma mark - [ Public Methods ]
- (void)setModel:(PLVLinkMicOnlineUser *)userModel{
    // 设置
    /// 数据模型
    self.userModel = userModel;
    
    /// 昵称文本
    NSString * actor = [PLVFdUtil checkStringUseable:userModel.actor] ? [NSString stringWithFormat:@"%@-",userModel.actor] : @"";
    self.nicknameLabel.text = [PLVFdUtil checkStringUseable:userModel.nickname] ? [NSString stringWithFormat:@"%@%@",actor,userModel.nickname] : [NSString stringWithFormat:@"unknown%@",userModel.linkMicUserId];

    /// 麦克风图标
    self.micButton.selected = !userModel.currentMicOpen;
    __weak typeof(self) weakSelf = self;
    userModel.micOpenChangedBlock = ^(PLVLinkMicOnlineUser * _Nonnull onlineUser) {
        if ([onlineUser.linkMicUserId isEqualToString:weakSelf.userModel.linkMicUserId]) {
            weakSelf.micButton.selected = !onlineUser.currentMicOpen;
        }
    };
    
    /// 摄像画面
    [self contentBackgroudViewAddView:userModel.canvasView];
    [userModel.canvasView rtcViewShow:userModel.currentCameraShouldShow];
    if (self.isOnlyAudio && userModel.isRealMainSpeaker) {
        [userModel.canvasView setSplashImageWithURLString:[PLVRoomDataManager sharedManager].roomData.menuInfo.splashImg];
        [userModel.canvasView rtcViewShow:NO];
    }
    userModel.cameraShouldShowChangedBlock = ^(PLVLinkMicOnlineUser * _Nonnull onlineUser) {
        [onlineUser.canvasView rtcViewShow:onlineUser.currentCameraShouldShow];
    };
    
    /// 音量
    [self setMicButtonNormalImageWithVolume:userModel.currentVolume];
    userModel.volumeChangedBlock = ^(PLVLinkMicOnlineUser * _Nonnull onlineUser) {
        if ([onlineUser.linkMicUserId isEqualToString:weakSelf.userModel.linkMicUserId]) {
            [weakSelf setMicButtonNormalImageWithVolume:onlineUser.currentVolume];
        }
    };
    
    [self updateControlShowStatus];
}

#pragma mark - [ Private Methods ]
- (UIImage *)getImageWithName:(NSString *)imageName{
    return [PLVLCUtils imageForLinkMicResource:imageName];
}

- (void)contentBackgroudViewAddView:(UIView *)contentView{
    contentView.frame = self.contentBackgroudView.bounds;
    contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.contentBackgroudView addSubview:contentView];
}

- (void)setMicButtonNormalImageWithVolume:(CGFloat)micVolume{
    int volumeLevel = ((int)(micVolume * 100 / 10)) * 10;
    NSString * micImageName = [NSString stringWithFormat:@"plvlc_linkmic_mic_volume_%d",volumeLevel];
    [self.micButton setImage:[self getImageWithName:micImageName] forState:UIControlStateNormal];
}

- (void)windowCellCornerShow:(BOOL)cornerShow{
    if (cornerShow) {
        self.contentBackgroudView.layer.cornerRadius = 8.0;
    }else{
        self.contentBackgroudView.layer.cornerRadius = 0;
    }
}

- (void)updateControlShowStatus {
    BOOL showControl = self.showInWindowCell || self.userModel.userType != PLVSocketUserTypeTeacher;
    self.nicknameLabel.hidden = !showControl;
    self.micButton.hidden = !showControl;
    self.shadowLayerLeft.hidden = !self.showInWindowCell;
    self.shadowLayer.hidden = !self.showInWindowCell;
}

#pragma mark UI
- (void)setupUI{
    // 添加 视图
    [self addSubview:self.contentBackgroudView];
    [self.layer addSublayer:self.shadowLayerLeft];
    [self.layer addSublayer:self.shadowLayer];
    [self addSubview:self.micButton];
    [self addSubview:self.nicknameLabel];
}

#pragma mark Getter
- (UIView *)contentBackgroudView{
    if (!_contentBackgroudView) {
        _contentBackgroudView = [[UIView alloc]init];
        _contentBackgroudView.clipsToBounds = YES;
    }
    return _contentBackgroudView;
}

- (CAGradientLayer *)shadowLayerLeft{
    if (!_shadowLayerLeft) {
        _shadowLayerLeft = [CAGradientLayer layer];
        _shadowLayerLeft.startPoint = CGPointMake(0, 0.5);
        _shadowLayerLeft.endPoint = CGPointMake(1, 0.5);
        _shadowLayerLeft.colors = @[(__bridge id)[UIColor colorWithRed:0/255.0 green:0/255.0 blue:0/255.0 alpha:0.1].CGColor, (__bridge id)[UIColor colorWithRed:0/255.0 green:0/255.0 blue:0/255.0 alpha:0.0].CGColor];
        _shadowLayerLeft.locations = @[@(0), @(1.0f)];
    }
    return _shadowLayerLeft;
}

- (CAGradientLayer *)shadowLayer{
    if (!_shadowLayer) {
        _shadowLayer = [CAGradientLayer layer];
        _shadowLayer.startPoint = CGPointMake(0.5, 0);
        _shadowLayer.endPoint = CGPointMake(0.5, 1);
        _shadowLayer.colors = @[(__bridge id)[UIColor colorWithRed:0/255.0 green:0/255.0 blue:0/255.0 alpha:0.0].CGColor, (__bridge id)[UIColor colorWithRed:0/255.0 green:0/255.0 blue:0/255.0 alpha:0.7].CGColor];
        _shadowLayer.locations = @[@(0), @(1.0f)];
    }
    return _shadowLayer;
}

- (UIButton *)micButton{
    if (!_micButton) {
        _micButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_micButton setImage:[self getImageWithName:@"plvlc_linkmic_window_mic_open"] forState:UIControlStateNormal];
        [_micButton setImage:[self getImageWithName:@"plvlc_linkmic_window_mic_close"] forState:UIControlStateSelected];
    }
    return _micButton;
}

- (UILabel *)nicknameLabel{
    if (!_nicknameLabel) {
        _nicknameLabel = [[UILabel alloc]init];
        _nicknameLabel.text = PLVLocalizedString(@"连麦人昵称");
        _nicknameLabel.textColor = [UIColor whiteColor];
        _nicknameLabel.font = [UIFont fontWithName:@"PingFang SC" size:12];
    }
    return _nicknameLabel;
}

- (BOOL)isOnlyAudio {
    return [PLVRoomDataManager sharedManager].roomData.channelInfo.isOnlyAudio;
}

- (void)setShowInWindowCell:(BOOL)showInWindowCell {
    _showInWindowCell = showInWindowCell;
    [self updateControlShowStatus];
}

@end
