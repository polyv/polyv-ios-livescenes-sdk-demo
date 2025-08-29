//
//  PLVLCMediaMoreView.m
//  PLVLiveScenesDemo
//
//  Created by Lincal on 2020/9/29.
//  Copyright © 2020 PLV. All rights reserved.
//

#import "PLVLCMediaMoreView.h"

#import "PLVLCMediaMoreCell.h"
#import "PLVLCSubtitleSettingCell.h"
#import "PLVMultiLanguageManager.h"
#import <PLVFoundationSDK/PLVFoundationSDK.h>
#import <PLVLiveScenesSDK/PLVConsoleLogger.h>

@interface PLVLCMediaMoreView () <UITableViewDataSource, UITableViewDelegate, PLVLCMediaMoreCellDelegate, PLVLCSubtitleSettingCellDelegate>

#pragma mark 状态
@property (nonatomic, assign) BOOL moreViewShow;

#pragma mark 数据
@property (nonatomic, strong) NSMutableArray <PLVLCMediaMoreModel *> * dataArray;
@property (nonatomic, strong) NSMutableArray <PLVLCMediaMoreModel *> * optionsDataArray;
@property (nonatomic, strong) NSMutableArray <PLVLCMediaMoreModel *> * switchesDataArray;

#pragma mark UI
/// view hierarchy
///
/// (PLVLCMediaMoreView) self
/// ├── (UIView) shdowBackgroundView
/// └── (UITableView) tableView
@property (nonatomic, strong) UIView * shdowBackgroundView;
@property (nonatomic, strong) UITableView * tableView;
@property (nonatomic, strong) PLVLCMediaMoreCell *danmuCell;

@end

@implementation PLVLCMediaMoreView

#pragma mark - [ Life Period ]
- (instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        [self setupUI];
        self.optionsDataArray = [[NSMutableArray alloc]init];
        self.switchesDataArray = [[NSMutableArray alloc]init];
    }
    return self;
}

- (void)layoutSubviews{
    BOOL fullScreen = [UIScreen mainScreen].bounds.size.width > [UIScreen mainScreen].bounds.size.height;
    
    CGFloat viewWidth = CGRectGetWidth(self.superview.bounds);
    CGFloat viewHeight = CGRectGetHeight(self.superview.bounds);
    
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
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad && viewWidth == PLVScreenWidth) {
            // iPad且非分屏时，布局为屏幕一半
            CGFloat topPadding = viewHeight / 2 - 56.0 * self.dataArray.count / 2;
            self.shdowBackgroundView.frame = CGRectMake(viewWidth / 2, 0, viewWidth / 2, viewHeight);
            self.tableView.frame = self.shdowBackgroundView.frame;
        }else{
            self.shdowBackgroundView.frame = self.superview.bounds;
            self.tableView.frame = self.superview.bounds;
        }

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
        [self.switchesDataArray removeAllObjects];
        [self.optionsDataArray removeAllObjects];
        for (int i = 0;i < [dataArray count]; i++) {
            if (dataArray[i].mediaMoreModelMode == PLVLCMediaMoreModelMode_Switch) {
                [self.switchesDataArray addObject:dataArray[i]];
            } else {
                [self.optionsDataArray addObject:dataArray[i]];
            }
        }
    }else{
        PLV_LOG_ERROR(PLVConsoleLogModuleTypePlayer,@"PLVLCMediaMoreView - refreshTableViewWithDataArray failed, dataArray illegal:%@",dataArray);
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

- (void)showMoreViewOnSuperview:(UIView *)superview {
    [self removeFromSuperview];
    [superview addSubview:self];
    self.frame = superview.bounds;
    
    [self.superview bringSubviewToFront:self]; /// 保证在父视图中，层级最前
    if (!_moreViewShow) {
        [self switchShowStatusWithAnimation];
    }
}

//当屏幕旋转的时候需要重新设置superview 和 frame
- (void)updateMoreViewOnSuperview:(UIView *)superview {
    if (_moreViewShow) {
        [self showMoreViewOnSuperview:superview];
    }
}

- (void)switchShowStatusWithAnimation{
    [self switchShowStatusWithAnimationAfterDelay:0];
}

- (PLVLCMediaMoreModel *)getMoreModelAtIndex:(NSInteger)index{
    if (index >= 0 && [PLVFdUtil checkArrayUseable:self.dataArray] && index < self.dataArray.count) {
        PLVLCMediaMoreModel * model = [self.dataArray objectAtIndex:index];
        return model;
    }else{
        PLV_LOG_ERROR(PLVConsoleLogModuleTypePlayer,@"PLVLCMediaMoreView - getMoreModelAtIndex failed, dataArray:%@",self.dataArray);
        return nil;
    }
}

- (void)openDanmuButton:(BOOL)open {
    if (self.danmuCell) {
        [self.danmuCell openDanmuButton:open];
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
        _shdowBackgroundView.backgroundColor = PLV_UIColorFromRGBA(@"000000", 0.85);
    }
    return _shdowBackgroundView;
}

- (UITableView *)tableView{
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        _tableView.showsVerticalScrollIndicator = NO;
        _tableView.showsHorizontalScrollIndicator = NO;
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
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
    return [PLVFdUtil checkArrayUseable:self.switchesDataArray] ? self.optionsDataArray.count + 1 : self.optionsDataArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString * cellId = @"PLVLCMediaMoreCellId";
    static NSString *subtitleCellId = @"PLVLCSubtitleSettingCellId";
    
    PLVLCMediaMoreModel * model;
    UITableViewCell *cell;
    
    if (indexPath.row == 0 && [PLVFdUtil checkArrayUseable:self.switchesDataArray]) {
        // 创建普通 Cell
        PLVLCMediaMoreCell *moreCell = [tableView dequeueReusableCellWithIdentifier:cellId];
        if (!moreCell) {
            moreCell = [[PLVLCMediaMoreCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellId];
            moreCell.selectionStyle = UITableViewCellSelectionStyleNone;
            moreCell.delegate = self;
        }
        [moreCell setSwitchesDataArray:self.switchesDataArray];
        cell = moreCell;
        for (int i = 0; i < self.switchesDataArray.count; i++) {
            if ([self.switchesDataArray[i].optionTitle isEqualToString:PLVLocalizedString(@"弹幕")]) {
                self.danmuCell = (PLVLCMediaMoreCell *)cell;
            }
        }
    } else {
        NSInteger currentRow = [PLVFdUtil checkArrayUseable:self.switchesDataArray] ? (indexPath.row - 1) : indexPath.row;
        if (currentRow < self.optionsDataArray.count) {
            model = self.optionsDataArray[currentRow];
            if ([model.optionTitle isEqualToString:PLVLocalizedString(@"回放字幕")]) {
                // 创建字幕设置 Cell
                PLVLCSubtitleSettingCell *subtitleCell = [tableView dequeueReusableCellWithIdentifier:subtitleCellId];
                if (!subtitleCell) {
                    subtitleCell = [[PLVLCSubtitleSettingCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:subtitleCellId];
                    subtitleCell.selectionStyle = UITableViewCellSelectionStyleNone;
                    subtitleCell.delegate = self;
                }
                NSArray *subtitleList = PLV_SafeArraryForDictKey(model.customDictionary, @"subtitleList");
                [subtitleCell setupWithSubtitleList:subtitleList];
                cell = subtitleCell;
            } else {
                PLVLCMediaMoreCell *moreCell = [tableView dequeueReusableCellWithIdentifier:cellId];
                if (!moreCell) {
                    moreCell = [[PLVLCMediaMoreCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellId];
                    moreCell.selectionStyle = UITableViewCellSelectionStyleNone;
                    moreCell.delegate = self;
                }
                [moreCell setModel:model];
                cell = moreCell;
            }
        }else{
            PLV_LOG_ERROR(PLVConsoleLogModuleTypePlayer,@"PLVLCMediaMoreView - get model failed, indexPath illegal:%@",indexPath);
        }
    }
    return cell;
}

#pragma mark UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    BOOL fullScreen = [UIScreen mainScreen].bounds.size.width > [UIScreen mainScreen].bounds.size.height;
    BOOL isPad = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
    NSInteger currentRow = [PLVFdUtil checkArrayUseable:self.switchesDataArray] ? (indexPath.row - 1) : indexPath.row;
    BOOL isSubtitleCell = NO;
    CGFloat adjustHeight = 0;
    if (currentRow < self.optionsDataArray.count) {
        PLVLCMediaMoreModel *model = self.optionsDataArray[currentRow];
        if ([model.optionTitle isEqualToString:PLVLocalizedString(@"回放字幕")]) {
            isSubtitleCell = YES;
        }
        
        if (model.optionItemsArray.count > PLVLCMediaMoreCellOptionCountPerRow){
            NSInteger rowCount = model.optionItemsArray.count/PLVLCMediaMoreCellOptionCountPerRow + 1;
            adjustHeight += (rowCount - 1)* 10;
        }
    }
    return fullScreen || isPad || isSubtitleCell ? (88.0 + adjustHeight ) : (56.0 + adjustHeight);
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

#pragma mark PLVLCSubtitleSettingCellDelegate

- (void)PLVLCSubtitleSettingCell:(PLVLCSubtitleSettingCell *)cell didUpdateSubtitleState:(PLVPlaybackSubtitleModel *)originalSubtitle translateSubtitle:(PLVPlaybackSubtitleModel *)translateSubtitle {
    if (self.delegate && [self.delegate respondsToSelector:@selector(plvLCMediaMoreView:didUpdateSubtitleState:translateSubtitle:)]) {
        [self.delegate plvLCMediaMoreView:self didUpdateSubtitleState:originalSubtitle translateSubtitle:translateSubtitle];
    }
}

#pragma mark - [ Event ]
- (void)tapGestureAction:(UITapGestureRecognizer *)tap{
    [self switchShowStatusWithAnimation];
}

@end
