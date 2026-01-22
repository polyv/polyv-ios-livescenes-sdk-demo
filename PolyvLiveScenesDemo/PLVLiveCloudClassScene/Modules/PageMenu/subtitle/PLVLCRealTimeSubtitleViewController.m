//
//  PLVLCRealTimeSubtitleViewController.m
//  PolyvLiveScenesDemo
//
//  Created on 2024.
//  Copyright © 2024 PLV. All rights reserved.
//

#import "PLVLCRealTimeSubtitleViewController.h"
#import "PLVLCSubtitleCell.h"
#import "PLVLCRealTimeSubtitleConfigView.h"
#import "PLVLiveSubtitleTranslation.h"
#import "PLVLiveRealTimeSubtitleHandler.h"
#import "PLVMultiLanguageManager.h"
#import <PLVFoundationSDK/PLVFoundationSDK.h>

@interface PLVLCRealTimeSubtitleViewController () <UITableViewDataSource, UITableViewDelegate, PLVLCRealTimeSubtitleConfigViewDelegate>

/// 频道ID
@property (nonatomic, copy) NSString *channelId;

/// 观众ID
@property (nonatomic, copy) NSString *viewerId;

/// 原文语言
@property (nonatomic, copy, nullable) NSString *originLanguage;

/// 可用语言列表
@property (nonatomic, strong, nullable) NSArray<NSString *> *availableLanguages;

/// UI 组件
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIView *toolBar;
@property (nonatomic, strong) UILabel *languageLabel;
@property (nonatomic, strong) UIButton *settingButton;

/// 字幕数据源
@property (nonatomic, strong) NSArray<PLVLiveSubtitleTranslation *> *subtitles;

/// 是否自动滚动到底部
@property (nonatomic, assign) BOOL shouldAutoScrollToBottom;

/// 字幕配置视图
@property (nonatomic, strong) PLVLCRealTimeSubtitleConfigView *configView;

/// 字幕显示设置
@property (nonatomic, assign) BOOL subtitleEnabled;          // 字幕总开关（控制是否显示字幕）
@property (nonatomic, assign) BOOL showOriginSubtitle;       // 是否显示原文（语言选择状态）
@property (nonatomic, assign) BOOL showTranslateSubtitle;    // 是否显示翻译（语言选择状态）
@property (nonatomic, copy) NSString *translateLanguage;     // 翻译语言代码

@end

@implementation PLVLCRealTimeSubtitleViewController

#pragma mark - Life Cycle

- (instancetype)initWithChannelId:(NSString *)channelId
                         viewerId:(NSString *)viewerId
                   originLanguage:(nullable NSString *)originLanguage
               translateLanguage:(nullable NSString *)translateLanguage
               availableLanguages:(nullable NSArray<NSString *> *)availableLanguages {
    if (self = [super init]) {
        _channelId = channelId;
        _viewerId = viewerId;
        _availableLanguages = availableLanguages;
        _shouldAutoScrollToBottom = YES;
        _subtitles = @[];
        
        // 默认开启字幕，显示双语
        _subtitleEnabled = YES;
        _showOriginSubtitle = YES;
        _showTranslateSubtitle = YES;
        _originLanguage = originLanguage;
        _translateLanguage = translateLanguage ?: @"origin";
        if ([_translateLanguage isEqualToString:@"origin"]) {
            _showTranslateSubtitle = NO;
        } 
        
        // 初始化配置视图
        _configView = [[PLVLCRealTimeSubtitleConfigView alloc] init];
        _configView.delegate = self;
        [_configView setupWithAvailableLanguages:availableLanguages];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor colorWithRed:0x20/255.0 green:0x21/255.0 blue:0x27/255.0 alpha:1];
    
    [self setupUI];
    [self restoreSettings];
    [self updateLanguageLabel];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self layoutSubviews];
}

#pragma mark - UI Setup

- (void)setupUI {
    // 创建工具栏
    [self setupToolBar];
    
    // 创建TableView
    [self setupTableView];
}

- (void)setupToolBar {
    self.toolBar = [[UIView alloc] init];
    self.toolBar.backgroundColor = [UIColor colorWithRed:0x1A/255.0 green:0x1B/255.0 blue:0x20/255.0 alpha:1];
    [self.view addSubview:self.toolBar];
    
    // 语言标签
    self.languageLabel = [[UILabel alloc] init];
    self.languageLabel.font = [UIFont systemFontOfSize:14];
    self.languageLabel.textColor = [UIColor whiteColor];
    self.languageLabel.text = PLVLocalizedString(@"实时字幕");
    self.languageLabel.numberOfLines = 1; // 单行显示
    self.languageLabel.lineBreakMode = NSLineBreakByTruncatingTail; // 超长时尾部截断
    self.languageLabel.adjustsFontSizeToFitWidth = NO; // 不自动调整字体大小，保持清晰度
    [self.toolBar addSubview:self.languageLabel];
    
    // 设置按钮
    self.settingButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.settingButton setTitle:PLVLocalizedString(@"设置") forState:UIControlStateNormal];
    [self.settingButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.settingButton.titleLabel.font = [UIFont systemFontOfSize:14];
    [self.settingButton addTarget:self action:@selector(settingButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self.toolBar addSubview:self.settingButton];
}

- (void)setupTableView {
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.estimatedRowHeight = 60;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    [self.view addSubview:self.tableView];
    
    // 注册Cell
    [self.tableView registerClass:[PLVLCSubtitleCell class] forCellReuseIdentifier:@"PLVLCSubtitleCell"];
}

- (void)layoutSubviews {
    CGFloat viewWidth = self.view.bounds.size.width;
    CGFloat viewHeight = self.view.bounds.size.height;
    CGFloat toolBarHeight = 44.0f;
    CGFloat padding = 16.0f;
    CGFloat spacing = 8.0f; // 标签和按钮之间的间距
    
    // 工具栏布局
    self.toolBar.frame = CGRectMake(0, 0, viewWidth, toolBarHeight);
    
    // 设置按钮布局（先布局右侧按钮）
    CGSize settingButtonSize = [self.settingButton sizeThatFits:CGSizeMake(CGFLOAT_MAX, toolBarHeight)];
    self.settingButton.frame = CGRectMake(viewWidth - padding - settingButtonSize.width, 
                                         (toolBarHeight - settingButtonSize.height) / 2.0f,
                                         settingButtonSize.width, settingButtonSize.height);
    
    // 语言标签布局（占据剩余空间，确保有足够宽度显示各种文本）
    // 计算可用宽度：工具栏宽度 - 左边距 - 右边距 - 按钮宽度 - 间距
    CGFloat availableWidth = viewWidth - padding - padding - settingButtonSize.width - spacing;
    
    // 直接使用可用的最大宽度，标签宽度固定，避免文本变化时频繁调整
    CGFloat labelHeight = 20.0f; // 字体大小14，高度固定20即可
    
    self.languageLabel.frame = CGRectMake(padding, 
                                         (toolBarHeight - labelHeight) / 2.0f, 
                                         availableWidth, 
                                         labelHeight);
    
    // TableView布局
    self.tableView.frame = CGRectMake(0, toolBarHeight, viewWidth, viewHeight - toolBarHeight);
}

#pragma mark - Public Method

- (void)updateSubtitles:(NSArray<PLVLiveSubtitleTranslation *> *)subtitles {
    self.subtitles = subtitles ?: @[];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
        
        // 自动滚动到底部
        if (self.shouldAutoScrollToBottom && self.subtitles.count > 0) {
            NSIndexPath *lastIndexPath = [NSIndexPath indexPathForRow:self.subtitles.count - 1 inSection:0];
            [self.tableView scrollToRowAtIndexPath:lastIndexPath
                                 atScrollPosition:UITableViewScrollPositionBottom
                                         animated:YES];
        }
    });
}

#pragma mark - Private Method

- (void)updateLanguageLabel {
    NSString *languageText = @"";
    
    // 如果字幕总开关关闭，显示"不显示"
    if (!self.subtitleEnabled) {
        languageText = PLVLocalizedString(@"不显示");
    } else if (self.showOriginSubtitle && self.showTranslateSubtitle) {
        // 双语模式
        NSString *translateLangName = [self languageNameForCode:self.translateLanguage];
        languageText = [NSString stringWithFormat:@"%@/%@", PLVLocalizedString(@"双语"), translateLangName];
    } else if (self.showOriginSubtitle) {
        // 只显示原文
        NSString *originLangName = [self languageNameForCode:self.originLanguage];
        languageText = [NSString stringWithFormat:@"%@/%@", PLVLocalizedString(@"原文"), originLangName];
    } else if (self.showTranslateSubtitle) {
        // 只显示翻译
        NSString *translateLangName = [self languageNameForCode:self.translateLanguage];
        languageText = [NSString stringWithFormat:@"%@/%@", PLVLocalizedString(@"翻译"), translateLangName];
    } else {
        languageText = PLVLocalizedString(@"不显示");
    }
    
    self.languageLabel.text = languageText;
}

- (NSString *)languageNameForCode:(NSString *)languageCode {
    // 使用统一的语言映射方法
    return [PLVLiveRealTimeSubtitleHandler languageNameForCode:languageCode];
}

- (void)restoreSettings {
    // 从本地恢复设置
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    // 检查是否有保存的设置
    BOOL hasSettings = [defaults objectForKey:@"PLVLCSubtitleEnabled"] != nil;
    if (hasSettings) {
        self.subtitleEnabled = [defaults boolForKey:@"PLVLCSubtitleEnabled"];
    }
}

- (void)saveSettings {
    // 保存设置到本地
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:self.subtitleEnabled forKey:@"PLVLCSubtitleEnabled"];
    [defaults synchronize];
}

#pragma mark - Action

- (void)settingButtonClicked:(UIButton *)sender {
    // 显示配置视图
    [self showConfigView];
}

- (void)showConfigView {
    if (!self.configView) {
        return;
    }
    
    // 同步当前状态到配置视图
    BOOL bilingualEnabled = self.showOriginSubtitle && self.showTranslateSubtitle;
    NSString *selectedLanguage = self.translateLanguage ;
    
    [self.configView updateState:self.subtitleEnabled
                bilingualEnabled:bilingualEnabled
                selectedLanguage:selectedLanguage];
    
    // 显示配置视图
    UIViewController *topViewController = [self findTopViewController];
    if (topViewController && topViewController.view) {
        [self.configView showInView:topViewController.view];
    } else {
        [self.configView showInView:self.view];
    }
}

- (UIViewController *)findTopViewController {
    UIViewController *topViewController = self;
    while (topViewController.parentViewController) {
        topViewController = topViewController.parentViewController;
    }
    return topViewController;
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.subtitles.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    PLVLCSubtitleCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PLVLCSubtitleCell" forIndexPath:indexPath];
    
    if (indexPath.row < self.subtitles.count) {
        PLVLiveSubtitleTranslation *subtitle = self.subtitles[indexPath.row];
        // 只有在字幕总开关开启时才显示字幕内容
        BOOL showOrigin = self.subtitleEnabled && self.showOriginSubtitle;
        BOOL showTranslation = self.subtitleEnabled && self.showTranslateSubtitle;
        [cell configureWithSubtitle:subtitle
                         showOrigin:showOrigin
                     showTranslation:showTranslation];
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row < self.subtitles.count) {
        PLVLiveSubtitleTranslation *subtitle = self.subtitles[indexPath.row];
        // 只有在字幕总开关开启时才显示字幕内容
        BOOL showOrigin = self.subtitleEnabled && self.showOriginSubtitle;
        BOOL showTranslation = self.subtitleEnabled && self.showTranslateSubtitle;
        return [PLVLCSubtitleCell cellHeightWithSubtitle:subtitle
                                              showOrigin:showOrigin
                                         showTranslation:showTranslation
                                                   width:tableView.bounds.size.width];
    }
    return 0;
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    // 用户开始滚动时，暂停自动滚动
    self.shouldAutoScrollToBottom = NO;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    // 滚动结束后，如果滚动到底部，恢复自动滚动
    CGFloat contentHeight = scrollView.contentSize.height;
    CGFloat scrollViewHeight = scrollView.bounds.size.height;
    CGFloat offsetY = scrollView.contentOffset.y;
    
    if (offsetY + scrollViewHeight >= contentHeight - 10) {
        self.shouldAutoScrollToBottom = YES;
    }
}

#pragma mark - PLVLCRealTimeSubtitleConfigViewDelegate

- (void)realTimeSubtitleConfigView:(PLVLCRealTimeSubtitleConfigView *)configView
                   didChangeEnabled:(BOOL)enabled {
    NSLog(@"实时字幕开关: %@", enabled ? @"开启" : @"关闭");
    
    // 只更新字幕总开关，不改变语言选择状态
    self.subtitleEnabled = enabled;
    
//    // 如果是首次开启且之前没有任何语言选择，默认显示原文
//    if (enabled && !self.showOriginSubtitle && !self.showTranslateSubtitle) {
//        self.showOriginSubtitle = YES;
//        self.showTranslateSubtitle = NO;
//    }
    
    [self updateLanguageLabel];
    [self.tableView reloadData];
    [self saveSettings];
}

- (void)realTimeSubtitleConfigView:(PLVLCRealTimeSubtitleConfigView *)configView
              didChangeBilingualEnabled:(BOOL)enabled {
    NSLog(@"双语字幕开关: %@", enabled ? @"开启" : @"关闭");
    
    // 更新语言设置
    if (enabled) {
        // 开启双语：同时显示原文和译文
        self.showOriginSubtitle = YES;
        self.showTranslateSubtitle = YES;
    } else {
        // 关闭双语：根据选中的语言决定显示内容
        NSString *selectedLanguage = configView.selectedLanguage;
        if ([selectedLanguage isEqualToString:@"origin"]) {
            // 选中原文
            self.showOriginSubtitle = YES;
            self.showTranslateSubtitle = NO;
        } else {
            // 选中翻译语言
            self.showOriginSubtitle = NO;
            self.showTranslateSubtitle = YES;
        }
    }
    
    [self updateLanguageLabel];
    [self.tableView reloadData];
    [self saveSettings];
}

- (void)realTimeSubtitleConfigView:(PLVLCRealTimeSubtitleConfigView *)configView
                didSelectLanguage:(NSString *)language {
    NSLog(@"选择语言: %@", language);
    
    // 更新语言设置
    if ([language isEqualToString:@"origin"]) {
        // 选择原文（不翻译）
        self.showOriginSubtitle = YES;
        self.showTranslateSubtitle = NO;
        self.translateLanguage = @"origin";
    } else {
        // 选择翻译语种
        self.translateLanguage = language;
        
        // 如果双语开关开启，显示双语；否则只显示翻译
        if (configView.bilingualEnabled) {
            self.showOriginSubtitle = YES;
            self.showTranslateSubtitle = YES;
        } else {
            self.showOriginSubtitle = NO;
            self.showTranslateSubtitle = YES;
        }

        // 通知外部修改翻译语言
        if ([self.delegate respondsToSelector:@selector(realTimeSubtitleViewController:didSetTranslateLanguage:)]) {
            [self.delegate realTimeSubtitleViewController:self didSetTranslateLanguage:language];
        }
    }
    
    [self updateLanguageLabel];
    [self.tableView reloadData];
    [self saveSettings];
}

@end
