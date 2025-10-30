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
PLVSABitRateSheetDelegate,
PLVSAMixLayoutSheetDelegate,
PLVSANoiseCancellationModeSwitchSheetDelegate,
PLVSAExternalDeviceSwitchSheetDelegate
>

#pragma mark UI
/// view hierarchy
///
/// (PLVSAStreamerSettingView) self
/// ├── (UIView) configView
/// ├── (UIButton) backButton
/// ├── (UIButton) startButton
/// ├── (UIView) customMaskView
/// └── (UIView) PLVSAXXXXSheet
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
@property (nonatomic, strong) UIView *buttonView;;
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
/// 连麦布局
@property (nonatomic, strong) UIButton *mixLayoutButton;
/// 贴纸按钮
@property (nonatomic, strong) UIButton *stickerButton;
/// 本地视频按钮  用于加载本地相册视频并播放
@property (nonatomic, strong) UIButton *stickerVideoButton;
/// 虚拟背景按钮
@property (nonatomic, strong) UIButton *virtualBackgroundButton;
/// 降噪模式
@property (nonatomic, strong) UIButton *noiseCancellationModeButton;
/// 外接设备
@property (nonatomic, strong) UIButton *externalDeviceButton;
/// 回放设置
@property (nonatomic, strong) UIButton *playbackSettingButton;
/// 直播名称
@property (nonatomic, strong) UILabel *channelNameLabel;
/// 输入框蒙层（负责承载频道名称输入框和频道名称剩余可输入的字符数）
@property (nonatomic, strong) UIView *customMaskView;
/// 频道名称剩余可输入字符数
@property (nonatomic, strong) UILabel *limitLable;
/// 频道名称输入框
@property (nonatomic, strong) UITextView *channelNameTextView;
/// 清晰度选择面板
@property (nonatomic, strong) PLVSABitRateSheet *bitRateSheet;
/// 连麦布局选择面板
@property (nonatomic, strong) PLVSAMixLayoutSheet *mixLayoutSheet;
/// 降噪模式选择面板
@property (nonatomic, strong) PLVSANoiseCancellationModeSwitchSheet *noiseCancellationModeSwitchSheet;
/// 外接设备选择面板
@property (nonatomic, strong) PLVSAExternalDeviceSwitchSheet *externalDeviceSwitchSheet;
/// 美颜开关
@property (nonatomic, strong) UIButton *beautyButton;

#pragma mark 数据
@property (nonatomic, assign) CGFloat configViewHeight;
@property (nonatomic, assign) CGFloat channelNameLabelHeight;
/// 初始化时的默认清晰度
@property (nonatomic, assign) PLVResolutionType resolutionType;
/// 初始化时的默认连麦布局
@property (nonatomic, assign) PLVMixLayoutType mixLayoutType;
/// 当前控制器是否可以进行屏幕旋转
@property (nonatomic, assign) BOOL canAutorotate;
/// 当前是否显示连麦布局
@property (nonatomic, assign) BOOL canMixLayout;
/// 当前是否显示推流画面比例
@property (nonatomic, assign, readonly) BOOL showStreamScale;
/// 当前频道降噪等级
@property (nonatomic, assign) PLVBLinkMicNoiseCancellationLevel noiseCancellationLevel;
/// 当前频道外接设备是否开启
@property (nonatomic, assign) BOOL externalDeviceEnabled;
/// 当前频道是否开启回放
@property (nonatomic, assign) BOOL playbackEnabled;

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
        [self initPlaybackEnabled];
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
    [self addSubview:self.configView];
    [self addSubview:self.backButton];
    [self addSubview:self.startButton];
    
    
    [self addSubview:self.customMaskView];
    [self.customMaskView addSubview:self.limitLable];
    [self.customMaskView addSubview:self.channelNameTextView];
    
    [self.configView addSubview:self.channelNameLabel];
    
    [self.configView addSubview:self.lineView];
    [self.configView addSubview:self.buttonView];
    
    [self.buttonView addSubview:self.cameraReverseButton];
    NSMutableArray *muButtonArray = [NSMutableArray arrayWithArray:@[self.cameraReverseButton]];
    
    if ([PLVRoomDataManager sharedManager].roomData.canUseBeauty) {
        [self.buttonView addSubview:self.beautyButton];
        [muButtonArray addObject:self.beautyButton];
    }
    
    // 虚拟背景
    if ([PLVRoomDataManager sharedManager].roomData.mattingEnabled) {
        [self.buttonView addSubview:self.virtualBackgroundButton];
        [muButtonArray addObject:self.virtualBackgroundButton];
    }
    
    [self.buttonView addSubview:self.mirrorButton];
    [self.buttonView addSubview:self.bitRateButton];
    [muButtonArray addObjectsFromArray:@[self.mirrorButton,
                                         self.bitRateButton]];
    if (self.showOrientation) {
        [self.buttonView addSubview:self.orientationButton];
        [muButtonArray addObject:self.orientationButton];
    }
    [self.buttonView addSubview:self.noiseCancellationModeButton];
    [self.buttonView addSubview:self.externalDeviceButton];
    [self.buttonView addSubview:self.streamScaleButton];
    [muButtonArray addObjectsFromArray:@[self.noiseCancellationModeButton,
                                         self.externalDeviceButton,
                                         self.streamScaleButton]];
    if (self.showMixLayout) {
        [self.buttonView addSubview:self.mixLayoutButton];
        [muButtonArray addObject:self.mixLayoutButton];
    }

    [self.buttonView addSubview:self.stickerButton];
    [muButtonArray addObject:self.stickerButton];
    
    [self.buttonView addSubview:self.stickerVideoButton];
    [muButtonArray addObject:self.stickerVideoButton];
    
    if ([PLVRoomDataManager sharedManager].roomData.roomUser.viewerType == PLVRoomUserTypeTeacher) {
        [self.buttonView addSubview:self.playbackSettingButton];
        [muButtonArray addObject:self.playbackSettingButton];
    }
    
    self.buttonArray = [muButtonArray copy];
}

- (void)updateUI {
    BOOL isPad = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
    CGFloat originX = [PLVSAUtils sharedUtils].areaInsets.left;
    CGFloat originY = [PLVSAUtils sharedUtils].areaInsets.top;
    CGFloat bottom = [PLVSAUtils sharedUtils].areaInsets.bottom;
    BOOL isLandscape = [PLVSAUtils sharedUtils].isLandscape;
    
    CGFloat backButtonTop = originY + 9;
    CGFloat startButtonBottom = bottom + (isLandscape ? 16 : 45);
    CGFloat configViewWidth = self.bounds.size.width;
    CGFloat sideSpacing = 48;
    CGFloat sideMargin = sideSpacing + originX;
    CGFloat startButtonWidth = MIN(MIN(self.bounds.size.width, self.bounds.size.height) - 2 * sideSpacing , 280);
    
    if (isPad) {
        backButtonTop = originY + 20;
        startButtonBottom = bottom + 100;
        sideSpacing = 64;
        sideMargin = sideSpacing + originX;
    }
    
    /// 标题文本高度适应
    self.channelNameLabelHeight = [self.channelNameLabel sizeThatFits:CGSizeMake(configViewWidth - sideMargin * 2, MAXFLOAT)].height;
    
    self.backButton.frame = CGRectMake(originX + 24, backButtonTop, 36, 36);
    self.customMaskView.frame = self.bounds;
    self.configView.frame = self.bounds;
    /// 初始化时默认收起输入框
    [self takeBackTextView];
    
    CGFloat startX = (CGRectGetWidth(self.bounds) - startButtonWidth) / 2;
    self.startButton.frame = CGRectMake(startX, self.bounds.size.height - startButtonBottom - 50, startButtonWidth, 50);
    self.gradientLayer.frame = self.startButton.bounds;
    
    /// 频道名称 (手机端横屏状态时，最多显示两行文本)
    CGFloat textHeight = self.channelNameLabelHeight > 48 ? 51 : self.channelNameLabelHeight;
    self.channelNameLabel.frame = CGRectMake(sideMargin, CGRectGetMaxY(self.backButton.frame) + 20, configViewWidth - sideMargin * 2 ,textHeight);
    
    /// 分割线
    self.lineView.frame = CGRectMake(CGRectGetMinX(self.channelNameLabel.frame), CGRectGetMaxY(self.channelNameLabel.frame) + 13, CGRectGetWidth(self.channelNameLabel.frame), 2);
    
    /// 底部按钮
    self.buttonView.frame = CGRectMake(sideMargin, CGRectGetMaxY(self.lineView.frame), configViewWidth - sideMargin * 2, CGRectGetMinY(self.startButton.frame) - CGRectGetMaxY(self.lineView.frame) - 8);
    NSInteger configButtonCount = isLandscape || isPad ? 8 : 5;
    CGSize buttonSize = CGSizeMake(32, 58);
    self.streamScaleButton.hidden = !self.showStreamScale;
    NSUInteger showButtonCount = !self.showStreamScale ? (self.buttonArray.count - 1) : self.buttonArray.count;
    NSUInteger buttonLineNum = showButtonCount % configButtonCount == 0 ? showButtonCount / configButtonCount : showButtonCount / configButtonCount + 1;
    CGFloat buttonBottomMargin = !isLandscape || buttonLineNum == 1 ? 24 : 0;
    CGFloat buttonVerticalSpacing = MIN(24, (self.buttonView.frame.size.height - buttonSize.height * buttonLineNum - buttonBottomMargin) / (buttonLineNum + 1));
    CGFloat buttonTop = self.buttonView.frame.size.height - buttonSize.height * buttonLineNum - buttonVerticalSpacing * buttonLineNum;
    CGFloat buttonPadding = (MIN(self.bounds.size.width, self.bounds.size.height) - 48 * 2 - (buttonSize.width * 5)) / 4;
    if (isPad) {
        buttonPadding = (MIN(self.bounds.size.width, self.bounds.size.height) - 48 * 2 - (buttonSize.width * 8)) / 7;
    }
    
    NSInteger firstLineCount = buttonLineNum > 1 ? configButtonCount : showButtonCount;
    CGFloat firstButtonOriginX = (self.buttonView.frame.size.width - firstLineCount * buttonSize.width - buttonPadding * (firstLineCount - 1)) / 2;
    CGFloat buttonOriginX = firstButtonOriginX;
   
    NSUInteger showButtonNum = 0;
    for (int i = 0; i < self.buttonArray.count; i++) {
        UIButton * button = self.buttonArray[i];
        if (button.hidden) {
            continue;
        }
        showButtonNum ++;
        button.frame = CGRectMake(buttonOriginX, buttonTop, buttonSize.width, buttonSize.height);
        if (showButtonNum % configButtonCount == 0) {
            buttonOriginX = firstButtonOriginX;
            buttonTop += buttonSize.height + buttonVerticalSpacing;
        } else {
            buttonOriginX += buttonSize.width + buttonPadding;
        }
    }
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
    self.channelNameLabel.text = channelName;
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
    button.titleLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:12];
    [button setTitleColor:PLV_UIColorFromRGBA(@"#F0F1F5",0.6) forState:UIControlStateNormal];
    
    [button setTitle:title forState:UIControlStateNormal];
    [button setImage: [PLVSAUtils imageForLiveroomResource:normalImageString] forState:UIControlStateNormal];
    [button setImage:[PLVSAUtils imageForLiveroomResource:selectedImageString] forState:UIControlStateSelected];
    
    button.imageEdgeInsets = UIEdgeInsetsMake(0,2,25,2);
    button.titleEdgeInsets = UIEdgeInsetsMake(38,-28,0,0);
    [button.titleLabel setTextAlignment:NSTextAlignmentCenter];
    [button.titleLabel setLineBreakMode:NSLineBreakByWordWrapping];
    
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
        if ([PLVMultiLanguageManager sharedManager].currentLanguage == PLVMultiLanguageModeZH || [PLVMultiLanguageManager sharedManager].currentLanguage == PLVMultiLanguageModeZH_HK) {
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
    self.customMaskView.hidden = show;
}

/// 读取本地连麦布局配置
- (PLVMixLayoutType)getLocalMixLayoutType {
    // 如果本地有记录优先读取
    NSString *mixLayoutKey = [NSString stringWithFormat:@"%@_%@", kSettingMixLayoutKey, [PLVRoomDataManager sharedManager].roomData.channelId];
    NSString *saveMixLayoutTypeString = [[NSUserDefaults standardUserDefaults] objectForKey:mixLayoutKey];
    if ([PLVFdUtil checkStringUseable:saveMixLayoutTypeString] && [PLVRoomDataManager sharedManager].roomData.showMixLayoutButtonEnabled) {
        PLVMixLayoutType saveMixLayout = saveMixLayoutTypeString.integerValue;
        if (saveMixLayout >= 1 && saveMixLayout <=5) {
            return saveMixLayout;
        }
    }
    // 默认混流配置
    return [PLVRoomDataManager sharedManager].roomData.defaultMixLayoutType;
}

- (void)initPlaybackEnabled {
    if ([PLVRoomDataManager sharedManager].roomData.roomUser.viewerType == PLVRoomUserTypeTeacher) {
        return;
    }
    NSString *channelId = [PLVRoomDataManager sharedManager].roomData.channelId;
    PLVLiveVideoConfig *liveConfig = [PLVLiveVideoConfig sharedInstance];
    typeof(self) __weak weakSelf = self;
    [PLVLiveVideoAPI requestPlaybackEnableWithChannelId:channelId appId:liveConfig.appId appSecret:liveConfig.appSecret completion:^(BOOL enable, NSError * _Nullable error) {
        if (!error) {
            weakSelf.playbackEnabled = enable;
        } else {
            PLV_LOG_DEBUG(PLVConsoleLogModuleTypeVerbose, @"PLVSAStreamerSettingSheet request playback enable error: %@", error.localizedDescription);
        }
        
    }];
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

- (UIView *)customMaskView {
    if (!_customMaskView) {
        _customMaskView = [[UIView alloc]init];
        _customMaskView.backgroundColor = PLV_UIColorFromRGBA(@"#000000", 0.5);
        _customMaskView.hidden = YES;
    }
    return _customMaskView;
}

- (UIView *)configView {
    if (!_configView){
        _configView = [[UIView alloc]init];
        _configView.backgroundColor = PLV_UIColorFromRGBA(@"#000000",0.15);
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
        _cameraReverseButton.titleEdgeInsets = UIEdgeInsetsMake(_cameraReverseButton.imageView.frame.size.height + 4, - 67, 0, -38);
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
        _mirrorButton.titleEdgeInsets = UIEdgeInsetsMake(_mirrorButton.imageView.frame.size.height + 4, - 67, 0, -38);
    }
    return _mirrorButton;
}

- (UIButton *)bitRateButton {
    if (!_bitRateButton) {
        _bitRateButton = [self buttonWithTitle:PLVLocalizedString(@"高清") NormalImageString:@"plvsa_liveroom_btn_hd" selectedImageString:@"plvsa_liveroom_btn_hd"];
        [_bitRateButton addTarget:self action:@selector(bitRateAction:) forControlEvents:UIControlEventTouchUpInside];
        _bitRateButton.titleEdgeInsets = UIEdgeInsetsMake(_bitRateButton.imageView.frame.size.height + 4, - 67, 0, -38);
    }
    return _bitRateButton;
}

- (UIButton *)orientationButton {
    if (!_orientationButton) {
        _orientationButton = [self buttonWithTitle:PLVLocalizedString(@"横竖屏") NormalImageString:@"plvsa_liveroom_btn_orientation" selectedImageString:@"plvsa_liveroom_btn_orientation"];
        [_orientationButton addTarget:self action:@selector(orientationAction:) forControlEvents:UIControlEventTouchUpInside];
        _orientationButton.titleEdgeInsets = UIEdgeInsetsMake(_orientationButton.imageView.frame.size.height + 4, - 67, 0, -38);
    }
    return _orientationButton;
}

- (UIButton *)streamScaleButton {
    if (!_streamScaleButton) {
        _streamScaleButton = [self buttonWithTitle:PLVLocalizedString(@"开播比例") NormalImageString:@"plvsa_liveroom_btn_streamscale_16_9" selectedImageString:@"plvsa_liveroom_btn_streamscale_4_3"];
        [_streamScaleButton addTarget:self action:@selector(streamScaleAction:) forControlEvents:UIControlEventTouchUpInside];
        _streamScaleButton.titleEdgeInsets = UIEdgeInsetsMake(_streamScaleButton.imageView.frame.size.height + 4, - 67, 0, -38);
        _streamScaleButton.hidden = YES;
    }
    return _streamScaleButton;
}

- (UIButton *)stickerButton {
    if (!_stickerButton) {
        _stickerButton = [self buttonWithTitle:PLVLocalizedString(@"贴图") NormalImageString:@"plvsa_liveroom_btn_sticker" selectedImageString:@"plvsa_liveroom_btn_sticker"];
        [_stickerButton addTarget:self action:@selector(stickerButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        _stickerButton.titleEdgeInsets = UIEdgeInsetsMake(_stickerButton.imageView.frame.size.height + 4, - 67, 0, -38);
    }
    return _stickerButton;
}

- (UIButton *)stickerVideoButton {
    if (!_stickerVideoButton) {
        _stickerVideoButton = [self buttonWithTitle:PLVLocalizedString(@"视频") NormalImageString:@"plvsa_liveroom_btn_local_video" selectedImageString:@"plvsa_liveroom_btn_local_video"];
        [_stickerVideoButton addTarget:self action:@selector(stickerVideoButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        _stickerVideoButton.titleEdgeInsets = UIEdgeInsetsMake(_stickerVideoButton.imageView.frame.size.height + 4, - 67, 0, -38);
    }
    return _stickerVideoButton;
}

- (UIButton *)virtualBackgroundButton {
    if (!_virtualBackgroundButton) {
        _virtualBackgroundButton = [self buttonWithTitle:PLVLocalizedString(@"虚拟背景") NormalImageString:@"plvsa_liveroom_btn_virtual_bg" selectedImageString:@"plvsa_liveroom_btn_virtual_bg"];
        [_virtualBackgroundButton addTarget:self action:@selector(virtualBackgroundButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        _virtualBackgroundButton.titleEdgeInsets = UIEdgeInsetsMake(_virtualBackgroundButton.imageView.frame.size.height + 4, - 67, 0, -38);
    }
    return _virtualBackgroundButton;
}

- (UIButton *)noiseCancellationModeButton {
    if (!_noiseCancellationModeButton) {
        _noiseCancellationModeButton = [self buttonWithTitle:PLVLocalizedString(@"声音音质Btn") NormalImageString:@"plvsa_liveroom_btn_noise_reduction" selectedImageString:@"plvsa_liveroom_btn_noise_reduction"];
        [_noiseCancellationModeButton addTarget:self action:@selector(noiseCancellationModeButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        _noiseCancellationModeButton.titleEdgeInsets = UIEdgeInsetsMake(_noiseCancellationModeButton.imageView.frame.size.height + 4, - 67, 0, -38);
    }
    return _noiseCancellationModeButton;
}

- (UIButton *)externalDeviceButton {
    if (!_externalDeviceButton) {
        _externalDeviceButton = [self buttonWithTitle:PLVLocalizedString(@"外接设备Btn") NormalImageString:@"plvsa_liveroom_btn_external_device" selectedImageString:@"plvsa_liveroom_btn_external_device"];
        [_externalDeviceButton addTarget:self action:@selector(externalDeviceButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        _externalDeviceButton.titleEdgeInsets = UIEdgeInsetsMake(_externalDeviceButton.imageView.frame.size.height + 4, - 67, 0, -38);
    }
    return _externalDeviceButton;
}

- (UIButton *)playbackSettingButton {
    if (!_playbackSettingButton) {
        _playbackSettingButton = [self buttonWithTitle:PLVLocalizedString(@"直播回放") NormalImageString:@"plvsa_liveroom_btn_playback_close" selectedImageString:@"plvsa_liveroom_btn_playback_open"];
        [_playbackSettingButton addTarget:self action:@selector(playbackSettingButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        _playbackSettingButton.titleEdgeInsets = UIEdgeInsetsMake(_playbackSettingButton.imageView.frame.size.height + 4, - 67, 0, -38);
    }
    return _playbackSettingButton;
}

- (UILabel *)channelNameLabel {
    if (!_channelNameLabel) {
        _channelNameLabel = [[UILabel alloc]init];
        _channelNameLabel.text = PLVLocalizedString(@"PLVSALiveroomLiveTitleTips");
        _channelNameLabel.backgroundColor = [UIColor clearColor];
        _channelNameLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:18];
        _channelNameLabel.textColor = PLV_UIColorFromRGBA(@"#FFFFFF", 0.6);
        _channelNameLabel.numberOfLines = 2;
        _channelNameLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        _channelNameLabel.textAlignment = NSTextAlignmentCenter;
        _channelNameLabel.userInteractionEnabled = YES;
        if ([PLVRoomDataManager sharedManager].roomData.roomUser.viewerType == PLVRoomUserTypeTeacher) {
            UITapGestureRecognizer *tapGes = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(startEditingAction:)];
            [_channelNameLabel addGestureRecognizer:tapGes];
        }
    }
    return _channelNameLabel;
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


- (UIView *)buttonView {
    if (!_buttonView) {
        _buttonView = [[UIView alloc] init];
    }
    return _buttonView;
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
        _beautyButton = [self buttonWithTitle:PLVLocalizedString(@"美颜") NormalImageString:@"plvsa_beauty_setter" selectedImageString:@"plvsa_beauty_setter"];
        [_beautyButton addTarget:self action:@selector(beautyButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        _beautyButton.titleEdgeInsets = UIEdgeInsetsMake(_beautyButton.imageView.frame.size.height + 4, - 67, 0, -38);
        
    }
    return _beautyButton;
}

- (UIButton *)mixLayoutButton {
    if (!_mixLayoutButton) {
        _mixLayoutButton = [self buttonWithTitle:PLVLocalizedString(@"连麦布局Btn") NormalImageString:@"plvsa_liveroom_btn_mixLayout" selectedImageString:@"plvsa_liveroom_btn_mixLayout"];
        [_mixLayoutButton addTarget:self action:@selector(mixLayoutButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        _mixLayoutButton.titleEdgeInsets = UIEdgeInsetsMake(_mixLayoutButton.imageView.frame.size.height + 4, - 67, 0, -38);
    }
    return _mixLayoutButton;
}

- (PLVSAMixLayoutSheet *)mixLayoutSheet {
    if (!_mixLayoutSheet) {
        BOOL isPad = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
        CGFloat heightScale = isPad ? 0.43 : 0.52;
        CGFloat widthScale = 0.44;
        CGFloat maxWH = MAX([UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width);
        CGFloat sheetHeight = maxWH * heightScale;
        CGFloat sheetLandscapeWidth = maxWH * widthScale;
        _mixLayoutSheet = [[PLVSAMixLayoutSheet alloc] initWithSheetHeight:sheetHeight sheetLandscapeWidth:sheetLandscapeWidth];
        [_mixLayoutSheet setupOptionsWithCurrentMixLayoutType:[self getLocalMixLayoutType] currentBackgroundColor:PLVMixLayoutBackgroundColor_Black]; // 纯视频场景默认为平铺模式
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
    PLVRoomData *roomData = [PLVRoomDataManager sharedManager].roomData;
    return roomData.roomUser.viewerType == PLVRoomUserTypeTeacher && roomData.showMixLayoutButtonEnabled && roomData.appStartMultiplexingLayoutEnabled;
}

- (BOOL)showOrientation {
    return [PLVRoomDataManager sharedManager].roomData.showOrientationButtonEnabled;
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

- (void)setPlaybackEnabled:(BOOL)playbackEnabled {
    _playbackEnabled = playbackEnabled;
    self.playbackSettingButton.selected = playbackEnabled;
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

- (void)playbackSettingButtonAction:(UIButton *)sender {
    self.playbackEnabled = !self.playbackSettingButton.selected;
    typeof(self) __weak weakSelf = self;
    NSString *channelId = [PLVRoomDataManager sharedManager].roomData.channelId;
    [PLVLiveVideoAPI updatePlaybackSettingWithChannelId:channelId playbackEnabled:self.playbackEnabled completion:nil failure:^(NSError * _Nonnull error) {
        PLV_LOG_DEBUG(PLVConsoleLogModuleTypeVerbose, @"PLVSAStreamerSettingSheet update playback enable error: %@", error.localizedDescription);
        weakSelf.playbackEnabled = !weakSelf.playbackEnabled;
    }];
}

- (void)stickerButtonAction:(UIButton *)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(streamerSettingViewDidClickStickerButton:)]) {
        [self.delegate streamerSettingViewDidClickStickerButton:self];
    }
}

- (void)stickerVideoButtonAction:(UIButton *)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(streamerSettingViewDidClickStickerVideoButton:)]) {
        [self.delegate streamerSettingViewDidClickStickerVideoButton:self];
    }
}

- (void)virtualBackgroundButtonAction:(UIButton *)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(streamerSettingViewDidClickVirtualBackgroundButton:)]) {
        [self.delegate streamerSettingViewDidClickVirtualBackgroundButton:self];
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
    self.channelNameLabel.text = self.channelNameTextView.text.length ? self.channelNameTextView.text : PLVLocalizedString(@"PLVSALiveroomLiveTitleTips");
    // 计算文本高度
    CGFloat textViewHeight = [textView sizeThatFits:CGSizeMake(textView.frame.size.width, MAXFLOAT)].height;
    CGFloat labelHeight = [self.channelNameLabel sizeThatFits:CGSizeMake(self.channelNameLabel.frame.size.width, MAXFLOAT)].height;
    self.configViewHeight += labelHeight - self.channelNameLabelHeight;
    self.channelNameLabelHeight = labelHeight;
    
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
    return YES;
}

#pragma mark - Override UIView Methods

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *hitView = [super hitTest:point withEvent:event];
    
    // 如果点击的是当前视图本身(而不是子视图)，则不响应事件
    if (hitView == self || [hitView isEqual:self.configView] || [hitView isEqual:self.buttonView]) {
        return nil;
    }
    
    return hitView;
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

- (void)plvsaMixLayoutSheet:(PLVSAMixLayoutSheet *)mixLayoutSheet didSelectBackgroundColor:(PLVMixLayoutBackgroundColor)colorType {
    if (self.delegate && [self.delegate respondsToSelector:@selector(streamerSettingViewMixLayoutButtonClickWithBackgroundColor:)]) {
        [self.delegate streamerSettingViewMixLayoutButtonClickWithBackgroundColor:colorType];
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
    self.configView.frame = self.bounds;

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
        self.customMaskView.hidden = YES; // show == NO时，showConfigView内部会处理
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
