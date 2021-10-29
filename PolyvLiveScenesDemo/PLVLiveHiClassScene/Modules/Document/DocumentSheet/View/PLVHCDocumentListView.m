//
//  PLVHCDocumentListView.m
//  PLVLiveScenesDemo
//
//  Created by lijingtong on 2021/6/29.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVHCDocumentListView.h"

/// 工具
#import "PLVHCUtils.h"

/// UI
#import "PLVHCDocumentListUploadCell.h"
#import "PLVHCDocumentListCell.h"
#import "PLVHCDocumentDeleteView.h"

/// 数据
#import "PLVHCDocumentListViewModel.h"

/// 模块
#import "PLVRoomDataManager.h"
#import "PLVDocumentConvertManager.h"

/// 依赖库
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>
#import <PLVFoundationSDK/PLVFoundationSDK.h>
#import <MJRefresh/MJRefresh.h>


static NSString *DocListAddCellIdentifier = @"DocumentListAddCellIdentifier";
static NSString *DocumentListCellIdentifier = @"DocumentListCellIdentifier";


@interface PLVHCDocumentListView ()<
UICollectionViewDataSource,
UICollectionViewDelegate,
PLVHCDocumentDeleteViewDelegate,
PLVHCDocumentListViewModelDelegate
>

#pragma mark UI
@property (nonatomic, strong) UIView *topView;
@property (nonatomic, strong) UILabel *titleLabel; // 标题
@property (nonatomic, strong) UILabel *countLabel; // 文档数量
@property (nonatomic, strong) UICollectionView *collectionView; // 文档列表
@property (nonatomic, strong) PLVHCDocumentDeleteView *deleteView; // 删除文档视图

#pragma mark 数据
@property (nonatomic, assign) CGSize cellSize; // 列表Item宽度
@property (nonatomic, strong) PLVHCDocumentListViewModel *viewModel;

@end

@implementation PLVHCDocumentListView


#pragma mark - [ Life Cycle ]

- (instancetype)init {
    if (self = [super init]) {
        
        [self.topView addSubview:self.titleLabel];
        [self.topView addSubview:self.countLabel];
        
        [self addSubview:self.topView];
        [self addSubview:self.collectionView];
        
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGSize selfSize = self.bounds.size;
    CGFloat margin = 16;
    CGFloat topHeight = 38;
    
    self.topView.frame = CGRectMake(0, 0, selfSize.width, topHeight);
    
    self.titleLabel.frame = CGRectMake(margin, 0, 68, topHeight);
    self.countLabel.frame = CGRectMake(selfSize.width - 100 - margin, 0, 100, topHeight);
    
    self.collectionView.frame = CGRectMake(8, topHeight + 8, selfSize.width - 8 * 2, selfSize.height - topHeight - 8);
    
}

#pragma mark - [ Override ]

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *touchView = [super hitTest:point withEvent:event];
    if (touchView.superview != self.deleteView) {
        [self dismissDeleteView];
    }
    return touchView;
}

#pragma mark - [ Public Method ]

- (void)dismissDeleteView {
    if (self.deleteView &&
        self.deleteView.superview) {
        [self.deleteView dismiss];
    }
}

- (void)refreshListView{
    [self.collectionView.mj_header beginRefreshing];
}

#pragma mark - [ Private Method ]
#pragma mark Getter

- (UIView *)topView {
    if (!_topView) {
        _topView = [[UIView alloc] init];
        _topView.backgroundColor = [PLVColorUtil colorFromHexString:@"#2D3452"];
    }
    return _topView;
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = [UIFont boldSystemFontOfSize:16];
        _titleLabel.textColor = PLV_UIColorFromRGB(@"#F0F1F5");
        _titleLabel.text = @"所有文档";
        _titleLabel.textAlignment = NSTextAlignmentLeft;
    }
    
    return _titleLabel;
}

- (UILabel *)countLabel {
    if (!_countLabel) {
        _countLabel = [[UILabel alloc] init];
        _countLabel.font = [UIFont boldSystemFontOfSize:12];
        _countLabel.textColor = PLV_UIColorFromRGB(@"#CFD1D6");
        _countLabel.textAlignment = NSTextAlignmentRight;
    }
    
    return _countLabel;
}

- (UICollectionView *)collectionView {
    if (!_collectionView) {
        UICollectionViewFlowLayout *cvfLayout = [[UICollectionViewFlowLayout alloc] init];
        cvfLayout.minimumInteritemSpacing = 28;
        cvfLayout.minimumLineSpacing  =28;
        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:cvfLayout];
        _collectionView.backgroundColor = [PLVColorUtil colorFromHexString:@"#22273D"];
        _collectionView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
        _collectionView.dataSource = self;
        _collectionView.delegate = self;
        _collectionView.contentInset = UIEdgeInsetsZero;
        [_collectionView registerClass:PLVHCDocumentListUploadCell.class forCellWithReuseIdentifier:DocListAddCellIdentifier];
        [_collectionView registerClass:PLVHCDocumentListCell.class forCellWithReuseIdentifier:DocumentListCellIdentifier];
        
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

- (CGSize)cellSize {
    if (_cellSize.width == 0) {
        CGSize defaultImgSize = CGSizeMake(144, 80);
        CGFloat collectionViewWidth = self.collectionView.bounds.size.width;
        
        UICollectionViewFlowLayout *cvfLayout = (UICollectionViewFlowLayout *)self.collectionView.collectionViewLayout;
        
        CGFloat itemWidth = (collectionViewWidth - cvfLayout.minimumInteritemSpacing * 3) / 4;
        
        _cellSize = CGSizeMake(itemWidth, itemWidth * defaultImgSize.height / defaultImgSize.width + 28);
    }
    
    return _cellSize;
}

- (PLVHCDocumentListViewModel *)viewModel {
    if (!_viewModel) {
        _viewModel = [[PLVHCDocumentListViewModel alloc] init];
        _viewModel.delegate = self;
    }
    return _viewModel;
}

#pragma mark showDeleteView

- (void)showDeleteView:(CGPoint)point index:(NSInteger)index {
    if (! self.deleteView) {
        self.deleteView = [[PLVHCDocumentDeleteView alloc] initWithFrame:CGRectMake(0, 0, 64, 45)];
        self.deleteView.delegate = self;
    }
    
    self.deleteView.center = point;
    self.deleteView.index = index;
    [self.deleteView showInView:self];
}

#pragma mark - [ Event ]
#pragma mark Action

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

#pragma mark - [ Delegate ]
#pragma mark UICollectionView DataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self.viewModel dataCount] + 1;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.item == 0) {
        PLVHCDocumentListUploadCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:DocListAddCellIdentifier forIndexPath:indexPath];
        [cell uploadTarget:self action:@selector(uploadDocAction:)];
        [cell tipTarget:self action:@selector(tipDocAction:)];
        return cell;
        
    } else {
        
        id model = [self.viewModel documetModelAtIndex:indexPath.item];
        PLVHCDocumentListCell *cell = (PLVHCDocumentListCell *)[collectionView dequeueReusableCellWithReuseIdentifier:DocumentListCellIdentifier forIndexPath:indexPath];
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
            PLVHCDocumentListCell *cell = (PLVHCDocumentListCell *)[collectionView cellForItemAtIndexPath:indexPath];
            CGPoint cellPoint =cell.frame.origin;
            cellPoint.x += cell.frame.size.width / 2.0;
            CGPoint point = [collectionView convertPoint:cellPoint toView:collectionView];
            point.x += CGRectGetMinX(collectionView.frame) - collectionView.contentOffset.x;
            point.y += CGRectGetMinY(collectionView.frame) - collectionView.contentOffset.y + 7;
            point.y = MAX(point.y, 22.5);
            [weakSelf showDeleteView:point index:tag];
        };
        cell.buttonHandler = ^(PLVDocumentUploadStatus state, PLVDocumentUploadModel * _Nonnull uploadModel) {
            if (state == PLVDocumentUploadStatusFailure) {
                [[PLVDocumentUploadClient sharedClient] retryUploadWithModel:uploadModel];
            } else if (state == PLVDocumentUploadStatusConvertFailure) {
                NSString *message = @"暂不支持加密文档，请确保文档已解密 或 转为PDF文件 重试。如无法解决请联系客服。";
                [PLVHCUtils showAlertWithTitle:@"无法解码" message:message cancelActionTitle:@"取消" cancelActionBlock:nil confirmActionTitle:@"重新上传" confirmActionBlock:^{
                   
                    [weakSelf.viewModel deleteDocumentWithIndex:indexPath.item clearConvertFailureFile:NO completion:^{
                        
                        [[PLVDocumentUploadClient sharedClient] retryUploadConvertFailureDocumentWithModel:uploadModel];
                   
                    } failure:^(NSError * _Nonnull error) {}];
                    
                }];
            }
        };
        cell.animateLossButtonHandler = ^(NSString * _Nonnull fileId) {
            [PLVDocumentConvertManager removeAnimateLossCacheWithFileId:fileId];
        };
        return cell;
    }
}

#pragma mark UICollectionView Delegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if ([self.viewModel selectAtIndex:indexPath.item]) {
        id model = [self.viewModel documetModelAtIndex:indexPath.item];
        PLVDocumentModel *docModel = (PLVDocumentModel *)model;
        
        if (self.delegate &&
            [self.delegate respondsToSelector:@selector(documentListView:didSelectItemModel:)] &&
            docModel &&
            [docModel isKindOfClass:[PLVDocumentModel class]]) {
            [self.delegate documentListView:self didSelectItemModel:docModel];
        }
    } else {
        [self.collectionView deselectItemAtIndexPath:indexPath animated:YES];
    }
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return self.cellSize;
}

#pragma mark PLVHCDocumentDeleteViewDelegate

- (void)documentDeleteView:(PLVHCDocumentDeleteView *)documentDeleteView didTapDeleteAtIndex:(NSInteger)index {
    [self dismissDeleteView];
    __weak typeof(self) weakSelf = self;
    [PLVHCUtils showAlertWithTitle:@"删除文档" message:@"删除文档后将无法恢复" cancelActionTitle:@"取消" cancelActionBlock:^{} confirmActionTitle:@"删除" confirmActionBlock:^{
        [weakSelf.viewModel deleteDocumentWithIndex:index clearConvertFailureFile:YES completion:^{
            [PLVHCUtils showToastWithType:PLVHCToastTypeIcon_CoursewareDelete message:@"已删除课件"];
        } failure:^(NSError * _Nonnull error) {}];
    }];
}

#pragma mark PLVHCDocumentListViewModelDelegate

- (void)documentListViewModel:(PLVHCDocumentListViewModel *)documentListViewModel didFinishLoading:(BOOL)success error:(NSError *)error {
    [self.collectionView.mj_header endRefreshing];
    
    if (!success) {
        NSString *tips = @"请求文档列表失败，请稍候重试";
        if (error) {
            tips = [tips stringByAppendingFormat:@" #%zd", error.code];
        }
        [PLVHCUtils showToastInWindowWithMessage:tips];
    }
}

- (void)documentListViewModel:(PLVHCDocumentListViewModel *)documentListViewModel didDeleteDataFail:(NSError *)error {
    NSString *tips = @"删除文档失败，请稍候重试";
    if (error) {
        tips = [tips stringByAppendingFormat:@" #%zd", error.code];
    }
    [PLVHCUtils showToastInWindowWithMessage:tips];
}

- (void)documentListViewModelDataUpdate:(PLVHCDocumentListViewModel *)documentListViewModel {
    self.countLabel.text = [NSString stringWithFormat:@"共%ld个", [self.viewModel dataCount]];
    [self.collectionView reloadData];
}

@end
