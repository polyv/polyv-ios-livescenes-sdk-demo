//
//  PLVSAMixLayoutSheet.m
//  PLVLiveScenesDemo
//
//  Created by Dhan on 2023/7/25.
//  Copyright © 2023 PLV. All rights reserved.
//

#import "PLVSAMixLayoutSheet.h"
#import "PLVSAUtils.h"
#import "PLVMultiLanguageManager.h"
#import "PLVRoomDataManager.h"
#import <PLVFoundationSDK/PLVFdUtil.h>

@interface PLVSAMixLayoutOptionButton : UIView

@property (nonatomic, strong) UIImageView *layoutIconImageView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *subtitleLabel;
@property (nonatomic, strong) UIImageView *selectedImageView;
@property (nonatomic, assign) BOOL selected;
@property (nonatomic, assign) PLVMixLayoutType mixLayoutType;

/// 点击触发
@property (nonatomic, copy) void (^buttonActionBlock) (PLVMixLayoutType mixLayoutType);

- (instancetype)initWithMixLayoutType:(PLVMixLayoutType)mixLayoutType;

@end

@implementation PLVSAMixLayoutOptionButton

#pragma mark - [ Life Cycle ]

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat width = self.bounds.size.width;
    CGFloat height = self.bounds.size.height;
    
    // 按比例布局（以原始 158x52 基准）
    CGFloat iconW = width * (58.0 / 158.0);
    CGFloat iconH = height * (40.0 / 52.0);
    CGFloat iconX = width * (6.0 / 158.0);
    CGFloat iconY = height * (6.0 / 52.0);
    self.layoutIconImageView.frame = CGRectMake(iconX, iconY, iconW, iconH);
    
    // 布局标题
    CGFloat titleSpacing = width * (8.0 / 158.0);
    CGFloat titleX = CGRectGetMaxX(self.layoutIconImageView.frame) + titleSpacing;
    CGFloat titleHeight = self.titleLabel.font.lineHeight;
    self.titleLabel.frame = CGRectMake(titleX, iconY, MAX(0, width - titleX), titleHeight);
    
    // 布局副标题
    CGFloat bottomInset = height * (8.0 / 52.0);
    CGFloat subtitleY = CGRectGetMaxY(self.titleLabel.frame);
    self.subtitleLabel.frame = CGRectMake(titleX, subtitleY, MAX(0, width - titleX), MAX(0, height - subtitleY - bottomInset));
    
    // 选中图标
    CGFloat selW = width * (14.0 / 158.0);
    CGFloat selH = height * (16.0 / 52.0);
    self.selectedImageView.frame = CGRectMake(width - selW, height - selH, selW, selH);
}

#pragma mark - [ Public Method ]

- (instancetype)initWithMixLayoutType:(PLVMixLayoutType)mixLayoutType {
    self = [super init];
    if (self) {
        _mixLayoutType = mixLayoutType;
        
        [self initUI];
        
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureAction:)];
        [self addGestureRecognizer:tapGesture];
    }
    return self;
}

- (void)setSelected:(BOOL)selected {
    _selected = selected;
    self.layer.borderWidth = selected ? 1.0 : 0;
    self.selectedImageView.hidden = !selected;
}

#pragma mark - [ Private Method ]

- (void)initUI {
    self.backgroundColor = [UIColor colorWithRed:0xf0/255.0 green:0xf1/255.0 blue:0xf5/255.0 alpha:0.04];
    self.layer.borderColor = [UIColor colorWithRed:0x43/255.0 green:0x99/255.0 blue:0xff/255.0 alpha:1.0].CGColor;
    self.layer.borderWidth = self.selected ? 1.0 : 0;
    self.layer.cornerRadius = 8.0;
    
    [self addSubview:self.layoutIconImageView];
    [self addSubview:self.titleLabel];
    [self addSubview:self.subtitleLabel];
    [self addSubview:self.selectedImageView];
    
    [self updateContentWithMixLayoutType:self.mixLayoutType];
}

- (void)updateContentWithMixLayoutType:(PLVMixLayoutType)mixLayoutType {
    switch (mixLayoutType) {
        case PLVMixLayoutType_Single:
            self.titleLabel.text = PLVLocalizedString(@"单人演讲");
            self.subtitleLabel.text = PLVLocalizedString(@"显示第一画面");
            self.layoutIconImageView.image = [PLVSAUtils imageForLiveroomResource:@"plvsa_liveroom_mixLayout_single_btn"];
            break;
        case PLVMixLayoutType_RightList:
            self.titleLabel.text = PLVLocalizedString(@"右侧列表");
            self.subtitleLabel.text = PLVLocalizedString(@"右侧平铺演示");
            self.layoutIconImageView.image = [PLVSAUtils imageForLiveroomResource:@"plvsa_liveroom_mixLayout_rightList_btn"];
            break;
        case PLVMixLayoutType_BottomList:
            self.titleLabel.text = PLVLocalizedString(@"底部列表");
            self.subtitleLabel.text = PLVLocalizedString(@"底部平铺演示");
            self.layoutIconImageView.image = [PLVSAUtils imageForLiveroomResource:@"plvsa_liveroom_mixLayout_bottomList_btn"];
            break;
        case PLVMixLayoutType_MainSpeaker:
            self.titleLabel.text = PLVLocalizedString(@"底部悬浮");
            self.subtitleLabel.text = PLVLocalizedString(@"主讲人突出显示");
            self.layoutIconImageView.image = [PLVSAUtils imageForLiveroomResource:@"plvsa_liveroom_mixLayout_mainSpeaker_btn"];
            break;
        case PLVMixLayoutType_Tile:
            self.titleLabel.text = PLVLocalizedString(@"宫格视图");
            self.subtitleLabel.text = PLVLocalizedString(@"所有画面均分");
            self.layoutIconImageView.image = [PLVSAUtils imageForLiveroomResource:@"plvsa_liveroom_mixLayout_tile_btn"];
            break;
    }
}

#pragma mark Getter & Setter

- (UIImageView *)layoutIconImageView {
    if (!_layoutIconImageView) {
        _layoutIconImageView = [[UIImageView alloc] init];
        _layoutIconImageView.contentMode = UIViewContentModeScaleAspectFit;
        _layoutIconImageView.backgroundColor = [UIColor clearColor];
    }
    return _layoutIconImageView;
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.textColor = PLV_UIColorFromRGB(@"#FFFFFF");
        _titleLabel.font = [UIFont fontWithName:@"PingFangSC-Medium" size:14];
        _titleLabel.textAlignment = NSTextAlignmentLeft;
    }
    return _titleLabel;
}

- (UILabel *)subtitleLabel {
    if (!_subtitleLabel) {
        _subtitleLabel = [[UILabel alloc] init];
        _subtitleLabel.textColor = PLV_UIColorFromRGBA(@"#FFFFFF", 0.6);
        _subtitleLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:12];
        _subtitleLabel.textAlignment = NSTextAlignmentLeft;
        _subtitleLabel.numberOfLines = 0;
    }
    return _subtitleLabel;
}

- (UIImageView *)selectedImageView {
    if (!_selectedImageView) {
        _selectedImageView = [[UIImageView alloc] init];
        _selectedImageView.image = [PLVSAUtils imageForLiveroomResource:@"plvsa_liveroom_selected_icon"];
        _selectedImageView.hidden = YES;
    }
    return _selectedImageView;
}

#pragma mark - [ Event ]

- (void)tapGestureAction:(UITapGestureRecognizer *)tapGesture {
    if (self.buttonActionBlock) {
        self.buttonActionBlock(self.mixLayoutType);
    }
}

@end

@interface PLVSAMixLayoutSheet()

// UI
@property (nonatomic, strong) UIScrollView *scrollView; // 滚动视图
@property (nonatomic, strong) UIView *contentContainerView; // 内容容器视图
@property (nonatomic, strong) UILabel *titleLable;
@property (nonatomic, strong) UILabel *tipsLabel; // 标题下提示
@property (nonatomic, strong) UILabel *backgroundTitleLabel; // 背景设置标题
@property (nonatomic, strong) UIScrollView *backgroundScrollView; // 背景颜色选择滚动视图
@property (nonatomic, strong) UIView *backgroundContainerView; // 背景颜色选择容器
@property (nonatomic, strong) NSArray <UIButton *> *backgroundColorButtons; // 背景颜色按钮数组



/// 数据
// 可选连麦布局枚举值数组
@property (nonatomic, strong) NSArray *mixLayoutTypeArray;
// 可选连麦布局字符串数组
@property (nonatomic, strong) NSArray <NSString *>*mixLayoutTypeStringArray;
// 选项按钮数组，只初始化一次
@property (nonatomic, strong) NSArray <PLVSAMixLayoutOptionButton *> *optionsButtonArray;

@end

@implementation PLVSAMixLayoutSheet

#pragma mark - [ Life Cycle ]
- (instancetype)initWithSheetHeight:(CGFloat)sheetHeight sheetLandscapeWidth:(CGFloat)sheetLandscapeWidth {
    // 动态计算高度以容纳背景设置区域
    CGFloat dynamicHeight = sheetHeight + 120; // 增加背景设置区域的高度
    self = [super initWithSheetHeight:dynamicHeight sheetLandscapeWidth:sheetLandscapeWidth];
    if (self) {
        [self initUI];
    }
    return self;
}

- (void)initUI {
    [self.contentView addSubview:self.scrollView];
    [self.scrollView addSubview:self.contentContainerView];
    [self.contentContainerView addSubview:self.titleLable];
    [self.contentContainerView addSubview:self.tipsLabel];
    [self.contentContainerView addSubview:self.backgroundTitleLabel];
    [self.contentContainerView addSubview:self.backgroundScrollView];
    [self.backgroundScrollView addSubview:self.backgroundContainerView];
    [self setupBackgroundColorButtons];
}

#pragma mark - [ Override ]

- (void)layoutSubviews {
    [super layoutSubviews];
    BOOL isPad = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
    CGFloat contentViewWidth = self.contentView.bounds.size.width;
    CGFloat contentViewHeight = self.contentView.bounds.size.height;
    
    // 设置滚动视图
    self.scrollView.frame = CGRectMake(0, 0, contentViewWidth, contentViewHeight);
    
    CGFloat titleLableLeft = 32;
    CGFloat buttonWidth = 88;
    CGFloat buttonHeight = 36;
    CGFloat buttonY = 83;
    CGFloat paddingX = (contentViewWidth - self.optionsButtonArray.count * buttonWidth) / (self.optionsButtonArray.count + 1);
    // iPad时的中间和两边边距
    CGFloat middlePadding = 0;
    CGFloat margin = 0;
    BOOL isLandscape = [PLVSAUtils sharedUtils].isLandscape;
    
    if (isPad) {
        titleLableLeft = 56;
        buttonWidth = 120;
        middlePadding = contentViewWidth * 0.052;
        margin = (contentViewWidth - middlePadding * (self.optionsButtonArray.count - 1) - buttonWidth * self.optionsButtonArray.count) / 2;
    }
    
    // 标题和提示标签布局
    self.titleLable.frame = CGRectMake(titleLableLeft, 32, 90, 18);
    self.tipsLabel.frame = CGRectMake(titleLableLeft, 58, contentViewWidth - titleLableLeft * 2, 18);
    
    // 自适应按比例尺寸（保持 158:52 比例）
    NSInteger buttonsPerRow = 2;
    CGFloat horizontalInset = isPad ? 24.0 : 16.0; // 左右与列间统一间距
    CGFloat totalSpacing = (buttonsPerRow + 1) * horizontalInset;
    CGFloat layoutButtonWidth = (contentViewWidth - totalSpacing) / buttonsPerRow;
    CGFloat aspectRatio = 52.0 / 158.0; // 高/宽
    CGFloat layoutButtonHeight = layoutButtonWidth * aspectRatio;
    CGFloat rowSpacing = isPad ? 24.0 : 16.0;
    
    // 行数
    NSInteger rows = (self.optionsButtonArray.count + buttonsPerRow - 1) / buttonsPerRow;
    
    for (int i = 0; i < self.optionsButtonArray.count; i ++) {
        PLVSAMixLayoutOptionButton *button = self.optionsButtonArray[i];
        NSInteger row = i / buttonsPerRow;
        NSInteger col = i % buttonsPerRow;
        
        CGFloat buttonX = horizontalInset + col * (layoutButtonWidth + horizontalInset);
        CGFloat buttonY = 83 + row * (layoutButtonHeight + rowSpacing);
        
        button.frame = CGRectMake(buttonX, buttonY, layoutButtonWidth, layoutButtonHeight);
    }
    
    // 背景设置布局
    CGFloat backgroundTitleY = 83 + rows * (layoutButtonHeight + 16);
    if (isPad) {
        backgroundTitleY = 83 + rows * (layoutButtonHeight + 24) + 32;
    }
    self.backgroundTitleLabel.frame = CGRectMake(titleLableLeft, backgroundTitleY, contentViewWidth - titleLableLeft * 2, 22);
    
    CGFloat backgroundContainerY = backgroundTitleY + 32;
    CGFloat backgroundContainerHeight = 60;
    self.backgroundScrollView.frame = CGRectMake(titleLableLeft, backgroundContainerY, contentViewWidth - titleLableLeft * 2, backgroundContainerHeight);
    
    // 计算背景容器的内容宽度
    CGFloat colorButtonWidth = 52; // 容器宽度
    CGFloat colorButtonSpacing = 16;
    CGFloat totalColorButtonsWidth = self.backgroundColorButtons.count * colorButtonWidth + (self.backgroundColorButtons.count - 1) * colorButtonSpacing;
    CGFloat contentWidth = MAX(totalColorButtonsWidth, self.backgroundScrollView.bounds.size.width);
    self.backgroundContainerView.frame = CGRectMake(0, 0, contentWidth, backgroundContainerHeight);
    
    // 布局背景颜色按钮 - 支持左右滑动，上面是颜色块，下面是颜色名称
    CGFloat colorButtonHeight = 56; // 容器高度
    
    for (int i = 0; i < self.backgroundColorButtons.count; i++) {
        UIView *containerView = self.backgroundColorButtons[i];
        CGFloat containerX = i * (colorButtonWidth + colorButtonSpacing);
        CGFloat containerY = (backgroundContainerHeight - colorButtonHeight) / 2;
        containerView.frame = CGRectMake(containerX, containerY, colorButtonWidth, colorButtonHeight);
        
        // 布局缩略图（上面）- 44*30，居中显示
        UIImageView *thumbView = containerView.subviews[0];
        CGFloat thumbViewX = (colorButtonWidth - 44) / 2; // 水平居中
        CGFloat thumbViewY = 4; // 距离顶部4pt
        thumbView.frame = CGRectMake(thumbViewX, thumbViewY, 44, 30);
        
        // 布局颜色名称标签（下面）- 与缩略图间隔2pt，距离容器底部2pt
        UILabel *colorLabel = containerView.subviews[1];
        CGFloat labelY = thumbViewY + 30 + 2; // 缩略图底部 + 2pt间隔
        CGFloat labelHeight = colorButtonHeight - labelY - 2; // 剩余高度减去底部2pt
        colorLabel.frame = CGRectMake(0, labelY, colorButtonWidth, labelHeight);
        
        // 布局按钮覆盖层
        UIButton *colorButton = containerView.subviews[2];
        colorButton.frame = CGRectMake(0, 0, colorButtonWidth, colorButtonHeight);
    }
    
    // 计算内容总高度并设置滚动视图内容大小
    CGFloat totalContentHeight = backgroundContainerY + backgroundContainerHeight + 20; // 底部留20pt间距
    self.contentContainerView.frame = CGRectMake(0, 0, contentViewWidth, totalContentHeight);
    self.scrollView.contentSize = CGSizeMake(contentViewWidth, totalContentHeight);
}

- (void)setupOptionsWithCurrentMixLayoutType:(PLVMixLayoutType)currentMixLayoutType 
                        currentBackgroundColor:(PLVMixLayoutBackgroundColor)currentBackgroundColor {
    // 设置连麦布局选项
    NSMutableArray *buttonMuArray = [[NSMutableArray alloc] initWithCapacity:[self.mixLayoutTypeArray count]];
    for (int i = 0; i < self.mixLayoutTypeArray.count; i ++) {
        PLVMixLayoutType mixLayoutType = [self.mixLayoutTypeArray[i] integerValue];
        PLVSAMixLayoutOptionButton *button = [[PLVSAMixLayoutOptionButton alloc] initWithMixLayoutType:mixLayoutType];
        
        __weak typeof(self) weakSelf = self;
        button.buttonActionBlock = ^(PLVMixLayoutType type) {
            [weakSelf mixLayoutButtonAction:type];
        };
        
        if (mixLayoutType == currentMixLayoutType) {
            button.selected = YES;
        }
        
        [self.contentContainerView addSubview:button];
        [buttonMuArray addObject:button];
    }
    self.optionsButtonArray = [buttonMuArray copy];
    
    // 设置背景颜色选项
    [self updateBackgroundSelectedColorType:currentBackgroundColor];
}

- (void)updateMixLayoutType:(PLVMixLayoutType)currentType {
    for (PLVSAMixLayoutOptionButton *button in self.optionsButtonArray) {
        button.selected = NO;
        if (button.mixLayoutType == currentType) {
            button.selected = YES;
        }
    }
}

#pragma mark Getter

- (UIScrollView *)scrollView {
    if (!_scrollView) {
        _scrollView = [[UIScrollView alloc] init];
        _scrollView.showsVerticalScrollIndicator = YES;
        _scrollView.showsHorizontalScrollIndicator = NO;
        _scrollView.bounces = YES;
        _scrollView.alwaysBounceVertical = NO;
    }
    return _scrollView;
}

- (UIView *)contentContainerView {
    if (!_contentContainerView) {
        _contentContainerView = [[UIView alloc] init];
        _contentContainerView.backgroundColor = [UIColor clearColor];
    }
    return _contentContainerView;
}

- (UILabel *)titleLable {
    if (!_titleLable) {
        _titleLable = [[UILabel alloc] init];
        _titleLable.font = [UIFont fontWithName:@"PingFangSC-Regular" size:18];
        _titleLable.textColor = PLV_UIColorFromRGB(@"#F0F1F5");
        _titleLable.text = PLVLocalizedString(@"连麦布局");
    }
    return _titleLable;
}



- (NSArray *)mixLayoutTypeArray {
    if (!_mixLayoutTypeArray) {
        _mixLayoutTypeArray = @[@(PLVMixLayoutType_MainSpeaker), @(PLVMixLayoutType_Tile), @(PLVMixLayoutType_Single), @(PLVMixLayoutType_RightList), @(PLVMixLayoutType_BottomList)];
    }
    return _mixLayoutTypeArray;
}

- (NSArray <NSString *> *)mixLayoutTypeStringArray {
    if (!_mixLayoutTypeStringArray) {
        NSMutableArray *muArray = [[NSMutableArray alloc] initWithCapacity:self.mixLayoutTypeArray.count];
        for (int i = 0; i < [self.mixLayoutTypeArray count]; i++) {
            PLVMixLayoutType mixLayoutType = [self.mixLayoutTypeArray[i] integerValue];
            NSString *string = [PLVRoomData mixLayoutTypeStringWithType:mixLayoutType];
            [muArray addObject:string];
        }
        _mixLayoutTypeStringArray = [muArray copy];
    }
    return _mixLayoutTypeStringArray;
}

- (UILabel *)tipsLabel {
    if (!_tipsLabel) {
        _tipsLabel = [[UILabel alloc] init];
        _tipsLabel.textColor = PLV_UIColorFromRGBA(@"#F0F1F5", 0.6);
        _tipsLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:12];
        _tipsLabel.text = PLVLocalizedString(@"选择后对所有人⽣效，观众不可修改布局");
    }
    return _tipsLabel;
}

- (UILabel *)backgroundTitleLabel {
    if (!_backgroundTitleLabel) {
        _backgroundTitleLabel = [[UILabel alloc] init];
        _backgroundTitleLabel.textColor = PLV_UIColorFromRGBA(@"#FFFFFF", 0.6);
        _backgroundTitleLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:12];
        _backgroundTitleLabel.text = PLVLocalizedString(@"背景设置");
    }
    return _backgroundTitleLabel;
}

- (UIScrollView *)backgroundScrollView {
    if (!_backgroundScrollView) {
        _backgroundScrollView = [[UIScrollView alloc] init];
        _backgroundScrollView.showsHorizontalScrollIndicator = NO;
        _backgroundScrollView.showsVerticalScrollIndicator = NO;
        _backgroundScrollView.bounces = YES;
        _backgroundScrollView.alwaysBounceHorizontal = NO;
    }
    return _backgroundScrollView;
}

- (UIView *)backgroundContainerView {
    if (!_backgroundContainerView) {
        _backgroundContainerView = [[UIView alloc] init];
        _backgroundContainerView.backgroundColor = [UIColor clearColor];
    }
    return _backgroundContainerView;
}

#pragma mark - [ Private ]

- (void)setupBackgroundColorButtons {
    NSArray<NSNumber *> *backgroundTypes = @[
        @(PLVMixLayoutBackgroundColor_Black),
        @(PLVMixLayoutBackgroundColor_Blue),
        @(PLVMixLayoutBackgroundColor_Purple),
        @(PLVMixLayoutBackgroundColor_Green),
        @(PLVMixLayoutBackgroundColor_Orange),
        @(PLVMixLayoutBackgroundColor_NormalBlack)
    ];
    
    NSMutableArray *buttons = [NSMutableArray array];
    for (int i = 0; i < backgroundTypes.count; i++) {
        PLVMixLayoutBackgroundColor colorType = [backgroundTypes[i] integerValue];
        
        // 创建容器视图
        UIView *containerView = [[UIView alloc] init];
        containerView.backgroundColor = PLV_UIColorFromRGBA(@"#F0F1F5", 0.04); // #F0F1F5 4%透明度
        containerView.layer.cornerRadius = 4;
        containerView.tag = i;
        
        // 创建缩略图视图
        UIImageView *thumbView = [[UIImageView alloc] init];
        thumbView.contentMode = UIViewContentModeScaleAspectFill;
        thumbView.clipsToBounds = YES;
        thumbView.layer.cornerRadius = 6;
        [containerView addSubview:thumbView];
        
        // 通过枚举获取URL并使用工具类加载
        NSString *urlString = [PLVRoomData mixBackgroundURLStringWithType:colorType];
        if (urlString) {
            NSURL *url = [NSURL URLWithString:urlString];
            [PLVSAUtils setImageView:thumbView url:url];
        }
        
        // 创建颜色名称标签
        UILabel *colorLabel = [[UILabel alloc] init];
        colorLabel.text = [PLVRoomData mixBackgroundDisplayNameForType:colorType];
        colorLabel.textColor = PLV_UIColorFromRGBA(@"#F0F1F5", 0.6);
        colorLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:10];
        colorLabel.textAlignment = NSTextAlignmentCenter;
        [containerView addSubview:colorLabel];
        
        // 创建按钮覆盖层用于点击
        UIButton *colorButton = [UIButton buttonWithType:UIButtonTypeCustom];
        colorButton.backgroundColor = [UIColor clearColor];
        colorButton.tag = i;
        [colorButton addTarget:self action:@selector(backgroundColorButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        [containerView addSubview:colorButton];
        
        [self.backgroundContainerView addSubview:containerView];
        [buttons addObject:containerView];
    }
    
    self.backgroundColorButtons = [buttons copy];
    CGFloat colorButtonWidth = 52; // 容器宽度
    CGFloat colorButtonSpacing = 16;
    CGFloat backgroundContainerHeight = 60;
    
    // 设置滚动视图的内容大小
    if (self.backgroundColorButtons.count > 0) {
        CGFloat totalWidth = self.backgroundColorButtons.count * colorButtonWidth + (self.backgroundColorButtons.count - 1) * colorButtonSpacing;
        self.backgroundScrollView.contentSize = CGSizeMake(totalWidth, backgroundContainerHeight);
    }
}

- (void)backgroundColorButtonAction:(UIButton *)sender {
    // 处理背景颜色选择
    for (UIView *containerView in self.backgroundColorButtons) {
        // 重置容器背景色和边框
        containerView.backgroundColor = PLV_UIColorFromRGBA(@"#F0F1F5", 0.04);
        containerView.layer.borderWidth = 0;
    }
    
    // 设置选中状态
    UIView *selectedContainer = self.backgroundColorButtons[sender.tag];
    // 设置容器边框为蓝色
    selectedContainer.layer.borderColor = PLV_UIColorFromRGBA(@"#4399FF", 1.0).CGColor;
    selectedContainer.layer.borderWidth = 2; // 选中时边框更粗
    
    // 将索引转换为枚举类型
    PLVMixLayoutBackgroundColor colorType = [self backgroundColorTypeFromIndex:sender.tag];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(plvsaMixLayoutSheet:didSelectBackgroundColor:)]) {
        [self.delegate plvsaMixLayoutSheet:self didSelectBackgroundColor:colorType];
    }
}

- (void)updateBackgroundSelectedColorType:(PLVMixLayoutBackgroundColor)colorType {
    NSInteger index = [self indexFromBackgroundColorType:colorType];
    if (index < 0 || index >= self.backgroundColorButtons.count) { return; }
    
    for (UIView *containerView in self.backgroundColorButtons) {
        containerView.layer.borderWidth = 0;
    }
    UIView *selectedContainer = self.backgroundColorButtons[index];
    selectedContainer.layer.borderColor = PLV_UIColorFromRGBA(@"#4399FF", 1.0).CGColor;
    selectedContainer.layer.borderWidth = 2;
}

/// 将背景颜色枚举转换为索引
- (NSInteger)indexFromBackgroundColorType:(PLVMixLayoutBackgroundColor)colorType {
    switch (colorType) {
        case PLVMixLayoutBackgroundColor_Black: return 0;
        case PLVMixLayoutBackgroundColor_Blue: return 1;
        case PLVMixLayoutBackgroundColor_Purple: return 2;
        case PLVMixLayoutBackgroundColor_Green: return 3;
        case PLVMixLayoutBackgroundColor_Orange: return 4;
        case PLVMixLayoutBackgroundColor_NormalBlack: return 5;
        default: return -1;
    }
}

/// 将索引转换为背景颜色枚举
- (PLVMixLayoutBackgroundColor)backgroundColorTypeFromIndex:(NSInteger)index {
    switch (index) {
        case 0: return PLVMixLayoutBackgroundColor_Black;
        case 1: return PLVMixLayoutBackgroundColor_Blue;
        case 2: return PLVMixLayoutBackgroundColor_Purple;
        case 3: return PLVMixLayoutBackgroundColor_Green;
        case 4: return PLVMixLayoutBackgroundColor_Orange;
        case 5: return PLVMixLayoutBackgroundColor_NormalBlack;
        default: return PLVMixLayoutBackgroundColor_Black;
    }
}

#pragma mark - [ Action ]

- (void)mixLayoutButtonAction:(PLVMixLayoutType)type {
    PLVNetworkStatus networkStatus = [PLVReachability reachabilityForInternetConnection].currentReachabilityStatus;
    if (networkStatus != PLVNotReachable) {
        for (PLVSAMixLayoutOptionButton *button in self.optionsButtonArray) {
            button.selected = NO;
        }
        
        // 找到对应的按钮并设置为选中状态
        for (PLVSAMixLayoutOptionButton *button in self.optionsButtonArray) {
            if (button.mixLayoutType == type) {
                button.selected = YES;
                break;
            }
        }
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(plvsaMixLayoutSheet:mixLayoutButtonClickWithMixLayoutType:)]) {
            [self.delegate plvsaMixLayoutSheet:self mixLayoutButtonClickWithMixLayoutType:type];
        }
    } else {
        [PLVSAUtils showToastWithMessage:PLVLocalizedString(@"网络异常，请恢复网络后重试") inView:[PLVSAUtils sharedUtils].homeVC.view];
    }
}


@end
