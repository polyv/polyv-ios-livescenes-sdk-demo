//
//  PLVLCLinkMicLandscapeControlBar.m
//  PLVLiveScenesDemo
//
//  Created by Lincal on 2020/8/31.
//  Copyright © 2020 PLV. All rights reserved.
//

#import "PLVLCLinkMicLandscapeControlBar.h"

#import "PLVLCUtils.h"
#import "PLVMultiLanguageManager.h"
#import <PLVFoundationSDK/PLVFoundationSDK.h>
#import <PLVLiveScenesSDK/PLVLivePictureInPictureManager.h>
#import <PLVLiveScenesSDK/PLVConsoleLogger.h>

static const int kLinkMicBtnTouchInterval = 300; // 连麦按钮防止连续点击间隔:300毫秒

@interface PLVLCLinkMicLandscapeControlBar ()

#pragma mark 状态
@property (nonatomic, assign) BOOL phoneRotated; // 当前电话图标是否已旋转 (NO未旋转:倾斜 YES已旋转:水平)
@property (nonatomic, assign) BOOL showRequestIndex; // 当前是否显示连麦排序

#pragma mark 数据
@property (nonatomic, assign) NSTimeInterval linkMicBtnLastTimeInterval; // 连麦按钮上一次点击的时间戳

#pragma mark UI
@property (nonatomic, strong) UITapGestureRecognizer * tapGR;
/// view hierarchy
///
/// (PLVLCLinkMicLandscapeControlBar) self
/// ├── (UIView) backgroundView (lowest)
/// ├── (UIButton) onOffButton
/// ├── (UILabel) textLabel
/// ├── (UILabel) detailLabel
/// ├── (UIButton) cameraButton
/// ├── (UIButton) switchCameraButton
/// └── (UIButton) micButton (top)

@end

@implementation PLVLCLinkMicLandscapeControlBar

@synthesize delegate = _delegate;
@synthesize canMove = _canMove;
@synthesize barType = _barType;
@synthesize status = _status;
@synthesize switchCameraButtonFront = _switchCameraButtonFront;
@synthesize mediaControlButtonsShow = _mediaControlButtonsShow;
@synthesize cameraButtonEnable = _cameraButtonEnable;
@synthesize pictureInPictureStarted= _pictureInPictureStarted;

@synthesize selfWidth = _selfWidth;
@synthesize selfHeight = _selfHeight;

@synthesize backgroundView = _backgroundView;
@synthesize onOffButton = _onOffButton;
@synthesize textLabel = _textLabel;
@synthesize detailLabel = _detailLabel;
@synthesize cameraButton = _cameraButton;
@synthesize switchCameraButton = _switchCameraButton;
@synthesize micButton = _micButton;

#pragma mark - [ Life Period ]
- (void)dealloc{
    PLV_LOG_INFO(PLVConsoleLogModuleTypeLinkMic,@"%s",__FUNCTION__);
}

- (instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        [self setupData];
        [self setupUI];
    }
    return self;
}

- (void)layoutSubviews{
    BOOL statusJoined = self.status == PLVLCLinkMicControlBarStatus_Joined;
    BOOL fullScreen = [UIScreen mainScreen].bounds.size.width > [UIScreen mainScreen].bounds.size.height;
    
    if (fullScreen) {
        // 横屏布局
        [self refreshBackgroudViewFrame];
        
        CGFloat textLabelHeight = 17.0;
        CGFloat onOffButtonTextLabelPadding = 4.0;
        
        CGFloat onOffButtonHeight = 32.0;
        CGFloat onOffButtonX = (self.selfWidth - onOffButtonHeight) / 2.0;
        CGFloat onOffButtonY = statusJoined ? (self.selfHeight - 12.0 - onOffButtonHeight) : (self.selfHeight - (onOffButtonHeight + textLabelHeight + onOffButtonTextLabelPadding)) / 2.0;

        self.onOffButton.frame = CGRectMake(onOffButtonX, onOffButtonY, onOffButtonHeight, onOffButtonHeight);
        
        CGFloat textLabelY = CGRectGetMaxY(self.onOffButton.frame) + onOffButtonTextLabelPadding;
        self.textLabel.frame = CGRectMake(0, textLabelY, self.selfWidth, textLabelHeight);
        self.detailLabel.frame = CGRectMake(0, CGRectGetMaxY(self.textLabel.frame), self.selfWidth, 14);
        
        self.micButton.frame = CGRectMake(onOffButtonX, 12.0, onOffButtonHeight, onOffButtonHeight);
        
        if (self.barType == PLVLCLinkMicControlBarType_Audio) {
            /// 音频连麦类型
            self.cameraButton.hidden = YES;
            self.switchCameraButton.hidden = YES;
        }else{
            /// 视频连麦类型
            self.cameraButton.hidden = NO;
            self.switchCameraButton.hidden = NO;
        
            CGFloat cameraButtonY = CGRectGetMaxY(self.micButton.frame) + 16.0;
            self.cameraButton.frame = CGRectMake(onOffButtonX, cameraButtonY, onOffButtonHeight, onOffButtonHeight);
            
            CGFloat switchCameraButtonY = CGRectGetMaxY(self.cameraButton.frame) + 16.0;
            self.switchCameraButton.frame = CGRectMake(onOffButtonX, switchCameraButtonY, onOffButtonHeight, onOffButtonHeight);
        }
    }else{
        // 竖屏布局
        [self showSelfViewWithAnimation:NO];
    }
}


#pragma mark - [ Public Methods ]

- (void)changeBarType:(PLVLCLinkMicControlBarType)barType {
    _barType = barType;
    [self setNeedsLayout];
}

- (void)controlBarStatusSwitchTo:(PLVLCLinkMicControlBarStatus)status{
    _status = status;

    self.showRequestIndex = NO;
    self.detailLabel.alpha = 0;

    if (status == PLVLCLinkMicControlBarStatus_Default) { // 默认状态，控制栏隐藏
        [self refreshSelfViewFrameAnimation];

        [self onOffButtonIconChange:NO];
        [self onOffButtonColorChange:PLVColor_OnOffButton_Green];
        [self mediaControlButtonsShow:NO];

        [self textLabelContentChange:PLVLocalizedString(@"申请连麦")];
        
        [self resetButtons];
        [self setupData];
    }else if (status == PLVLCLinkMicControlBarStatus_Open) { // 显示 ‘申请连麦’
        [self refreshSelfViewFrameAnimation];
        
        [self onOffButtonIconChange:NO];
        [self onOffButtonRotate:NO];
        [self onOffButtonColorChange:PLVColor_OnOffButton_Green];
        [self mediaControlButtonsShow:NO];
        
        NSString *textLabelString = self.barType == PLVLCLinkMicControlBarType_Audio ? PLVLocalizedString(@"申请音频连麦"): PLVLocalizedString(@"申请视频连麦");
        [self textLabelContentChange:textLabelString];
        
        [self resetButtons];
    }else if (status == PLVLCLinkMicControlBarStatus_Waiting){ // 显示 ‘请求中...’
        [self refreshSelfViewFrameAnimation];
        
        [self onOffButtonRotate:YES];
        [self onOffButtonColorChange:PLVColor_OnOffButton_Red];
        
        [self textLabelContentChange:PLVLocalizedString(@"请求中...")];
        
        [self mediaControlButtonsShow:NO];
    }else if (status == PLVLCLinkMicControlBarStatus_Joined){ // 已连麦，显示相关的控制按钮
        [self onOffButtonRotate:YES];
        [self onOffButtonColorChange:PLVColor_OnOffButton_Red];

        [self refreshSelfViewFrameAnimation];
        [self textLabelShow:NO];
        [self mediaControlButtonsShow:YES];
    }
}

- (void)controlBarUserInteractionEnabled:(BOOL)enable{
    self.onOffButton.enabled = enable;
    self.userInteractionEnabled = enable;
    self.tapGR.enabled = enable;
}

- (void)refreshControlBarFrame{
    CGRect rangeRect = self.superview.bounds; /// 不考虑安全区域
    CGFloat x;
    if (self.status == PLVLCLinkMicControlBarStatus_Default) {
        x = CGRectGetMaxX(rangeRect);
    }else{
        x = CGRectGetMaxX(rangeRect) - self.selfWidth;
    }
    CGFloat y = (CGRectGetMaxY(rangeRect) - self.selfHeight) / 2.0;
    self.frame = CGRectMake(x, y, self.selfWidth, self.selfHeight);
    [self setNeedsLayout];
    [self shouldShowCameraEnableAlert];
}

- (void)synchControlBarState:(id<PLVLCLinkMicControlBarProtocol>)controlBar{
    if (controlBar && controlBar != self) {
        self.cameraButtonEnable = controlBar.cameraButtonEnable;
        self.barType = controlBar.barType;
        [self controlBarStatusSwitchTo:controlBar.status];
        self.cameraButton.selected = controlBar.cameraButton.selected;
        self.switchCameraButton.selected = controlBar.switchCameraButton.selected;
        self.switchCameraButton.alpha = _mediaControlButtonsShow ? (self.switchCameraButton.selected ? 0.5 : 1.0) : 0.0;
        self.switchCameraButtonFront = controlBar.switchCameraButtonFront;
        self.micButton.selected = controlBar.micButton.selected;
        self.pictureInPictureStarted = controlBar.pictureInPictureStarted;
    }
}

/// 出现隐藏动画
- (void)showSelfViewWithAnimation:(BOOL)show{
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:(show ? PLVLCLinkMicControlBar_CommonTime : 0.1) animations:^{
        weakSelf.alpha = show ? 1.0 : 0.0;
        [weakSelf controlBarUserInteractionEnabled:show];
    }];
}

- (void)changeCameraButtonOpenUIWithoutEvent:(BOOL)toCameraOpen{
    if (!self.cameraButtonEnable && toCameraOpen) {
        [self cameraButtonAction:self.cameraButton];
        return;
    }
    self.cameraButton.selected = !toCameraOpen;
    BOOL currentOpen = !self.cameraButton.selected;
    self.switchCameraButton.selected = !currentOpen;
    self.switchCameraButton.alpha = currentOpen ? 1.0 : 0.5;
}

- (void)updateLinkMicRequestIndex:(NSInteger)index {
    if (self.status != PLVLCLinkMicControlBarStatus_Waiting) {
        return;
    }
    
    if (index >= 0) {
        self.detailLabel.alpha = 1;
        self.showRequestIndex = YES;
        
        NSString *numberString = index >= 50 ? @"50+" : [NSString stringWithFormat:@"%zd", index+1];
        NSString *text = [NSString stringWithFormat:PLVLocalizedString(@"排队%@"), numberString];
        self.detailLabel.text = text;
    } else {
        self.detailLabel.alpha = 0;
        self.showRequestIndex = NO;
    }
}

#pragma mark - [ Private Methods ]
- (void)setupData{
    self.canMove = YES;
    self.status = PLVLCLinkMicControlBarStatus_Default;
    self.linkMicBtnLastTimeInterval = 0.0;
    self.pictureInPictureStarted = NO;
}

- (UIImage *)getImageWithName:(NSString *)imageName{
    return [PLVLCUtils imageForLinkMicResource:imageName];
}

#pragma mark UI
- (void)setupUI{
    // 添加 手势
    self.tapGR = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureAction:)];
    [self addGestureRecognizer:self.tapGR];
    
    // 添加 视图
    [self addSubview:self.backgroundView];
    [self addSubview:self.onOffButton];
    [self addSubview:self.textLabel];
    [self addSubview:self.detailLabel];
    [self addSubview:self.cameraButton];
    [self addSubview:self.switchCameraButton];
    [self addSubview:self.micButton];
    [self resetButtons];

    // 添加 UI 细节
    self.alpha = 0;
    self.layer.shadowColor = [UIColor colorWithRed:0/255.0 green:0/255.0 blue:0/255.0 alpha:0.1].CGColor;
    self.layer.shadowOffset = CGSizeMake(0,0.5);
    self.layer.shadowOpacity = 1;
    self.layer.shadowRadius = 8;
}

- (void)resetButtons{
    // 恢复默认值
    _cameraButton.selected = !PLVLCLinkMicControlBarCameraDefaultOpen;
    _switchCameraButton.selected = !PLVLCLinkMicControlBarCameraDefaultOpen;
    _switchCameraButtonFront = PLVLCLinkMicControlBarSwitchCameraDefaultFront;
    _micButton.selected = !PLVLCLinkMicControlBarMicDefaultOpen;
    _cameraButtonEnable = YES;
}

- (void)refreshBackgroudViewFrame{
    self.backgroundView.frame = CGRectMake(0, 0, self.selfWidth, self.selfHeight);
    
    CAShapeLayer * shapeLayer = [CAShapeLayer layer];
    shapeLayer.path = [UIBezierPath bezierPathWithRoundedRect:self.backgroundView.bounds byRoundingCorners:UIRectCornerBottomLeft | UIRectCornerTopLeft cornerRadii:CGSizeMake(8, 8)].CGPath;
    _backgroundView.layer.mask = shapeLayer;
}

#pragma mark Getter

- (CGFloat)selfWidth {
    CGFloat width = 0;
    if (self.status == PLVLCLinkMicControlBarStatus_Open) {
        width = 96.0;
    } else {
        width = 64.0;
    }
    CGFloat xPadding = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad ? 8 : 0;// 适配iPad
    return width + xPadding;
}

- (CGFloat)selfHeight {
    CGFloat height = 0;
    if (self.status == PLVLCLinkMicControlBarStatus_Waiting) {
        if (self.showRequestIndex) {
            height = 91.0;
        } else {
            height = 77.0;
        }
    } else if (self.status == PLVLCLinkMicControlBarStatus_Joined) {
        if (self.barType == PLVLCLinkMicControlBarType_Audio) {
            height = 104.0;
        }else{
            height = 200.0;
        }
    } else {
        height = 77.0;
    }
    return height;
}

- (UIView *)backgroundView{
    if (!_backgroundView) {
        _backgroundView = [[UIView alloc] init];
        _backgroundView.backgroundColor = PLV_UIColorFromRGBA(@"333344",0.8);
    }
    return _backgroundView;
}

- (UIButton *)onOffButton{
    if (!_onOffButton) {
        _onOffButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _onOffButton.layer.cornerRadius = 16.0;
        _onOffButton.adjustsImageWhenHighlighted = NO;
        [_onOffButton setBackgroundColor:PLVColor_OnOffButton_Green];
        [_onOffButton setImage:[self getImageWithName:@"plvlc_linkmic_phone"] forState:UIControlStateNormal];
        [_onOffButton addTarget:self action:@selector(onOffButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _onOffButton;
}

- (UILabel *)textLabel{
    if (!_textLabel) {
        _textLabel = [[UILabel alloc] init];
        _textLabel.text = PLVLocalizedString(@"申请连麦");
        _textLabel.textAlignment = NSTextAlignmentCenter;
        _textLabel.textColor = [UIColor whiteColor];
        _textLabel.font = [UIFont systemFontOfSize:12];
    }
    return _textLabel;
}

- (UILabel *)detailLabel {
    if (!_detailLabel) {
        _detailLabel = [[UILabel alloc] init];
        _detailLabel.textAlignment = NSTextAlignmentCenter;
        _detailLabel.textColor = [UIColor colorWithWhite:1 alpha:0.6];
        _detailLabel.font = [UIFont systemFontOfSize:10];
    }
    return _detailLabel;
}

- (UIButton *)cameraButton{
    if (!_cameraButton) {
        _cameraButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _cameraButton.alpha = 0;
        [_cameraButton setImage:[self getImageWithName:@"plvlc_linkmic_camera_open"] forState:UIControlStateNormal];
        [_cameraButton setImage:[self getImageWithName:@"plvlc_linkmic_camera_close"] forState:UIControlStateSelected];
        [_cameraButton addTarget:self action:@selector(cameraButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _cameraButton;
}

- (UIButton *)switchCameraButton{
    if (!_switchCameraButton) {
        _switchCameraButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_switchCameraButton setImage:[self getImageWithName:@"plvlc_linkmic_camera_switch"] forState:UIControlStateNormal];
        [_switchCameraButton setImage:[self getImageWithName:@"plvlc_linkmic_camera_switch_close"] forState:UIControlStateSelected];
        [_switchCameraButton addTarget:self action:@selector(switchCameraButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _switchCameraButton;
}

- (UIButton *)micButton{
    if (!_micButton) {
        _micButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _micButton.alpha = 0;
        [_micButton setImage:[self getImageWithName:@"plvlc_linkmic_mic_open"] forState:UIControlStateNormal];
        [_micButton setImage:[self getImageWithName:@"plvlc_linkmic_mic_close"] forState:UIControlStateSelected];
        [_micButton addTarget:self action:@selector(micButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _micButton;
}

#pragma mark Animation
/// 刷新控制栏长度动画
- (void)refreshSelfViewFrameAnimation{
    [self controlBarUserInteractionEnabled:NO];
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:PLVLCLinkMicControlBar_ShiftTime delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        [weakSelf refreshControlBarFrame];
        weakSelf.alpha = 1;
    } completion:^(BOOL finished) {
        [weakSelf controlBarUserInteractionEnabled:YES];
    }];
}

/// 开关按钮 改变图标
- (void)onOffButtonIconChange:(BOOL)showSettingIcon{
    if (showSettingIcon) {
        [self.onOffButton setImage:[self getImageWithName:@"plvlc_linkmic_setting"] forState:UIControlStateNormal]; /// 展示‘齿轮’图标
    }else{
        [self.onOffButton setImage:[self getImageWithName:@"plvlc_linkmic_phone"] forState:UIControlStateNormal]; /// 展示‘电话’图标
    }
}

/// 开关按钮 改变颜色动画
- (void)onOffButtonColorChange:(UIColor *)color{
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:PLVLCLinkMicControlBar_CommonTime animations:^{
        [weakSelf.onOffButton setBackgroundColor:color];
    } completion:^(BOOL finished) {
    }];
}

/// 开关按钮 旋转动画
- (void)onOffButtonRotate:(BOOL)rotate{
    if (_phoneRotated != rotate) {
        CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
        animation.duration = PLVLCLinkMicControlBar_CommonTime;
        if (rotate) {
            animation.fromValue = @(0.0);
            animation.toValue = @(0.71 * M_PI);
        }else{
            animation.fromValue = @(0.71 * M_PI);
            animation.toValue = @(0.0);
        }
        animation.removedOnCompletion = NO;
        animation.autoreverses = NO;
        animation.fillMode = kCAFillModeForwards;
        [self.onOffButton.layer addAnimation:animation forKey:@"plv-rotate-layer"];
        _phoneRotated = rotate;
    }
}

/// 文本框 文字改变动画
- (void)textLabelContentChange:(NSString *)text{
    __weak typeof(self) weakSelf = self;
    NSTimeInterval totalTime = PLVLCLinkMicControlBar_CommonTime;
    [UIView animateWithDuration:(totalTime / 2.0) animations:^{
        weakSelf.textLabel.alpha = 0;
    } completion:^(BOOL finished) {
        weakSelf.textLabel.text = text;
        
        if (weakSelf.status != PLVLCLinkMicControlBarStatus_Joined) {
            [UIView animateWithDuration:(totalTime / 2.0) animations:^{
                weakSelf.textLabel.alpha = 1;
            }completion:^(BOOL finished) {
            }];
        }
    }];
}

/// 文本框 显示或隐藏动画
- (void)textLabelShow:(BOOL)show{
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:PLVLCLinkMicControlBar_CommonTime animations:^{
        weakSelf.textLabel.alpha = show ? 1.0 : 0.0;
    }];
}

/// 判断是否显示分屏模式下不能使用摄像头的提醒
- (void)shouldShowCameraEnableAlert {
    BOOL isPad = ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad);
    if (isPad) {
        BOOL isSplitView = UIViewGetWidth(self.superview) < [UIScreen mainScreen].bounds.size.width;
        if (isSplitView && self.cameraButtonEnable && self.status == PLVLCLinkMicControlBarStatus_Joined && self.barType == PLVLCLinkMicControlBarType_Video) {
            if (!self.cameraButton.selected) {
                [self cameraButtonAction:self.cameraButton];
                [PLVLCUtils showHUDWithTitle:nil detail:PLVLocalizedString(@"分屏模式下无法使用摄像头，已自动关闭摄像头") view:self.superview afterDelay:3.0];
            } else {
                [PLVLCUtils showHUDWithTitle:nil detail:PLVLocalizedString(@"分屏模式下无法使用摄像头，已自动禁用摄像头") view:self.superview afterDelay:3.0];
            }
            self.cameraButtonEnable = NO;
            self.cameraButton.userInteractionEnabled = NO;
        } else if (!isSplitView || self.status != PLVLCLinkMicControlBarStatus_Joined) {
            self.cameraButtonEnable = YES;
            self.cameraButton.userInteractionEnabled = YES;
            self.cameraButton.alpha = (self.status == PLVLCLinkMicControlBarStatus_Joined && self.barType == PLVLCLinkMicControlBarType_Video) ? 1.0 : 0.0;
        }
    }
}

/// 控制系列按钮 显示或隐藏动画
- (void)mediaControlButtonsShow:(BOOL)show{
    _mediaControlButtonsShow = show;
    self.tapGR.enabled = !show;
    CGFloat alpha = show ? 1.0 : 0.0;
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:PLVLCLinkMicControlBar_CommonTime animations:^{
        weakSelf.cameraButton.alpha = weakSelf.cameraButtonEnable ? alpha : 0.5;
        weakSelf.switchCameraButton.alpha = show ? (weakSelf.switchCameraButton.selected ? 0.5 : 1.0) : 0.0;
        weakSelf.micButton.alpha = alpha;
    }];
}

#pragma mark Action
- (void)tapGestureAction:(UITapGestureRecognizer *)tapGR {
    if (self.status == PLVLCLinkMicControlBarStatus_Open || self.status == PLVLCLinkMicControlBarStatus_Waiting) {
        [self onOffButtonAction:self.onOffButton];
    }
}

- (void)onOffButtonAction:(UIButton *)button{
    if ([PLVLivePictureInPictureManager sharedInstance].pictureInPictureActive) {
        [PLVLCUtils showHUDWithTitle:PLVLocalizedString(@"小窗播放中，不支持连麦") detail:@"" view:self.superview];
        return;
    }
    if (self.pictureInPictureStarted) {
        [PLVLCUtils showHUDWithTitle:@"小窗正在启动中，不支持连麦" detail:@"" view:self.superview];
        return;
    }
    // 防止短时间内重复点击，kLinkMicBtnTouchInterval间隔内的点击会直接忽略
    NSTimeInterval curTimeInterval = [PLVFdUtil curTimeInterval];
    if (curTimeInterval - self.linkMicBtnLastTimeInterval > kLinkMicBtnTouchInterval) {
        [self notifyListenerOnOffButtonClickedCurrentStatus];
    }
    self.linkMicBtnLastTimeInterval = curTimeInterval;
}

- (void)notifyListenerOnOffButtonClickedCurrentStatus {
    if ([self.delegate respondsToSelector:@selector(plvLCLinkMicControlBar:onOffButtonClickedCurrentStatus:)]) {
        [self.delegate plvLCLinkMicControlBar:self onOffButtonClickedCurrentStatus:self.status];
    }
}

- (void)cameraButtonAction:(UIButton *)button{
    button.enabled = NO;
    BOOL wannaOpen = self.cameraButton.selected && self.cameraButtonEnable;
    if ([self.delegate respondsToSelector:@selector(plvLCLinkMicControlBar:cameraButtonClicked:openResult:)]) {
        __weak typeof(self) weakSelf = self;
        [self.delegate plvLCLinkMicControlBar:self cameraButtonClicked:wannaOpen openResult:^(BOOL openResult) {
            dispatch_async(dispatch_get_main_queue(), ^{
                button.enabled = YES;
                if (openResult) {
                    button.selected = !wannaOpen;
                    weakSelf.switchCameraButton.selected = !wannaOpen;
                    weakSelf.switchCameraButton.alpha = wannaOpen ? 1.0 : 0.5;
                }
            });
        }];
    }
}

- (void)switchCameraButtonAction:(UIButton *)button{
    if (_switchCameraButton.selected) { return; }
    _switchCameraButtonFront = !_switchCameraButtonFront;
    if ([self.delegate respondsToSelector:@selector(plvLCLinkMicControlBar:switchCameraButtonClicked:)]) {
        [self.delegate plvLCLinkMicControlBar:self switchCameraButtonClicked:_switchCameraButtonFront];
    }
}

- (void)micButtonAction:(UIButton *)button{
    button.selected = !button.selected;
    if ([self.delegate respondsToSelector:@selector(plvLCLinkMicControlBar:micCameraButtonClicked:)]) {
        [self.delegate plvLCLinkMicControlBar:self micCameraButtonClicked:!button.selected];
    }
}

@end
