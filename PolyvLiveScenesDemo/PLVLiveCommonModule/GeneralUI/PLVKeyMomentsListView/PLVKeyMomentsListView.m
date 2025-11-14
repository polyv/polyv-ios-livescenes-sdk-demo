//
//  PLVKeyMomentsListView.m
//  PLVLiveScenesDemo
//
//  Created by Developer on 2025/01/01.
//  Copyright © 2025 PLV. All rights reserved.
//

#import "PLVKeyMomentsListView.h"
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>
#import <PLVFoundationSDK/PLVFoundationSDK.h>
#import <SDWebImage/UIImageView+WebCache.h>
#import "PLVLCUtils.h"

static CGFloat kKeyMomentsListViewAnimationDuration = 0.3;

@interface PLVKeyMomentsListCell : UITableViewCell

@property (nonatomic, strong) PLVKeyMomentModel *keyMoment;

@end

@interface PLVKeyMomentsListView () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UIView *backgroundView;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIButton *closeButton;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, assign) BOOL isShowing;

// 横屏适配相关
@property (nonatomic, assign) CGFloat sheetHeight; // 竖屏时的高度
@property (nonatomic, assign) CGFloat sheetLandscapeWidth; // 横屏时的宽度
@property (nonatomic, assign) BOOL supportLandscape; // 是否支持横屏
@property (nonatomic, assign) UIInterfaceOrientation currentOrientation; // 当前方向

@end

@implementation PLVKeyMomentsListView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        // 默认值：竖屏高度400，横屏宽度400
        self.sheetHeight = 400;
        self.sheetLandscapeWidth = 400;
        self.supportLandscape = YES;
        self.currentOrientation = [UIApplication sharedApplication].statusBarOrientation;
        self.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    [self addSubview:self.backgroundView];
    [self addSubview:self.contentView];
    [self.contentView addSubview:self.titleLabel];
    [self.contentView addSubview:self.closeButton];
    [self.contentView addSubview:self.tableView];
    
    // 初始状态：根据横竖屏设置初始位置
    [self resetContentViewPosition];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.backgroundView.frame = self.bounds;
    
    // 如果正在显示，更新内容视图位置（用于横竖屏切换）
    if (self.isShowing) {
        [self updateContentViewShowPosition];
    }
    
    // 内容视图内部布局
    CGFloat padding = 16;
    CGFloat titleHeight = 20;
    CGFloat closeButtonSize = 24;
    CGFloat contentViewWidth = CGRectGetWidth(self.contentView.bounds);
    CGFloat contentViewHeight = CGRectGetHeight(self.contentView.bounds);
    
    self.titleLabel.frame = CGRectMake(padding, padding, contentViewWidth - padding * 2 - closeButtonSize - 8, titleHeight);
    self.closeButton.frame = CGRectMake(contentViewWidth - padding - closeButtonSize, padding, closeButtonSize, closeButtonSize);
    
    CGFloat tableY = padding + titleHeight + 12;
    self.tableView.frame = CGRectMake(0, tableY, contentViewWidth, contentViewHeight - tableY);
    
    // 更新圆角
    [self updateContentViewCornerRadius];
}

#pragma mark - Public Methods

- (void)show {
    if (self.isShowing) return;
    
    // 确保视图已经被添加到父视图
    if (!self.superview) {
        return;
    }
    
    // 确保 frame 正确
    if (CGRectIsEmpty(self.frame)) {
        self.frame = self.superview.bounds;
    }
    
    // 监听设备方向变化（如果支持横屏）
    if (self.supportLandscape) {
        [[NSNotificationCenter defaultCenter] addObserver:self 
                                                 selector:@selector(deviceOrientationDidChangeNotification:) 
                                                     name:UIDeviceOrientationDidChangeNotification 
                                                   object:nil];
    }
    
    self.isShowing = YES;
    self.alpha = 1;
    
    // 重置位置
    [self resetContentViewPosition];
    
    // 执行显示动画
    [UIView animateWithDuration:kKeyMomentsListViewAnimationDuration animations:^{
        [self updateContentViewShowPosition];
    }];
}

- (void)hide {
    if (!self.isShowing) return;
    
    self.isShowing = NO;
    
    // 执行隐藏动画
    [UIView animateWithDuration:kKeyMomentsListViewAnimationDuration animations:^{
        self.alpha = 0;
        [self resetContentViewPosition];
    } completion:^(BOOL finished) {
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        if ([self.delegate respondsToSelector:@selector(keyMomentsListViewWillDismiss:)]) {
            [self.delegate keyMomentsListViewWillDismiss:self];
        }
    }];
}

- (void)setKeyMoments:(NSArray<PLVKeyMomentModel *> *)keyMoments {
    _keyMoments = keyMoments;
    [self.tableView reloadData];
}

#pragma mark - Private Methods

- (void)backgroundTapped {
    [self hide];
}

- (void)closeButtonTapped {
    [self hide];
}

/// 重置内容视图到隐藏位置（动画前）
- (void)resetContentViewPosition {
    CGFloat viewWidth = CGRectGetWidth(self.bounds);
    CGFloat viewHeight = CGRectGetHeight(self.bounds);
    
    // 如果 bounds 无效，使用默认值
    if (viewWidth <= 0 || viewHeight <= 0) {
        viewWidth = [UIScreen mainScreen].bounds.size.width;
        viewHeight = [UIScreen mainScreen].bounds.size.height;
    }
    
    BOOL isLandscape = [PLVLCUtils sharedUtils].isLandscape && self.supportLandscape;
    
    if (isLandscape) {
        // 横屏：初始位置在屏幕右侧外
        CGFloat contentWidth = self.sheetLandscapeWidth;
        self.contentView.frame = CGRectMake(viewWidth, 0, contentWidth, viewHeight);
    } else {
        // 竖屏：初始位置在屏幕底部外
        self.contentView.frame = CGRectMake(0, viewHeight, viewWidth, self.sheetHeight);
    }
}

/// 更新内容视图到显示位置（动画中）
- (void)updateContentViewShowPosition {
    CGFloat viewWidth = CGRectGetWidth(self.bounds);
    CGFloat viewHeight = CGRectGetHeight(self.bounds);
    
    // 如果 bounds 无效，使用默认值
    if (viewWidth <= 0 || viewHeight <= 0) {
        viewWidth = [UIScreen mainScreen].bounds.size.width;
        viewHeight = [UIScreen mainScreen].bounds.size.height;
    }
    
    BOOL isLandscape = [PLVLCUtils sharedUtils].isLandscape && self.supportLandscape;
    
    if (isLandscape) {
        // 横屏：从右侧滑入
        CGFloat rightInsets = [PLVLCUtils sharedUtils].areaInsets.right;
        CGFloat contentWidth = self.sheetLandscapeWidth + rightInsets;
        self.contentView.frame = CGRectMake(viewWidth - contentWidth, 0, contentWidth, viewHeight);
    } else {
        // 竖屏：从底部滑入
        self.contentView.frame = CGRectMake(0, viewHeight - self.sheetHeight, viewWidth, self.sheetHeight);
    }
}

/// 更新内容视图圆角
- (void)updateContentViewCornerRadius {
    BOOL isLandscape = [PLVLCUtils sharedUtils].isLandscape && self.supportLandscape;
    
    if (isLandscape) {
        // 横屏：左侧圆角
        self.contentView.layer.cornerRadius = 12;
        self.contentView.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMinXMaxYCorner;
    } else {
        // 竖屏：顶部圆角
        self.contentView.layer.cornerRadius = 12;
        self.contentView.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner;
    }
}

/// 设备方向变化通知
- (void)deviceOrientationDidChangeNotification:(NSNotification *)notify {
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    if (orientation == self.currentOrientation) {
        return;
    }
    if (orientation == UIInterfaceOrientationPortrait ||
        orientation == UIInterfaceOrientationLandscapeLeft ||
        orientation == UIInterfaceOrientationLandscapeRight) {
        self.currentOrientation = orientation;
        if (self.isShowing) {
            // 如果正在显示，重新布局并动画
            [UIView animateWithDuration:kKeyMomentsListViewAnimationDuration animations:^{
                [self updateContentViewShowPosition];
                [self updateContentViewCornerRadius];
            }];
        }
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.keyMoments.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    PLVKeyMomentsListCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PLVKeyMomentsListCell" forIndexPath:indexPath];
    cell.keyMoment = self.keyMoments[indexPath.row];
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    PLVKeyMomentModel *keyMoment = self.keyMoments[indexPath.row];
    if ([self.delegate respondsToSelector:@selector(keyMomentsListView:didSelectKeyMoment:)]) {
        [self.delegate keyMomentsListView:self didSelectKeyMoment:keyMoment];
    }
    
    [self hide];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 80;
}

#pragma mark - Getters

- (UIView *)backgroundView {
    if (!_backgroundView) {
        _backgroundView = [[UIView alloc] init];
        _backgroundView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(backgroundTapped)];
        [_backgroundView addGestureRecognizer:tap];
    }
    return _backgroundView;
}

- (UIView *)contentView {
    if (!_contentView) {
        _contentView = [[UIView alloc] init];
        _contentView.backgroundColor = [UIColor whiteColor];
        _contentView.layer.cornerRadius = 12;
        _contentView.layer.masksToBounds = YES;
    }
    return _contentView;
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.text = @"精彩看点";
        _titleLabel.font = [UIFont boldSystemFontOfSize:18];
        _titleLabel.textColor = [UIColor blackColor];
    }
    return _titleLabel;
}

- (UIButton *)closeButton {
    if (!_closeButton) {
        _closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_closeButton setTitle:@"✕" forState:UIControlStateNormal];
        [_closeButton setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
        _closeButton.titleLabel.font = [UIFont systemFontOfSize:18];
        [_closeButton addTarget:self action:@selector(closeButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    }
    return _closeButton;
}

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        _tableView.dataSource = self;
        _tableView.delegate = self;
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableView.showsVerticalScrollIndicator = NO;
        [_tableView registerClass:[PLVKeyMomentsListCell class] forCellReuseIdentifier:@"PLVKeyMomentsListCell"];
    }
    return _tableView;
}

@end

#pragma mark - PLVKeyMomentsListCell

@interface PLVKeyMomentsListCell ()

@property (nonatomic, strong) UIImageView *thumbnailImageView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *timeLabel;

@end

@implementation PLVKeyMomentsListCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        [self setupCellUI];
    }
    return self;
}

- (void)setupCellUI {
    [self.contentView addSubview:self.thumbnailImageView];
    [self.contentView addSubview:self.titleLabel];
    [self.contentView addSubview:self.timeLabel];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat padding = 16;
    CGFloat thumbnailSize = 60;
    CGFloat contentHeight = CGRectGetHeight(self.contentView.bounds);
    
    self.thumbnailImageView.frame = CGRectMake(padding, (contentHeight - thumbnailSize) / 2, thumbnailSize, thumbnailSize);
    
    CGFloat labelX = padding + thumbnailSize + 12;
    CGFloat labelWidth = CGRectGetWidth(self.contentView.bounds) - labelX - padding;
    
    self.titleLabel.frame = CGRectMake(labelX, (contentHeight - 40) / 2, labelWidth, 22);
    self.timeLabel.frame = CGRectMake(labelX, CGRectGetMaxY(self.titleLabel.frame) + 2, labelWidth, 16);
}

- (void)setKeyMoment:(PLVKeyMomentModel *)keyMoment {
    _keyMoment = keyMoment;
    
    self.titleLabel.text = keyMoment.title;
    self.timeLabel.text = [PLVFdUtil secondsToString:keyMoment.markTime];
    
    // 加载缩略图
   if (keyMoment.previewUrl) {
        // 使用网络图片加载库加载，这里先设置占位图
         [self.thumbnailImageView sd_setImageWithURL:[NSURL URLWithString:keyMoment.previewUrl]];
    }
}

#pragma mark - Getters

- (UIImageView *)thumbnailImageView {
    if (!_thumbnailImageView) {
        _thumbnailImageView = [[UIImageView alloc] init];
        _thumbnailImageView.contentMode = UIViewContentModeScaleAspectFill;
        _thumbnailImageView.clipsToBounds = YES;
        _thumbnailImageView.layer.cornerRadius = 6;
        _thumbnailImageView.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1];
    }
    return _thumbnailImageView;
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = [UIFont systemFontOfSize:16];
        _titleLabel.textColor = [UIColor blackColor];
        _titleLabel.numberOfLines = 1;
    }
    return _titleLabel;
}

- (UILabel *)timeLabel {
    if (!_timeLabel) {
        _timeLabel = [[UILabel alloc] init];
        _timeLabel.font = [UIFont systemFontOfSize:14];
        _timeLabel.textColor = [UIColor grayColor];
    }
    return _timeLabel;
}

@end
