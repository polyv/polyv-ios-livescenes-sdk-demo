//
//  PLVSAStreamerSettingView.m
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2021/5/19.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVSAStreamerSettingView.h"
#import <PLVFoundationSDK/PLVFoundationSDK.h>
#import "PLVSAUtils.h"
#import "PLVSABitRateSheet.h"

#define TEXT_MAX_LENGTH 50

static NSString *const EnterTips = @"点击输入直播标题";

@interface PLVSAStreamerSettingView ()<
UITextViewDelegate,
PLVSABitRateSheetDelegate
>

#pragma mark UI
/// view hierarchy
///
/// (PLVSAStreamerSettingView) self
/// ├── (UIView) maskView
/// ├── (UIView) configView
/// ├── (UIView) bitRateSheet
/// ├── (UIButton) startButton
/// └── (UIButton) backButtton
/// 返回
@property (nonatomic, strong) UIButton *backButton;
/// 开始直播
@property (nonatomic, strong) UIButton *startButton;
/// 开始直播按钮渐变色
@property (nonatomic, strong) CAGradientLayer *gradientLayer;
/// 设置面板（负责承载摄像头切换、镜像开关、清晰度按钮、分割线和频道名称）
@property (nonatomic, strong) UIView *configView;
/// 分割线
@property (nonatomic, strong) UIView *lineView;
/// 摄像头切换
@property (nonatomic, strong) UIButton *cameraReverseButton;
/// 镜像开关
@property (nonatomic, strong) UIButton *mirrorButton;
/// 清晰度
@property (nonatomic, strong) UIButton *bitRateButton;
/// 横竖屏切换
@property (nonatomic, strong) UIButton *orientationButton;
/// 直播名称
@property (nonatomic, strong) UILabel *channelNameLable;
/// 输入框蒙层（负责承载频道名称输入框和频道名称剩余可输入的字符数）
@property (nonatomic, strong) UIView *maskView;
/// 频道名称剩余可输入字符数
@property (nonatomic, strong) UILabel *limitLable;
/// 频道名称输入框
@property (nonatomic, strong) UITextView *channelNameTextView;
/// 清晰度选择面板
@property (nonatomic, strong) PLVSABitRateSheet *bitRateSheet;
/// 文本滚动视图（为了兼容手机端横屏标题太长时，显示不美观的问题）
@property (nonatomic, strong) UIScrollView *scrollView;
/// 美颜开关
@property (nonatomic, strong) UIButton *beautyButton;

#pragma mark 数据
@property (nonatomic, assign) CGFloat configViewHeight;
@property (nonatomic, assign) CGFloat channelNameLableHeight;
/// 初始化时的默认清晰度
@property (nonatomic, assign) PLVResolutionType resolutionType;
/// 当前控制器是否可以进行屏幕旋转
@property (nonatomic, assign) BOOL canAutorotate;

@end

@implementation PLVSAStreamerSettingView

#pragma mark - [ Life Cycle ]

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setupUI];
        [self addObserver];
        [self initChannelName];
        /// 根据需要选择默认清晰度（默认最高清晰度）
        [self initBitRate:[PLVRoomDataManager sharedManager].roomData.maxResolution];
        // 初始化设备方向为 竖屏
        [[PLVSAUtils sharedUtils] setupDeviceOrientation:UIDeviceOrientationPortrait];
        UITapGestureRecognizer *tapGes = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(endEditingAction:)];
        [self addGestureRecognizer:tapGes];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self updateUI];
}

- (void)dealloc {
    [self removeObserver];
}

#pragma mark - Notifications
- (void)addObserver {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}

- (void)removeObserver {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - [ Private Method ]

- (void)setupUI {
    [self addSubview:self.backButton];
    [self addSubview:self.startButton];
    if ([PLVRoomDataManager sharedManager].roomData.appBeautyEnabled) {
        [self addSubview:self.beautyButton];
    }
    
    [self addSubview:self.maskView];
    [self.maskView addSubview:self.limitLable];
    [self.maskView addSubview:self.channelNameTextView];
    
    /// 初始化高度
    self.configViewHeight = 195;
    self.channelNameLableHeight = 26;
    
    [self addSubview:self.configView];
    [self.configView addSubview:self.scrollView];
    [self.scrollView addSubview:self.channelNameLable];
    
    [self.configView addSubview:self.lineView];
    [self.configView addSubview:self.cameraReverseButton];
    [self.configView addSubview:self.mirrorButton];
    [self.configView addSubview:self.bitRateButton];
    [self.configView addSubview:self.orientationButton];
}

- (void)updateUI {
    BOOL isPad = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
    CGFloat originX = [PLVSAUtils sharedUtils].areaInsets.left;
    CGFloat originY = [PLVSAUtils sharedUtils].areaInsets.top;
    CGFloat bottom = [PLVSAUtils sharedUtils].areaInsets.bottom;
    BOOL isLandscape = [PLVSAUtils sharedUtils].isLandscape;
    
    CGFloat backButttonTop = originY + 9;
    CGFloat startButtonBottom = bottom + (isLandscape ? 16 : 45);
    CGFloat startButtonWidth = [PLVRoomDataManager sharedManager].roomData.appBeautyEnabled ? 206 : 320;
    CGFloat beautyButtonWidth = [PLVRoomDataManager sharedManager].roomData.appBeautyEnabled ? 114 : 0;
    CGFloat configViewWidth = startButtonWidth + 8 + beautyButtonWidth;
    CGFloat channelNameLableLeft = 28;
    CGFloat lineViewLeft = 24;
    
    if (isPad) {
        backButttonTop = originY + 20;
        startButtonBottom = bottom + 100;
        startButtonWidth = CGRectGetWidth(self.frame) * 0.47;
        configViewWidth = CGRectGetWidth(self.frame) * 0.66;
        channelNameLableLeft = 41;
        lineViewLeft = 32;
    }
    
    /// 标题文本高度适应
    CGFloat lableHeight = [self.channelNameLable sizeThatFits:CGSizeMake(configViewWidth - channelNameLableLeft * 2, MAXFLOAT)].height;
    self.configViewHeight += lableHeight - self.channelNameLableHeight;
    self.channelNameLableHeight = lableHeight;
    
    self.backButton.frame = CGRectMake(originX + 24, backButttonTop, 36, 36);
    self.maskView.frame = self.bounds;
    /// 初始化时默认收起输入框
    [self takeBackTextView];
    
    if ([PLVRoomDataManager sharedManager].roomData.appBeautyEnabled) {
        /// 美颜按钮
        CGFloat beautyX = (CGRectGetWidth(self.bounds) - startButtonWidth - beautyButtonWidth - 8) / 2;
        self.beautyButton.frame = CGRectMake(beautyX, self.bounds.size.height - startButtonBottom - 50, beautyButtonWidth, 50);
        
        /// 开始直播按钮
        self.startButton.frame = CGRectMake(CGRectGetMaxX(self.beautyButton.frame) + 8, self.beautyButton.frame.origin.y, startButtonWidth, 50);
        self.gradientLayer.frame = self.startButton.bounds;
    }
    else {
        /// 开始直播按钮
        CGFloat startX = (CGRectGetWidth(self.bounds) - startButtonWidth) / 2;
        self.startButton.frame = CGRectMake(startX, self.bounds.size.height - startButtonBottom - 50, startButtonWidth, 50);
        self.gradientLayer.frame = self.startButton.bounds;
    }
    
    /// 设置控件
    CGFloat configViewHeight = isLandscape && !isPad ? 195 : self.configViewHeight;
    self.configView.frame = CGRectMake((CGRectGetWidth(self.bounds) - configViewWidth) / 2.0, self.bounds.size.height - startButtonBottom - 50 - 24 - configViewHeight, configViewWidth, configViewHeight);
    
    /// 频道名称 (手机端横屏状态时，最多显示两行文本)
    CGFloat textHeight = self.channelNameLableHeight > 48 ? 51 : self.channelNameLableHeight;
    CGFloat scrollViewHeight = isLandscape && !isPad ? textHeight : self.channelNameLableHeight;
    self.scrollView.frame = CGRectMake(channelNameLableLeft, 28, configViewWidth - channelNameLableLeft * 2, scrollViewHeight);
    self.scrollView.contentSize = CGSizeMake(CGRectGetWidth(self.scrollView.frame), self.channelNameLableHeight);
    self.channelNameLable.frame = CGRectMake(0, 0, CGRectGetWidth(self.scrollView.bounds), self.channelNameLableHeight);
    
    /// 分割线
    self.lineView.frame = CGRectMake(lineViewLeft, UIViewGetBottom(self.scrollView) + 13, CGRectGetWidth(self.configView.bounds) - lineViewLeft * 2, 1);
    
    /// 底部按钮
    CGSize buttonSize = CGSizeMake(32, 58);
    CGFloat buttonTop = CGRectGetMaxY(self.configView.bounds) - buttonSize.height - 33;
    CGFloat orientationButtonOffsetWidth = 15.0;
    CGFloat buttonPadding = (CGRectGetWidth(self.configView.bounds) - (buttonSize.width * 4 + orientationButtonOffsetWidth)) / 5;
    self.cameraReverseButton.frame = CGRectMake(buttonPadding, buttonTop, buttonSize.width, buttonSize.height);
    self.mirrorButton.frame = CGRectMake(UIViewGetRight(self.cameraReverseButton) + buttonPadding, buttonTop, buttonSize.width, buttonSize.height);
    self.bitRateButton.frame = CGRectMake(UIViewGetRight(self.mirrorButton) + buttonPadding, buttonTop, buttonSize.width, buttonSize.height);
    self.orientationButton.frame = CGRectMake(UIViewGetRight(self.bitRateButton) + buttonPadding, buttonTop, buttonSize.width + orientationButtonOffsetWidth, buttonSize.height);
    
}

/// 初始化默认清晰度
- (void)initBitRate:(PLVResolutionType)resolutionType {
    PLVResolutionType maxResolution = [PLVRoomDataManager sharedManager].roomData.maxResolution;
    self.resolutionType = resolutionType > maxResolution ? PLVResolutionType360P : resolutionType;
    [self changeBitRateButtonTitleAndImageWithBitRate:self.resolutionType];
}

/// 初始化直播间标题
- (void)initChannelName {
    NSString *channelName = [PLVRoomDataManager sharedManager].roomData.channelName;
    self.channelNameLable.text = channelName;
    self.channelNameTextView.text = channelName;
}

/// 收起输入框
- (void)takeBackTextView {
    CGFloat textViewX = [PLVSAUtils sharedUtils].landscape ? 136 : 29.5;
    CGFloat textViewWidth = CGRectGetWidth(self.bounds) - textViewX * 2;
    self.channelNameTextView.frame = CGRectMake(textViewX, CGRectGetHeight(self.bounds), textViewWidth, 50);
    self.limitLable.frame = CGRectMake(UIViewGetRight(self.channelNameTextView) - 80 - 10, UIViewGetBottom(self.channelNameTextView) + 17 + 20, 80, 17);
}

/// 弹出输入框
- (void)popupTextView:(CGFloat)keyboardY {
    /// 根据键盘高度设置输入框的坐标
    CGFloat paddingY = 12;
    CGFloat textViewX = [PLVSAUtils sharedUtils].landscape ? 136 : 29.5;
    CGFloat textViewWidth = CGRectGetWidth(self.bounds) - textViewX * 2;
    CGFloat textViewHeight = [self.channelNameTextView sizeThatFits:CGSizeMake(textViewWidth, MAXFLOAT)].height;
    self.channelNameTextView.frame = CGRectMake(textViewX, keyboardY - textViewHeight - 17 - paddingY, textViewWidth, textViewHeight);
    self.limitLable.frame = CGRectMake(UIViewGetRight(self.channelNameTextView) - 80 - 10, keyboardY - 4 - 17, 80, 17);
}

- (UIButton *)buttonWithTitle:(NSString *)title NormalImageString:(NSString *)normalImageString selectedImageString:(NSString *)selectedImageString {
    UIButton *button = [[UIButton alloc] init];
    button.imageView.contentMode = UIViewContentModeScaleAspectFit;
    button.titleLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:14];
    [button setTitleColor:PLV_UIColorFromRGBA(@"#F0F1F5",0.6) forState:UIControlStateNormal];
    
    [button setTitle:title forState:UIControlStateNormal];
    [button setImage: [PLVSAUtils imageForLiveroomResource:normalImageString] forState:UIControlStateNormal];
    [button setImage:[PLVSAUtils imageForLiveroomResource:selectedImageString] forState:UIControlStateSelected];
    
    button.imageEdgeInsets = UIEdgeInsetsMake(0,2,25,2);
    button.titleEdgeInsets = UIEdgeInsetsMake(38,-28,0,0);
    [button.titleLabel setTextAlignment:NSTextAlignmentCenter];
    
    return button;
}

/// 计算输入框文本长度
- (double)calculateTextLengthWithString:(NSString *)text {
    double strLength = 0;
    for (int i = 0; i < text.length; i++) {
        NSRange range = NSMakeRange(i, 1);
        NSString *strFromSubStr = [text substringWithRange:range];
        const char * cStringFromstr = [strFromSubStr UTF8String];
        if (cStringFromstr != NULL && strlen(cStringFromstr) == 3){
            strLength += 1;
        } else {
            strLength += 0.5;
        }
    }
    return round(strLength);
}

/// 根据当前清晰度改变清晰度按钮标题和icon
- (void)changeBitRateButtonTitleAndImageWithBitRate:(PLVResolutionType)resolutionType {
    switch (resolutionType) {
        case PLVResolutionType720P:{
            [self.bitRateButton setImage:[PLVSAUtils imageForLiveroomResource:@"plvsa_liveroom_btn_uhd"]  forState:UIControlStateNormal];
            [self.bitRateButton setTitle:@"超清" forState:UIControlStateNormal];
            break;
        }
        case PLVResolutionType360P:{
            [self.bitRateButton setImage:[PLVSAUtils imageForLiveroomResource:@"plvsa_liveroom_btn_hd"]  forState:UIControlStateNormal];
            [self.bitRateButton setTitle:@"高清" forState:UIControlStateNormal];
            break;
        }
        case PLVResolutionType180P:{
            [self.bitRateButton setImage:[PLVSAUtils imageForLiveroomResource:@"plvsa_liveroom_btn_sd"]  forState:UIControlStateNormal];
            [self.bitRateButton setTitle:@"标清" forState:UIControlStateNormal];
            break;
        }
        default:
            break;
    }
}

- (void)showConfigView:(BOOL)show {
    self.configView.hidden = !show;
    self.maskView.hidden = show;
}

#pragma mark Getter & Setter

- (UIButton *)backButton {
    if (!_backButton) {
        _backButton = [UIButton buttonWithType:UIButtonTypeCustom];
        UIImage *image = [PLVSAUtils imageForLiveroomResource:@"plvsa_liveroom_btn_back"];
        [_backButton setImage:image forState:UIControlStateNormal];
        [_backButton addTarget:self action:@selector(backButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _backButton;
}

- (UIButton *)startButton {
    if (!_startButton) {
        _startButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _startButton.layer.cornerRadius = 25;
        _startButton.layer.masksToBounds = YES;
        _startButton.titleLabel.font = [UIFont fontWithName:@"PingFangSC-Medium" size:16];
        NSString *buttonTitle = [PLVRoomDataManager sharedManager].roomData.roomUser.viewerType == PLVRoomUserTypeTeacher ? @"开始直播" : @"进入直播间";
        [_startButton setTitle:buttonTitle forState:UIControlStateNormal];
        [_startButton addTarget:self action:@selector(startButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        [_startButton.layer insertSublayer:self.gradientLayer atIndex:0];
    }
    return _startButton;
}

- (CAGradientLayer *)gradientLayer {
    if (!_gradientLayer) {
        _gradientLayer = [CAGradientLayer layer];
        _gradientLayer.colors = @[(__bridge id)PLV_UIColorFromRGB(@"#0080FF").CGColor, (__bridge id)PLV_UIColorFromRGB(@"#3399FF").CGColor];
        _gradientLayer.locations = @[@0.5, @1.0];
        _gradientLayer.startPoint = CGPointMake(0, 0);
        _gradientLayer.endPoint = CGPointMake(1.0, 0);
    }
    return _gradientLayer;
}

- (UIView *)maskView {
    if (!_maskView) {
        _maskView = [[UIView alloc]init];
        _maskView.backgroundColor = PLV_UIColorFromRGBA(@"#0000000", 0.5);
        _maskView.hidden = YES;
    }
    return _maskView;
}

- (UIView *)configView {
    if (!_configView){
        _configView = [[UIView alloc]init];
        _configView.backgroundColor = PLV_UIColorFromRGBA(@"#464646",0.5);
        _configView.layer.masksToBounds = YES;
        _configView.layer.cornerRadius = 16;
    }
    return _configView;
}

- (UIButton *)cameraReverseButton {
    if (!_cameraReverseButton) {
        _cameraReverseButton = [self buttonWithTitle:@"翻转" NormalImageString:@"plvsa_liveroom_btn_cameraReverse" selectedImageString:@"plvsa_liveroom_btn_cameraReverse"];
        _cameraReverseButton.enabled = NO;
        [_cameraReverseButton addTarget:self action:@selector(cameraReverseAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _cameraReverseButton;
}

- (UIButton *)mirrorButton {
    if (!_mirrorButton) {
        _mirrorButton = [self buttonWithTitle:@"镜像" NormalImageString:@"plvsa_liveroom_btn_mirrorClose" selectedImageString:@"plvsa_liveroom_btn_mirrorOpen"];
        // 默认开启镜像
        _mirrorButton.selected = YES;
        _mirrorButton.enabled = NO;
        [_mirrorButton addTarget:self action:@selector(mirrorAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _mirrorButton;
}

- (UIButton *)bitRateButton {
    if (!_bitRateButton) {
        _bitRateButton = [self buttonWithTitle:@"高清" NormalImageString:@"plvsa_liveroom_btn_hd" selectedImageString:@"plvsa_liveroom_btn_hd"];
        [_bitRateButton addTarget:self action:@selector(bitRateAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _bitRateButton;
}

- (UIButton *)orientationButton {
    if (!_orientationButton) {
        _orientationButton = [self buttonWithTitle:@"横竖屏" NormalImageString:@"plvsa_liveroom_btn_orientation" selectedImageString:@"plvsa_liveroom_btn_orientation"];
        [_orientationButton addTarget:self action:@selector(orientationAction:) forControlEvents:UIControlEventTouchUpInside];
        _orientationButton.imageEdgeInsets = UIEdgeInsetsMake(0,10,25,10);
    }
    return _orientationButton;
}

- (UILabel *)channelNameLable {
    if (!_channelNameLable) {
        _channelNameLable = [[UILabel alloc]init];
        _channelNameLable.text = EnterTips;
        _channelNameLable.backgroundColor = [UIColor clearColor];
        _channelNameLable.font = [UIFont fontWithName:@"PingFangSC-Regular" size:18];
        _channelNameLable.textColor = PLV_UIColorFromRGBA(@"#FFFFFF", 0.6);
        _channelNameLable.numberOfLines = 0;
        _channelNameLable.lineBreakMode = NSLineBreakByCharWrapping;
        _channelNameLable.textAlignment = NSTextAlignmentLeft;
        _channelNameLable.userInteractionEnabled = YES;
        if ([PLVRoomDataManager sharedManager].roomData.roomUser.viewerType == PLVRoomUserTypeTeacher) {
            UITapGestureRecognizer *tapGes = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(startEditingAction:)];
            [_channelNameLable addGestureRecognizer:tapGes];
        }
    }
    return _channelNameLable;
}

- (UITextView *)channelNameTextView {
    if (!_channelNameTextView) {
        _channelNameTextView = [[UITextView alloc]init];
        _channelNameTextView.scrollEnabled = NO;
        _channelNameTextView.backgroundColor = [UIColor clearColor];
        _channelNameTextView.font = [UIFont fontWithName:@"PingFangSC-Regular" size:18];
        _channelNameTextView.textColor = PLV_UIColorFromRGB(@"#FFFFFF");
        _channelNameTextView.textAlignment = NSTextAlignmentLeft;
        _channelNameTextView.tintColor = PLV_UIColorFromRGB(@"#FFFFFF");
        _channelNameTextView.delegate = self;
    }
    return _channelNameTextView;
}

- (UILabel *)limitLable {
    if (!_limitLable) {
        _limitLable = [[UILabel alloc]init];
        _limitLable.text = @"50";
        _limitLable.font = [UIFont fontWithName:@"PingFangSC-Regular" size:12];
        _limitLable.textColor = PLV_UIColorFromRGBA(@"#FFFFFF", 0.7);
        _limitLable.textAlignment = NSTextAlignmentRight;
    }
    return _limitLable;
}

- (UIView *)lineView {
    if (!_lineView) {
        _lineView = [[UIView alloc]init];
        _lineView.backgroundColor = PLV_UIColorFromRGBA(@"#FFFFFF", 0.1);
    }
    return _lineView;
}

- (UIScrollView *)scrollView {
    if (!_scrollView) {
        _scrollView = [[UIScrollView alloc] init];
        _scrollView.showsVerticalScrollIndicator = NO;
    }
    return _scrollView;
}

- (PLVSABitRateSheet *)bitRateSheet {
    if (!_bitRateSheet) {
        BOOL isPad = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
        CGFloat heightScale = isPad ? 0.233 : 0.285;
        CGFloat widthScale = 0.23;
        CGFloat maxWH = MAX([UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width);
        CGFloat sheetHeight = maxWH * heightScale;
        CGFloat sheetLandscapeWidth = maxWH * widthScale;
        _bitRateSheet = [[PLVSABitRateSheet alloc] initWithSheetHeight:sheetHeight sheetLandscapeWidth:sheetLandscapeWidth];
        [_bitRateSheet setupBitRateOptionsWithCurrentBitRate:self.resolutionType];
        _bitRateSheet.delegate = self;
    }
    return _bitRateSheet;
}

- (UIButton *)beautyButton {
    if (!_beautyButton) {
        _beautyButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_beautyButton setImage:[PLVSAUtils imageForBeautyResource:@"plvsa_beauty_setter"] forState:UIControlStateNormal];
        [_beautyButton setTitle:@"美颜" forState:UIControlStateNormal];
        [_beautyButton setTitleColor:[PLVColorUtil colorFromHexString:@"#0382FF"] forState:UIControlStateNormal];
        _beautyButton.titleLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:18];
        _beautyButton.backgroundColor = [UIColor whiteColor];
        _beautyButton.layer.masksToBounds = YES;
        _beautyButton.layer.cornerRadius = 25;
        [_beautyButton setImageEdgeInsets:UIEdgeInsetsMake(0, -8, 0, 0)];
        [_beautyButton setTitleEdgeInsets:UIEdgeInsetsMake(0, 8, 0, 0)];
        [_beautyButton addTarget:self action:@selector(beautyButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _beautyButton;
}

#pragma mark - [ Event ]

#pragma mark Action

- (void)backButtonAction:(id)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(streamerSettingViewBackButtonClick)]) {
        [self.delegate streamerSettingViewBackButtonClick];
    }
}

- (void)startButtonAction:(id)sender {
    if (self.channelNameTextView.text && self.channelNameTextView.text.length) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(streamerSettingViewStartButtonClickWithResolutionType:)]) {
            [self.delegate streamerSettingViewStartButtonClickWithResolutionType:self.resolutionType];
        }
    } else {
        [PLVSAUtils showToastInHomeVCWithMessage:@"直播标题不能为空"];
    }
}

- (void)cameraReverseAction:(UIButton *)sender {
    sender.userInteractionEnabled = NO; //控制翻转按钮点击间隔，防止短时间内重复点击
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        sender.userInteractionEnabled = YES;
    });
    if (self.delegate && [self.delegate respondsToSelector:@selector(streamerSettingViewCameraReverseButtonClick)]) {
        [self.delegate streamerSettingViewCameraReverseButtonClick];
    }
}

- (void)mirrorAction:(UIButton *)sender {
    sender.selected = !sender.selected;
    sender.userInteractionEnabled = NO; //控制镜像按钮点击间隔，防止短时间内重复点击
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        sender.userInteractionEnabled = YES;
    });
    if (self.delegate && [self.delegate respondsToSelector:@selector(streamerSettingViewMirrorButtonClickWithMirror:)]) {
        [self.delegate streamerSettingViewMirrorButtonClickWithMirror:sender.selected];
    }
}

- (void)bitRateAction:(UIButton *)sender {
    [self.bitRateSheet showInView:self];
}

- (void)orientationAction:(UIButton *)sender {
    sender.selected = !sender.selected;
    UIDeviceOrientation orientation = sender.selected ? UIDeviceOrientationLandscapeLeft : UIDeviceOrientationPortrait;
    [self changeDeviceOrientation:orientation];
}


- (void)startEditingAction:(UITapGestureRecognizer *)tap {
    double newLength = [self calculateTextLengthWithString:self.channelNameTextView.text];
    self.limitLable.text = [NSString stringWithFormat:@"%.0f", newLength];
    [self.channelNameTextView becomeFirstResponder];
}

- (void)endEditingAction:(UITapGestureRecognizer *)tap {
    [self endEditing:NO];
}

- (void)beautyButtonAction:(UIButton *)sender {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(streamerSettingViewDidClickBeautyButton:)]) {
        [self.delegate streamerSettingViewDidClickBeautyButton:self];
    }
}

#pragma mark - [ Delegate ]

#pragma mark <UITextViewDelegate>
- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if ([text isEqualToString:@"\n"]) {
        [textView resignFirstResponder];
        return NO;
    }
    
    if(range.length + range.location > textView.text.length) {
        return NO;
    }
    
    NSString *toBeString = [textView.text stringByReplacingCharactersInRange:range withString:text];
    double newLength = [self calculateTextLengthWithString:toBeString];
    if (newLength <= TEXT_MAX_LENGTH) {
        self.limitLable.text = [NSString stringWithFormat:@"%.0f", newLength];
        return YES;
    } else {
        return NO;
    }
}

- (void)textViewDidChange:(UITextView *)textView {
    self.channelNameLable.text = self.channelNameTextView.text.length ? self.channelNameTextView.text : EnterTips;
    // 计算文本高度
    CGFloat textViewHeight = [textView sizeThatFits:CGSizeMake(textView.frame.size.width, MAXFLOAT)].height;
    CGFloat lableHeight = [self.channelNameLable sizeThatFits:CGSizeMake(self.channelNameLable.frame.size.width, MAXFLOAT)].height;
    self.configViewHeight += lableHeight - self.channelNameLableHeight;
    self.channelNameLableHeight = lableHeight;
    
    CGRect rect = self.channelNameTextView.frame;
    CGFloat offsetHeight = textViewHeight - rect.size.height;
    self.channelNameTextView.frame = CGRectMake(rect.origin.x, rect.origin.y - offsetHeight, rect.size.width, textViewHeight);
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    NSString *channelName = textView.text;
    if (channelName.length && ![[PLVRoomDataManager sharedManager].roomData.channelName isEqualToString:channelName]) {
        [PLVLiveVideoAPI updateChannelName:channelName channelId:[PLVRoomDataManager sharedManager].roomData.channelId completion:^{
            [PLVRoomDataManager sharedManager].roomData.channelName = channelName;
            
            [PLVSAUtils showToastInHomeVCWithMessage:@"直播标题修改成功"];
        } failure:^(NSError *error) {
            [PLVSAUtils showToastInHomeVCWithMessage:@"直播标题修改失败，请重新输入"];
        }];
    }
}


#pragma mark <PLVSABitRateSheetDelegate>
- (void)plvsaBitRateSheet:(PLVSABitRateSheet *)bitRateSheet bitRateButtonClickWithBitRate:(PLVResolutionType)bitRate {
    self.resolutionType = bitRate;
    [self changeBitRateButtonTitleAndImageWithBitRate:self.resolutionType];
    if (self.delegate && [self.delegate respondsToSelector:@selector(streamerSettingViewBitRateButtonClickWithResolutionType:)]) {
        [self.delegate streamerSettingViewBitRateButtonClickWithResolutionType:bitRate];
    }
    
}

#pragma mark - [ Event ]
#pragma mark Notification
- (void)keyboardWillShow:(NSNotification *)notification {
    [self showConfigView:NO];
    CGFloat keyboardY = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue].origin.y;
    [self popupTextView:keyboardY];
}

- (void)keyboardWillHide:(NSNotification *)notification {
    [self showConfigView:YES];
    
    BOOL isPad = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
    if (isPad) {
        CGFloat configViewWidth = CGRectGetWidth(self.frame) * 0.66;
        self.configView.frame = CGRectMake((CGRectGetWidth(self.bounds) - configViewWidth) / 2.0, UIViewGetTop(self.startButton) - 24 - self.configViewHeight, configViewWidth, self.configViewHeight);
    } else {
        self.configView.frame = CGRectMake(UIViewGetLeft(self.startButton), UIViewGetTop(self.startButton) - 24 - self.configViewHeight, CGRectGetWidth(self.startButton.frame), self.configViewHeight);
    }
    
    self.channelNameLable.frame = CGRectMake(0, 0, CGRectGetWidth(self.scrollView.bounds), self.channelNameLableHeight);
    [self takeBackTextView];
}

#pragma mark - [ Public Method ]
- (void)cameraAuthorizationGranted:(BOOL)prepareSuccess {
    self.cameraReverseButton.enabled = prepareSuccess;
    self.mirrorButton.enabled = prepareSuccess;
}

- (void)enableMirrorButton:(BOOL)enable{
    self.mirrorButton.enabled = enable;
}

- (void)enableOrientationButton:(BOOL)enable{
    self.orientationButton.enabled = enable;
}

- (void)changeDeviceOrientation:(UIDeviceOrientation)orientation {
    self.canAutorotate = YES;
    [PLVFdUtil changeDeviceOrientation:orientation];
    self.canAutorotate = NO;
    // 缓存设备方向
    [[PLVSAUtils sharedUtils] setupDeviceOrientation:orientation];
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(streamerSettingViewDidChangeDeviceOrientation:)]) {
        [self.delegate streamerSettingViewDidChangeDeviceOrientation:self];
    }
}

- (void)showBeautySheet:(BOOL)show {
    [self showConfigView:!show];
    self.backButton.hidden = show;
    if (show) {
        self.maskView.hidden = YES; // show == NO时，showConfigView内部会处理
    }
    self.beautyButton.hidden = show;
    self.startButton.hidden = show;
}

@end
