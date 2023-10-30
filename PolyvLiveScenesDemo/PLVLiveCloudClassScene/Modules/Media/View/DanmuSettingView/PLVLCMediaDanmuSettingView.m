//
//  PLVLCMediaDanmuSettingView.m
//  PolyvLiveScenesDemo
//
//  Created by Dhan on 2023/4/24.
//  Copyright © 2023 PLV. All rights reserved.
//

#import "PLVLCMediaDanmuSettingView.h"

#import "PLVMultiLanguageManager.h"
#import "PLVLCMediaDanmuSettingCell.h"
#import <PLVFoundationSDK/PLVFoundationSDK.h>

@interface PLVLCMediaDanmuSettingView () <UITableViewDataSource, UITableViewDelegate, PLVLCMediaDanmuSettingCellDelegate>

#pragma mark 状态
@property (nonatomic, assign) BOOL danmuSettingViewShow;

#pragma mark 数据

#pragma mark UI
/// view hierarchy
///
/// (PLVLCMediaDanmuSettingView) self
/// ├── (UIView) shdowBackgroundView
/// └── (UITableView) tableView
@property (nonatomic, strong) UIView *shdowBackgroundView;
@property (nonatomic, strong) UITableView * tableView;
@property (nonatomic, strong) PLVLCMediaDanmuSettingCell *danmuSettingCell;

@end

@implementation PLVLCMediaDanmuSettingView

#pragma mark - [ Life Period ]
- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setupUI];
    }
    return self;
}

- (void)layoutSubviews{
    BOOL fullScreen = [UIScreen mainScreen].bounds.size.width > [UIScreen mainScreen].bounds.size.height;
    
    CGFloat viewWidth = CGRectGetWidth(self.superview.bounds);
    CGFloat viewHeight = CGRectGetHeight(self.superview.bounds);
    
    CGFloat rightSafeAreaPadding = 0;
    if (@available(iOS 11.0, *)) { rightSafeAreaPadding = self.safeAreaInsets.right; }
    
    if (!fullScreen) {
        // 竖屏布局
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad && viewWidth == PLVScreenWidth) {
            // iPad且非分屏时，布局为屏幕一半
            self.shdowBackgroundView.frame = CGRectMake(viewWidth / 2, 0, viewWidth / 2, viewHeight);
            self.tableView.frame = self.shdowBackgroundView.frame;
            
        } else {
            // 竖屏时 直接隐藏
            if (self.danmuSettingViewShow) {
                [self switchShowStatusWithAnimation];
            }
        }
        
    } else {
        // 横屏布局
        self.shdowBackgroundView.frame = CGRectMake(viewWidth / 2, 0, viewWidth / 2, viewHeight);
        self.tableView.frame = CGRectMake(viewWidth / 2, viewHeight / 2 - 28 , viewWidth / 2, viewHeight / 2 + 28);
    }
}


#pragma mark - [ Public Methods ]

- (void)refreshTableView{
    [self.tableView reloadData];
}

- (void)switchShowStatusWithAnimation {
    [self switchShowStatusWithAnimationAfterDelay:0];
}

- (void)showDanmuSettingViewOnSuperview:(UIView *)superview {
    [self removeFromSuperview];
    [superview addSubview:self];
    self.frame = superview.bounds;
    [self.superview bringSubviewToFront:self]; /// 保证在父视图中，层级最前
    if (!_danmuSettingViewShow) {
        [self switchShowStatusWithAnimation];
    }
}
#pragma mark - [ Private Methods ]

- (void)setupUI {
    // 添加 手势
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureAction:)];
    [self addGestureRecognizer:tap];
    
    // 添加 UI
    [self addSubview:self.shdowBackgroundView];
    [self addSubview:self.tableView];

    // 设置 初始状态
    self.hidden = YES;
    self.shdowBackgroundView.alpha = 0;
    self.tableView.alpha = 0;
}

- (void)switchShowStatusWithAnimationAfterDelay:(NSTimeInterval)delay {
    _danmuSettingViewShow = !_danmuSettingViewShow;
    
    if (_danmuSettingViewShow) {
        self.hidden = NO;
        self.userInteractionEnabled = YES;
    }
    
    CGFloat alpha = _danmuSettingViewShow ? 1.0 : 0.0;
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:0.3 delay:delay options:UIViewAnimationOptionCurveEaseInOut animations:^{
        weakSelf.shdowBackgroundView.alpha = alpha;
        weakSelf.tableView.alpha = alpha;
    } completion:^(BOOL finished) {
        weakSelf.hidden = !weakSelf.danmuSettingViewShow;
        if (!weakSelf.danmuSettingViewShow) { weakSelf.userInteractionEnabled = NO; }
    }];
}


#pragma mark Getter

- (UIView *)shdowBackgroundView {
    if (!_shdowBackgroundView) {
        _shdowBackgroundView = [[UIView alloc] init];
        _shdowBackgroundView.backgroundColor = PLV_UIColorFromRGBA(@"000000", 0.85);
    }
    return _shdowBackgroundView;
}

- (UITableView *)tableView{
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        _tableView.showsVerticalScrollIndicator = NO;
        _tableView.showsHorizontalScrollIndicator = NO;
        _tableView.scrollEnabled = NO;
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.backgroundColor = [UIColor clearColor];
        _tableView.tableFooterView = [[UIView alloc] init];
    }
    return _tableView;
}

#pragma mark Getter

#pragma mark - [ Delegate ]

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellId = @"PLVLCMediaDanmuSettingCellId";
    PLVLCMediaDanmuSettingCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    if(!cell) {
        cell = [[PLVLCMediaDanmuSettingCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellId];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.delegate = self;
    }
    
    NSArray <NSNumber *> *scaleValueArray = @[@34, @26, @20, @14, @6];
    NSArray <NSString *> *scaleTitleArray = @[PLVLocalizedString(@"缓慢"), PLVLocalizedString(@"较慢"), PLVLocalizedString(@"标准"), PLVLocalizedString(@"较快"), PLVLocalizedString(@"快速")];
    NSNumber *index = @2;//默认选择标准
    for (int i = 0; i < scaleValueArray.count; i++) {
        if ([scaleValueArray[i] isEqualToNumber:self.defaultDanmuSpeed]) {
            index = [NSNumber numberWithInt:i];
            break;
        }
    }
    [cell setDanmuSpeedCellWithTitle:PLVLocalizedString(@"弹幕速度") scaleValueArray:scaleValueArray scaleTitleArray:scaleTitleArray defaultScaleIndex:index];
    return cell;
}

#pragma mark UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    BOOL fullScreen = [UIScreen mainScreen].bounds.size.width > [UIScreen mainScreen].bounds.size.height;
    BOOL isPad = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
    return fullScreen || isPad ? 88.0 : 56.0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
}

- (void)plvLCMediaDanmuSettingCell:(PLVLCMediaDanmuSettingCell *)cell updateSelectedScaleValue:(NSNumber *)scalevalue {
    if (self.delegate && [self.delegate respondsToSelector:@selector(plvLCMediaDanmuSettingView:danmuSpeedUpdate:)]) {
        [self.delegate plvLCMediaDanmuSettingView:self danmuSpeedUpdate:scalevalue];
        NSLog(@"弹幕速度更新：%f",scalevalue.floatValue);
    }
}

#pragma mark - [ Event ]

- (void)tapGestureAction:(UITapGestureRecognizer *)tap {
    CGPoint point = [tap locationInView:self];
    if (CGRectContainsPoint(self.shdowBackgroundView.frame, point) || CGRectContainsPoint(self.tableView.frame, point)) {
        return;
    }
    [self switchShowStatusWithAnimation];
}

@end
