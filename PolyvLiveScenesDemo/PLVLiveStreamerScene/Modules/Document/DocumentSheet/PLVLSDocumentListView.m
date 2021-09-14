//
//  PLVLSDocumentListView.m
//  PLVLiveStreamerDemo
//
//  Created by Hank on 2021/3/8.
//  Copyright © 2021 PLV. All rights reserved.
//  文档列表

#import "PLVLSDocumentListView.h"

/// 工具
#import "PLVLSUtils.h"

/// UI
#import "PLVLSDocumentListUploadCell.h"
#import "PLVLSDocumentListCell.h"
#import "PLVLSDocumentDeleteView.h"

/// 数据
#import "PLVLSDocumentListViewModel.h"

/// 模块
#import "PLVRoomDataManager.h"
#import "PLVDocumentConvertManager.h"

/// 依赖库
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>
#import <PLVFoundationSDK/PLVFoundationSDK.h>
#import <MJRefresh/MJRefresh.h>

static NSString *DocListAddCellIdentifier = @"DocumentListAddCellIdentifier";

@interface PLVLSDocumentListView ()<
UICollectionViewDataSource,
UICollectionViewDelegate,
PLVLSDocumentDeleteViewProtocol,
PLVSDocumentListProtocol
>

/// UI
@property (nonatomic, strong) UILabel *lbTitle;                                 // 标题
@property (nonatomic, strong) UILabel *lbCount;                                 // 文档数量
@property (nonatomic, strong) UIView *viewLine;                                 // 分割线
@property (nonatomic, strong) UICollectionView *collectionView;                 // 文档列表
@property (nonatomic, strong) PLVLSDocumentDeleteView *deleteView;              // 删除文档视图
@property (nonatomic, strong) UIButton *refreshButton;                              // 文档刷新

/// 数据
@property (nonatomic, assign) CGSize cellSize;                                  // 列表Item宽度
@property (nonatomic, assign) NSInteger selectAutoId;                           // 选择的文档autoId;
@property (nonatomic, strong) PLVLSDocumentListViewModel *viewModel;

@end

@implementation PLVLSDocumentListView

#pragma mark - [ Life Period ]

- (instancetype)init {
    if (self = [super init]) {
        [self addSubview:self.lbTitle];
        [self addSubview:self.lbCount];
        [self addSubview:self.viewLine];
        [self addSubview:self.collectionView];
        [self addSubview:self.refreshButton];
        
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGSize selfSize = self.bounds.size;
    CGFloat margin = 28;
    
    self.lbTitle.frame = CGRectMake(margin, 0, 68, 22);
    self.lbCount.frame = CGRectMake(CGRectGetMaxX(self.lbTitle.frame) + 8, 0, 100, 22);
    self.refreshButton.frame = CGRectMake(selfSize.width - 64 - 68, 0, 68, 20);
    self.viewLine.frame = CGRectMake(margin, 30, selfSize.width - 2 * margin, 1);
    self.collectionView.frame = CGRectMake(0, 39, selfSize.width, selfSize.height - 39);
    
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *touchView = [super hitTest:point withEvent:event];
    if (touchView.superview != self.deleteView) {
        [self dismissDeleteView];
    }
    return touchView;
}

#pragma mark - [ Getter ]

- (UILabel *)lbTitle {
    if (! _lbTitle) {
        _lbTitle = [[UILabel alloc] init];
        _lbTitle.font = [UIFont boldSystemFontOfSize:16];
        _lbTitle.textColor = PLV_UIColorFromRGB(@"#F0F1F5");
        _lbTitle.text = @"所有文档";
    }
    
    return _lbTitle;
}

- (UILabel *)lbCount {
    if (! _lbCount) {
        _lbCount = [[UILabel alloc] init];
        _lbCount.font = [UIFont boldSystemFontOfSize:12];
        _lbCount.textColor = PLV_UIColorFromRGB(@"#CFD1D6");
        _lbCount.textAlignment = NSTextAlignmentLeft;
    }
    
    return _lbCount;
}

- (UIView *)viewLine {
    if (! _viewLine) {
        _viewLine = [[UIView alloc] init];
        _viewLine.backgroundColor = PLV_UIColorFromRGBA(@"#F0F1F5", 0.1);
    }
    
    return _viewLine;
}

- (UICollectionView *)collectionView {
    if (! _collectionView) {
        UICollectionViewFlowLayout *cvfLayout = [[UICollectionViewFlowLayout alloc] init];
        cvfLayout.minimumLineSpacing = 28;
        cvfLayout.minimumInteritemSpacing = 28;
        
        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:cvfLayout];
        _collectionView.backgroundColor = [UIColor clearColor];
        _collectionView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
        _collectionView.dataSource = self;
        _collectionView.delegate = self;
        _collectionView.contentInset = UIEdgeInsetsMake(8, 28, PLVLSUtils.safeBottomPad, 28);
        [_collectionView registerClass:PLVLSDocumentListUploadCell.class forCellWithReuseIdentifier:DocListAddCellIdentifier];
        
        __weak typeof(self) weakSelf = self;
        MJRefreshNormalHeader *mjHeader = [MJRefreshNormalHeader headerWithRefreshingBlock:^{
            [weakSelf.viewModel loadData];
        }];
        mjHeader.lastUpdatedTimeLabel.hidden = YES;
        mjHeader.stateLabel.hidden = YES;
        [mjHeader.loadingView setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleWhite];
        
        _collectionView.mj_header = mjHeader;
    }
    
    return _collectionView;
}

- (UIButton *)refreshButton {
    if (!_refreshButton) {
        _refreshButton = [UIButton buttonWithType:UIButtonTypeCustom];
        UIImage *normalImage = [PLVLSUtils imageForDocumentResource:@"plvls_doc_btn_refresh"];
        [_refreshButton setImage:normalImage forState:UIControlStateNormal];
        [_refreshButton setTitle:@"刷新" forState:UIControlStateNormal];
        _refreshButton.titleLabel.font = [UIFont systemFontOfSize:14];
        [_refreshButton setTitleColor:[PLVColorUtil colorFromHexString:@"#4399FF"] forState:UIControlStateNormal];
        [_refreshButton addTarget:self action:@selector(refreshAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _refreshButton;
}

- (CGSize)cellSize {
    if (_cellSize.width == 0) {
        CGSize defaultImgSize = CGSizeMake(144, 80);
        CGFloat collectionViewWidth = self.collectionView.bounds.size.width;
        
        UICollectionViewFlowLayout *cvfLayout = (UICollectionViewFlowLayout *)self.collectionView.collectionViewLayout;
        
        CGFloat itemWidth = (collectionViewWidth - self.collectionView.contentInset.left - self.collectionView.contentInset.right - cvfLayout.minimumInteritemSpacing * 3) / 4;
        
        _cellSize = CGSizeMake(itemWidth, itemWidth * defaultImgSize.height / defaultImgSize.width + 28);
    }
    
    return _cellSize;
}

- (PLVLSDocumentListViewModel *)viewModel {
    if (!_viewModel) {
        _viewModel = [[PLVLSDocumentListViewModel alloc] init];
        _viewModel.viewProxy = self;
    }
    return _viewModel;
}

#pragma mark - [ Public Methods ]
#pragma mark Cell Loading

- (void)startSelectCellLoading {
    PLVLSDocumentListCell *cell = [self getSelectCell];
    [cell startLoading];
}

- (void)stopSelectCellLoading {
    PLVLSDocumentListCell *cell = [self getSelectCell];
    [cell stopLoading];
}

- (PLVLSDocumentListCell *)getSelectCell {
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:self.viewModel.selectedIndex inSection:0];
    PLVLSDocumentListCell *cell = (PLVLSDocumentListCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
    return cell;
}

#pragma mark - [ Action ]

- (void)uploadDocAction:(UIButton *)button {
    if (self.delegate && [self.delegate respondsToSelector:@selector(documentListViewUploadDocument:)]) {
        [self.delegate documentListViewUploadDocument:self];
    }
}

- (void)tipDocAction:(UIButton *)button {
    if (self.delegate && [self.delegate respondsToSelector:@selector(documentListViewShowTip:)]) {
        [self.delegate documentListViewShowTip:self];
    }
}

- (void)refreshAction:(UIButton *)button {
    [self.collectionView.mj_header beginRefreshing];
}

#pragma mark - PLVSDocumentList Protocol

- (void)documentListViewModel_finishLoading:(BOOL)success error:(NSError * _Nullable)error {
    [self.collectionView.mj_header endRefreshing];
    
    if (!success) {
        NSString *tips = @"请求文档列表失败，请稍候重试";
        if (error) {
            tips = [tips stringByAppendingFormat:@" #%zd", error.code];
        }
        [PLVLSUtils showToastInHomeVCWithMessage:tips];
    }
}

- (void)documentListViewModel_deleteDataFail:(NSError *)error {
    NSString *tips = @"删除文档失败，请稍候重试";
    if (error) {
        tips = [tips stringByAppendingFormat:@" #%zd", error.code];
    }
    [PLVLSUtils showToastInHomeVCWithMessage:tips];
}

- (void)documentListViewModel_dataUpdate {
    self.lbCount.text = [NSString stringWithFormat:@"共%ld个", [self.viewModel dataCount]];
    [self.collectionView reloadData];
    
    NSIndexPath *selectIndexPath = [NSIndexPath indexPathForItem:self.viewModel.selectedIndex inSection:0];
    [self.collectionView selectItemAtIndexPath:selectIndexPath
                                      animated:NO
                                scrollPosition:UICollectionViewScrollPositionNone];
}

#pragma mark - UICollectionView DataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self.viewModel dataCount] + 1;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.item == 0) {
        PLVLSDocumentListUploadCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:DocListAddCellIdentifier forIndexPath:indexPath];
        [cell uploadTarget:self action:@selector(uploadDocAction:)];
        [cell tipTarget:self action:@selector(tipDocAction:)];
        return cell;
        
    } else {
        NSString *identifier = nil;
        id model = [self.viewModel documetModelAtIndex:indexPath.item];
        if ([model isKindOfClass:[PLVDocumentUploadModel class]]) {
            PLVDocumentUploadModel *uploadModel = (PLVDocumentUploadModel *)model;
            identifier = uploadModel.fileId;
        } else {
            PLVDocumentModel *uploadedModel = (PLVDocumentModel *)model;
            identifier = uploadedModel.fileId;
        }
        
        [self.collectionView registerClass:[PLVLSDocumentListCell class] forCellWithReuseIdentifier:identifier];
        PLVLSDocumentListCell *cell = (PLVLSDocumentListCell *)[collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:indexPath];
        if ([model isKindOfClass:[PLVDocumentUploadModel class]]) {
            PLVDocumentUploadModel *uploadModel = (PLVDocumentUploadModel *)model;
            [cell setUploadModel:uploadModel];
        } else {
            PLVDocumentModel *uploadedModel = (PLVDocumentModel *)model;
            [cell setDocumentModel:uploadedModel];
        }
        cell.tag = indexPath.item;
        
        __weak typeof(self) weakSelf = self;
        cell.longPressHandler = ^(NSInteger tag) {
            PLVLSDocumentListCell *cell = (PLVLSDocumentListCell *)[collectionView cellForItemAtIndexPath:indexPath];
            CGPoint cellPoint =cell.frame.origin;
            cellPoint.x += cell.frame.size.width / 2.0;
            CGPoint point = [collectionView convertPoint:cellPoint toView:collectionView];
            point.x += CGRectGetMinX(collectionView.frame) - collectionView.contentOffset.x;
            point.y += CGRectGetMinY(collectionView.frame) - collectionView.contentOffset.y + 7;
            point.y = MAX(point.y, 22.5);
            [weakSelf showDeleteView:point index:tag];
        };
        cell.buttonHandler = ^(NSInteger state) {
            if (state == 1) {
                [[PLVDocumentUploadClient sharedClient] retryUploadWithFileId:identifier];
            } else if (state == 4) {
                NSString *errorMsg = [weakSelf.viewModel errorMsgWithFileId:identifier];
                NSString *message = [NSString stringWithFormat:@"转码失败原因：%@", errorMsg];
                [PLVLSUtils showAlertWithMessage:message cancelActionTitle:@"确定" cancelActionBlock:nil];
            }
        };
        cell.animateLossButtonHandler = ^{
            [PLVDocumentConvertManager removeAnimateLossCacheWithFileId:identifier];
        };
        return cell;
    }
}

#pragma mark - UICollectionView Delegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if ([self.viewModel selectAtIndex:indexPath.item]) {
        id model = [self.viewModel documetModelAtIndex:indexPath.item];
        PLVDocumentModel *docModel = (PLVDocumentModel *)model;
        
        if (self.delegate &&
            [self.delegate respondsToSelector:@selector(documentListView:didSelectItemModel:changeDocument:)] &&
            docModel &&
            [docModel isKindOfClass:[PLVDocumentModel class]]) {
            BOOL isChangeDocument = self.selectAutoId != self.viewModel.selectedAutoId;
            self.selectAutoId = self.viewModel.selectedAutoId;
            [self.delegate documentListView:self didSelectItemModel:docModel changeDocument:isChangeDocument];
        }
    } else {
        [self.collectionView deselectItemAtIndexPath:indexPath animated:YES];
//        [self.collectionView reloadData];
    }
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return self.cellSize;
}

#pragma mark - PLVLSDocumentDeleteView Protocol

- (void)deleteAtIndex:(NSInteger)index {
    [self dismissDeleteView];
    
    if (index == self.viewModel.selectedIndex) {
        [PLVLSUtils showToastInHomeVCWithMessage:@"不能删除展示中的文档"];
        return;
    }
    
    self.viewModel.deletingIndex = index;
    
    __weak typeof(self) weakSelf = self;
    [PLVLSUtils showAlertWithMessage:@"删除文档后将无法恢复，确认删除吗？" cancelActionTitle:@"取消" cancelActionBlock:nil confirmActionTitle:@"删除" confirmActionBlock:^{
        [weakSelf.viewModel deleteDocumentAtDeletingIndex];
    }];
}

#pragma mark DeleteView Related

- (void)showDeleteView:(CGPoint)point index:(NSInteger)index {
    if (! self.deleteView) {
        self.deleteView = [[PLVLSDocumentDeleteView alloc] initWithFrame:CGRectMake(0, 0, 64, 45)];
        self.deleteView.delegate = self;
    }
    
    self.deleteView.center = point;
    self.deleteView.index = index;
    [self.deleteView showInView:self];
}

- (void)dismissDeleteView {
    if (self.deleteView && self.deleteView.superview) {
        [self.deleteView dismiss];
    }
}

- (void)refreshListView{
    [self.collectionView.mj_header beginRefreshing];
}

@end
