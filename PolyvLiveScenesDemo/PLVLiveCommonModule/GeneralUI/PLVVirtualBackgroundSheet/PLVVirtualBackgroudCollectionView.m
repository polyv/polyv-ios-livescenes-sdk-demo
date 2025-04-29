//
//  PLVVirtualBackgroudCollectionView.m
//  PolyvLiveScenesDemo
//
//  Created by polyv on 2025/4/10.
//  Copyright © 2025 PLV. All rights reserved.
//

#import "PLVVirtualBackgroudCollectionView.h"
#import "PLVVirtualBackgroudCell.h"
#import "PLVVirtualBackgroundUtil.h"
#import "PLVMultiLanguageManager.h"
#import "PLVAlertViewController.h"

static NSString * const kPLVVirtualBackgroudCellID = @"PLVVirtualBackgroudCell";
static CGFloat const kPLVVirtualBackgroudCellPadding = 5.0;

@interface PLVVirtualBackgroudCollectionView () <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, PLVVirtualBackgroudCellDelegate>

@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) NSMutableArray<PLVVirtualBackgroudModel *> *dataArray;  // 无、上传、背景模糊、本地图片操作项
@property (nonatomic, strong) NSMutableArray<PLVVirtualBackgroudModel *> *presetData; // 内置素材

@property (nonatomic, strong) NSIndexPath *selIndex;

@end

@implementation PLVVirtualBackgroudCollectionView

#pragma mark - [ Life Cycle ]

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.selIndex = [NSIndexPath indexPathForRow:0 inSection:0];
        
        [self setupDefaultData];
        [self initPresetData];

        [self addSubview:self.collectionView];
        
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    // 更新collectionView布局
    self.collectionView.frame = self.bounds;
}

#pragma mark - [ Public Method ]

- (void)setupWithBackgroundImages:(NSArray<UIImage *> *)images {
    [self.dataArray removeAllObjects];
    
    // 默认最前面的项目为固定项
    [self setupDefaultData];
    
    // 添加内置图片
    for (UIImage *image in images) {
        PLVVirtualBackgroudModel *model = [[PLVVirtualBackgroudModel alloc] init];
        model.image = image;
        model.type = PLVVirtualBackgroudCellInnerPicture;
        model.title = PLVLocalizedString(@"虚拟背景");
        [self.dataArray addObject:model];
    }
    
    [self.collectionView reloadData];
}

- (void)addUploadedImage:(UIImage *)image {
    if (image) {
        PLVVirtualBackgroudModel *model = [[PLVVirtualBackgroudModel alloc] init];
        model.image = image;
        model.type = PLVVirtualBackgroudCellCustomPicture;
        model.title = PLVLocalizedString(@"本地图片");

        [self.dataArray addObject:model];
        
        [self.collectionView reloadData];
        
//        // 自动滚动到新添加的项
//        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:self.dataArray.count - 1 inSection:0];
//        [self.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
    }
}

-(NSInteger)customImgCoutn{
    NSInteger cusCount = self.dataArray.count - 3;
    return cusCount;
}

#pragma mark - [ Private Method ]

- (void)setupDefaultData {
    [self.dataArray removeAllObjects];
    
    // 添加无背景选项
    PLVVirtualBackgroudModel *noneModel = [[PLVVirtualBackgroudModel alloc] init];
    noneModel.image = [PLVVirtualBackgroundUtil imageForResource:@"plv_virtualbg_none"];
    noneModel.type = PLVVirtualBackgroudCellDefault;
    noneModel.title = PLVLocalizedString(@"无");
    [self.dataArray addObject:noneModel];
    
    // 添加上传按钮
    PLVVirtualBackgroudModel *uploadModel = [[PLVVirtualBackgroudModel alloc] init];
    uploadModel.image = [PLVVirtualBackgroundUtil imageForResource:@"plv_virtualbg_upload"];
    uploadModel.type = PLVVirtualBackgroudCellUpload;
    uploadModel.title = PLVLocalizedString(@"自定义");
    [self.dataArray addObject:uploadModel];
    
    // 添加模糊背景
    PLVVirtualBackgroudModel *blurModel = [[PLVVirtualBackgroudModel alloc] init];
    blurModel.image = [PLVVirtualBackgroundUtil imageForResource:@"plv_virtualbg_blur"];
    blurModel.type = PLVVirtualBackgroudCellBlur;
    blurModel.title = PLVLocalizedString(@"背景模糊");
    [self.dataArray addObject:blurModel];
}

- (void)initPresetData{
    
    [self.presetData removeAllObjects];
    NSArray *presetImages = @[@"plv_virtualbg_0",
                              @"plv_virtualbg_1",
                              @"plv_virtualbg_2",
                              @"plv_virtualbg_3",
                              @"plv_virtualbg_4",
                              @"plv_virtualbg_5",
                              @"plv_virtualbg_6",
                              @"plv_virtualbg_7",
                              @"plv_virtualbg_8",
                              @"plv_virtualbg_9"];
    NSArray *presetOrigImages = @[@"plv_virtualbg_orig_0",
                              @"plv_virtualbg_orig_1",
                              @"plv_virtualbg_orig_2",
                              @"plv_virtualbg_orig_3",
                              @"plv_virtualbg_orig_4",
                              @"plv_virtualbg_orig_5",
                              @"plv_virtualbg_orig_6",
                              @"plv_virtualbg_orig_7",
                              @"plv_virtualbg_orig_8",
                              @"plv_virtualbg_orig_9"];
    NSArray *presetOrigLandscapeImages = @[@"plv_virtualbg_orig_0_landscape",
                              @"plv_virtualbg_orig_1_landscape",
                              @"plv_virtualbg_orig_2_landscape",
                              @"plv_virtualbg_orig_3_landscape",
                              @"plv_virtualbg_orig_4_landscape",
                              @"plv_virtualbg_orig_5_landscape",
                              @"plv_virtualbg_orig_6_landscape",
                              @"plv_virtualbg_orig_7_landscape",
                              @"plv_virtualbg_orig_8_landscape",
                              @"plv_virtualbg_orig_9_landscape"];
    
    for (NSInteger i=0; i< presetImages.count; i++){
        PLVVirtualBackgroudModel *model = [[PLVVirtualBackgroudModel alloc] init];
        NSString *imageName = presetImages[i];
        NSString *imageSourceName = presetOrigImages[i];
        model.image = [PLVVirtualBackgroundUtil imageForResource:imageName];
        model.type = PLVVirtualBackgroudCellInnerPicture;
        model.imageSourceName = imageSourceName;
        model.landscapeImageSourceName = presetOrigLandscapeImages[i];
        
        [self.presetData addObject:model];
    }
}

#pragma mark - [ UICollectionViewDataSource ]

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    return 2;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (0 == section){
        return self.dataArray.count;
    }
    else if (1 ==section){
        return self.presetData.count;
    }
    return 0;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    PLVVirtualBackgroudCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kPLVVirtualBackgroudCellID forIndexPath:indexPath];
    
    if (0 == indexPath.section){
        if (indexPath.item < self.dataArray.count) {
            PLVVirtualBackgroudModel *model = self.dataArray[indexPath.item];
            [cell configCellWithModel:model];
            cell.delegate = self;
            
            // 设置选中状态
            BOOL isSeleted = (indexPath.row == self.selIndex.row) && (indexPath.section == self.selIndex.section);
            [cell setSelected:isSeleted animated:NO];
        }
    }
    else if (1 == indexPath.section){
        if (indexPath.item < self.presetData.count) {
            PLVVirtualBackgroudModel *model = self.presetData[indexPath.item];
            [cell configCellWithModel:model];
            cell.delegate = self;
            
            // 设置选中状态
            BOOL isSeleted = (indexPath.row == self.selIndex.row) && (indexPath.section == self.selIndex.section);
            [cell setSelected:isSeleted animated:NO];
        }
    }
    
    return cell;
}


#pragma mark - [ UICollectionViewDelegate ]

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    // 重置选中状态
    PLVVirtualBackgroudCell *oldCell = (PLVVirtualBackgroudCell *)[collectionView cellForItemAtIndexPath: self.selIndex];
    [oldCell setSelected:NO animated:YES];
    
    PLVVirtualBackgroudCell *newCell = (PLVVirtualBackgroudCell *)[collectionView cellForItemAtIndexPath:indexPath];
    [newCell setSelected:YES animated:YES];
        
    if (0 == indexPath.section){
        if (indexPath.row < self.dataArray.count) {
            PLVVirtualBackgroudModel *model = self.dataArray[indexPath.row];
            
            // 如果点击的是上传按钮，则触发上传回调
            if (model.type == PLVVirtualBackgroudCellUpload) {
                if (self.delegate && [self.delegate respondsToSelector:@selector(virtualBackgroudCollectionViewDidClickUploadButton:)]) {
                    [self.delegate virtualBackgroudCollectionViewDidClickUploadButton:self];
                }
                return;
            }
            
            if (self.delegate && [self.delegate respondsToSelector:@selector(virtualBackgroudCollectionView:data:)]){
                [self.delegate virtualBackgroudCollectionView:self data:model];
            }
        }
    }
    else if (1 == indexPath.section){
        if (indexPath.row < self.presetData.count) {
            PLVVirtualBackgroudModel *model = self.presetData[indexPath.row];
            
            // 触发回调通知代理
            if (self.delegate && [self.delegate respondsToSelector:@selector(virtualBackgroudCollectionView:data:)]){
                [self.delegate virtualBackgroudCollectionView:self data:model];
            }
        }
    }
    
    self.selIndex = indexPath;
}

#pragma mark - [ UICollectionViewDelegateFlowLayout ]

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    // 计算cell尺寸，根据屏幕宽度动态调整
    CGFloat cellHeight = 75.0;
    CGFloat cellWidth = 58;
    
    return CGSizeMake(cellWidth, cellHeight);
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(10, 0, 10, 0);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return kPLVVirtualBackgroudCellPadding;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return kPLVVirtualBackgroudCellPadding;
}

#pragma mark - [ PLVVirtualBackgroudCellDelegate ]

- (void)virtualBackgroudCellDidClickDeleteButton:(PLVVirtualBackgroudCell *)cell {
    PLVAlertViewController *alert = [PLVAlertViewController alertControllerWithMessage:PLVLocalizedString(@"确认要删除该背景图片吗？")
                                                                     cancelActionTitle:PLVLocalizedString(@"取消")
                                                                         cancelHandler:^{
                                                                    }
                                                                    confirmActionTitle:PLVLocalizedString(@"确认")
                                                                        confirmHandler:^{
        
        NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
        if (indexPath) {
            // 如果删除的是当前选中的自定义图片
            if ((indexPath.row == self.selIndex.row) && (indexPath.section == self.selIndex.section)){
                // 回调选中None cell
                [self.dataArray removeObjectAtIndex:indexPath.row];
                self.selIndex = [NSIndexPath indexPathForRow:0 inSection:0];
                PLVVirtualBackgroudModel *model = [self.dataArray firstObject];
                if (self.delegate && [self.delegate respondsToSelector:@selector(virtualBackgroudCollectionView:data:)]){
                    [self.delegate virtualBackgroudCollectionView:self data:model];
                }
                [self.collectionView reloadData];
            }
            else{
                // 刷新列表
                [self.dataArray removeObjectAtIndex:indexPath.row];
                [self.collectionView reloadData];
            }
        }
    }];
   
    [[self viewController] presentViewController:alert animated:NO completion:nil];
}

#pragma mark -- Private
- (UIViewController *)viewController{
    UIViewController *vc = nil;
    
    UIResponder *responder = self;
    while (responder) {
        if ([responder isKindOfClass:[UIViewController class]]) {
            vc = (UIViewController *)responder;
            break;
        }
        responder = [responder nextResponder];
    }
    
    return vc;
}

#pragma mark - [ Getter ]

- (UICollectionView *)collectionView {
    if (!_collectionView) {
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        layout.scrollDirection = UICollectionViewScrollDirectionVertical;
        
        _collectionView = [[UICollectionView alloc] initWithFrame:self.bounds collectionViewLayout:layout];
        _collectionView.backgroundColor = [UIColor clearColor];
        _collectionView.showsHorizontalScrollIndicator = NO;
        _collectionView.showsVerticalScrollIndicator = NO;
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
        
        // 注册cell
        [_collectionView registerClass:[PLVVirtualBackgroudCell class] forCellWithReuseIdentifier:kPLVVirtualBackgroudCellID];
    }
    return _collectionView;
}

- (NSMutableArray<PLVVirtualBackgroudModel *> *)dataArray {
    if (!_dataArray) {
        _dataArray = [NSMutableArray array];
    }
    return _dataArray;
}

- (NSMutableArray<PLVVirtualBackgroudModel *> *)presetData{
    if (!_presetData){
        _presetData = [[NSMutableArray alloc] init];
    }
    return _presetData;
}

@end
