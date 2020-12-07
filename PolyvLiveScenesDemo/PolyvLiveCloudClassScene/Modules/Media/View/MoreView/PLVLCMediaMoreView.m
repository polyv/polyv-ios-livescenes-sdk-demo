//
//  PLVLCMediaMoreView.m
//  PolyvLiveScenesDemo
//
//  Created by Lincal on 2020/9/29.
//  Copyright © 2020 polyv. All rights reserved.
//

#import "PLVLCMediaMoreView.h"

#import "PLVLCMediaMoreCell.h"
#import <PolyvFoundationSDK/PolyvFoundationSDK.h>

@interface PLVLCMediaMoreView () <UITableViewDataSource, UITableViewDelegate, PLVLCMediaMoreCellDelegate>

#pragma mark 状态
@property (nonatomic, assign) BOOL moreViewShow;

#pragma mark 数据
@property (nonatomic, strong) NSMutableArray <PLVLCMediaMoreModel *> * dataArray;

#pragma mark UI
/// view hierarchy
///
/// (PLVLCMediaMoreView) self
/// ├── (UIView) shdowBackgroundView
/// └── (UITableView) tableView
@property (nonatomic, strong) UIView * shdowBackgroundView;
@property (nonatomic, strong) UITableView * tableView;

@end

@implementation PLVLCMediaMoreView

#pragma mark - [ Life Period ]
- (instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        [self setupUI];
    }
    return self;
}

- (void)layoutSubviews{
    BOOL fullScreen = [UIScreen mainScreen].bounds.size.width > [UIScreen mainScreen].bounds.size.height;
    
    CGFloat viewWidth = CGRectGetWidth(self.bounds);
    CGFloat viewHeight = CGRectGetHeight(self.bounds);
    
    CGFloat topSafeAreaPadding;
    if (@available(iOS 11.0, *)) {
        topSafeAreaPadding = self.safeAreaInsets.top;
    } else {
        topSafeAreaPadding = self.topPaddingBelowiOS11;
    }
    
    CGFloat rightSafeAreaPadding = 0;
    if (@available(iOS 11.0, *)) { rightSafeAreaPadding = self.safeAreaInsets.right; }
    
    if (!fullScreen) {
        // 竖屏布局
        self.shdowBackgroundView.frame = self.bounds;
        self.tableView.frame = self.bounds;
    }else{
        // 横屏布局
        CGFloat rightPaddingScale = 280.0 / 896.0;
        CGFloat rightPadding = rightPaddingScale * viewWidth + rightSafeAreaPadding;
        if (rightPadding < 280.0) { rightPadding = 280.0; }
    
        self.shdowBackgroundView.frame = CGRectMake(viewWidth - rightPadding, 0, rightPadding, viewHeight);
        self.tableView.frame = CGRectMake(viewWidth - rightPadding, 30, rightPadding, viewHeight - 30);
    }
}


#pragma mark - [ Public Methods ]
- (void)refreshTableView{
    [self.tableView reloadData];
}

- (void)refreshTableViewWithDataArray:(NSArray <PLVLCMediaMoreModel *> *)dataArray{
    if ([PLVFdUtil checkArrayUseable:dataArray]) {
        self.dataArray = [dataArray mutableCopy];
    }else{
        NSLog(@"PLVLCMediaMoreView - refreshTableViewWithDataArray failed, dataArray illegal:%@",dataArray);
    }
}

- (void)updateTableViewWithDataArrayByMatchModel:(NSArray<PLVLCMediaMoreModel *> *)updateDataArray{
    if (self.dataArray.count > 0) {
        NSMutableArray * originalArray = [self.dataArray copy];
        for (PLVLCMediaMoreModel * updateModel in updateDataArray) {
            BOOL foundMatchModel = NO;
            for (int i = 0; i < originalArray.count; i ++) {
                PLVLCMediaMoreModel * originalModel = originalArray[i];
                if ([updateModel matchOtherMoreModel:originalModel]) {
                    // 若 选项系列总标题 相同，则认为同一系列，则用新的替换旧的
                    [self.dataArray replaceObjectAtIndex:i withObject:updateModel];
                    foundMatchModel = YES;
                    break;
                }
            }

            if (!foundMatchModel) {
                // 若最终都未发现此选项系列，则新增此选项系列
                [self.dataArray addObject:updateModel];
            }
        }
    }else{
        [self refreshTableViewWithDataArray:updateDataArray];
    }
}

- (void)showMoreViewOnSuperview:(UIView *)superview{
    [self removeFromSuperview];
    [superview addSubview:self];
    self.frame = superview.bounds;
    
    [self.superview bringSubviewToFront:self]; /// 保证在父视图中，层级最前
    [self switchShowStatusWithAnimation];
}

- (void)switchShowStatusWithAnimation{
    [self switchShowStatusWithAnimationAfterDelay:0];
}

- (PLVLCMediaMoreModel *)getMoreModelAtIndex:(NSInteger)index{
    if (index >= 0 && [PLVFdUtil checkArrayUseable:self.dataArray] && index < self.dataArray.count) {
        PLVLCMediaMoreModel * model = [self.dataArray objectAtIndex:index];
        return model;
    }else{
        NSLog(@"PLVLCMediaMoreView - getMoreModelAtIndex failed, dataArray:%@",self.dataArray);
        return nil;
    }
}


#pragma mark - [ Private Methods ]
- (void)setupUI{
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

- (void)switchShowStatusWithAnimationAfterDelay:(NSTimeInterval)delay{
    _moreViewShow = !_moreViewShow;
    
    if (_moreViewShow) {
        self.hidden = NO;
        self.userInteractionEnabled = YES;
    }
    
    CGFloat alpha = _moreViewShow ? 1.0 : 0.0;
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:0.3 delay:delay options:UIViewAnimationOptionCurveEaseInOut animations:^{
        weakSelf.tableView.alpha = alpha;
        weakSelf.shdowBackgroundView.alpha = alpha;
    } completion:^(BOOL finished) {
        weakSelf.hidden = !weakSelf.moreViewShow;
        if (!weakSelf.moreViewShow) { weakSelf.userInteractionEnabled = NO; }
    }];
}

#pragma mark Getter
- (UIView *)shdowBackgroundView{
    if (!_shdowBackgroundView) {
        _shdowBackgroundView = [[UIView alloc] init];
        _shdowBackgroundView.backgroundColor = UIColorFromRGBA(@"000000", 0.85);
    }
    return _shdowBackgroundView;
}

- (UITableView *)tableView{
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        _tableView.showsVerticalScrollIndicator = NO;
        _tableView.showsHorizontalScrollIndicator = NO;
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.backgroundColor = [UIColor clearColor];
        _tableView.tableFooterView = [[UIView alloc] init];
    }
    return _tableView;
}


#pragma mark - [ Delegate ]
#pragma mark UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.dataArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString * cellId = @"PLVLCMediaMoreCellId";
    
    PLVLCMediaMoreModel * model;
    if (indexPath.row < self.dataArray.count) {
        model = self.dataArray[indexPath.row];
    }else{
        NSLog(@"PLVLCMediaMoreView - get model failed, indexPath illegal:%@",indexPath);
    }
    
    PLVLCMediaMoreCell * cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    if (!cell) {
        cell = [[PLVLCMediaMoreCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellId];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.delegate = self;
    }
    [cell setModel:model];
    
    return cell;
}

#pragma mark UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    BOOL fullScreen = [UIScreen mainScreen].bounds.size.width > [UIScreen mainScreen].bounds.size.height;
    return fullScreen ? 88.0 : 56.0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [self switchShowStatusWithAnimation];
}

#pragma mark PLVLCMediaMoreCellDelegate
- (void)plvLCMediaMoreCell:(PLVLCMediaMoreCell *)cell buttonClickedWithModel:(nonnull PLVLCMediaMoreModel *)moreModel{
    if (self.delegate && [self.delegate respondsToSelector:@selector(plvLCMediaMoreView:optionItemSelected:)]) {
        [self.delegate plvLCMediaMoreView:self optionItemSelected:moreModel];
    }
    [self switchShowStatusWithAnimationAfterDelay:0.1]; /// 延后 0.1秒 回收页面，保证用户可感知已选中
}


#pragma mark - [ Event ]
- (void)tapGestureAction:(UITapGestureRecognizer *)tap{
    [self switchShowStatusWithAnimation];
}

@end
