//
//  PLVSAChatroomSettingSheet.m
//  PLVLiveScenesDemo
//

#import "PLVSAChatroomSettingSheet.h"

#import "PLVSAUtils.h"
#import "PLVMultiLanguageManager.h"
#import <PLVFoundationSDK/PLVFoundationSDK.h>

static NSString * const kPLVSAChatroomHeightUserDefaultsKey = @"PLVSAChatroomSetting.height";
static NSString * const kPLVSAChatroomFontUserDefaultsKey = @"PLVSAChatroomSetting.font";

@implementation PLVSAChatroomSetting

- (instancetype)init {
    self = [super init];
    if (self) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        id heightValue = [defaults objectForKey:kPLVSAChatroomHeightUserDefaultsKey];
        id fontValue = [defaults objectForKey:kPLVSAChatroomFontUserDefaultsKey];
        _heightLevel = heightValue ? [heightValue integerValue] : PLVSAChatroomHeightLevelMedium;
        _fontLevel = fontValue ? [fontValue integerValue] : PLVSAChatroomFontLevelSmall;
        _heightLevel = MAX(PLVSAChatroomHeightLevelLow, MIN(PLVSAChatroomHeightLevelHigh, _heightLevel));
        _fontLevel = MAX(PLVSAChatroomFontLevelSmall, MIN(PLVSAChatroomFontLevelLarge, _fontLevel));
    }
    return self;
}

- (void)save {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:self.heightLevel forKey:kPLVSAChatroomHeightUserDefaultsKey];
    [defaults setInteger:self.fontLevel forKey:kPLVSAChatroomFontUserDefaultsKey];
}

+ (CGFloat)heightForLevel:(PLVSAChatroomHeightLevel)level maximumHeight:(CGFloat)maximumHeight landscape:(BOOL)landscape {
    CGFloat height;
    switch (level) {
        case PLVSAChatroomHeightLevelLow:
            height = landscape ? 72.0 : 118.0;
            break;
        case PLVSAChatroomHeightLevelHigh:
            height = landscape ? 164.0 : 358.0;
            break;
        case PLVSAChatroomHeightLevelMedium:
        default:
            height = landscape ? 108.0 : 238.0;
            break;
    }
    return MIN(height, maximumHeight);
}

+ (CGFloat)fontSizeForLevel:(PLVSAChatroomFontLevel)level {
    switch (level) {
        case PLVSAChatroomFontLevelMedium:
            return 14.0;
        case PLVSAChatroomFontLevelLarge:
            return 16.0;
        case PLVSAChatroomFontLevelSmall:
        default:
            return 12.0;
    }
}

@end

@interface PLVSAChatroomSettingView ()

@property (nonatomic, strong) UILabel *heightTitleLabel;
@property (nonatomic, strong) UILabel *fontTitleLabel;
@property (nonatomic, strong) UIView *heightSelectorView;
@property (nonatomic, strong) UIView *fontSelectorView;
@property (nonatomic, strong) NSArray<UIButton *> *heightButtons;
@property (nonatomic, strong) NSArray<UIButton *> *fontButtons;
@property (nonatomic, strong) UIButton *doneButton;

@end


@implementation PLVSAChatroomSettingView

- (instancetype)init {
    self = [super init];
    if (self) {
        self.backgroundColor = UIColor.clearColor;
        self.hidden = YES;

        _heightTitleLabel = [self titleLabelWithText:PLVLocalizedString(@"高度")];
        _fontTitleLabel = [self titleLabelWithText:PLVLocalizedString(@"字号")];
        _heightSelectorView = [self selectorView];
        _fontSelectorView = [self selectorView];
        _heightButtons = [self addButtonsWithTitles:@[PLVLocalizedString(@"高"), PLVLocalizedString(@"中"), PLVLocalizedString(@"低")]
                                                  levels:@[@(PLVSAChatroomHeightLevelHigh), @(PLVSAChatroomHeightLevelMedium), @(PLVSAChatroomHeightLevelLow)]
                                                  action:@selector(heightButtonAction:)
                                                  toView:_heightSelectorView];
        _fontButtons = [self addButtonsWithTitles:@[PLVLocalizedString(@"大"), PLVLocalizedString(@"中"), PLVLocalizedString(@"小")]
                                                levels:@[@(PLVSAChatroomFontLevelLarge), @(PLVSAChatroomFontLevelMedium), @(PLVSAChatroomFontLevelSmall)]
                                                action:@selector(fontButtonAction:)
                                                toView:_fontSelectorView];

        _doneButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _doneButton.backgroundColor = PLV_UIColorFromRGB(@"#3082FE");
        _doneButton.layer.cornerRadius = 20.0;
        _doneButton.titleLabel.font = [UIFont systemFontOfSize:14.0 weight:UIFontWeightMedium];
        [_doneButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
        [_doneButton setTitle:PLVLocalizedString(@"完成") forState:UIControlStateNormal];
        [_doneButton addTarget:self action:@selector(doneButtonAction) forControlEvents:UIControlEventTouchUpInside];

        [self addSubview:_heightTitleLabel];
        [self addSubview:_fontTitleLabel];
        [self addSubview:_heightSelectorView];
        [self addSubview:_fontSelectorView];
        [self addSubview:_doneButton];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];

    CGFloat selectorWidth = 32.0;
    CGFloat selectorHeight = 116.0;
    CGFloat columnPadding = 12.0;
    CGFloat right = MAX(8.0, self.rightInset + 8.0);
    CGFloat fontX = CGRectGetWidth(self.bounds) - right - selectorWidth;
    CGFloat heightX = fontX - columnPadding - selectorWidth;
    CGFloat selectorY = MAX(30.0, self.controlsBottom - selectorHeight);

    self.heightSelectorView.frame = CGRectMake(heightX, selectorY, selectorWidth, selectorHeight);
    self.fontSelectorView.frame = CGRectMake(fontX, selectorY, selectorWidth, selectorHeight);
    self.heightTitleLabel.frame = CGRectMake(heightX - 4.0, selectorY - 24.0, selectorWidth + 8.0, 20.0);
    self.fontTitleLabel.frame = CGRectMake(fontX - 4.0, selectorY - 24.0, selectorWidth + 8.0, 20.0);

    [self layoutButtons:self.heightButtons inSelector:self.heightSelectorView];
    [self layoutButtons:self.fontButtons inSelector:self.fontSelectorView];

    CGFloat doneWidth = 96.0;
    CGFloat doneHeight = 40.0;
    self.doneButton.frame = CGRectMake(CGRectGetWidth(self.bounds) - right - doneWidth,
                                       CGRectGetHeight(self.bounds) - self.bottomInset - doneHeight - 8.0,
                                       doneWidth,
                                       doneHeight);
}

- (void)updateHeightLevel:(NSInteger)heightLevel fontLevel:(NSInteger)fontLevel {
    [self updateButtons:self.heightButtons selectedLevel:heightLevel];
    [self updateButtons:self.fontButtons selectedLevel:fontLevel];
}

- (UILabel *)titleLabelWithText:(NSString *)text {
    UILabel *label = [[UILabel alloc] init];
    label.text = text;
    label.font = [UIFont systemFontOfSize:12.0];
    label.textColor = UIColor.whiteColor;
    label.textAlignment = NSTextAlignmentCenter;
    return label;
}

- (UIView *)selectorView {
    UIView *view = [[UIView alloc] init];
    view.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.24];
    view.layer.cornerRadius = 16.0;
    return view;
}

- (NSArray<UIButton *> *)addButtonsWithTitles:(NSArray<NSString *> *)titles
                                        levels:(NSArray<NSNumber *> *)levels
                                        action:(SEL)action
                                        toView:(UIView *)view {
    NSMutableArray<UIButton *> *buttons = [NSMutableArray arrayWithCapacity:titles.count];
    for (NSUInteger idx = 0; idx < titles.count; idx++) {
        NSString *title = titles[idx];
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.tag = levels[idx].integerValue;
        button.titleLabel.font = [UIFont systemFontOfSize:12.0];
        [button setTitle:title forState:UIControlStateNormal];
        [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
        [view addSubview:button];
        [buttons addObject:button];
    }
    return [buttons copy];
}

- (void)layoutButtons:(NSArray<UIButton *> *)buttons inSelector:(UIView *)selector {
    CGFloat buttonSize = 28.0;
    CGFloat padding = (CGRectGetHeight(selector.bounds) - buttonSize * buttons.count) / (buttons.count + 1);
    for (NSUInteger idx = 0; idx < buttons.count; idx++) {
        UIButton *button = buttons[idx];
        button.frame = CGRectMake((CGRectGetWidth(selector.bounds) - buttonSize) / 2.0,
                                  padding + idx * (buttonSize + padding),
                                  buttonSize,
                                  buttonSize);
        button.layer.cornerRadius = buttonSize / 2.0;
    }
}

- (void)updateButtons:(NSArray<UIButton *> *)buttons selectedLevel:(NSInteger)selectedLevel {
    for (UIButton *button in buttons) {
        BOOL selected = button.tag == selectedLevel;
        button.selected = selected;
        button.backgroundColor = selected ? UIColor.whiteColor : UIColor.clearColor;
        [button setTitleColor:(selected ? PLV_UIColorFromRGB(@"#333333") : UIColor.whiteColor) forState:UIControlStateNormal];
    }
}

- (void)heightButtonAction:(UIButton *)button {
    [self updateButtons:self.heightButtons selectedLevel:button.tag];
    if (self.heightLevelChanged) {
        self.heightLevelChanged(button.tag);
    }
}

- (void)fontButtonAction:(UIButton *)button {
    [self updateButtons:self.fontButtons selectedLevel:button.tag];
    if (self.fontLevelChanged) {
        self.fontLevelChanged(button.tag);
    }
}

- (void)doneButtonAction {
    if (self.doneHandler) {
        self.doneHandler();
    }
}

@end

@interface PLVSAChatroomSettingSheet ()

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *heightTitleLabel;
@property (nonatomic, strong) UILabel *fontTitleLabel;
@property (nonatomic, strong) UIView *heightTrackView;
@property (nonatomic, strong) UIView *fontTrackView;
@property (nonatomic, strong) UIView *heightSelectedView;
@property (nonatomic, strong) UIView *fontSelectedView;
@property (nonatomic, strong) NSArray<UIButton *> *heightButtons;
@property (nonatomic, strong) NSArray<UIButton *> *fontButtons;
@property (nonatomic, strong) UIButton *cancelButton;
@property (nonatomic, strong) UIButton *completeButton;
@property (nonatomic, assign) PLVSAChatroomHeightLevel heightLevel;
@property (nonatomic, assign) PLVSAChatroomFontLevel fontLevel;

@end

@implementation PLVSAChatroomSettingSheet

#pragma mark - [ Life Cycle ]

- (instancetype)initWithSheetHeight:(CGFloat)sheetHeight sheetLandscapeWidth:(CGFloat)sheetLandscapeWidth {
    // 公屏设置需要直接观察左侧聊天区的实时效果，因此不使用全屏暗色遮罩。
    self = [super initWithSheetHeight:sheetHeight
                 sheetLandscapeWidth:sheetLandscapeWidth
                     backgroundColor:UIColor.clearColor];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    [self.contentView addSubview:self.titleLabel];
    [self.contentView addSubview:self.heightTitleLabel];
    [self.contentView addSubview:self.fontTitleLabel];
    [self.contentView addSubview:self.heightTrackView];
    [self.contentView addSubview:self.fontTrackView];
    [self.contentView addSubview:self.cancelButton];
    [self.contentView addSubview:self.completeButton];

    self.heightButtons = [self optionButtonsWithTitles:@[
        PLVLocalizedString(@"低"), PLVLocalizedString(@"中"), PLVLocalizedString(@"高")
    ] action:@selector(heightButtonAction:)];
    self.fontButtons = [self optionButtonsWithTitles:@[
        PLVLocalizedString(@"小"), PLVLocalizedString(@"中"), PLVLocalizedString(@"大")
    ] action:@selector(fontButtonAction:)];

    for (UIButton *button in self.heightButtons) {
        [self.contentView addSubview:button];
    }
    for (UIButton *button in self.fontButtons) {
        [self.contentView addSubview:button];
    }
}

#pragma mark - [ Override ]

- (void)layoutSubviews {
    [super layoutSubviews];

    CGFloat width = CGRectGetWidth(self.contentView.bounds);
    CGFloat height = CGRectGetHeight(self.contentView.bounds);
    BOOL landscape = [PLVSAUtils sharedUtils].isLandscape;

    if (landscape) {
        [self layoutLandscapeContentWithWidth:width];
    } else {
        [self layoutPortraitContentWithWidth:width height:height];
    }
    [self updateButtons:self.heightButtons selectedLevel:self.heightLevel];
    [self updateButtons:self.fontButtons selectedLevel:self.fontLevel];
}

- (void)layoutPortraitContentWithWidth:(CGFloat)width height:(CGFloat)height {
    CGFloat horizontalInset = 32.0;
    CGFloat labelWidth = 42.0;
    CGFloat optionSpacing = 12.0;
    CGFloat optionHeight = 36.0;
    CGFloat optionAreaLeft = horizontalInset + labelWidth + 16.0;
    CGFloat optionAreaWidth = MAX(0.0, width - optionAreaLeft - horizontalInset);
    CGFloat optionWidth = MAX(44.0, (optionAreaWidth - optionSpacing * 2.0) / 3.0);

    self.titleLabel.font = [UIFont boldSystemFontOfSize:16.0];
    self.heightTitleLabel.font = [UIFont systemFontOfSize:14.0];
    self.fontTitleLabel.font = [UIFont systemFontOfSize:14.0];
    self.titleLabel.frame = CGRectMake(horizontalInset, 28.0, width - horizontalInset * 2.0, 24.0);
    CGFloat heightRowY = 76.0;
    CGFloat fontRowY = heightRowY + optionHeight + 20.0;
    self.heightTitleLabel.frame = CGRectMake(horizontalInset, heightRowY, labelWidth, optionHeight);
    self.fontTitleLabel.frame = CGRectMake(horizontalInset, fontRowY, labelWidth, optionHeight);
    self.heightTrackView.hidden = YES;
    self.fontTrackView.hidden = YES;
    [self layoutButtons:self.heightButtons originX:optionAreaLeft originY:heightRowY width:optionWidth height:optionHeight spacing:optionSpacing];
    [self layoutButtons:self.fontButtons originX:optionAreaLeft originY:fontRowY width:optionWidth height:optionHeight spacing:optionSpacing];

    CGFloat actionButtonWidth = MIN(112.0, (width - horizontalInset * 2.0 - 16.0) / 2.0);
    CGFloat actionY = height - 52.0;
    self.cancelButton.frame = CGRectMake(horizontalInset, actionY, actionButtonWidth, 36.0);
    self.completeButton.frame = CGRectMake(width - horizontalInset - actionButtonWidth, actionY, actionButtonWidth, 36.0);
    [self updateActionButtonsForLandscape:NO];
}

- (void)layoutLandscapeContentWithWidth:(CGFloat)width {
    // PLVSABottomSheet 会在横屏右侧额外补齐安全区，这里仅在设计内容宽度内排版。
    CGFloat contentWidth = MIN(width, self.sheetLandscapeWidth);
    CGFloat contentRight = 20.0;
    CGFloat navigationHeight = 64.0;
    CGFloat labelWidth = 40.0;
    CGFloat trackLeft = 68.0;
    CGFloat trackHeight = 32.0;
    CGFloat trackWidth = MAX(120.0, contentWidth - trackLeft - contentRight);
    CGFloat heightRowY = 76.0;
    CGFloat fontRowY = heightRowY + 70.0;

    self.titleLabel.font = [UIFont systemFontOfSize:16.0 weight:UIFontWeightMedium];
    self.heightTitleLabel.font = [UIFont systemFontOfSize:14.0];
    self.fontTitleLabel.font = [UIFont systemFontOfSize:14.0];
    self.titleLabel.frame = CGRectMake(64.0, 0.0, MAX(0.0, contentWidth - 128.0), navigationHeight);
    self.cancelButton.frame = CGRectMake(16.0, 12.0, 40.0, 40.0);
    self.completeButton.frame = CGRectMake(contentWidth - contentRight - 40.0, 12.0, 40.0, 40.0);
    [self updateActionButtonsForLandscape:YES];

    self.heightTitleLabel.frame = CGRectMake(20.0, heightRowY, labelWidth, trackHeight);
    self.fontTitleLabel.frame = CGRectMake(20.0, fontRowY, labelWidth, trackHeight);
    self.heightTrackView.hidden = NO;
    self.fontTrackView.hidden = NO;
    self.heightTrackView.frame = CGRectMake(trackLeft, heightRowY, trackWidth, trackHeight);
    self.fontTrackView.frame = CGRectMake(trackLeft, fontRowY, trackWidth, trackHeight);
    self.heightTrackView.layer.cornerRadius = trackHeight / 2.0;
    self.fontTrackView.layer.cornerRadius = trackHeight / 2.0;

    CGFloat optionWidth = trackWidth / 3.0;
    [self layoutButtons:self.heightButtons originX:trackLeft originY:heightRowY width:optionWidth height:trackHeight spacing:0.0];
    [self layoutButtons:self.fontButtons originX:trackLeft originY:fontRowY width:optionWidth height:trackHeight spacing:0.0];
    [self layoutSelectedView:self.heightSelectedView level:self.heightLevel optionWidth:optionWidth trackHeight:trackHeight];
    [self layoutSelectedView:self.fontSelectedView level:self.fontLevel optionWidth:optionWidth trackHeight:trackHeight];
}

#pragma mark - [ Public Method ]

- (void)updateHeightLevel:(PLVSAChatroomHeightLevel)heightLevel
                fontLevel:(PLVSAChatroomFontLevel)fontLevel {
    self.heightLevel = heightLevel;
    self.fontLevel = fontLevel;
    [self updateButtons:self.heightButtons selectedLevel:heightLevel];
    [self updateButtons:self.fontButtons selectedLevel:fontLevel];
    [self setNeedsLayout];
}

#pragma mark - [ Private Method ]

- (NSArray<UIButton *> *)optionButtonsWithTitles:(NSArray<NSString *> *)titles action:(SEL)action {
    NSMutableArray<UIButton *> *buttons = [NSMutableArray arrayWithCapacity:titles.count];
    for (NSUInteger index = 0; index < titles.count; index++) {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.tag = index;
        button.layer.cornerRadius = 8.0;
        button.layer.borderWidth = 1.0;
        button.titleLabel.font = [UIFont systemFontOfSize:13.0];
        [button setTitle:titles[index] forState:UIControlStateNormal];
        [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
        [buttons addObject:button];
    }
    return [buttons copy];
}

- (void)layoutButtons:(NSArray<UIButton *> *)buttons
              originX:(CGFloat)originX
              originY:(CGFloat)originY
                 width:(CGFloat)width
                height:(CGFloat)height
               spacing:(CGFloat)spacing {
    for (NSUInteger index = 0; index < buttons.count; index++) {
        UIButton *button = buttons[index];
        button.frame = CGRectMake(originX + index * (width + spacing), originY, width, height);
    }
}

- (void)updateButtons:(NSArray<UIButton *> *)buttons selectedLevel:(NSInteger)selectedLevel {
    BOOL landscape = [PLVSAUtils sharedUtils].isLandscape;
    for (UIButton *button in buttons) {
        BOOL selected = button.tag == selectedLevel;
        button.selected = selected;
        button.titleLabel.font = [UIFont systemFontOfSize:(landscape ? 14.0 : 13.0)];
        button.layer.cornerRadius = landscape ? 0.0 : 8.0;
        button.layer.borderWidth = landscape ? 0.0 : 1.0;
        button.backgroundColor = landscape ? UIColor.clearColor : (selected ? PLV_UIColorFromRGB(@"#4399FF") : PLV_UIColorFromRGBA(@"#F0F1F5", 0.04));
        button.layer.borderColor = (selected ? PLV_UIColorFromRGB(@"#4399FF") : PLV_UIColorFromRGBA(@"#F0F1F5", 0.16)).CGColor;
        UIColor *titleColor = landscape ? (selected ? PLV_UIColorFromRGB(@"#31343F") : PLV_UIColorFromRGBA(@"#F0F1F5", 0.8)) : (selected ? UIColor.whiteColor : PLV_UIColorFromRGBA(@"#F0F1F5", 0.8));
        [button setTitleColor:titleColor forState:UIControlStateNormal];
    }
}

- (void)layoutSelectedView:(UIView *)selectedView
                     level:(NSInteger)level
               optionWidth:(CGFloat)optionWidth
               trackHeight:(CGFloat)trackHeight {
    CGFloat indicatorSize = MIN(30.0, trackHeight);
    CGFloat centerX = optionWidth * (level + 0.5);
    selectedView.frame = CGRectMake(centerX - indicatorSize / 2.0,
                                    (trackHeight - indicatorSize) / 2.0,
                                    indicatorSize,
                                    indicatorSize);
    selectedView.layer.cornerRadius = indicatorSize / 2.0;
}

- (void)updateActionButtonsForLandscape:(BOOL)landscape {
    self.cancelButton.layer.cornerRadius = landscape ? 0.0 : 18.0;
    self.cancelButton.layer.borderWidth = landscape ? 0.0 : 1.0;
    self.cancelButton.titleLabel.font = [UIFont systemFontOfSize:(landscape ? 22.0 : 14.0) weight:UIFontWeightRegular];
    [self.cancelButton setTitle:(landscape ? @"×" : PLVLocalizedString(@"取消")) forState:UIControlStateNormal];

    self.completeButton.layer.cornerRadius = landscape ? 0.0 : 18.0;
    self.completeButton.backgroundColor = landscape ? UIColor.clearColor : PLV_UIColorFromRGB(@"#4399FF");
    self.completeButton.titleLabel.font = [UIFont systemFontOfSize:(landscape ? 20.0 : 14.0) weight:UIFontWeightRegular];
    [self.completeButton setTitle:(landscape ? @"✓" : PLVLocalizedString(@"完成")) forState:UIControlStateNormal];
}

#pragma mark - [ Getter ]

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.text = PLVLocalizedString(@"公屏设置");
        _titleLabel.font = [UIFont boldSystemFontOfSize:16.0];
        _titleLabel.textColor = UIColor.whiteColor;
        _titleLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _titleLabel;
}

- (UILabel *)heightTitleLabel {
    if (!_heightTitleLabel) {
        _heightTitleLabel = [self rowTitleLabelWithText:PLVLocalizedString(@"高度")];
    }
    return _heightTitleLabel;
}

- (UILabel *)fontTitleLabel {
    if (!_fontTitleLabel) {
        _fontTitleLabel = [self rowTitleLabelWithText:PLVLocalizedString(@"字号")];
    }
    return _fontTitleLabel;
}

- (UIView *)heightTrackView {
    if (!_heightTrackView) {
        _heightTrackView = [self trackViewWithSelectedView:self.heightSelectedView];
    }
    return _heightTrackView;
}

- (UIView *)fontTrackView {
    if (!_fontTrackView) {
        _fontTrackView = [self trackViewWithSelectedView:self.fontSelectedView];
    }
    return _fontTrackView;
}

- (UIView *)trackViewWithSelectedView:(UIView *)selectedView {
    UIView *trackView = [[UIView alloc] init];
    trackView.backgroundColor = PLV_UIColorFromRGBA(@"#F0F1F5", 0.08);
    trackView.layer.cornerRadius = 14.0;
    [trackView addSubview:selectedView];
    return trackView;
}

- (UIView *)heightSelectedView {
    if (!_heightSelectedView) {
        _heightSelectedView = [self selectedIndicatorView];
    }
    return _heightSelectedView;
}

- (UIView *)fontSelectedView {
    if (!_fontSelectedView) {
        _fontSelectedView = [self selectedIndicatorView];
    }
    return _fontSelectedView;
}

- (UIView *)selectedIndicatorView {
    UIView *view = [[UIView alloc] init];
    view.backgroundColor = UIColor.whiteColor;
    view.userInteractionEnabled = NO;
    return view;
}

- (UILabel *)rowTitleLabelWithText:(NSString *)text {
    UILabel *label = [[UILabel alloc] init];
    label.text = text;
    label.font = [UIFont systemFontOfSize:14.0];
    label.textColor = PLV_UIColorFromRGBA(@"#F0F1F5", 0.8);
    return label;
}

- (UIButton *)cancelButton {
    if (!_cancelButton) {
        _cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _cancelButton.layer.cornerRadius = 18.0;
        _cancelButton.layer.borderWidth = 1.0;
        _cancelButton.layer.borderColor = PLV_UIColorFromRGB(@"#4C5160").CGColor;
        _cancelButton.titleLabel.font = [UIFont systemFontOfSize:14.0];
        [_cancelButton setTitle:PLVLocalizedString(@"取消") forState:UIControlStateNormal];
        [_cancelButton addTarget:self action:@selector(cancelButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _cancelButton;
}

- (UIButton *)completeButton {
    if (!_completeButton) {
        _completeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _completeButton.layer.cornerRadius = 18.0;
        _completeButton.backgroundColor = PLV_UIColorFromRGB(@"#4399FF");
        _completeButton.titleLabel.font = [UIFont systemFontOfSize:14.0];
        [_completeButton setTitle:PLVLocalizedString(@"完成") forState:UIControlStateNormal];
        [_completeButton addTarget:self action:@selector(completeButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _completeButton;
}

#pragma mark - [ Action ]

- (void)heightButtonAction:(UIButton *)button {
    self.heightLevel = button.tag;
    [self updateButtons:self.heightButtons selectedLevel:button.tag];
    [self setNeedsLayout];
    [self layoutIfNeeded];
    if (self.heightLevelChanged) {
        self.heightLevelChanged(button.tag);
    }
}

- (void)fontButtonAction:(UIButton *)button {
    self.fontLevel = button.tag;
    [self updateButtons:self.fontButtons selectedLevel:button.tag];
    [self setNeedsLayout];
    [self layoutIfNeeded];
    if (self.fontLevelChanged) {
        self.fontLevelChanged(button.tag);
    }
}

- (void)cancelButtonAction {
    [self dismiss];
}

- (void)completeButtonAction {
    if (self.completeHandler) {
        self.completeHandler();
    }
    [self dismiss];
}

@end
