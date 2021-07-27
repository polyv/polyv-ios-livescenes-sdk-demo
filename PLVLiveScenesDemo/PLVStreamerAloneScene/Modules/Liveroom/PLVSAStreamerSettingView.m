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

@interface PLVSAStreamerSettingView ()<UITextViewDelegate, PLVSABitRateSheetDelegate>

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
@property (nonatomic, strong) UIButton *backButtton;
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


#pragma mark 数据
@property (nonatomic, assign) CGFloat configViewHeight;
@property (nonatomic, assign) CGFloat channelNameLableHeight;
@property (nonatomic, assign) CGFloat channelNameTextViewHeight;
/// 初始化时的默认清晰度
@property (nonatomic, assign) PLVResolutionType resolutionType;

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
    [self addSubview:self.backButtton];
    [self addSubview:self.startButton];
    
    [self addSubview:self.maskView];
    [self.maskView addSubview:self.limitLable];
    [self.maskView addSubview:self.channelNameTextView];
    
    /// 初始化高度
    self.configViewHeight = 195;
    self.channelNameLableHeight = 26;
    
    [self addSubview:self.configView];
    [self.configView addSubview:self.channelNameLable];
    [self.configView addSubview:self.lineView];
    [self.configView addSubview:self.cameraReverseButton];
    [self.configView addSubview:self.mirrorButton];
    [self.configView addSubview:self.bitRateButton];
}

- (void)updateUI {
    /// 输入框和标题文本高度适应
    CGFloat textViewHeight = [self.channelNameTextView sizeThatFits:CGSizeMake(CGRectGetWidth(self.bounds) - 59, MAXFLOAT)].height;
    CGFloat lableHeight = [self.channelNameLable sizeThatFits:CGSizeMake(CGRectGetWidth(self.configView.bounds) - 56, MAXFLOAT)].height;
    self.configViewHeight += lableHeight - self.channelNameLableHeight;
    self.channelNameLableHeight = lableHeight;
    self.channelNameTextViewHeight = textViewHeight;
    
    CGFloat originX = [PLVSAUtils sharedUtils].areaInsets.left;
    CGFloat originY = [PLVSAUtils sharedUtils].areaInsets.top;
    CGFloat bottom = [PLVSAUtils sharedUtils].areaInsets.bottom + 45;
    self.backButtton.frame = CGRectMake(originX + 24, originY + 9, 36, 36);
    self.startButton.frame = CGRectMake((self.bounds.size.width - 328) / 2.0, self.bounds.size.height - bottom - 50, 328, 50);
    self.gradientLayer.frame = self.startButton.bounds;
    self.maskView.frame = self.bounds;
    self.channelNameTextView.frame = CGRectMake(29.5, originY + CGRectGetHeight(self.bounds) / 4, CGRectGetWidth(self.bounds) - 59, self.channelNameTextViewHeight);
    self.limitLable.frame = CGRectMake(UIViewGetRight(self.channelNameTextView) - 80 - 10, UIViewGetBottom(self.channelNameTextView) + 17 + 20, 80, 17);
    
    self.configView.frame = CGRectMake(UIViewGetLeft(self.startButton), UIViewGetTop(self.startButton) - 24 - self.configViewHeight, CGRectGetWidth(self.startButton.frame), self.configViewHeight);
    self.channelNameLable.frame = CGRectMake(28, 28, CGRectGetWidth(self.configView.bounds) - 56, self.channelNameLableHeight);
    self.lineView.frame = CGRectMake(24, UIViewGetBottom(self.channelNameLable) + 13, CGRectGetWidth(self.configView.bounds) - 48, 1);
    CGSize buttonSize = CGSizeMake(32, 58);
    self.cameraReverseButton.frame = CGRectMake(55, CGRectGetMaxY(self.configView.bounds) - buttonSize.height - 33, buttonSize.width, buttonSize.height);
    self.mirrorButton.frame = CGRectMake(UIViewGetRight(self.cameraReverseButton) + 64, UIViewGetTop(self.cameraReverseButton), buttonSize.width, buttonSize.height);
    self.bitRateButton.frame = CGRectMake(CGRectGetMaxX(self.configView.bounds) - 55 - buttonSize.width, UIViewGetTop(self.cameraReverseButton), buttonSize.width, buttonSize.height);
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

#pragma mark Getter & Setter

- (UIButton *)backButtton {
    if (!_backButtton) {
        _backButtton = [UIButton buttonWithType:UIButtonTypeCustom];
        UIImage *image = [PLVSAUtils imageForLiveroomResource:@"plvsa_liveroom_btn_back"];
        [_backButtton setImage:image forState:UIControlStateNormal];
        [_backButtton addTarget:self action:@selector(backButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _backButtton;
}

- (UIButton *)startButton {
    if (!_startButton) {
        _startButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _startButton.layer.cornerRadius = 25;
        _startButton.layer.masksToBounds = YES;
        _startButton.titleLabel.font = [UIFont fontWithName:@"PingFangSC-Medium" size:16];
        [_startButton setTitle:@"开始直播" forState:UIControlStateNormal];
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
        UITapGestureRecognizer *tapGes = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(startEditingAction:)];
        [_channelNameLable addGestureRecognizer:tapGes];
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

- (PLVSABitRateSheet *)bitRateSheet {
    if (!_bitRateSheet) {
        CGFloat sheetHeight = [UIScreen mainScreen].bounds.size.height * 0.285;
        _bitRateSheet = [[PLVSABitRateSheet alloc] initWithSheetHeight:sheetHeight];
        [_bitRateSheet setupBitRateOptionsWithCurrentBitRate:self.resolutionType];
        _bitRateSheet.delegate = self;
    }
    return _bitRateSheet;
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
    if (self.delegate && [self.delegate respondsToSelector:@selector(streamerSettingViewCameraReverseButtonClick)]) {
        [self.delegate streamerSettingViewCameraReverseButtonClick];
    }
}

- (void)mirrorAction:(UIButton *)sender {
    sender.selected = !sender.selected;
    if (self.delegate && [self.delegate respondsToSelector:@selector(streamerSettingViewMirrorButtonClickWithMirror:)]) {
        [self.delegate streamerSettingViewMirrorButtonClickWithMirror:sender.selected];
    }
}

- (void)bitRateAction:(UIButton *)sender {
    [self.bitRateSheet showInView:self];
}


- (void)startEditingAction:(UITapGestureRecognizer *)tap {
    double newLength = [self calculateTextLengthWithString:self.channelNameTextView.text];
    self.limitLable.text = [NSString stringWithFormat:@"%.0f", newLength];
    [self.channelNameTextView becomeFirstResponder];
}

- (void)endEditingAction:(UITapGestureRecognizer *)tap {
    [self endEditing:NO];
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
    self.channelNameTextViewHeight = textViewHeight;

    CGRect rect = self.channelNameTextView.frame;
    self.channelNameTextView.frame = CGRectMake(rect.origin.x, rect.origin.y, rect.size.width, self.channelNameTextViewHeight);
    self.limitLable.frame = CGRectMake(UIViewGetRight(self.channelNameTextView) - 80 - 10, UIViewGetBottom(self.channelNameTextView) + 17 + 20, 80, 17);
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
    self.maskView.hidden = NO;
    self.configView.hidden = YES;
}

- (void)keyboardWillHide:(NSNotification *)notification {
    self.maskView.hidden = YES;
    self.configView.hidden = NO;
    self.configView.frame = CGRectMake(UIViewGetLeft(self.startButton), UIViewGetTop(self.startButton) - 24 - self.configViewHeight, CGRectGetWidth(self.startButton.frame), self.configViewHeight);
    self.channelNameLable.frame = CGRectMake(28, 28, CGRectGetWidth(self.configView.bounds) - 56, self.channelNameLableHeight);
}

#pragma mark - [ Public Method ]
- (void)cameraAuthorizationGranted:(BOOL)prepareSuccess {
    self.cameraReverseButton.enabled = prepareSuccess;
    self.mirrorButton.enabled = prepareSuccess;
}

- (void)enableMirrorButton:(BOOL)enable{
    self.mirrorButton.enabled = enable;
}

@end
