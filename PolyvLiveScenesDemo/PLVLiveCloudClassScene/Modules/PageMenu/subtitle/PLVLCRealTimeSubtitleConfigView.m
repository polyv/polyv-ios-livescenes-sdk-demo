//
//  PLVLCRealTimeSubtitleConfigView.m
//  PolyvLiveScenesDemo
//
//  Created on 2024.
//  Copyright © 2024 PLV. All rights reserved.
//

#import "PLVLCRealTimeSubtitleConfigView.h"
#import "PLVLCRealTimeSubtitleLanguageSelectView.h"
#import "PLVLiveRealTimeSubtitleHandler.h"
#import "PLVLCUtils.h"
#import "PLVMultiLanguageManager.h"

#import <PLVFoundationSDK/PLVFdUtil.h>
#import <PLVFoundationSDK/PLVColorUtil.h>

static CGFloat kRealTimeSubtitleConfigSheetHeight = 240.0;      // 竖屏时弹窗高度
static CGFloat kRealTimeSubtitleConfigSheetLandscapeWidth = 375.0; // 横屏时弹窗宽度

/// 语言代码对应的显示名称（使用统一的语言映射方法）
static NSString *LanguageDisplayName(NSString *languageCode) {
    return [PLVLiveRealTimeSubtitleHandler languageNameForCode:languageCode];
}

@interface PLVLCRealTimeSubtitleConfigView ()

/// 数据
@property (nonatomic, strong) NSArray<NSString *> *availableLanguages;  // 可用的翻译语言列表

@property (nonatomic, assign) BOOL subtitleEnabled;         // 实时字幕启用状态
@property (nonatomic, assign) BOOL bilingualEnabled;        // 双语字幕启用状态
@property (nonatomic, copy) NSString *selectedLanguage;     // 当前选中的语言代码

/// UI
@property (nonatomic, strong) UILabel *titleLabel;                    // 标题
@property (nonatomic, strong) UIButton *closeButton;                  // 关闭按钮
@property (nonatomic, strong) UIView *innerContentView;               // 内部内容容器

@property (nonatomic, strong) UIView *subtitleSwitchRow;              // 实时字幕开关行
@property (nonatomic, strong) UILabel *subtitleSwitchLabel;           // 实时字幕标签
@property (nonatomic, strong) UISwitch *subtitleSwitch;               // 实时字幕开关

@property (nonatomic, strong) UIView *languageSelectRow;              // 字幕语言选择行
@property (nonatomic, strong) UILabel *languageSelectLabel;           // 字幕语言标签
@property (nonatomic, strong) UILabel *selectedLanguageLabel;         // 选中的语言显示
@property (nonatomic, strong) UIImageView *arrowImageView;            // 右箭头图标

@property (nonatomic, strong) UIView *bilingualSwitchRow;             // 双语字幕开关行
@property (nonatomic, strong) UILabel *bilingualSwitchLabel;          // 双语字幕标签
@property (nonatomic, strong) UISwitch *bilingualSwitch;              // 双语字幕开关

@property (nonatomic, strong) PLVLCRealTimeSubtitleLanguageSelectView *languageSelectView; // 语言选择视图

@end

@implementation PLVLCRealTimeSubtitleConfigView

#pragma mark - Life Cycle

- (instancetype)init {
    return [self initWithSheetHeight:kRealTimeSubtitleConfigSheetHeight 
                 sheetLandscapeWidth:kRealTimeSubtitleConfigSheetLandscapeWidth];
}

- (instancetype)initWithSheetHeight:(CGFloat)sheetHeight sheetLandscapeWidth:(CGFloat)sheetLandscapeWidth {
    UIColor *backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5];
    self = [super initWithSheetHeight:sheetHeight 
                  sheetLandscapeWidth:sheetLandscapeWidth 
                      backgroundColor:backgroundColor];
    if (self) {
        [self setupUI];
        [self setupData];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    // 确保 contentView 的 bounds 有效
    if (CGRectIsEmpty(self.contentView.bounds)) {
        return;
    }
    
    CGFloat contentWidth = CGRectGetWidth(self.contentView.bounds);
    
    // 内部内容容器：充满父类contentView
    self.innerContentView.frame = self.contentView.bounds;
    
    // 标题和关闭按钮
    self.titleLabel.frame = CGRectMake(0, 16, contentWidth, 22);
    self.closeButton.frame = CGRectMake(contentWidth - 44, 8, 44, 44);
    
    // 内容区域
    CGFloat contentY = CGRectGetMaxY(self.titleLabel.frame) + 16;
    
    // 行高和边距
    CGFloat rowHeight = 52;
    CGFloat leftPadding = 16;
    CGFloat rightPadding = 16;
    CGFloat rowWidth = contentWidth - leftPadding - rightPadding;
    
    // 实时字幕开关行
    self.subtitleSwitchRow.frame = CGRectMake(leftPadding, contentY, rowWidth, rowHeight);
    self.subtitleSwitchLabel.frame = CGRectMake(0, 0, rowWidth - 60, rowHeight);
    self.subtitleSwitch.frame = CGRectMake(rowWidth - 51, (rowHeight - 31) / 2, 51, 31);
    
    // 字幕语言选择行
    self.languageSelectRow.frame = CGRectMake(leftPadding, CGRectGetMaxY(self.subtitleSwitchRow.frame), rowWidth, rowHeight);
    self.languageSelectLabel.frame = CGRectMake(0, 0, 80, rowHeight);
    self.selectedLanguageLabel.frame = CGRectMake(CGRectGetWidth(self.languageSelectRow.bounds) - 120 - 16, 0, 120, rowHeight);
    self.arrowImageView.frame = CGRectMake(CGRectGetMaxX(self.selectedLanguageLabel.frame) + 4, (rowHeight - 12) / 2, 12, 12);
    
    // 双语字幕开关行
    self.bilingualSwitchRow.frame = CGRectMake(leftPadding, CGRectGetMaxY(self.languageSelectRow.frame), rowWidth, rowHeight);
    self.bilingualSwitchLabel.frame = CGRectMake(0, 0, rowWidth - 60, rowHeight);
    self.bilingualSwitch.frame = CGRectMake(rowWidth - 51, (rowHeight - 31) / 2, 51, 31);
}

#pragma mark - Private Methods

- (void)setupUI {
    // 设置父类contentView的背景色和圆角
    self.contentView.backgroundColor = PLV_UIColorFromRGBA(@"#202127", 1.0);
    [self setSheetCornerRadius:16];
    
    // 内部内容容器（添加到父类contentView中）
    [self.contentView addSubview:self.innerContentView];
    
    // 标题和关闭按钮
    [self.innerContentView addSubview:self.titleLabel];
    [self.innerContentView addSubview:self.closeButton];
    
    // 实时字幕开关行
    [self.innerContentView addSubview:self.subtitleSwitchRow];
    [self.subtitleSwitchRow addSubview:self.subtitleSwitchLabel];
    [self.subtitleSwitchRow addSubview:self.subtitleSwitch];
    
    // 字幕语言选择行
    [self.innerContentView addSubview:self.languageSelectRow];
    [self.languageSelectRow addSubview:self.languageSelectLabel];
    [self.languageSelectRow addSubview:self.selectedLanguageLabel];
    [self.languageSelectRow addSubview:self.arrowImageView];
    
    // 双语字幕开关行
    [self.innerContentView addSubview:self.bilingualSwitchRow];
    [self.bilingualSwitchRow addSubview:self.bilingualSwitchLabel];
    [self.bilingualSwitchRow addSubview:self.bilingualSwitch];
    
    // 添加点击手势到语言选择行
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(languageRowTapped:)];
    [self.languageSelectRow addGestureRecognizer:tap];
    self.languageSelectRow.userInteractionEnabled = YES;
}

- (void)setupData {
    // 默认状态：关闭
    self.subtitleEnabled = NO;
    self.bilingualEnabled = NO;
    self.selectedLanguage = @"origin";
    
    // 更新UI状态
    [self updateUIState];
}

- (void)updateUIState {
    // 更新开关状态
    self.subtitleSwitch.on = self.subtitleEnabled;
    self.bilingualSwitch.on = self.bilingualEnabled;
    
    // 更新语言显示
    NSString *displayName = LanguageDisplayName(self.selectedLanguage);
    self.selectedLanguageLabel.text = displayName;
    
    // 判断是否选择了"原文（不翻译）"
    BOOL isOriginLanguage = [self.selectedLanguage isEqualToString:@"origin"];
    
    // 如果选择了原文，双语开关必须关闭且不可用
    if (isOriginLanguage) {
        self.bilingualEnabled = NO;
        self.bilingualSwitch.on = NO;
        self.bilingualSwitch.enabled = NO;
        self.bilingualSwitchLabel.textColor = PLV_UIColorFromRGBA(@"#FFFFFF", 0.4); // 置灰
    } else {
        // 选择了翻译语种，双语开关可用
        self.bilingualSwitch.enabled = YES;
        self.bilingualSwitchLabel.textColor = [UIColor whiteColor];
    }
    
    // 字幕关闭时，语言选择和双语开关行置灰且不可交互
    BOOL controlsEnabled = self.subtitleEnabled;
    self.languageSelectRow.userInteractionEnabled = controlsEnabled;
    self.languageSelectLabel.textColor = controlsEnabled ? [UIColor whiteColor] : PLV_UIColorFromRGBA(@"#FFFFFF", 0.4);
    self.selectedLanguageLabel.textColor = controlsEnabled ? PLV_UIColorFromRGBA(@"#ADADC0", 1.0) : PLV_UIColorFromRGBA(@"#ADADC0", 0.4);
    self.arrowImageView.alpha = controlsEnabled ? 1.0 : 0.4;
    
    // 如果字幕关闭或选择原文，双语开关置灰
    if (!controlsEnabled || isOriginLanguage) {
        self.bilingualSwitch.enabled = NO;
        self.bilingualSwitchLabel.textColor = PLV_UIColorFromRGBA(@"#FFFFFF", 0.4);
    }
}

#pragma mark - Public Methods

- (void)setupWithAvailableLanguages:(NSArray<NSString *> *)languages {
    if (![PLVFdUtil checkArrayUseable:languages]) {
        self.availableLanguages = @[];
        return;
    }
    
    // 始终在首位添加"原文（不翻译）"选项
    NSMutableArray *allLanguages = [NSMutableArray arrayWithObject:@"origin"];
    [allLanguages addObjectsFromArray:languages];
    self.availableLanguages = [allLanguages copy];
}

- (void)updateState:(BOOL)enabled
   bilingualEnabled:(BOOL)bilingualEnabled
   selectedLanguage:(NSString *)language {
    self.subtitleEnabled = enabled;
    self.bilingualEnabled = bilingualEnabled;
    self.selectedLanguage = language ?: @"origin";
    
    [self updateUIState];
}

- (void)showInView:(UIView *)parentView {
    [super showInView:parentView];
}

- (void)hide {
    [self dismiss];
}

- (void)deviceOrientationDidChange {
    [self dismiss];
}

#pragma mark - Event Response

- (void)closeButtonAction:(UIButton *)button {
    [self hide];
}

- (void)subtitleSwitchChanged:(UISwitch *)switchControl {
    self.subtitleEnabled = switchControl.on;
    [self updateUIState];
    
    // 通知代理
    if (self.delegate && [self.delegate respondsToSelector:@selector(realTimeSubtitleConfigView:didChangeEnabled:)]) {
        [self.delegate realTimeSubtitleConfigView:self didChangeEnabled:self.subtitleEnabled];
    }
}

- (void)bilingualSwitchChanged:(UISwitch *)switchControl {
    self.bilingualEnabled = switchControl.on;
    [self updateUIState];
    
    // 通知代理
    if (self.delegate && [self.delegate respondsToSelector:@selector(realTimeSubtitleConfigView:didChangeBilingualEnabled:)]) {
        [self.delegate realTimeSubtitleConfigView:self didChangeBilingualEnabled:self.bilingualEnabled];
    }
}

- (void)languageRowTapped:(UITapGestureRecognizer *)gesture {
    // 如果字幕未开启，不响应点击
    if (!self.subtitleEnabled) {
        return;
    }
    
    if (self.availableLanguages.count == 0) {
        return;
    }
    
    if (!self.languageSelectView) {
        self.languageSelectView = [[PLVLCRealTimeSubtitleLanguageSelectView alloc] init];
        __weak typeof(self) weakSelf = self;
        self.languageSelectView.selectionHandler = ^(NSString * _Nonnull selectedLanguage) {
            weakSelf.selectedLanguage = selectedLanguage;
            [weakSelf updateUIState];
            
            // 通知代理
            if (weakSelf.delegate && [weakSelf.delegate respondsToSelector:@selector(realTimeSubtitleConfigView:didSelectLanguage:)]) {
                [weakSelf.delegate realTimeSubtitleConfigView:weakSelf didSelectLanguage:selectedLanguage];
            }
        };
    }
    
    [self.languageSelectView setupWithLanguages:self.availableLanguages selectedLanguage:self.selectedLanguage];
    [self.languageSelectView showInView:self.superview];
}

#pragma mark - Getter & Setter

- (UIView *)innerContentView {
    if (!_innerContentView) {
        _innerContentView = [[UIView alloc] init];
    }
    return _innerContentView;
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.text = PLVLocalizedString(@"实时字幕");
        _titleLabel.textColor = [UIColor whiteColor];
        _titleLabel.font = [UIFont boldSystemFontOfSize:16];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _titleLabel;
}

- (UIButton *)closeButton {
    if (!_closeButton) {
        _closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_closeButton setImage:[PLVLCUtils imageForLiveRoomResource:@"plvlc_player_close_btn"] forState:UIControlStateNormal];
        [_closeButton addTarget:self action:@selector(closeButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _closeButton;
}

- (UIView *)subtitleSwitchRow {
    if (!_subtitleSwitchRow) {
        _subtitleSwitchRow = [[UIView alloc] init];
    }
    return _subtitleSwitchRow;
}

- (UILabel *)subtitleSwitchLabel {
    if (!_subtitleSwitchLabel) {
        _subtitleSwitchLabel = [[UILabel alloc] init];
        _subtitleSwitchLabel.text = PLVLocalizedString(@"实时字幕");
        _subtitleSwitchLabel.textColor = [UIColor whiteColor];
        _subtitleSwitchLabel.font = [UIFont systemFontOfSize:14];
    }
    return _subtitleSwitchLabel;
}

- (UISwitch *)subtitleSwitch {
    if (!_subtitleSwitch) {
        _subtitleSwitch = [[UISwitch alloc] init];
        _subtitleSwitch.onTintColor = PLV_UIColorFromRGB(@"#4399FF");
        [_subtitleSwitch addTarget:self action:@selector(subtitleSwitchChanged:) forControlEvents:UIControlEventValueChanged];
    }
    return _subtitleSwitch;
}

- (UIView *)languageSelectRow {
    if (!_languageSelectRow) {
        _languageSelectRow = [[UIView alloc] init];
    }
    return _languageSelectRow;
}

- (UILabel *)languageSelectLabel {
    if (!_languageSelectLabel) {
        _languageSelectLabel = [[UILabel alloc] init];
        _languageSelectLabel.text = PLVLocalizedString(@"字幕语言");
        _languageSelectLabel.textColor = [UIColor whiteColor];
        _languageSelectLabel.font = [UIFont systemFontOfSize:14];
    }
    return _languageSelectLabel;
}

- (UILabel *)selectedLanguageLabel {
    if (!_selectedLanguageLabel) {
        _selectedLanguageLabel = [[UILabel alloc] init];
        _selectedLanguageLabel.text = PLVLocalizedString(@"原文(不翻译)");
        _selectedLanguageLabel.textColor = PLV_UIColorFromRGBA(@"#ADADC0", 1.0);
        _selectedLanguageLabel.font = [UIFont systemFontOfSize:14];
        _selectedLanguageLabel.textAlignment = NSTextAlignmentRight;
    }
    return _selectedLanguageLabel;
}

- (UIImageView *)arrowImageView {
    if (!_arrowImageView) {
        UIImage *arrowImage = [PLVLCUtils imageForLiveRoomResource:@"plvlc_subtitle_arrow_icon"];
        if (!arrowImage) {
            // 如果没有图片资源，创建一个简单的箭头
            UIGraphicsBeginImageContextWithOptions(CGSizeMake(12, 12), NO, 0);
            UIBezierPath *path = [UIBezierPath bezierPath];
            [path moveToPoint:CGPointMake(4, 2)];
            [path addLineToPoint:CGPointMake(8, 6)];
            [path addLineToPoint:CGPointMake(4, 10)];
            [PLV_UIColorFromRGBA(@"#ADADC0", 1.0) setStroke];
            path.lineWidth = 2;
            [path stroke];
            arrowImage = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
        }
        _arrowImageView = [[UIImageView alloc] initWithImage:arrowImage];
        _arrowImageView.contentMode = UIViewContentModeScaleAspectFit;
    }
    return _arrowImageView;
}

- (UIView *)bilingualSwitchRow {
    if (!_bilingualSwitchRow) {
        _bilingualSwitchRow = [[UIView alloc] init];
    }
    return _bilingualSwitchRow;
}

- (UILabel *)bilingualSwitchLabel {
    if (!_bilingualSwitchLabel) {
        _bilingualSwitchLabel = [[UILabel alloc] init];
        _bilingualSwitchLabel.text = PLVLocalizedString(@"双语字幕");
        _bilingualSwitchLabel.textColor = [UIColor whiteColor];
        _bilingualSwitchLabel.font = [UIFont systemFontOfSize:14];
    }
    return _bilingualSwitchLabel;
}

- (UISwitch *)bilingualSwitch {
    if (!_bilingualSwitch) {
        _bilingualSwitch = [[UISwitch alloc] init];
        _bilingualSwitch.onTintColor = PLV_UIColorFromRGB(@"#4399FF");
        _bilingualSwitch.enabled = NO; // 默认不可用
        [_bilingualSwitch addTarget:self action:@selector(bilingualSwitchChanged:) forControlEvents:UIControlEventValueChanged];
    }
    return _bilingualSwitch;
}

@end
