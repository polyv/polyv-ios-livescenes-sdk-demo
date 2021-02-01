//
//  PLVECCommodityViewController.m
//  PolyvLiveScenesDemo
//
//  Created by Hank on 2021/1/20.
//  Copyright © 2021 polyv. All rights reserved.
//  商品列表核心类

#import "PLVECCommodityViewController.h"

#import "PLVRoomDataManager.h"
#import "PLVECCommodityModelsManager.h"

#import "PLVECCommodityView.h"
#import "PLVECCommodityCell.h"

@interface PLVECCommodityViewController ()
<
UIGestureRecognizerDelegate
,UITableViewDelegate
,UITableViewDataSource
,PLVECCommodityCellDelegate
>

// 商品数据管理
@property (nonatomic, strong) PLVECCommodityModelsManager *commodityModelsManager;
// 商品列表View
@property (nonatomic, strong) PLVECCommodityView *commodityView;

@end

@implementation PLVECCommodityViewController

#pragma mark - [ Life Period ]
- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupUI];
    
    _commodityModelsManager = [[PLVECCommodityModelsManager alloc] init];
    [self loadCommodityInfo];
}

#pragma mark - [ Public Methods ]
- (void)receiveProductMessage:(NSInteger)status content:(id)content {
    [self.commodityModelsManager receiveProductMessage:status content:content];
    [self.commodityView reloadData:self.commodityModelsManager.totalItems];
}

#pragma mark - [ Private Methods ]
- (void)setupUI {
    [self.view addSubview:self.commodityView];
    
    // 添加点击关闭按钮关闭页面回调
    __weak typeof(self) weakSelf = self;
    self.commodityView.closeButtonActionBlock = ^(PLVECBottomView * _Nonnull view) {
        [weakSelf tapAction:nil];
    };
    
    // 添加单击关闭页面手势
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] init];
    [tapGestureRecognizer addTarget:self action:@selector(tapAction:)];
    tapGestureRecognizer.delegate = self;
    [self.view addGestureRecognizer:tapGestureRecognizer];
}

- (void)loadCommodityInfo {
    [self.commodityView startLoading];
    
    __weak typeof(self)weakSelf = self;
    [self.commodityModelsManager loadCommodityInfoWithCompletion:^(NSError * _Nonnull error) {
        [weakSelf.commodityView stopLoading];
        if (error) {
            NSLog(@"loadCommodityInfo-loadCommodityInfoWithCompletion 请求失败：%@", error.localizedDescription);
        }
        [weakSelf.commodityView reloadData:weakSelf.commodityModelsManager.totalItems];
    }];
}

#pragma mark Getter
- (PLVECCommodityView *)commodityView {
    if (! _commodityView) {
        
        CGFloat height = 410 + P_SafeAreaBottomEdgeInsets();
        CGRect frame = CGRectMake(0, CGRectGetHeight(self.view.bounds)-height- P_SafeAreaTopEdgeInsets(),
                                              CGRectGetWidth(self.view.bounds), height);
        
        _commodityView = [[PLVECCommodityView alloc] initWithFrame:frame];
        _commodityView.dataSource = self;
        _commodityView.delegate = self;
    }
    
    return _commodityView;
}

#pragma mark - Action
- (void)tapAction:(UIGestureRecognizer *)gestureRecognizer {
    [self dismissViewControllerAnimated:YES completion:^{}];
}

#pragma mark - Delegate
#pragma mark UIGestureRecognizerDelegate
-(BOOL) gestureRecognizer:(UIGestureRecognizer*)gestureRecognizer shouldReceiveTouch:(UITouch*)touch {
    return touch.view == self.view; // 设置商品列表View（PLVECCommodityView）不响应手势
}

#pragma mark UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.commodityModelsManager.models.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *reuseIdentifier = @"reuseIdentifier";
    PLVECCommodityCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
    if (!cell) {
        cell = [[PLVECCommodityCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
        cell.delegate = self;
    }
    cell.model = self.commodityModelsManager.models[indexPath.section];
    
    return cell;
}

#pragma mark UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 88.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 20.0;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    UIView *view = [[UIView alloc] init];
    view.backgroundColor = [UIColor clearColor];
    return view;
}

#pragma mark UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    // 商品列表滑动到底部加载更多
    CGFloat bottomOffset = scrollView.contentSize.height - scrollView.contentOffset.y;
    if (bottomOffset < CGRectGetHeight(scrollView.bounds) + 1
        && self.commodityModelsManager.totalItems != self.commodityModelsManager.models.count) { // tolerance
        [self.commodityView startLoading];
        
        __weak typeof(self) weakSelf = self;
        [self.commodityModelsManager loadMoreCommodityInfoWithCompletion:^(NSError * _Nonnull error) {
            [weakSelf.commodityView stopLoading];
            if (error) {
                NSLog(@"scrollViewDidScroll-loadMoreCommodityInfoWithCompletion 请求失败：%@", error.localizedDescription);
                return;
            }
            
            [weakSelf.commodityView reloadData:weakSelf.commodityModelsManager.totalItems];
        }];
    }
}

#pragma mark PLVECCommodityCellDelegate
- (void)didSelectWithCommodityCell:(PLVECCommodityCell *)commodityCell {
    NSURL *jumpLinkUrl = commodityCell.jumpLinkUrl;
    if (! jumpLinkUrl) {
        return;
    }
    
    NSLog(@"商品跳转：%@",jumpLinkUrl);
    [self dismissViewControllerAnimated:NO completion:^{}];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(jumpToGoodsDetail:)]) {
        [self.delegate jumpToGoodsDetail:jumpLinkUrl];
    } else {
        if (![UIApplication.sharedApplication openURL:jumpLinkUrl]) {
            NSLog(@"url: %@",jumpLinkUrl);
        }
    }
    
}

@end
