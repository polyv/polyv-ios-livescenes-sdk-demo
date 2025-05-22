//
//  PLVLCSubtitleSettingsView.m
//  PolyvLiveScenesDemo
//
//  Created by Dhan on 2025/5/8.
//  Copyright © 2025 PLV. All rights reserved.
//

#import "PLVLCSubtitleSettingsView.h"
#import "PLVLCUtils.h"
#import "PLVMultiLanguageManager.h"
#import "PLVActionSheet.h"
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>

@interface PLVLCSubtitleLanguageSelectionView : UIView

@property (nonatomic, strong) UILabel *languageLabel;
@property (nonatomic, strong) UIImageView *arrowImageView;
@property (nonatomic, copy) void (^tapHandler)(void);

- (void)updateWithLanguage:(NSString *)language;

@end

@implementation PLVLCSubtitleLanguageSelectionView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setupUI];
    }
    return self;
}

- (UILabel *)languageLabel {
    if (!_languageLabel) {
        _languageLabel = [[UILabel alloc] init];
        _languageLabel.text = @"英文";
        _languageLabel.textColor = PLV_UIColorFromRGB(@"C2C2C2");
        _languageLabel.font = [UIFont fontWithName:@"PingFang SC" size:12];
    }
    return _languageLabel;
}

- (UIImageView *)arrowImageView {
    if (!_arrowImageView) {
        _arrowImageView = [[UIImageView alloc] init];
        _arrowImageView.image = [PLVLCUtils imageForLiveRoomResource:@"plvlc_liveroom_arrow_down"];
        _arrowImageView.contentMode = UIViewContentModeScaleAspectFit;
    }
    return _arrowImageView;
}

- (void)setupUI {
    // 设置背景和边框
    self.backgroundColor = [UIColor clearColor];
    self.layer.borderWidth = 1.0;
    self.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.5].CGColor;
    self.layer.cornerRadius = 4.0;
    self.clipsToBounds = YES;
    
    [self addSubview:self.languageLabel];
    [self addSubview:self.arrowImageView];

    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc]
                                          initWithTarget:self
                                          action:@selector(viewTapped)];
    [self addGestureRecognizer:tapGesture];
    self.userInteractionEnabled = YES;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat padding = 4.0;
    CGFloat arrowSize = 12.0;
    CGFloat spacing = 5.0;
    
    // 设置箭头位置，固定在右侧
    self.arrowImageView.frame = CGRectMake(
        self.bounds.size.width - arrowSize - padding,
        (self.bounds.size.height - arrowSize) / 2.0,
        arrowSize,
        arrowSize
    );
    
    // 设置语言标签位置，左对齐并留出箭头空间
    self.languageLabel.frame = CGRectMake(
        padding,
        0,
        self.bounds.size.width - padding * 2 - arrowSize - spacing,
        self.bounds.size.height
    );
}

- (void)updateWithLanguage:(NSString *)language {
    self.languageLabel.text = language;
    [self sizeToFit];
}

- (CGSize)sizeThatFits:(CGSize)size {
    CGFloat padding = 4.0;
    CGFloat arrowSize = 12.0;
    CGFloat spacing = 5.0;
    
    // 计算文本大小
    NSString *text = self.languageLabel.text ? : @"";
    CGSize textSize = [text sizeWithAttributes:@{
        NSFontAttributeName: self.languageLabel.font
    }];
    
    // 计算总宽度 = 左内边距 + 文本宽度 + 间距 + 箭头宽度 + 右内边距
    CGFloat width = padding + textSize.width + spacing + arrowSize + padding;
    // 固定高度或基于内容高度
    CGFloat height = MAX(28.0, textSize.height + padding * 2);
    
    return CGSizeMake(width, height);
}

- (void)viewTapped {
    if (self.tapHandler) {
        self.tapHandler();
    }
}

@end

@interface PLVLCSubtitleSettingsView ()

// 状态
@property (nonatomic, assign) BOOL originalEnabled;
@property (nonatomic, assign) BOOL translateEnabled;

// 数据
@property (nonatomic, strong) PLVPlaybackSubtitleModel *currentOriginalSubtitle;
@property (nonatomic, strong) PLVPlaybackSubtitleModel *currentTranslateSubtitle;
@property (nonatomic, strong) NSArray<PLVPlaybackSubtitleModel *> *subtitleList;
@property (nonatomic, strong) NSArray<PLVPlaybackSubtitleModel *> *originalSubtitles;
@property (nonatomic, strong) NSArray<PLVPlaybackSubtitleModel *> *translateSubtitles;

// UI
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *originalSubtitleLabel;
@property (nonatomic, strong) UIButton *originalSubtitleButton;
@property (nonatomic, strong) UILabel *translateSubtitleLabel;
@property (nonatomic, strong) UIButton *translateSubtitleButton;
@property (nonatomic, strong) PLVLCSubtitleLanguageSelectionView *languageSelectionView;

@end

@implementation PLVLCSubtitleSettingsView

#pragma mark - Life Cycle

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setupUI];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    BOOL fullScreen = [UIScreen mainScreen].bounds.size.width > [UIScreen mainScreen].bounds.size.height;
    BOOL isPad = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
    
    CGFloat padding = 16.0;
    CGFloat viewWidth = CGRectGetWidth(self.bounds);
    CGFloat controlsHeight = 26.0;
    
    CGFloat titleLabelWidth = [self.titleLabel sizeThatFits:CGSizeMake(120, controlsHeight)].width;
    if (!fullScreen && !isPad) {
        // 竖屏布局
        CGFloat topPadding = 15.0;
        
        CGFloat leftPaddingScale = 88.0 / 375.0;
        CGFloat leftPadding = leftPaddingScale * viewWidth;
        
        CGFloat titleLabelLeftPaddingForTail = leftPadding - 24.0;
        CGFloat titleLabelX = titleLabelLeftPaddingForTail - titleLabelWidth;
        self.titleLabel.frame = CGRectMake(titleLabelX, topPadding, titleLabelWidth, controlsHeight);
        self.titleLabel.textAlignment = NSTextAlignmentRight;
    } else {
        // 横屏布局
        self.titleLabel.frame = CGRectMake(padding, 0, titleLabelWidth, controlsHeight);
        self.titleLabel.textAlignment = NSTextAlignmentLeft;
    }
    
    self.originalSubtitleButton.frame = CGRectMake( CGRectGetMaxX(self.titleLabel.frame) + padding, CGRectGetMinY(self.titleLabel.frame), controlsHeight, controlsHeight);
    CGFloat originalSubtitleLabelWidth = [self.originalSubtitleLabel sizeThatFits:CGSizeMake(120, controlsHeight)].width;
    self.originalSubtitleLabel.frame = CGRectMake( CGRectGetMaxX(self.originalSubtitleButton.frame) + 4, CGRectGetMinY(self.originalSubtitleButton.frame), originalSubtitleLabelWidth, controlsHeight);
    CGFloat translateSubtitleLabelOriginY = !self.originalEnabled ? CGRectGetMinY(self.originalSubtitleLabel.frame) : CGRectGetMaxY(self.originalSubtitleButton.frame) + 8;
    self.translateSubtitleButton.frame = CGRectMake(CGRectGetMaxX(self.titleLabel.frame) + padding, translateSubtitleLabelOriginY, controlsHeight, controlsHeight);
    CGFloat translateSubtitleLabelWidth = [self.translateSubtitleLabel sizeThatFits:CGSizeMake(120, controlsHeight)].width;
    self.translateSubtitleLabel.frame = CGRectMake( CGRectGetMaxX(self.translateSubtitleButton.frame) + 4, translateSubtitleLabelOriginY, translateSubtitleLabelWidth, controlsHeight);
    CGFloat languageSelectionViewWidth = [self.languageSelectionView sizeThatFits:CGSizeMake(120, controlsHeight)].width;
    self.languageSelectionView.frame = CGRectMake( CGRectGetMaxX(self.translateSubtitleLabel.frame) + 4, translateSubtitleLabelOriginY, languageSelectionViewWidth, controlsHeight);
}

#pragma mark - Private Methods

- (void)setupUI {
    [self addSubview:self.titleLabel];
    [self addSubview:self.originalSubtitleButton];
    [self addSubview:self.originalSubtitleLabel];
    [self addSubview:self.translateSubtitleButton];
    [self addSubview:self.translateSubtitleLabel];
    [self addSubview:self.languageSelectionView];
}

- (void)showLanguageSelectionOptions {
    if (![PLVFdUtil checkArrayUseable:self.translateSubtitles]) {
        return;
    }
    
    // 添加语言选择
    NSMutableArray *languages = [NSMutableArray array];
    NSMutableArray *languagesName = [NSMutableArray array];
    for (PLVPlaybackSubtitleModel *model in self.translateSubtitles) {
        if ([PLVPlaybackSubtitleModel isSubtitleAvailable:model]) {
            [languages addObject:model];
            [languagesName addObject:PLVLocalizedString(model.language)];
        }
    }
    if (![PLVFdUtil checkArrayUseable:languages]) {
        return;
    }
    [PLVActionSheet showActionSheetWithTitle:PLVLocalizedString(@"翻译语言") cancelBtnTitle:PLVLocalizedString(@"取消") destructiveBtnTitle:nil otherBtnTitles:[languagesName copy] handler:^(PLVActionSheet * _Nonnull actionSheet, NSInteger index) {
        if (index> 0) {
            PLVPlaybackSubtitleModel *currentModel = languages[index-1];
            self.currentTranslateSubtitle = currentModel;
            [self updateLanguageButtonWithLanguage:PLVLocalizedString(currentModel.language)];
            [self notifyUpdateSubtitle];
        }
    }];
}

#pragma mark - Getters

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.text = PLVLocalizedString(@"回放字幕");
        _titleLabel.textColor = PLV_UIColorFromRGB(@"C2C2C2");
        _titleLabel.font = [UIFont fontWithName:@"PingFang SC" size:12];
    }
    return _titleLabel;
}

- (UILabel *)originalSubtitleLabel {
    if (!_originalSubtitleLabel) {
        _originalSubtitleLabel = [[UILabel alloc] init];
        _originalSubtitleLabel.text = PLVLocalizedString(@"原声字幕");
        _originalSubtitleLabel.textColor = PLV_UIColorFromRGB(@"C2C2C2");
        _originalSubtitleLabel.font = [UIFont fontWithName:@"PingFang SC" size:12];
    }
    return _originalSubtitleLabel;
}

- (UILabel *)translateSubtitleLabel {
    if (!_translateSubtitleLabel) {
        _translateSubtitleLabel = [[UILabel alloc] init];
        _translateSubtitleLabel.text = PLVLocalizedString(@"翻译字幕");
        _translateSubtitleLabel.textColor = PLV_UIColorFromRGB(@"C2C2C2");
        _translateSubtitleLabel.font = [UIFont fontWithName:@"PingFang SC" size:12];
    }
    return _translateSubtitleLabel;
}

- (UIButton *)originalSubtitleButton {
    if (!_originalSubtitleButton) {
        _originalSubtitleButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_originalSubtitleButton setImage:[PLVLCUtils imageForLiveRoomResource:@"plvlc_liveroom_checkbox_unselected"] forState:UIControlStateNormal];
        [_originalSubtitleButton setImage:[PLVLCUtils imageForLiveRoomResource:@"plvlc_liveroom_checkbox_selected"] forState:UIControlStateSelected];
        [_originalSubtitleButton addTarget:self
                                        action:@selector(originalSubtitleButtonAction:)
                              forControlEvents:UIControlEventTouchUpInside];
    }
    return _originalSubtitleButton;
}

- (UIButton *)translateSubtitleButton {
    if (!_translateSubtitleButton) {
        _translateSubtitleButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_translateSubtitleButton setImage:[PLVLCUtils imageForLiveRoomResource:@"plvlc_liveroom_checkbox_unselected"] forState:UIControlStateNormal];
        [_translateSubtitleButton setImage:[PLVLCUtils imageForLiveRoomResource:@"plvlc_liveroom_checkbox_selected"] forState:UIControlStateSelected];
        [_translateSubtitleButton addTarget:self
                                     action:@selector(translateSubtitleButtonAction:)
                           forControlEvents:UIControlEventTouchUpInside];
    }
    return _translateSubtitleButton;
}

- (PLVLCSubtitleLanguageSelectionView *)languageSelectionView {
    if (!_languageSelectionView) {
        _languageSelectionView = [[PLVLCSubtitleLanguageSelectionView alloc] init];
        [_languageSelectionView updateWithLanguage:@"英文"];
        __weak typeof(self) weakSelf = self;
        _languageSelectionView.tapHandler = ^{
            [weakSelf showLanguageSelectionOptions];
        };
        _languageSelectionView.hidden = YES;
    }
    return _languageSelectionView;
}

#pragma mark - Public Methods

- (void)setupWithSubtitleList:(NSArray<NSDictionary *> *)subtitleList {
    if (![subtitleList isKindOfClass:[NSArray class]] || subtitleList.count == 0) {
        return;
    }
    
    NSMutableArray *models = [NSMutableArray array];
    NSMutableArray *originalModels = [NSMutableArray array];
    NSMutableArray *translateModels = [NSMutableArray array];
    
    // 解析字幕列表
    for (NSDictionary *dict in subtitleList) {
        PLVPlaybackSubtitleModel *model = [PLVPlaybackSubtitleModel modelWithDictionary:dict];
        if (![PLVPlaybackSubtitleModel isSubtitleAvailable:model]) {
            continue;
        }
        [models addObject:model];
        
        // 分类存储字幕
        if (model.isOriginal) {
            [originalModels addObject:model];
        } else {
            [translateModels addObject:model];
        }
    }
    
    self.subtitleList = [models copy];
    self.originalSubtitles = [originalModels copy];
    self.translateSubtitles = [translateModels copy];
    
    // 默认设置
    BOOL hasOriginal = originalModels.count > 0;
    BOOL hasTranslate = translateModels.count > 0;
    
    // 设置默认状态
    self.originalEnabled = hasOriginal;
    self.originalSubtitleButton.selected = self.originalEnabled;
    self.originalSubtitleButton.enabled = hasOriginal;
    self.originalSubtitleLabel.hidden = !hasOriginal;
    self.originalSubtitleButton.hidden = !hasOriginal;
    
    if (hasOriginal) {
        self.currentOriginalSubtitle = originalModels.firstObject;
    }
    
    self.translateEnabled = hasTranslate;
    self.translateSubtitleButton.selected = self.translateEnabled;
    self.translateSubtitleButton.enabled = hasTranslate;
    self.translateSubtitleLabel.hidden = !hasTranslate;
    self.translateSubtitleButton.hidden = !hasTranslate;
    
    // 设置默认翻译字幕语言（如果有）
    if (hasTranslate) {
        self.currentTranslateSubtitle = translateModels.firstObject;
        [self updateLanguageButtonWithLanguage:PLVLocalizedString(self.currentTranslateSubtitle.language)];
    }
    
    // 更新语言选择按钮显示状态
    self.languageSelectionView.hidden = !hasTranslate;
    [self notifyUpdateSubtitle];
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

- (void)updateLanguageButtonWithLanguage:(NSString *)language {
    [self.languageSelectionView updateWithLanguage:language];
    [self setNeedsLayout]; // 更新布局以适应可能的文本宽度变化
}

#pragma mark - Actions

- (void)originalSubtitleButtonAction:(UIButton *)button {
    button.selected = !button.selected;
    self.originalEnabled = button.selected;
    [self notifyUpdateSubtitle];
}

- (void)translateSubtitleButtonAction:(UIButton *)button {
    button.selected = !button.selected;
    self.translateEnabled = button.selected;
    
    [self notifyUpdateSubtitle];
}

- (void)notifyUpdateSubtitle {
    if (self.delegate && [self.delegate respondsToSelector:@selector(PLVLCSubtitleSettingsView:didUpdateSubtitleState:translateSubtitle:)]) {
        [self.delegate PLVLCSubtitleSettingsView:self didUpdateSubtitleState:self.originalEnabled ? self.currentOriginalSubtitle : nil translateSubtitle:self.translateEnabled ? self.currentTranslateSubtitle : nil];
    }
}

@end
