//
//  PLVECRealTimeSubtitleView.m
//  PolyvLiveScenesDemo
//

#import "PLVECRealTimeSubtitleView.h"
#import "PLVLiveRealTimeSubtitleHandler.h"
#import "PLVLiveSubtitleModel.h"
#import "PLVECRealTimeSubtitleCell.h"
#import "PLVECUtils.h"

static const CGFloat kDefaultHeight = 106.0f;      // 固定高度106px（设计稿要求）
static const CGFloat kExpandedHeight = 260.0f;      // 展开高度
static const CGFloat kCornerRadius = 8.0f;          // 圆角
static const CGFloat kVerticalPadding = 12.0f;     // 垂直内边距
static const CGFloat kButtonSize = 24.0f;          // 按钮大小
static const CGFloat kButtonMargin = 8.0f;         // 按钮边距

@interface PLVECRealTimeSubtitleView () <PLVLiveRealTimeSubtitleHandlerDelegate, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIButton *closeButton;
@property (nonatomic, strong) UIButton *expandButton;
@property (nonatomic, strong) PLVLiveRealTimeSubtitleHandler *subtitleHandler;
@property (nonatomic, strong) NSArray<PLVLiveSubtitleTranslation *> *subtitles;
@property (nonatomic, strong) NSArray<PLVLiveSubtitleTranslation *> *displaySubtitles;
@property (nonatomic, assign) BOOL isExpanded;
@property (nonatomic, assign) BOOL showOriginSubtitle;
@property (nonatomic, assign) BOOL showTranslateSubtitle;
@property (nonatomic, assign) BOOL subtitleEnabled; // 字幕是否启用（实时字幕开关）
@property (nonatomic, assign) BOOL shouldAutoScrollToBottom; // 是否自动滚动到底部（参考云课堂方案）
@property (nonatomic, strong) UIPanGestureRecognizer *panGestureRecognizer;
@property (nonatomic, assign) CGPoint panStartPoint; // 手势开始时的视图位置
@property (nonatomic, assign) BOOL bilingualEnabled; // 双语开关状态（以配置为准）

@end

@implementation PLVECRealTimeSubtitleView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        // 默认设置：原文不翻译（以配置视图默认一致）
        _bilingualEnabled = NO;
        self.showOriginSubtitle = YES;
        self.showTranslateSubtitle = NO;
        self.subtitleEnabled = NO; // 默认不启用，等待外部调用 setSubtitleEnabled:YES
        self.shouldAutoScrollToBottom = YES;
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    // 设置背景（深灰色半透明，符合设计稿）
    self.backgroundColor = [UIColor colorWithRed:0.15 green:0.15 blue:0.15 alpha:0.85];
    self.layer.cornerRadius = kCornerRadius;
    self.layer.masksToBounds = YES;
    
    // 创建容器视图（用于内容区域）
    self.containerView = [[UIView alloc] init];
    self.containerView.backgroundColor = [UIColor clearColor];
    [self addSubview:self.containerView];
    
    // 创建TableView（用于显示多条字幕）
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.showsVerticalScrollIndicator = NO;
    self.tableView.showsHorizontalScrollIndicator = NO; // 禁用水平滚动指示器
    self.tableView.scrollEnabled = YES;
    self.tableView.alwaysBounceHorizontal = NO; // 禁用水平弹跳
    self.tableView.alwaysBounceVertical = YES; // 允许垂直弹跳
    self.tableView.estimatedRowHeight = 60.0f;
    // 只设置上下内边距，左右内边距通过 cell 内部 label 的 frame 来控制
    self.tableView.contentInset = UIEdgeInsetsMake(kVerticalPadding, 0, kVerticalPadding , 0);
    [self.containerView addSubview:self.tableView];
    
    // 注册Cell
    [self.tableView registerClass:[PLVECRealTimeSubtitleCell class] forCellReuseIdentifier:@"PLVECRealTimeSubtitleCell"];
    
    // 创建关闭按钮（右上角，白色X图标）
    self.closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *closeImage = [PLVECUtils imageForWatchResource:@"plv_close_btn"];
    [self.closeButton setImage:closeImage forState:UIControlStateNormal];
    [self.closeButton addTarget:self action:@selector(closeButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.closeButton];
    
    // 创建展开/收起按钮（右下角）
    self.expandButton = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *expandImage = [PLVECUtils imageForWatchResource:@"plvec_live_realtime_subtitle_extend"];
    UIImage *collapseImage = [PLVECUtils imageForWatchResource:@"plvec_live_realtime_subtitle_scale"];
    [self.expandButton setImage:expandImage forState:UIControlStateNormal];
    [self.expandButton setImage:collapseImage forState:UIControlStateSelected];
    [self.expandButton addTarget:self action:@selector(expandButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.expandButton];
    
    // 添加拖动手势识别器
    self.panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
    [self addGestureRecognizer:self.panGestureRecognizer];
    
    self.hidden = YES;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat width = self.bounds.size.width;
    CGFloat height = self.bounds.size.height;
    
    // 关闭按钮（右上角）
    self.closeButton.frame = CGRectMake(width - kButtonSize - kButtonMargin, kButtonMargin, kButtonSize, kButtonSize);
    
    // 展开/收起按钮（右下角）
    self.expandButton.frame = CGRectMake(width - kButtonSize - kButtonMargin, height - kButtonSize - kButtonMargin, kButtonSize, kButtonSize);
    
    // 容器视图（左右离父视图边距相等）
    // 右边距需要避开按钮：按钮宽 + 按钮边距 + 额外间隙
    CGFloat sideMargin = kButtonSize + 4.0f;
    
    // 容器宽度 = 总宽度 - 左边距 - 右边距
    CGFloat containerWidth = width - sideMargin ;
    
    // 设置 Frame：x = sideMargin，确保左右对称
    self.containerView.frame = CGRectMake(0, 0, containerWidth, height);
    
    // TableView（填充容器）
    self.tableView.frame = self.containerView.bounds;
}

- (void)initDataWithChannelId:(NSString *)channelId viewerId:(NSString *)viewerId {
    // 创建字幕处理器
    self.subtitleHandler = [[PLVLiveRealTimeSubtitleHandler alloc] init];
    self.subtitleHandler.delegate = self;
    [self.subtitleHandler initDataWithChannelId:channelId viewerId:viewerId];
}

- (void)updateSubtitles:(NSArray<PLVLiveSubtitleTranslation *> *)subtitles {
    self.subtitles = subtitles ?: @[];

    // 电商场景：收起/展开都显示完整历史，通过自动吸底保证默认看到最新一条（参考云课堂方案）
    self.displaySubtitles = self.subtitles;
    self.tableView.scrollEnabled = YES;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
        
        // 自动滚动到底部（仅当用户未主动上滑查看历史时）
        if (self.shouldAutoScrollToBottom && self.displaySubtitles.count > 0) {
            [self scrollTableToBottomAnimated:YES];
        }
    });
}

- (void)expand {
    self.isExpanded = YES;
    self.expandButton.selected = YES;
    [self updateLayout];
    [self updateSubtitles:self.subtitles];
}

- (void)collapse {
    self.isExpanded = NO;
    self.expandButton.selected = NO;
    
    [self updateLayout];
    [self updateSubtitles:self.subtitles];
}

- (void)updateLayout {
    // 固定高度106px（设计稿要求），展开时260px
    CGFloat height = self.isExpanded ? kExpandedHeight : kDefaultHeight;
    CGRect frame = self.frame;
    
    // 保持顶部位置不变，视图向下展开
    frame.size.height = height;
    
    self.frame = frame;
    
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

- (void)closeButtonClicked:(UIButton *)sender {
    // 点击关闭按钮时，禁用字幕并通知代理
    [self setSubtitleEnabled:NO];
    
    if ([self.delegate respondsToSelector:@selector(realTimeSubtitleViewDidClose:)]) {
        [self.delegate realTimeSubtitleViewDidClose:self];
    }
}

- (void)expandButtonClicked:(UIButton *)sender {
    if (self.isExpanded) {
        [self collapse];
    } else {
        [self expand];
    }
}

- (void)showSettingPopupMenu {
    // TODO: 显示设置弹窗（语言选择、开关控制）
}

#pragma mark - Pan Gesture Handler

- (void)handlePanGesture:(UIPanGestureRecognizer *)gesture {
    UIView *superview = self.superview;
    if (!superview) {
        return;
    }
    
    CGPoint translation = [gesture translationInView:superview];
    
    switch (gesture.state) {
        case UIGestureRecognizerStateBegan: {
            // 记录手势开始时的视图位置
            self.panStartPoint = self.frame.origin;
            break;
        }
        case UIGestureRecognizerStateChanged: {
            // 计算新位置
            CGFloat newX = self.panStartPoint.x + translation.x;
            CGFloat newY = self.panStartPoint.y + translation.y;
            
            // 限制在父视图范围内
            CGFloat minX = 0;
            CGFloat minY = 0;
            CGFloat maxX = superview.bounds.size.width - self.bounds.size.width;
            CGFloat maxY = superview.bounds.size.height - self.bounds.size.height;
            
            newX = MAX(minX, MIN(maxX, newX));
            newY = MAX(minY, MIN(maxY, newY));
            
            // 更新视图位置
            CGRect newFrame = self.frame;
            newFrame.origin.x = newX;
            newFrame.origin.y = newY;
            self.frame = newFrame;
            break;
        }
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled: {
            // 手势结束
            break;
        }
        default:
            break;
    }
}


- (PLVLiveRealTimeSubtitleHandler *)subtitleHandler {
    return _subtitleHandler;
}

- (void)setBilingualEnabled:(BOOL)enabled {
    _bilingualEnabled = enabled;
    if (enabled) {
        // 双语模式：同时显示原文和译文
        self.showOriginSubtitle = YES;
        self.showTranslateSubtitle = YES;
    } else {
        // 关闭双语：如果当前只显示原文，则保持原文；否则默认回到只显示译文
        if (self.showOriginSubtitle && !self.showTranslateSubtitle) {
            self.showOriginSubtitle = YES;
            self.showTranslateSubtitle = NO;
        } else {
            self.showOriginSubtitle = NO;
            self.showTranslateSubtitle = YES;
        }
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
        if (self.shouldAutoScrollToBottom && self.displaySubtitles.count > 0) {
            [self scrollTableToBottomAnimated:NO];
        }
    });
}

- (void)applySelectedLanguage:(NSString *)language
             bilingualEnabled:(BOOL)bilingualEnabled {
    NSString *safeLanguage = (language && language.length > 0) ? language : @"origin";
    _bilingualEnabled = bilingualEnabled;
    
    BOOL isOrigin = [safeLanguage isEqualToString:@"origin"];
    if (isOrigin) {
        // 原文不翻译：只显示原文
        self.showOriginSubtitle = YES;
        self.showTranslateSubtitle = NO;
    } else if (bilingualEnabled) {
        // 双语：原文 + 译文
        self.showOriginSubtitle = YES;
        self.showTranslateSubtitle = YES;
    } else {
        // 单语：只显示译文
        self.showOriginSubtitle = NO;
        self.showTranslateSubtitle = YES;
    }
    
    // 刷新显示（不改数据源，只更新展示状态）
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
        if (self.shouldAutoScrollToBottom && self.displaySubtitles.count > 0) {
            [self scrollTableToBottomAnimated:NO];
        }
    });
}

- (void)setSubtitleEnabled:(BOOL)enabled {
    _subtitleEnabled = enabled;
    
    if (enabled) {
        // 启用字幕：显示字幕视图
        self.hidden = NO;
    } else {
        // 禁用字幕：隐藏字幕视图
        self.hidden = YES;
    }
}

#pragma mark - PLVLiveRealTimeSubtitleHandlerDelegate

- (void)subtitleHandler:(PLVLiveRealTimeSubtitleHandler *)handler didUpdateRealTimeSubtitle:(PLVLiveSubtitleModel *)subtitle {
    // 单条字幕更新（云课堂场景使用）
}

- (void)subtitleHandler:(PLVLiveRealTimeSubtitleHandler *)handler didUpdateAllSubtitles:(NSArray<PLVLiveSubtitleTranslation *> *)subtitles {
    [self updateSubtitles:subtitles];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.displaySubtitles.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    PLVECRealTimeSubtitleCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PLVECRealTimeSubtitleCell" forIndexPath:indexPath];
    
    PLVLiveSubtitleTranslation *translation = self.displaySubtitles[indexPath.row];
    
    // 参考云课堂方案：总开关开启才显示字幕内容
    BOOL showOrigin = self.subtitleEnabled && self.showOriginSubtitle;
    BOOL showTranslation = self.subtitleEnabled && self.showTranslateSubtitle;
    [cell configureWithSubtitle:translation showOrigin:showOrigin showTranslation:showTranslation];
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row < 0 || indexPath.row >= self.displaySubtitles.count) {
        return 0.0f;
    }
    PLVLiveSubtitleTranslation *translation = self.displaySubtitles[indexPath.row];
    
    BOOL showOrigin = self.subtitleEnabled && self.showOriginSubtitle;
    BOOL showTranslation = self.subtitleEnabled && self.showTranslateSubtitle;
    return [PLVECRealTimeSubtitleCell cellHeightWithSubtitle:translation
                                                 showOrigin:showOrigin
                                            showTranslation:showTranslation
                                                      width:tableView.bounds.size.width];
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60.0f;
}

#pragma mark - UIScrollViewDelegate (参考云课堂方案：用户滚动时暂停自动吸底)

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    self.shouldAutoScrollToBottom = NO;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self updateAutoScrollStateForScrollView:scrollView];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!decelerate) {
        [self updateAutoScrollStateForScrollView:scrollView];
    }
}

#pragma mark - Private

- (void)updateAutoScrollStateForScrollView:(UIScrollView *)scrollView {
    CGFloat contentHeight = scrollView.contentSize.height;
    CGFloat scrollViewHeight = scrollView.bounds.size.height;
    CGFloat offsetY = scrollView.contentOffset.y;
    if (offsetY + scrollViewHeight >= contentHeight - 10.0f) {
        self.shouldAutoScrollToBottom = YES;
    }
}

- (void)scrollTableToBottomAnimated:(BOOL)animated {
    NSInteger rowCount = [self.tableView numberOfRowsInSection:0];
    if (rowCount <= 0) {
        return;
    }
    NSIndexPath *lastIndexPath = [NSIndexPath indexPathForRow:rowCount - 1 inSection:0];
    [self.tableView scrollToRowAtIndexPath:lastIndexPath
                          atScrollPosition:UITableViewScrollPositionBottom
                                  animated:animated];
}

@end
