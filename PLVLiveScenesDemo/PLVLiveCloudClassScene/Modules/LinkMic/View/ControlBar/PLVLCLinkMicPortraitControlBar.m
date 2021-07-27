//
//  PLVLCLinkMicPortraitControlBar.m
//  PLVLiveScenesDemo
//
//  Created by Lincal on 2020/7/29.
//  Copyright © 2020 PLV. All rights reserved.
//

#import "PLVLCLinkMicPortraitControlBar.h"

#import "PLVLCUtils.h"
#import <PLVFoundationSDK/PLVFoundationSDK.h>

#define PLVLCLinkMicControlBar_HoverTime 5.0  // 悬停时长 (控制栏展开后，悬停多久后自动折叠)

/// 固定值
/// 高度
static const CGFloat PLVLCLinkMicVerticalControlBarHeigth = 48.0;       // Bar 高度
/// 宽度
static const CGFloat PLVLCLinkMicVerticalControlBarFoldWidth = 55.0;    // Bar 折叠宽度
static const CGFloat PLVLCLinkMicVerticalControlBarNormalWidth = 128.0; // Bar 正常宽度
static const CGFloat PLVLCLinkMicVerticalControlBarMaxWidth_Video = 200.0; // Bar 最大宽度 (视频连麦类型)
static const CGFloat PLVLCLinkMicVerticalControlBarMaxWidth_Audio = 122.0; // Bar 最大宽度 (音频连麦类型)

@interface PLVLCLinkMicPortraitControlBar () <CAAnimationDelegate>

#pragma mark 对象
@property (nonatomic, strong) NSTimer * timer;   // 定时器 (负责到指定时间，收起控制栏横条)

#pragma mark 状态
@property (nonatomic, assign) BOOL foldSelf;     // 当前是否折叠自身 (折叠:即不完全隐藏，留有部分可见)
@property (nonatomic, assign) BOOL hiddenSelf;   // 当前是否隐藏自身 (隐藏:即完全隐藏，完全不可见)
@property (nonatomic, assign) BOOL phoneRotated; // 当前电话图标是否已旋转 (NO未旋转:倾斜 YES已旋转:水平)

#pragma mark 数据
@property (nonatomic, assign) CGRect rangeRect;  // 可活动的区域值
@property (nonatomic, assign) CGPoint lastPoint; // 上一次停留的位置
@property (nonatomic, assign, readonly) CGFloat maxWidth; // 最大宽度 (根据类型返回不同值)

#pragma mark UI
@property (nonatomic, strong) UITapGestureRecognizer * tapGR;
/// view hierarchy
///
/// (PLVLCLinkMicPortraitControlBar) self
/// ├── (UIView) backgroundView (lowest)
/// ├── (UIButton) onOffButton
/// ├── (UILabel) textLabel
/// ├── (UIButton) cameraButton
/// ├── (UIButton) switchCameraButton
/// ├── (UIButton) micButton
/// └── (UIButton) hideButton (top)

@end

@implementation PLVLCLinkMicPortraitControlBar

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
@synthesize hideButton = _hideButton;

#pragma mark - [ Life Period ]
- (void)dealloc{
    [self stopFoldSelfViewTimer];
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
    BOOL fullScreen = [UIScreen mainScreen].bounds.size.width > [UIScreen mainScreen].bounds.size.height;
        
    BOOL firstLayout = self.bounds.size.width <= 0;
    if (firstLayout) {
        /// 设置起始位置
        self.frame = CGRectMake([UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height / 2, 0, self.selfHeight);
    }
    
    if (!fullScreen) {
        // 竖屏布局
        [self setBackgroudViewWidth];

        CGFloat onOffbuttonHeight = 32.0;
        CGFloat onOffbuttonY = (self.selfHeight - onOffbuttonHeight) / 2.0;
        self.onOffButton.frame = CGRectMake(8, onOffbuttonY, onOffbuttonHeight, onOffbuttonHeight);
        
        CGFloat textLabelWidth = 80.0;
        CGFloat textLabelHeight = 22.0;
        CGFloat textLabelX = CGRectGetMaxX(self.onOffButton.frame) + 8.0;
        CGFloat textLabelY = (self.selfHeight - textLabelHeight) / 2.0;
        self.textLabel.frame = CGRectMake(textLabelX, textLabelY, textLabelWidth, textLabelHeight);
        
        CGFloat buttonsY = (self.selfHeight - onOffbuttonHeight) / 2.0;
        if (self.barType == PLVLCLinkMicControlBarType_Audio) {
            /// 音频连麦类型
            self.cameraButton.hidden = YES;
            self.switchCameraButton.hidden = YES;
        }else{
            /// 视频连麦类型
            self.cameraButton.hidden = NO;
            self.switchCameraButton.hidden = NO;
            
            self.cameraButton.frame = CGRectMake(textLabelX, buttonsY, onOffbuttonHeight, onOffbuttonHeight);
            
            CGFloat switchCameraButtonX = CGRectGetMaxX(self.cameraButton.frame) + 8.0;
            self.switchCameraButton.frame = CGRectMake(switchCameraButtonX, buttonsY, onOffbuttonHeight, onOffbuttonHeight);
        }
        
        CGFloat micButtonX;
        if (self.barType == PLVLCLinkMicControlBarType_Audio) {
            micButtonX = CGRectGetMaxX(self.onOffButton.frame) + 8.0;
        }else{
            micButtonX = CGRectGetMaxX(self.switchCameraButton.frame) + 8.0;
        }
        self.micButton.frame = CGRectMake(micButtonX, buttonsY, onOffbuttonHeight, onOffbuttonHeight);
        
        CGFloat hideButtonX = CGRectGetMaxX(self.micButton.frame) + 8.0;
        self.hideButton.frame = CGRectMake(hideButtonX, buttonsY, onOffbuttonHeight, onOffbuttonHeight);
    }else{
        // 横屏布局
        [self showSelfViewWithAnimation:NO];
    }
}


#pragma mark - [ Public Methods ]
- (void)controlBarStatusSwitchTo:(PLVLCLinkMicControlBarStatus)status{
    _status = status;

    if (status == PLVLCLinkMicControlBarStatus_Default) { // 默认状态，控制栏隐藏
        [self hiddenSelfView];
        
        [self onOffButtonIconChange:NO];
        [self onOffButtonRotate:NO];
        [self onOffButtonColorChange:PLVColor_OnOffButton_Green];
        [self mediaControlButtonsShow:NO];

        [self textLabelContentChange:@"申请连麦"];
        
        [self resetButtons];
    }else if (status == PLVLCLinkMicControlBarStatus_Open) { // 显示 ‘申请连麦’
        [self unfoldSelfView];
        
        [self onOffButtonIconChange:NO];
        [self onOffButtonRotate:NO];
        [self onOffButtonColorChange:PLVColor_OnOffButton_Green];
        [self mediaControlButtonsShow:NO];

        [self textLabelContentChange:@"申请连麦"];
        
        [self resetButtons];
    }else if (status == PLVLCLinkMicControlBarStatus_Waiting){ // 显示 ‘请求中...’
        [self unfoldSelfView];
        
        [self onOffButtonRotate:YES];
        [self onOffButtonColorChange:PLVColor_OnOffButton_Red];
        
        [self textLabelContentChange:@"请求中..."];
    }else if (status == PLVLCLinkMicControlBarStatus_Joined){ // 已连麦，显示相关的控制按钮
        [self unfoldSelfView];
        
        [self onOffButtonRotate:YES];
        [self onOffButtonColorChange:PLVColor_OnOffButton_Red];
        
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
    BOOL firstLayout = self.bounds.size.width <= 0;
    [self readRangeRect];
    CGRect rangeRect = self.rangeRect;
    CGFloat x;
    if (self.status == PLVLCLinkMicControlBarStatus_Default) {
        x = CGRectGetMaxX(rangeRect);
    }else{
        x = CGRectGetMaxX(rangeRect) - self.selfWidth;
    }
    
    CGFloat y;
    if (self.lastPoint.x > 0) {
        y = self.lastPoint.y;
    }else{
        y = (CGRectGetMaxY(rangeRect) - self.selfHeight) / 2.0 - 10;
    }
    self.frame = CGRectMake(x, y, self.selfWidth, self.selfHeight);
    [self setNeedsLayout];
    
    if (firstLayout) { self.lastPoint = self.bounds.origin; }
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
    self.hiddenSelf = YES;
}

- (UIImage *)getImageWithName:(NSString *)imageName{
    return [PLVLCUtils imageForLinkMicResource:imageName];
}

#pragma mark UI
- (void)setupUI{
    // 添加 手势
    UIPanGestureRecognizer * panGR = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureAction:)];
    [self addGestureRecognizer:panGR];
    
    self.tapGR = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureAction:)];
    [self addGestureRecognizer:self.tapGR];
    
    // 添加 视图
    [self addSubview:self.backgroundView];
    [self addSubview:self.onOffButton];
    [self addSubview:self.textLabel];
    [self addSubview:self.cameraButton];
    [self addSubview:self.switchCameraButton];
    [self addSubview:self.micButton];
    [self addSubview:self.hideButton];
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

- (void)setBackgroudViewWidth{
    if (CGRectGetWidth(self.backgroundView.frame) == 0) {
        self.backgroundView.frame = CGRectMake(0, 0, self.maxWidth, self.selfHeight);
        
        CAShapeLayer * shapeLayer = [CAShapeLayer layer];
        shapeLayer.path = [UIBezierPath bezierPathWithRoundedRect:self.backgroundView.bounds byRoundingCorners:UIRectCornerBottomLeft | UIRectCornerTopLeft cornerRadii:CGSizeMake(25, 25)].CGPath;
        _backgroundView.layer.mask = shapeLayer;
    }
}

- (void)readRangeRect{
    if (@available(iOS 11.0, *)) {
        CGRect safeRect = self.superview.safeAreaLayoutGuide.layoutFrame;
        BOOL fullScreen = [UIScreen mainScreen].bounds.size.width > [UIScreen mainScreen].bounds.size.height;
        if (fullScreen && safeRect.origin.y == 20.0) {
            safeRect.size.height += safeRect.origin.y;
            safeRect.origin.y = 0.0;
        }
        self.rangeRect = safeRect;
    } else {
        self.rangeRect = self.superview.bounds;
    }
}

#pragma mark Getter
- (CGFloat)selfWidth{
    // 业务变更时，可直接修改此文件顶部的固定值
    CGFloat w = PLVLCLinkMicVerticalControlBarNormalWidth;
    if (_foldSelf) {
        w = PLVLCLinkMicVerticalControlBarFoldWidth;
    } else if(_status == PLVLCLinkMicControlBarStatus_Joined){
        w = self.maxWidth;
    }
    return w;
}

- (CGFloat)maxWidth{
    // 业务变更时，可直接修改此文件顶部的固定值
    if (self.barType == PLVLCLinkMicControlBarType_Audio) {
        return PLVLCLinkMicVerticalControlBarMaxWidth_Audio;
    }else{
        return PLVLCLinkMicVerticalControlBarMaxWidth_Video;
    }
}

- (CGFloat)selfHeight{
    // 业务变更时，可直接修改此文件顶部的固定值
    return PLVLCLinkMicVerticalControlBarHeigth;
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
        _textLabel.textAlignment = NSTextAlignmentLeft;
        _textLabel.textColor = [UIColor whiteColor];
        _textLabel.font = [UIFont fontWithName:@"PingFang SC" size:16];
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

- (UIButton *)hideButton{
    if (!_hideButton) {
        _hideButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _hideButton.alpha = 0;
        [_hideButton setImage:[self getImageWithName:@"plvlc_linkmic_control_hide"] forState:UIControlStateNormal];
        [_hideButton addTarget:self action:@selector(hideButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _hideButton;
}

#pragma mark Animation
/// 展开控制栏动画
- (void)unfoldSelfView{
    _foldSelf = NO;
    _hiddenSelf = NO;
    
    if (self.status == PLVLCLinkMicControlBarStatus_Joined) {
        [self onOffButtonIconChange:NO];
        [self onOffButtonRotate:YES];
        [self onOffButtonColorChange:PLVColor_OnOffButton_Red];
        [self mediaControlButtonsShow:YES];
    }else{
        [self textLabelShow:YES];
    }
    
    [self controlBarUserInteractionEnabled:NO];
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:PLVLCLinkMicControlBar_ShiftTime delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        [weakSelf refreshControlBarFrame];
        weakSelf.alpha = 1;
    } completion:^(BOOL finished) {
        [weakSelf controlBarUserInteractionEnabled:YES];
        [weakSelf startHideSelfViewTimer];
    }];
}

/// 折叠控制栏动画 (折叠:即不完全隐藏，留有部分可见)
- (void)foldSelfView{
    [self stopFoldSelfViewTimer];
    
    if (self.status == PLVLCLinkMicControlBarStatus_Waiting) {
        return;
    }
    
    if (!_foldSelf && !_hiddenSelf) {
        _foldSelf = YES;
                
        if (self.status == PLVLCLinkMicControlBarStatus_Joined) {
            [self onOffButtonRotate:NO];
            [self onOffButtonColorChange:PLVColor_OnOffButton_Gray];
            [self mediaControlButtonsShow:NO];
        }else{
            [self textLabelShow:NO];
        }
        
        [self controlBarUserInteractionEnabled:NO];
        __weak typeof(self) weakSelf = self;
        CGRect __block oriFrame = weakSelf.frame;
        [UIView animateWithDuration:PLVLCLinkMicControlBar_ShiftTime delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            oriFrame.origin.x = CGRectGetMaxX(weakSelf.rangeRect) - weakSelf.selfWidth;
            weakSelf.frame = oriFrame;
        } completion:^(BOOL finished) {
            [weakSelf controlBarUserInteractionEnabled:YES];
            /// 需延后设置长度
            oriFrame.size.width = weakSelf.selfWidth;
            weakSelf.frame = oriFrame;
        }];
    }
}

/// 隐藏控制栏动画 (隐藏:即完全隐藏，完全不可见)
- (void)hiddenSelfView{
    if (!_hiddenSelf) {
        _hiddenSelf = YES;
        
        [self textLabelShow:NO];
        
        [self controlBarUserInteractionEnabled:NO];
        __weak typeof(self) weakSelf = self;
        [UIView animateWithDuration:PLVLCLinkMicControlBar_ShiftTime delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            [weakSelf refreshControlBarFrame];
            weakSelf.alpha = 0;
        } completion:^(BOOL finished) {
            [weakSelf controlBarUserInteractionEnabled:YES];
        }];
    }
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
        animation.delegate = self;
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
    [UIView animateWithDuration:PLVLCLinkMicControlBar_ShiftTime animations:^{
        weakSelf.textLabel.alpha = show ? 1.0 : 0.0;
    }];
}

/// 控制系列按钮 显示或隐藏动画
- (void)mediaControlButtonsShow:(BOOL)show{
    _mediaControlButtonsShow = show;
    self.tapGR.enabled = !show;
    CGFloat alpha = show ? 1.0 : 0.0;
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:PLVLCLinkMicControlBar_ShiftTime animations:^{
        weakSelf.cameraButton.alpha = alpha;
        weakSelf.switchCameraButton.alpha = show ? (weakSelf.switchCameraButton.selected ? 0.5 : 1.0) : 0.0;
        weakSelf.micButton.alpha = alpha;
        weakSelf.hideButton.alpha = alpha;
    }];
}

#pragma mark Timer Manage
- (void)startHideSelfViewTimer{
    if (_timer) { [self stopFoldSelfViewTimer]; }
    PLVFWeakProxy * weakProxy = [PLVFWeakProxy proxyWithTarget:self];
    _timer = [NSTimer scheduledTimerWithTimeInterval:PLVLCLinkMicControlBar_HoverTime target:weakProxy selector:@selector(timerEvent:) userInfo:nil repeats:NO];
    [[NSRunLoop currentRunLoop] addTimer:_timer forMode:NSRunLoopCommonModes];
}

- (void)stopFoldSelfViewTimer{
    [_timer invalidate];
    _timer = nil;
}


#pragma mark - [ Event ]
- (void)timerEvent:(NSTimer *)timer{
    [self foldSelfView];
}

#pragma mark Action
- (void)panGestureAction:(UIPanGestureRecognizer*)panGR {
    if (!self.canMove) { return; }
    
    CGPoint p = [panGR locationInView:self.superview];
    if (panGR.state == UIGestureRecognizerStateBegan) {
        [self stopFoldSelfViewTimer];
        [self readRangeRect];
    } else if (panGR.state == UIGestureRecognizerStateChanged) {
        CGRect rect = self.frame;
        
        rect.origin.x = CGRectGetMaxX(self.rangeRect) - self.selfWidth;
        
        rect.origin.y += (p.y - self.lastPoint.y);
        if (rect.origin.y < self.rangeRect.origin.y) {
            rect.origin.y = self.rangeRect.origin.y;
        } else if (rect.origin.y > CGRectGetMaxY(self.rangeRect) - self.selfHeight) {
            rect.origin.y = CGRectGetMaxY(self.rangeRect) - self.selfHeight;
        }
        self.frame = rect;
    } else if (panGR.state == UIGestureRecognizerStateEnded){
        [self startHideSelfViewTimer];
    }
    self.lastPoint = self.frame.origin;
}

- (void)tapGestureAction:(UITapGestureRecognizer *)tapGR {
    if (self.status == PLVLCLinkMicControlBarStatus_Open || self.status == PLVLCLinkMicControlBarStatus_Waiting) {
        [self onOffButtonAction:self.onOffButton];
    }
}

- (void)onOffButtonAction:(UIButton *)button{
    BOOL joinedAndFold = self.status == PLVLCLinkMicControlBarStatus_Joined && self.foldSelf;
    if (self.status == PLVLCLinkMicControlBarStatus_Open || joinedAndFold) {
        [self unfoldSelfView];
    }
    
    if (joinedAndFold == NO) {
        if ([self.delegate respondsToSelector:@selector(plvLCLinkMicControlBar:onOffButtonClickedCurrentStatus:)]) {
            [self.delegate plvLCLinkMicControlBar:self onOffButtonClickedCurrentStatus:self.status];
        }
    }
}

- (void)cameraButtonAction:(UIButton *)button{
    [self startHideSelfViewTimer];
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
    [self startHideSelfViewTimer];
    _switchCameraButtonFront = !_switchCameraButtonFront;
    if ([self.delegate respondsToSelector:@selector(plvLCLinkMicControlBar:switchCameraButtonClicked:)]) {
        [self.delegate plvLCLinkMicControlBar:self switchCameraButtonClicked:_switchCameraButtonFront];
    }
}

- (void)micButtonAction:(UIButton *)button{
    [self startHideSelfViewTimer];
    button.selected = !button.selected;
    if ([self.delegate respondsToSelector:@selector(plvLCLinkMicControlBar:micCameraButtonClicked:)]) {
        [self.delegate plvLCLinkMicControlBar:self micCameraButtonClicked:!button.selected];
    }
}

- (void)hideButtonAction:(UIButton *)button{
    [self foldSelfView];
}

#pragma mark - [ Delegate ]
#pragma mark CAAnimationDelegate
- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag{
    if (flag) {
        if (self.foldSelf && self.status == PLVLCLinkMicControlBarStatus_Joined && !self.phoneRotated) {
            [self.onOffButton setBackgroundColor:PLVColor_OnOffButton_Clear];
            [self onOffButtonIconChange:YES];
        }
    }
}

@end
