//
//  PLVLCLinkMicLandscapeControlBar.m
//  PLVLiveScenesDemo
//
//  Created by Lincal on 2020/8/31.
//  Copyright © 2020 PLV. All rights reserved.
//

#import "PLVLCLinkMicLandscapeControlBar.h"

#import "PLVLCUtils.h"
#import <PLVFoundationSDK/PLVFoundationSDK.h>

/// 固定值
/// 宽度
static const CGFloat PLVLCLinkMicHorizontalControlBarWidth = 64.0;        // Bar 宽度
/// 高度
static const CGFloat PLVLCLinkMicHorizontalControlBarNormalHeight = 77.0; // Bar 正常高度
static const CGFloat PLVLCLinkMicHorizontalControlBarMaxHeight_Video = 200.0; // Bar 最大高度 (视频连麦类型)
static const CGFloat PLVLCLinkMicHorizontalControlBarMaxHeight_Audio = 104.0; // Bar 最大高度 (音频连麦类型)

@interface PLVLCLinkMicLandscapeControlBar ()

#pragma mark 状态
@property (nonatomic, assign) BOOL phoneRotated; // 当前电话图标是否已旋转 (NO未旋转:倾斜 YES已旋转:水平)

#pragma mark 数据
@property (nonatomic, assign, readonly) CGFloat maxHeight; // 最大高度 (根据类型返回不同值)

#pragma mark UI
@property (nonatomic, strong) UITapGestureRecognizer * tapGR;
/// view hierarchy
///
/// (PLVLCLinkMicLandscapeControlBar) self
/// ├── (UIView) backgroundView (lowest)
/// ├── (UIButton) onOffButton
/// ├── (UILabel) textLabel
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

@synthesize selfWidth = _selfWidth;
@synthesize selfHeight = _selfHeight;

@synthesize backgroundView = _backgroundView;
@synthesize onOffButton = _onOffButton;
@synthesize textLabel = _textLabel;
@synthesize cameraButton = _cameraButton;
@synthesize switchCameraButton = _switchCameraButton;
@synthesize micButton = _micButton;

#pragma mark - [ Life Period ]
- (void)dealloc{
    NSLog(@"%s",__FUNCTION__);
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
- (void)controlBarStatusSwitchTo:(PLVLCLinkMicControlBarStatus)status{
    _status = status;

    if (status == PLVLCLinkMicControlBarStatus_Default) { // 默认状态，控制栏隐藏
        [self refreshSelfViewFrameAnimation];

        [self onOffButtonIconChange:NO];
        [self onOffButtonColorChange:PLVColor_OnOffButton_Green];
        [self mediaControlButtonsShow:NO];

        [self textLabelContentChange:@"申请连麦"];
        
        [self resetButtons];
        [self setupData];
    }else if (status == PLVLCLinkMicControlBarStatus_Open) { // 显示 ‘申请连麦’
        [self refreshSelfViewFrameAnimation];
        
        [self onOffButtonIconChange:NO];
        [self onOffButtonRotate:NO];
        [self onOffButtonColorChange:PLVColor_OnOffButton_Green];
        [self mediaControlButtonsShow:NO];

        [self textLabelContentChange:@"申请连麦"];
        
        [self resetButtons];
    }else if (status == PLVLCLinkMicControlBarStatus_Waiting){ // 显示 ‘请求中...’
        [self refreshSelfViewFrameAnimation];
        
        [self onOffButtonRotate:YES];
        [self onOffButtonColorChange:PLVColor_OnOffButton_Red];
        
        [self textLabelContentChange:@"请求中..."];
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
}

- (void)synchControlBarState:(id<PLVLCLinkMicControlBarProtocol>)controlBar{
    if (controlBar && controlBar != self) {
        [self controlBarStatusSwitchTo:controlBar.status];
        self.barType = controlBar.barType;
        self.cameraButton.selected = controlBar.cameraButton.selected;
        self.switchCameraButton.selected = controlBar.switchCameraButton.selected;
        self.switchCameraButton.alpha = _mediaControlButtonsShow ? (self.switchCameraButton.selected ? 0.5 : 1.0) : 0.0;
        self.switchCameraButtonFront = controlBar.switchCameraButtonFront;
        self.micButton.selected = controlBar.micButton.selected;
    }
}

/// 出现隐藏动画
- (void)showSelfViewWithAnimation:(BOOL)show{
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:(show ? PLVLCLinkMicControlBar_CommonTime : 0.1) animations:^{
        weakSelf.alpha = show ? 1.0 : 0.0;
    }];
}

- (void)changeCameraButtonOpenUIWithoutEvent:(BOOL)toCameraOpen{
    self.cameraButton.selected = !toCameraOpen;
    BOOL currentOpen = !self.cameraButton.selected;
    self.switchCameraButton.selected = !currentOpen;
    self.switchCameraButton.alpha = currentOpen ? 1.0 : 0.5;
}

#pragma mark Setter
- (void)setBarType:(PLVLCLinkMicControlBarType)barType{
    _barType = barType;
    [self setNeedsLayout];
}


#pragma mark - [ Private Methods ]
- (void)setupData{
    self.canMove = YES;
    self.status = PLVLCLinkMicControlBarStatus_Default;
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
}

- (void)refreshBackgroudViewFrame{
    self.backgroundView.frame = CGRectMake(0, 0, self.selfWidth, self.selfHeight);
    
    CAShapeLayer * shapeLayer = [CAShapeLayer layer];
    shapeLayer.path = [UIBezierPath bezierPathWithRoundedRect:self.backgroundView.bounds byRoundingCorners:UIRectCornerBottomLeft | UIRectCornerTopLeft cornerRadii:CGSizeMake(8, 8)].CGPath;
    _backgroundView.layer.mask = shapeLayer;
}

#pragma mark Getter
- (CGFloat)selfWidth{
    // 业务变更时，可直接修改此文件顶部的固定值
    return PLVLCLinkMicHorizontalControlBarWidth;
}

- (CGFloat)selfHeight{
    // 业务变更时，可直接修改此文件顶部的固定值
    if (self.status == PLVLCLinkMicControlBarStatus_Joined) { return self.maxHeight; }
    return PLVLCLinkMicHorizontalControlBarNormalHeight;
}

- (CGFloat)maxHeight{
    // 业务变更时，可直接修改此文件顶部的固定值
    if (self.barType == PLVLCLinkMicControlBarType_Audio) {
        return PLVLCLinkMicHorizontalControlBarMaxHeight_Audio;
    }else{
        return PLVLCLinkMicHorizontalControlBarMaxHeight_Video;
    }
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
        _textLabel.text = @"申请连麦";
        _textLabel.textAlignment = NSTextAlignmentCenter;
        _textLabel.textColor = [UIColor whiteColor];
        _textLabel.font = [UIFont fontWithName:@"PingFang SC" size:12];
    }
    return _textLabel;
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
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:PLVLCLinkMicControlBar_ShiftTime delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        [weakSelf refreshControlBarFrame];
        weakSelf.alpha = 1;
    } completion:^(BOOL finished) {
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
        [UIView animateWithDuration:(totalTime / 2.0) animations:^{
            weakSelf.textLabel.alpha = 1;
        }];
    }];
}

/// 文本框 显示或隐藏动画
- (void)textLabelShow:(BOOL)show{
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:PLVLCLinkMicControlBar_CommonTime animations:^{
        weakSelf.textLabel.alpha = show ? 1.0 : 0.0;
    }];
}

/// 控制系列按钮 显示或隐藏动画
- (void)mediaControlButtonsShow:(BOOL)show{
    _mediaControlButtonsShow = show;
    self.tapGR.enabled = !show;
    CGFloat alpha = show ? 1.0 : 0.0;
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:PLVLCLinkMicControlBar_CommonTime animations:^{
        weakSelf.cameraButton.alpha = alpha;
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
    if ([self.delegate respondsToSelector:@selector(plvLCLinkMicControlBar:onOffButtonClickedCurrentStatus:)]) {
        [self.delegate plvLCLinkMicControlBar:self onOffButtonClickedCurrentStatus:self.status];
    }
}

- (void)cameraButtonAction:(UIButton *)button{
    button.enabled = NO;
    BOOL wannaOpen = self.cameraButton.selected;
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
