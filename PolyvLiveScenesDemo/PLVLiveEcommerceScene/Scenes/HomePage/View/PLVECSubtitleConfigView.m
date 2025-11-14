//
//  PLVECSubtitleConfigView.m
//  PolyvLiveScenesDemo
//
//  Created by polyv on 2025/10/10.
//  Copyright © 2025 PLV. All rights reserved.
//

#import "PLVECSubtitleConfigView.h"
#import "PLVECSubtitleTranslationSelectView.h"
#import "PLVECUtils.h"
#import "PLVMultiLanguageManager.h"
#import <PLVFoundationSDK/PLVFdUtil.h>
#import <PLVFoundationSDK/PLVColorUtil.h>

static CGFloat kSubtitleConfigSheetHeight = 190.0;      // 竖屏时弹窗高度
static CGFloat kSubtitleConfigSheetLandscapeWidth = 375.0; // 横屏时弹窗宽度

@interface PLVECSubtitleConfigView ()

/// 数据
@property (nonatomic, strong) NSArray<PLVPlaybackSubtitleModel *> *subtitleList;     // 全部字幕列表
@property (nonatomic, strong) NSArray<PLVPlaybackSubtitleModel *> *originalSubtitles; // 原声字幕列表
@property (nonatomic, strong) NSArray<PLVPlaybackSubtitleModel *> *translateSubtitles; // 翻译字幕列表

@property (nonatomic, assign) BOOL originalEnabled;     // 原声字幕启用状态
@property (nonatomic, assign) BOOL translateEnabled;    // 翻译字幕启用状态
@property (nonatomic, strong) PLVPlaybackSubtitleModel *currentOriginalSubtitle;  // 当前选中的原声字幕
@property (nonatomic, strong) PLVPlaybackSubtitleModel *currentTranslateSubtitle;  // 当前选中的翻译字幕

/// UI
@property (nonatomic, strong) UILabel *titleLabel;                    // 标题
@property (nonatomic, strong) UIButton *closeButton;                  // 关闭按钮
@property (nonatomic, strong) UIView *innerContentView;               // 内部内容容器（添加到父类contentView中）
@property (nonatomic, strong) UIView *originalSubtitleRow;            // 原声字幕行
@property (nonatomic, strong) UILabel *originalSubtitleLabel;         // 原声字幕标签
@property (nonatomic, strong) UILabel *originalLanguageLabel;         // 原声字幕语言标签
@property (nonatomic, strong) UIButton *originalSubtitleButton;       // 原声字幕开关
@property (nonatomic, strong) UIView *translateSubtitleRow;           // 翻译字幕行
@property (nonatomic, strong) UILabel *translateSubtitleLabel;        // 翻译字幕标签
@property (nonatomic, strong) UILabel *translateLanguageLabel;        // 翻译字幕语言标签
@property (nonatomic, strong) UIImageView *arrowImageView;            // 右箭头图标
@property (nonatomic, strong) UIButton *translateSubtitleButton;      // 翻译字幕开关

@property (nonatomic, strong) PLVECSubtitleTranslationSelectView *translationSelectView; // 翻译选择视图

@end

@implementation PLVECSubtitleConfigView

#pragma mark - Life Cycle

- (instancetype)init {
    return [self initWithSheetHeight:kSubtitleConfigSheetHeight sheetLandscapeWidth:kSubtitleConfigSheetLandscapeWidth];
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
    
    // 原声字幕行
    CGFloat rowHeight = 52;
    CGFloat leftPadding = 16;
    CGFloat rightPadding = 16;
    CGFloat rowWidth = contentWidth - leftPadding - rightPadding;
    
    self.originalSubtitleRow.frame = CGRectMake(leftPadding, contentY, rowWidth, rowHeight);
    self.originalSubtitleButton.frame = CGRectMake(0, (rowHeight - 16) / 2, 16, 16);
    self.originalSubtitleLabel.frame = CGRectMake(CGRectGetMaxX(self.originalSubtitleButton.frame) + 8, 0, 80, rowHeight);
    self.originalLanguageLabel.frame = CGRectMake(CGRectGetWidth(self.originalSubtitleRow.bounds) - 100 - 16, 0, 100, rowHeight);
    
    // 翻译字幕行
    self.translateSubtitleRow.frame = CGRectMake(leftPadding, CGRectGetMaxY(self.originalSubtitleRow.frame), rowWidth, rowHeight);
    self.translateSubtitleButton.frame = CGRectMake(0, (rowHeight - 16) / 2, 16, 16);
    self.translateSubtitleLabel.frame = CGRectMake(CGRectGetMaxX(self.translateSubtitleButton.frame) + 8, 0, 80, rowHeight);
    self.translateLanguageLabel.frame = CGRectMake(CGRectGetWidth(self.translateSubtitleRow.bounds) - 100 - 16, 0, 100, rowHeight);
    self.arrowImageView.frame = CGRectMake(CGRectGetMaxX(self.translateLanguageLabel.frame) + 4, (rowHeight - 12) / 2, 12, 12);
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
    
    // 原声字幕行
    [self.innerContentView addSubview:self.originalSubtitleRow];
    [self.originalSubtitleRow addSubview:self.originalSubtitleLabel];
    [self.originalSubtitleRow addSubview:self.originalLanguageLabel];
    [self.originalSubtitleRow addSubview:self.originalSubtitleButton];
    
    // 翻译字幕行
    [self.innerContentView addSubview:self.translateSubtitleRow];
    [self.translateSubtitleRow addSubview:self.translateSubtitleLabel];
    [self.translateSubtitleRow addSubview:self.translateLanguageLabel];
    [self.translateSubtitleRow addSubview:self.arrowImageView];
    [self.translateSubtitleRow addSubview:self.translateSubtitleButton];
    
    // 添加点击手势到翻译字幕行
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(translateRowTapped:)];
    [self.translateLanguageLabel addGestureRecognizer:tap];
    self.translateLanguageLabel.userInteractionEnabled = YES;
}

- (void)setupData {
    self.originalEnabled = NO;
    self.translateEnabled = NO;
}

- (void)updateSubtitleState {
    PLVPlaybackSubtitleModel *originalSubtitle = self.originalEnabled ? self.currentOriginalSubtitle : nil;
    PLVPlaybackSubtitleModel *translateSubtitle = self.translateEnabled ? self.currentTranslateSubtitle : nil;
    
    // 更新语言标签
    if (originalSubtitle) {
        self.originalLanguageLabel.text = PLVLocalizedString(originalSubtitle.language);
    } else {
        self.originalLanguageLabel.text = @"";
    }
    
    if (translateSubtitle) {
        self.translateLanguageLabel.text = PLVLocalizedString(translateSubtitle.language);
    } else {
        self.translateLanguageLabel.text = @"";
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(subtitleConfigView:didUpdateSubtitleOriginal:translate:)]) {
        [self.delegate subtitleConfigView:self didUpdateSubtitleOriginal:originalSubtitle translate:translateSubtitle];
    }
}

#pragma mark - Public Methods

- (void)setupWithSubtitleList:(NSArray<PLVPlaybackSubtitleModel *> *)subtitleList {
    if (![PLVFdUtil checkArrayUseable:subtitleList]) {
        return;
    }
    
    NSMutableArray *models = [NSMutableArray array];
    NSMutableArray *originalModels = [NSMutableArray array];
    NSMutableArray *translateModels = [NSMutableArray array];
    
    // 解析字幕列表
    for (PLVPlaybackSubtitleModel *model in subtitleList) {
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
    
    BOOL hasOriginal = originalModels.count > 0;
    BOOL hasTranslate = translateModels.count > 0;
    
    self.translateSubtitleButton.enabled = hasTranslate;
    
    // 每次视频切换后都使用初始设置（第一个字幕，默认启用）
    if (hasOriginal) {
        self.originalSubtitleButton.hidden = NO;
        self.originalSubtitleLabel.hidden = NO;
        self.originalLanguageLabel.hidden = NO;
        // 使用第一个原声字幕，默认启用
        self.currentOriginalSubtitle = originalModels.firstObject;
        self.originalEnabled = YES;
        self.originalSubtitleButton.selected = YES;
    } else {
        self.currentOriginalSubtitle = nil;
        self.originalEnabled = NO;
        self.originalSubtitleButton.selected = NO;
        // 没有原生字幕 隐藏相关组件
        self.originalSubtitleButton.hidden = YES;
        self.originalSubtitleLabel.hidden = YES;
        self.originalLanguageLabel.hidden = YES;
    }
    
    if (hasTranslate) {
        self.translateSubtitleButton.hidden = NO;
        self.translateSubtitleLabel.hidden = NO;
        self.translateLanguageLabel.hidden = NO;
        self.arrowImageView.hidden = NO;
        // 使用第一个翻译字幕，默认启用
        self.currentTranslateSubtitle = translateModels.firstObject;
        self.translateEnabled = YES;
        self.translateSubtitleButton.selected = YES;
    } else {
        self.currentTranslateSubtitle = nil;
        self.translateEnabled = NO;
        self.translateSubtitleButton.selected = NO;
        // 没有翻译字幕 隐藏相关组件
        self.translateSubtitleButton.hidden = YES;
        self.translateSubtitleLabel.hidden = YES;
        self.translateLanguageLabel.hidden = YES;
        self.arrowImageView.hidden = YES;
    }
    
    [self updateSubtitleState];
}

- (void)showInView:(UIView *)parentView {
    [super showInView:parentView];
}

- (void)hide {
    [self dismiss];
}

- (void)deviceOrientationDidChange {
    [super deviceOrientationDidChange];
    // 横竖屏切换时，更新翻译选择视图的位置
    if (self.translationSelectView && self.translationSelectView.superview) {
        BOOL isLandscape = [PLVECUtils sharedUtils].isLandscape && self.superLandscape;
        if (isLandscape) {
            CGFloat landscapeWidth = kSubtitleConfigSheetLandscapeWidth;
            CGFloat rightInset = [PLVECUtils sharedUtils].areaInsets.right;
            self.translationSelectView.frame = CGRectMake(
                CGRectGetWidth(self.superview.bounds) - landscapeWidth - rightInset,
                0,
                landscapeWidth + rightInset,
                CGRectGetHeight(self.superview.bounds)
            );
        } else {
            self.translationSelectView.frame = CGRectMake(
                0,
                CGRectGetHeight(self.superview.bounds) - 396,
                CGRectGetWidth(self.superview.bounds),
                396
            );
        }
    }
}

#pragma mark - Event Response

- (void)closeButtonAction:(UIButton *)button {
    [self hide];
}

- (void)originalSubtitleButtonAction:(UIButton *)button {
    self.originalEnabled = !self.originalEnabled;
    button.selected = self.originalEnabled;
    [self updateSubtitleState];
}

- (void)translateSubtitleButtonAction:(UIButton *)button {
    self.translateEnabled = !self.translateEnabled;
    button.selected = self.translateEnabled;
    [self updateSubtitleState];
}

- (void)translateRowTapped:(UITapGestureRecognizer *)gesture {
    if (self.translateSubtitles.count == 0 || self.translateEnabled == NO) return;
    
    if (!self.translationSelectView) {
        self.translationSelectView = [[PLVECSubtitleTranslationSelectView alloc] initWithFrame:CGRectZero];
        __weak typeof(self) weakSelf = self;
        self.translationSelectView.selectionHandler = ^(PLVPlaybackSubtitleModel * _Nonnull selectedModel) {
            weakSelf.currentTranslateSubtitle = selectedModel;
            [weakSelf updateSubtitleState];
        };
    }
    
    [self.translationSelectView setupWithSubtitleList:self.translateSubtitles selectedModel:self.currentTranslateSubtitle];
    BOOL isLandscape = [PLVECUtils sharedUtils].isLandscape && self.superLandscape;
    CGRect frame;
    if (isLandscape) {
        CGFloat landscapeWidth = kSubtitleConfigSheetLandscapeWidth;
        CGFloat rightInset = [PLVECUtils sharedUtils].areaInsets.right;
        frame = CGRectMake(
            CGRectGetWidth(self.superview.bounds) - landscapeWidth - rightInset,
            0,
            landscapeWidth + rightInset,
            CGRectGetHeight(self.superview.bounds)
        );
    } else {
        frame = CGRectMake(0, CGRectGetHeight(self.superview.bounds) - 396, CGRectGetWidth(self.superview.bounds), 396);
    }
    self.translationSelectView.frame = frame;
    [self.translationSelectView showInView:self.superview];
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
        _titleLabel.text = PLVLocalizedString(@"回放字幕");
        _titleLabel.textColor = [UIColor whiteColor];
        _titleLabel.font = [UIFont boldSystemFontOfSize:16];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _titleLabel;
}

- (UIButton *)closeButton {
    if (!_closeButton) {
        _closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_closeButton setImage:[PLVECUtils imageForWatchResource:@"plvec_player_close_btn"] forState:UIControlStateNormal];
        [_closeButton addTarget:self action:@selector(closeButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _closeButton;
}


- (UIView *)originalSubtitleRow {
    if (!_originalSubtitleRow) {
        _originalSubtitleRow = [[UIView alloc] init];
    }
    return _originalSubtitleRow;
}

- (UILabel *)originalSubtitleLabel {
    if (!_originalSubtitleLabel) {
        _originalSubtitleLabel = [[UILabel alloc] init];
        _originalSubtitleLabel.text = PLVLocalizedString(@"原生字幕");
        _originalSubtitleLabel.textColor = [UIColor whiteColor];
        _originalSubtitleLabel.font = [UIFont systemFontOfSize:14];
    }
    return _originalSubtitleLabel;
}

- (UILabel *)originalLanguageLabel {
    if (!_originalLanguageLabel) {
        _originalLanguageLabel = [[UILabel alloc] init];
        _originalLanguageLabel.text = PLVLocalizedString(@"中文");
        _originalLanguageLabel.textColor = PLV_UIColorFromRGBA(@"#ADADC0", 1.0);
        _originalLanguageLabel.font = [UIFont systemFontOfSize:14];
    }
    return _originalLanguageLabel;
}

- (UIButton *)originalSubtitleButton {
    if (!_originalSubtitleButton) {
        _originalSubtitleButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_originalSubtitleButton setImage:[PLVECUtils imageForWatchResource:@"plvec_checkbox_unselected"] forState:UIControlStateNormal];
        [_originalSubtitleButton setImage:[PLVECUtils imageForWatchResource:@"plvec_checkbox_selected"] forState:UIControlStateSelected];
        [_originalSubtitleButton addTarget:self action:@selector(originalSubtitleButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _originalSubtitleButton;
}

- (UIView *)translateSubtitleRow {
    if (!_translateSubtitleRow) {
        _translateSubtitleRow = [[UIView alloc] init];
    }
    return _translateSubtitleRow;
}

- (UILabel *)translateSubtitleLabel {
    if (!_translateSubtitleLabel) {
        _translateSubtitleLabel = [[UILabel alloc] init];
        _translateSubtitleLabel.text = PLVLocalizedString(@"翻译字幕");
        _translateSubtitleLabel.textColor = [UIColor whiteColor];
        _translateSubtitleLabel.font = [UIFont systemFontOfSize:14];
    }
    return _translateSubtitleLabel;
}

- (UILabel *)translateLanguageLabel {
    if (!_translateLanguageLabel) {
        _translateLanguageLabel = [[UILabel alloc] init];
        _translateLanguageLabel.text = PLVLocalizedString(@"英文");
        _translateLanguageLabel.textColor = PLV_UIColorFromRGBA(@"#ADADC0", 1.0);
        _translateLanguageLabel.font = [UIFont systemFontOfSize:14];
    }
    return _translateLanguageLabel;
}

- (UIImageView *)arrowImageView {
    if (!_arrowImageView) {
        UIImage *arrowImage = [PLVECUtils imageForWatchResource:@"plvec_subtitle_arrow_icon"];
        _arrowImageView = [[UIImageView alloc] initWithImage:arrowImage];
        _arrowImageView.contentMode = UIViewContentModeScaleAspectFit;
    }
    return _arrowImageView;
}

- (UIButton *)translateSubtitleButton {
    if (!_translateSubtitleButton) {
        _translateSubtitleButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_translateSubtitleButton setImage:[PLVECUtils imageForWatchResource:@"plvec_checkbox_unselected"] forState:UIControlStateNormal];
        [_translateSubtitleButton setImage:[PLVECUtils imageForWatchResource:@"plvec_checkbox_selected"] forState:UIControlStateSelected];
        [_translateSubtitleButton addTarget:self action:@selector(translateSubtitleButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _translateSubtitleButton;
}

@end
