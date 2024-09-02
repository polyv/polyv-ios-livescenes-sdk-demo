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
#import "PLVMultiLanguageManager.h"
#import "PLVSABitRateSheet.h"
#import "PLVSANoiseCancellationModeSwitchSheet.h"
#import "PLVSAExternalDeviceSwitchSheet.h"

#define TEXT_MAX_LENGTH 150

static NSString *const kSettingMixLayoutKey = @"kPLVSASettingMixLayoutKey";

@interface PLVSAStreamerSettingView ()<
UITextViewDelegate,
UIGestureRecognizerDelegate,
UIScrollViewDelegate,
PLVSABitRateSheetDelegate,
PLVSAMixLayoutSheetDelegate,
PLVSANoiseCancellationModeSwitchSheetDelegate,
PLVSAExternalDeviceSwitchSheetDelegate
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
/// 按钮滑动承载视图
@property (nonatomic, strong) UIScrollView *buttonScrollView;
/// 按钮分页控制器
@property (nonatomic, strong) UIPageControl *buttonPageControl;
/// 页面按钮数组
@property (nonatomic, strong) NSArray *buttonArray;
/// 摄像头切换
@property (nonatomic, strong) UIButton *cameraReverseButton;
/// 镜像开关
@property (nonatomic, strong) UIButton *mirrorButton;
/// 清晰度
@property (nonatomic, strong) UIButton *bitRateButton;
/// 横竖屏切换
@property (nonatomic, strong) UIButton *orientationButton;
/// 开播画面比例
@property (nonatomic, strong) UIButton *streamScaleButton;
/// 混流布局
@property (nonatomic, strong) UIButton *mixLayoutButton;
/// 降噪模式
@property (nonatomic, strong) UIButton *noiseCancellationModeButton;
/// 外接设备
@property (nonatomic, strong) UIButton *externalDeviceButton;
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
/// 混流布局选择面板
@property (nonatomic, strong) PLVSAMixLayoutSheet *mixLayoutSheet;
/// 降噪模式选择面板
@property (nonatomic, strong) PLVSANoiseCancellationModeSwitchSheet *noiseCancellationModeSwitchSheet;
/// 外接设备选择面板
@property (nonatomic, strong) PLVSAExternalDeviceSwitchSheet *externalDeviceSwitchSheet;
/// 文本滚动视图（为了兼容手机端横屏标题太长时，显示不美观的问题）
@property (nonatomic, strong) UIScrollView *scrollView;
/// 美颜开关
@property (nonatomic, strong) UIButton *beautyButton;

#pragma mark 数据
@property (nonatomic, assign) CGFloat configViewHeight;
@property (nonatomic, assign) CGFloat channelNameLableHeight;
/// 初始化时的默认清晰度
@property (nonatomic, assign) PLVResolutionType resolutionType;
/// 初始化时的默认混流布局
@property (nonatomic, assign) PLVMixLayoutType mixLayoutType;
/// 当前控制器是否可以进行屏幕旋转
@property (nonatomic, assign) BOOL canAutorotate;
/// 当前是否显示混流布局
@property (nonatomic, assign) BOOL canMixLayout;
/// 当前是否显示推流画面比例
@property (nonatomic, assign, readonly) BOOL showStreamScale;
/// 当前频道降噪等级
@property (nonatomic, assign) PLVBLinkMicNoiseCancellationLevel noiseCancellationLevel;
/// 当前频道外接设备是否开启
@property (nonatomic, assign) BOOL externalDeviceEnabled;

@end

@implementation PLVSAStreamerSettingView

#pragma mark - [ Life Cycle ]

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setupUI];
        [self addObserver];
        [self initChannelName];
        /// 根据需要选择默认清晰度
        [self initBitRate:[PLVRoomDataManager sharedManager].roomData.defaultResolution];
        // 初始化设备方向为 竖屏
        [[PLVSAUtils sharedUtils] setupDeviceOrientation:UIDeviceOrientationPortrait];
        UITapGestureRecognizer *tapGes = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(endEditingAction:)];
        tapGes.delegate = self;
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
    [self.configView addSubview:self.buttonScrollView];
    
    [self.buttonScrollView addSubview:self.cameraReverseButton];
    [self.buttonScrollView addSubview:self.mirrorButton];
    [self.buttonScrollView addSubview:self.bitRateButton];
    [self.buttonScrollView addSubview:self.orientationButton];
    [self.buttonScrollView addSubview:self.noiseCancellationModeButton];
    [self.buttonScrollView addSubview:self.externalDeviceButton];
    [self.buttonScrollView addSubview:self.streamScaleButton];
    
    NSMutableArray *muButtonArray = [NSMutableArray arrayWithArray:@[self.cameraReverseButton,
                                                                     self.mirrorButton,
                                                                     self.bitRateButton,
                                                                     self.orientationButton,
                                                                     self.noiseCancellationModeButton,
                                                                     self.externalDeviceButton,
                                                                     self.streamScaleButton]];
    if (self.showMixLayout) {
        [self.buttonScrollView addSubview:self.mixLayoutButton];
        [muButtonArray addObject:self.mixLayoutButton];
    }
    self.buttonArray = [muButtonArray copy];
    [self.configView addSubview:self.buttonPageControl];
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
    startButtonWidth += (self.showStreamScale ? 75 : 0);
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
    self.buttonScrollView.frame = CGRectMake(0, CGRectGetMaxY(self.lineView.frame), CGRectGetWidth(self.configView.bounds), CGRectGetHeight(self.configView.bounds) - CGRectGetMaxY(self.lineView.frame));
    [self setButtonFrameInScrollView];
    self.buttonPageControl.frame = CGRectMake(0, CGRectGetHeight(self.configView.bounds) - 20, CGRectGetWidth(self.configView.bounds), 20);
}

/// 初始化默认清晰度
- (void)initBitRate:(PLVResolutionType)resolutionType {
    PLVResolutionType maxResolution = [PLVRoomDataManager sharedManager].roomData.maxResolution;
    self.resolutionType = resolutionType > maxResolution ? maxResolution : resolutionType;
    [self changeBitRateButtonTitleAndImageWithBitRate:self.resolutionType streamQualityLevel:self.defaultQualityLevel];
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
- (void)changeBitRateButtonTitleAndImageWithBitRate:(PLVResolutionType)resolutionType streamQualityLevel:(NSString * _Nullable)streamQualityLevel {
    NSArray<PLVClientPushStreamTemplateVideoParams *> *videoParamsArray = [PLVLiveVideoConfig sharedInstance].videoParams;
    if ([PLVLiveVideoConfig sharedInstance].clientPushStreamTemplateEnabled &&
        [PLVFdUtil checkArrayUseable:videoParamsArray] &&
        [PLVFdUtil checkStringUseable:streamQualityLevel]) {
        __block PLVClientPushStreamTemplateVideoParams *videoParam;
        [videoParamsArray enumerateObjectsUsingBlock:^(PLVClientPushStreamTemplateVideoParams * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([streamQualityLevel isEqualToString:obj.qualityLevel]) {
                videoParam = obj;
                *stop = YES;
            }
        }];
        if ([PLVMultiLanguageManager sharedManager].currentLanguage == PLVMultiLanguageModeZH) {
            [self.bitRateButton setTitle:videoParam.qualityName forState:UIControlStateNormal];
        } else {
            [self.bitRateButton setTitle:videoParam.qualityEnName forState:UIControlStateNormal];
        }
        if ([videoParam.qualityLevel containsString:@"FHD"]) {
            resolutionType = PLVResolutionType1080P;
        } else if ([videoParam.qualityLevel containsString:@"SHD"]) {
            resolutionType = PLVResolutionType720P;
        } else if ([videoParam.qualityLevel containsString:@"HSD"]) {
            resolutionType = PLVResolutionType480P;
        } else if ([videoParam.qualityLevel containsString:@"LSD"]) {
            resolutionType = PLVResolutionType360P;
        } else {
            resolutionType = PLVResolutionType180P;
        }
    } else {
        switch (resolutionType) {
            case PLVResolutionType1080P:{
                [self.bitRateButton setTitle:PLVLocalizedString(@"超高清") forState:UIControlStateNormal];
                break;
            }
            case PLVResolutionType720P:{
                [self.bitRateButton setTitle:PLVLocalizedString(@"超清") forState:UIControlStateNormal];
                break;
            }
            case PLVResolutionType360P:{
                [self.bitRateButton setTitle:PLVLocalizedString(@"高清") forState:UIControlStateNormal];
                break;
            }
            case PLVResolutionType180P:{
                [self.bitRateButton setTitle:PLVLocalizedString(@"标清") forState:UIControlStateNormal];
                break;
            }
            default:
                break;
        }
    }
    
    if (resolutionType == PLVResolutionType180P) {
        [self.bitRateButton setImage:[PLVSAUtils imageForLiveroomResource:@"plvsa_liveroom_btn_sd"]  forState:UIControlStateNormal];
    } else if (resolutionType == PLVResolutionType360P) {
        [self.bitRateButton setImage:[PLVSAUtils imageForLiveroomResource:@"plvsa_liveroom_btn_sd"]  forState:UIControlStateNormal];
    } else if (resolutionType == PLVResolutionType480P) {
        [self.bitRateButton setImage:[PLVSAUtils imageForLiveroomResource:@"plvsa_liveroom_btn_hd"]  forState:UIControlStateNormal];
    } else if (resolutionType == PLVResolutionType720P) {
        [self.bitRateButton setImage:[PLVSAUtils imageForLiveroomResource:@"plvsa_liveroom_btn_fhd"]  forState:UIControlStateNormal];
    } else if (resolutionType == PLVResolutionType1080P) {
        [self.bitRateButton setImage:[PLVSAUtils imageForLiveroomResource:@"plvsa_liveroom_btn_uhd"]  forState:UIControlStateNormal];
    }
}

- (void)showConfigView:(BOOL)show {
    self.configView.hidden = !show;
    self.maskView.hidden = show;
}

/// 读取本地混流布局配置
- (PLVMixLayoutType)getLocalMixLayoutType {
    // 如果本地有记录优先读取
    NSString *mixLayoutKey = [NSString stringWithFormat:@"%@_%@", kSettingMixLayoutKey, [PLVRoomDataManager sharedManager].roomData.channelId];
    NSString *saveMixLayoutTypeString = [[NSUserDefaults standardUserDefaults] objectForKey:mixLayoutKey];
    if ([PLVFdUtil checkStringUseable:saveMixLayoutTypeString]) {
        PLVMixLayoutType saveMixLayout = saveMixLayoutTypeString.integerValue;
        if (saveMixLayout >= 1 && saveMixLayout <=3) {
            return saveMixLayout;
        }
    }
    // 默认混流配置
    return [PLVRoomDataManager sharedManager].roomData.defaultMixLayoutType;
}

- (void)setButtonFrameInScrollView {
    NSInteger configButtonCount = 5;
    CGSize buttonSize = CGSizeMake(32, 58);
    CGFloat buttonTop = (self.buttonScrollView.bounds.size.height - buttonSize.height) / 2;
    CGFloat buttonPadding = (CGRectGetWidth(self.configView.bounds) - (buttonSize.width * configButtonCount)) / (configButtonCount + 1) ;
    CGFloat buttonOriginX = buttonPadding;
    
    self.streamScaleButton.hidden = !self.showStreamScale;
    NSUInteger showButtonCount = 0;
    for (int i = 0; i < self.buttonArray.count; i++) {
        UIButton * button = self.buttonArray[i];
        if (button.hidden) {
            continue;
        }
        showButtonCount ++;
        if (showButtonCount == 6) {
            buttonOriginX += buttonPadding;
        }
        button.frame = CGRectMake(buttonOriginX, buttonTop, buttonSize.width, buttonSize.height);
        buttonOriginX += buttonSize.width + buttonPadding;
    }
    
    self.buttonScrollView.contentSize = CGSizeMake(CGRectGetWidth(self.configView.bounds) * 2, self.buttonScrollView.bounds.size.height);
}

#pragma mark Callback

- (void)callbackPushStreamScaleChanged:(PLVBLinkMicStreamScale)streamScale {
    [PLVRoomDataManager sharedManager].roomData.streamScale = streamScale;
    if ([PLVSAUtils sharedUtils].isLandscape) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(streamerSettingViewStreamScaleButtonClickWithStreamScale:)]) {
            [self.delegate streamerSettingViewStreamScaleButtonClickWithStreamScale:streamScale];
        }
    }
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
        NSString *buttonTitle = [PLVRoomDataManager sharedManager].roomData.roomUser.viewerType == PLVRoomUserTypeTeacher ? PLVLocalizedString(@"开始直播") : PLVLocalizedString(@"进入直播间");
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
        _cameraReverseButton = [self buttonWithTitle:PLVLocalizedString(@"翻转") NormalImageString:@"plvsa_liveroom_btn_cameraReverse" selectedImageString:@"plvsa_liveroom_btn_cameraReverse"];
        _cameraReverseButton.enabled = NO;
        [_cameraReverseButton addTarget:self action:@selector(cameraReverseAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _cameraReverseButton;
}

- (UIButton *)mirrorButton {
    if (!_mirrorButton) {
        _mirrorButton = [self buttonWithTitle:PLVLocalizedString(@"镜像") NormalImageString:@"plvsa_liveroom_btn_mirrorClose" selectedImageString:@"plvsa_liveroom_btn_mirrorOpen"];
        // 默认开启镜像
        _mirrorButton.selected = YES;
        _mirrorButton.enabled = NO;
        [_mirrorButton addTarget:self action:@selector(mirrorAction:) forControlEvents:UIControlEventTouchUpInside];
        _mirrorButton.titleEdgeInsets = UIEdgeInsetsMake(_mirrorButton.imageView.frame.size.height + 14, - 67, 0, -38);
    }
    return _mirrorButton;
}

- (UIButton *)bitRateButton {
    if (!_bitRateButton) {
        _bitRateButton = [self buttonWithTitle:PLVLocalizedString(@"高清") NormalImageString:@"plvsa_liveroom_btn_hd" selectedImageString:@"plvsa_liveroom_btn_hd"];
        [_bitRateButton addTarget:self action:@selector(bitRateAction:) forControlEvents:UIControlEventTouchUpInside];
        _bitRateButton.titleEdgeInsets = UIEdgeInsetsMake(_bitRateButton.imageView.frame.size.height + 14, - 67, 0, -38);
    }
    return _bitRateButton;
}

- (UIButton *)orientationButton {
    if (!_orientationButton) {
        _orientationButton = [self buttonWithTitle:PLVLocalizedString(@"横竖屏") NormalImageString:@"plvsa_liveroom_btn_orientation" selectedImageString:@"plvsa_liveroom_btn_orientation"];
        [_orientationButton addTarget:self action:@selector(orientationAction:) forControlEvents:UIControlEventTouchUpInside];
        _orientationButton.titleEdgeInsets = UIEdgeInsetsMake(_orientationButton.imageView.frame.size.height + 14, - 67, 0, -38);
    }
    return _orientationButton;
}

- (UIButton *)streamScaleButton {
    if (!_streamScaleButton) {
        _streamScaleButton = [self buttonWithTitle:PLVLocalizedString(@"开播比例") NormalImageString:@"plvsa_liveroom_btn_streamscale_16_9" selectedImageString:@"plvsa_liveroom_btn_streamscale_4_3"];
        [_streamScaleButton addTarget:self action:@selector(streamScaleAction:) forControlEvents:UIControlEventTouchUpInside];
        _streamScaleButton.titleEdgeInsets = UIEdgeInsetsMake(_streamScaleButton.imageView.frame.size.height + 14, - 68, 0, -40);
        _streamScaleButton.hidden = YES;
    }
    return _streamScaleButton;
}

- (UIButton *)noiseCancellationModeButton {
    if (!_noiseCancellationModeButton) {
        _noiseCancellationModeButton = [self buttonWithTitle:PLVLocalizedString(@"降噪") NormalImageString:@"plvsa_liveroom_btn_noise_reduction" selectedImageString:@"plvsa_liveroom_btn_noise_reduction"];
        [_noiseCancellationModeButton addTarget:self action:@selector(noiseCancellationModeButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        _noiseCancellationModeButton.titleEdgeInsets = UIEdgeInsetsMake(_noiseCancellationModeButton.imageView.frame.size.height + 14, - 67, 0, -38);
    }
    return _noiseCancellationModeButton;
}

- (UIButton *)externalDeviceButton {
    if (!_externalDeviceButton) {
        _externalDeviceButton = [self buttonWithTitle:PLVLocalizedString(@"外接设备") NormalImageString:@"plvsa_liveroom_btn_external_device" selectedImageString:@"plvsa_liveroom_btn_external_device"];
        [_externalDeviceButton addTarget:self action:@selector(externalDeviceButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        _externalDeviceButton.titleEdgeInsets = UIEdgeInsetsMake(_externalDeviceButton.imageView.frame.size.height + 14, - 67, 0, -38);
    }
    return _externalDeviceButton;
}

- (UILabel *)channelNameLable {
    if (!_channelNameLable) {
        _channelNameLable = [[UILabel alloc]init];
        _channelNameLable.text = PLVLocalizedString(@"PLVSALiveroomLiveTitleTips");
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

- (UIScrollView *)buttonScrollView {
    if (!_buttonScrollView) {
        _buttonScrollView = [[UIScrollView alloc] init];
        _buttonScrollView.showsHorizontalScrollIndicator = NO;
        _buttonScrollView.delegate = self;
        _buttonScrollView.pagingEnabled = YES;
    }
    return _buttonScrollView;
}

- (UIPageControl *)buttonPageControl {
    if (!_buttonPageControl) {
        _buttonPageControl = [[UIPageControl alloc] init];
        _buttonPageControl.numberOfPages = 2;
        _buttonPageControl.currentPage = 0;
        _buttonPageControl.currentPageIndicatorTintColor = [PLVColorUtil colorFromHexString:@"#2C96FF"];
        _buttonPageControl.pageIndicatorTintColor =  [PLVColorUtil colorFromHexString:@"#BEC2CA"];
    }
    return _buttonPageControl;
}

- (PLVSABitRateSheet *)bitRateSheet {
    if (!_bitRateSheet) {
        BOOL isPad = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
        CGFloat heightScale = isPad ? 0.233 : ([PLVFdUtil checkStringUseable:self.defaultQualityLevel] ? 0.50 : 0.285);
        CGFloat widthScale = [PLVFdUtil checkStringUseable:self.defaultQualityLevel] ? 0.40 : 0.23;
        CGFloat maxWH = MAX([UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width);
        CGFloat sheetHeight = maxWH * heightScale;
        CGFloat sheetLandscapeWidth = maxWH * widthScale;
        _bitRateSheet = [[PLVSABitRateSheet alloc] initWithSheetHeight:sheetHeight sheetLandscapeWidth:sheetLandscapeWidth];
        [_bitRateSheet setupBitRateOptionsWithCurrentBitRate:self.resolutionType streamQualityLevel:self.defaultQualityLevel];
        _bitRateSheet.delegate = self;
    }
    return _bitRateSheet;
}

- (UIButton *)beautyButton {
    if (!_beautyButton) {
        _beautyButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_beautyButton setImage:[PLVSAUtils imageForLiveroomResource:@"plvsa_beauty_setter"] forState:UIControlStateNormal];
        [_beautyButton setTitle:PLVLocalizedString(@"美颜") forState:UIControlStateNormal];
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

- (UIButton *)mixLayoutButton {
    if (!_mixLayoutButton) {
        _mixLayoutButton = [self buttonWithTitle:PLVLocalizedString(@"混流布局") NormalImageString:@"plvsa_liveroom_btn_mixLayout" selectedImageString:@"plvsa_liveroom_btn_mixLayout"];
        [_mixLayoutButton addTarget:self action:@selector(mixLayoutButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        _mixLayoutButton.titleEdgeInsets = UIEdgeInsetsMake(_orientationButton.imageView.frame.size.height + 14, - 67, 0, -38);
    }
    return _mixLayoutButton;
}

- (PLVSAMixLayoutSheet *)mixLayoutSheet {
    if (!_mixLayoutSheet) {
        BOOL isPad = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
        CGFloat heightScale = isPad ? 0.233 : 0.285;
        CGFloat widthScale = 0.23;
        CGFloat maxWH = MAX([UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width);
        CGFloat sheetHeight = maxWH * heightScale;
        CGFloat sheetLandscapeWidth = maxWH * widthScale;
        _mixLayoutSheet = [[PLVSAMixLayoutSheet alloc] initWithSheetHeight:sheetHeight sheetLandscapeWidth:sheetLandscapeWidth];
        [_mixLayoutSheet setupMixLayoutTypeOptionsWithCurrentMixLayoutType:[self getLocalMixLayoutType]]; // 纯视频场景默认为平铺模式
        _mixLayoutSheet.delegate = self;
    }
    return _mixLayoutSheet;
}

- (PLVSANoiseCancellationModeSwitchSheet *)noiseCancellationModeSwitchSheet {
    if (!_noiseCancellationModeSwitchSheet) {
        BOOL isPad = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
        CGFloat heightScale = isPad ? 0.36 : 0.517;
        CGFloat widthScale = 0.37;
        CGFloat maxWH = MAX([UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width);
        CGFloat sheetHeight = MAX(maxWH * heightScale, 420);
        CGFloat sheetLandscapeWidth = MAX(maxWH * widthScale, 375);
        _noiseCancellationModeSwitchSheet = [[PLVSANoiseCancellationModeSwitchSheet alloc] initWithSheetHeight:sheetHeight sheetLandscapeWidth:sheetLandscapeWidth];
        _noiseCancellationModeSwitchSheet.delegate = self;
    }
    return _noiseCancellationModeSwitchSheet;
}

- (PLVSAExternalDeviceSwitchSheet *)externalDeviceSwitchSheet {
    if (!_externalDeviceSwitchSheet) {
        BOOL isPad = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
        CGFloat heightScale = isPad ? 0.33 : 0.473;
        CGFloat widthScale = 0.37;
        CGFloat maxWH = MAX([UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width);
        CGFloat sheetHeight = MAX(maxWH * heightScale, 384);
        CGFloat sheetLandscapeWidth = MAX(maxWH * widthScale, 375);
        _externalDeviceSwitchSheet = [[PLVSAExternalDeviceSwitchSheet alloc] initWithSheetHeight:sheetHeight sheetLandscapeWidth:sheetLandscapeWidth];
        _externalDeviceSwitchSheet.delegate = self;
    }
    return _externalDeviceSwitchSheet;
}

- (BOOL)showStreamScale {
    if ([PLVSAUtils sharedUtils].isLandscape &&
        [PLVRoomDataManager sharedManager].roomData.roomUser.viewerType == PLVRoomUserTypeTeacher &&
        [PLVRoomDataManager sharedManager].roomData.appWebStartResolutionRatioEnabled) {
        return YES;
    }
    return NO;
}

- (BOOL)showMixLayout {
    return [PLVRoomDataManager sharedManager].roomData.roomUser.viewerType == PLVRoomUserTypeTeacher;
}

- (NSString *)defaultQualityLevel {
    if ([PLVLiveVideoConfig sharedInstance].clientPushStreamTemplateEnabled) {
        PLVRoomUserType viewerType = [PLVRoomDataManager sharedManager].roomData.roomUser.viewerType;
        if (viewerType == PLVRoomUserTypeTeacher) {
            return [PLVLiveVideoConfig sharedInstance].teacherDefaultQualityLevel;
        } else if (viewerType == PLVRoomUserTypeGuest) {
            return [PLVLiveVideoConfig sharedInstance].guestDefaultQualityLevel;
        }
    }
    return nil;
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
        [PLVSAUtils showToastInHomeVCWithMessage:PLVLocalizedString(@"直播标题不能为空")];
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

- (void)streamScaleAction:(UIButton *)sender {
    sender.selected = !sender.selected;
    PLVBLinkMicStreamScale streamScale = sender.selected ? PLVBLinkMicStreamScale4_3 : PLVBLinkMicStreamScale16_9;
    [self callbackPushStreamScaleChanged:streamScale];
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

- (void)mixLayoutButtonAction:(UIButton *)sender {
    [self.mixLayoutSheet showInView:self];
}

- (void)noiseCancellationModeButtonAction:(UIButton *)sender {
    [self.noiseCancellationModeSwitchSheet showInView:self.superview currentNoiseCancellationLevel:self.noiseCancellationLevel];
}

- (void)externalDeviceButtonAction:(UIButton *)sender {
    [self.externalDeviceSwitchSheet showInView:self.superview currentExternalDeviceEnabled:self.externalDeviceEnabled];
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
    self.channelNameLable.text = self.channelNameTextView.text.length ? self.channelNameTextView.text : PLVLocalizedString(@"PLVSALiveroomLiveTitleTips");
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
            
            [PLVSAUtils showToastInHomeVCWithMessage:PLVLocalizedString(@"直播标题修改成功")];
        } failure:^(NSError *error) {
            [PLVSAUtils showToastInHomeVCWithMessage:PLVLocalizedString(@"直播标题修改失败，请重新输入")];
        }];
    }
}

#pragma mark <UIGestureRecognizerDelegate>
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if ([NSStringFromClass([touch.view class]) isEqualToString:@"UITableViewCellContentView"] ||
        [NSStringFromClass([touch.view.superview class]) isEqualToString:@"UITableViewCellContentView"]) {
        return NO;
    }
    return  YES;
}

#pragma mark <UIScrollViewDelegate>

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat pageWidth = self.buttonScrollView.frame.size.width;
        NSInteger page = floor((self.buttonScrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
        self.buttonPageControl.currentPage = page;
}

#pragma mark <PLVSABitRateSheetDelegate>
- (void)plvsaBitRateSheet:(PLVSABitRateSheet *)bitRateSheet bitRateButtonClickWithBitRate:(PLVResolutionType)bitRate {
    self.resolutionType = bitRate;
    [self changeBitRateButtonTitleAndImageWithBitRate:self.resolutionType streamQualityLevel:nil];
    if (self.delegate && [self.delegate respondsToSelector:@selector(streamerSettingViewBitRateButtonClickWithResolutionType:)]) {
        [self.delegate streamerSettingViewBitRateButtonClickWithResolutionType:bitRate];
    }
}

- (void)plvsaBitRateSheet:(PLVSABitRateSheet *)bitRateSheet didSelectStreamQualityLevel:(NSString *)streamQualityLevel {
    [self changeBitRateButtonTitleAndImageWithBitRate:self.resolutionType streamQualityLevel:streamQualityLevel];
    if (self.delegate && [self.delegate respondsToSelector:@selector(streamerSettingViewBitRateSheetDidSelectStreamQualityLevel:)]) {
        [self.delegate streamerSettingViewBitRateSheetDidSelectStreamQualityLevel:streamQualityLevel];
    }
}

#pragma mark <PLVSAMixLayoutSheetDelegate>

- (void)plvsaMixLayoutSheet:(PLVSAMixLayoutSheet *)mixLayoutSheet mixLayoutButtonClickWithMixLayoutType:(PLVMixLayoutType)type {
    if (self.delegate && [self.delegate respondsToSelector:@selector(streamerSettingViewMixLayoutButtonClickWithMixLayoutType:)]) {
        [self.delegate streamerSettingViewMixLayoutButtonClickWithMixLayoutType:type];
    }
}

#pragma mark <PLVSANoiseCancellationModeSwitchSheetDelegate>

- (void)noiseCancellationModeSwitchSheet:(PLVSANoiseCancellationModeSwitchSheet *)noiseCancellationModeSwitchSheet wannaChangeNoiseCancellationLevel:(PLVBLinkMicNoiseCancellationLevel)noiseCancellationLevel {
    if (self.delegate && [self.delegate respondsToSelector:@selector(streamerSettingViewTopSettingButtonClickWithNoiseCancellationLevel:)]) {
        [self.delegate streamerSettingViewTopSettingButtonClickWithNoiseCancellationLevel:noiseCancellationLevel];
    }
}

#pragma mark <PLVSAExternalDeviceSwitchSheetDelegate>

- (void)externalDeviceSwitchSheet:(PLVSAExternalDeviceSwitchSheet *)externalDeviceSwitchSheet wannaChangeExternalDevice:(BOOL)enabled {
    if (self.delegate && [self.delegate respondsToSelector:@selector(streamerSettingViewExternalDeviceButtonClickWithExternalDeviceEnabled:)]) {
        [self.delegate streamerSettingViewExternalDeviceButtonClickWithExternalDeviceEnabled:enabled];
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
    self.orientationButton.selected = (orientation != UIDeviceOrientationPortrait);
    self.canAutorotate = YES;
    [PLVFdUtil changeDeviceOrientation:orientation];
    // 缓存设备方向
    [[PLVSAUtils sharedUtils] setupDeviceOrientation:orientation];
    self.canAutorotate = NO;
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

/// 当前开播流比例
- (void)synchPushStreamScale:(PLVBLinkMicStreamScale)streamScale {
    if (streamScale == PLVBLinkMicStreamScale16_9) {
        self.streamScaleButton.selected = NO;
    } else if (streamScale == PLVBLinkMicStreamScale4_3) {
        self.streamScaleButton.selected = YES;
    }
    [self callbackPushStreamScaleChanged:streamScale];
}

/// 当前噪声等级
- (void)synchNoiseCancellationLevel:(PLVBLinkMicNoiseCancellationLevel)noiseCancellationLevel {
    _noiseCancellationLevel = noiseCancellationLevel;
}

/// 当前外接设备开启
- (void)synchExternalDeviceEnabled:(BOOL)enabled {
    _externalDeviceEnabled = enabled;
}

- (void)externalDeviceSwitchSheetViewDismiss {
    [self.externalDeviceSwitchSheet dismiss];
}

@end
