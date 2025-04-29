//
//  PLVVirtualBackgroudSheet.m
//  PolyvLiveScenesDemo
//
//  Created by polyv on 2025/4/10.
//  Copyright © 2025 PLV. All rights reserved.
//

#import "PLVVirtualBackgroudSheet.h"
#import "PLVVirtualBackgroudCollectionView.h"
#import "PLVImagePickerViewController.h"
#import "PLVVirtualBackgroundUtil.h"

const NSInteger kMaxCustomImageItem = 3;

@interface PLVVirtualBackgroudSheet () <PLVVirtualBackgroudCollectionViewDelegate>

@property (nonatomic, strong) PLVVirtualBackgroudCollectionView *collectionView;
@property (nonatomic, strong) UILabel *titleLable;

@end

@implementation PLVVirtualBackgroudSheet

- (instancetype)initWithSheetHeight:(CGFloat)sheetHeight sheetLandscapeWidth:(CGFloat)sheetLandscapeWidth{
    self = [super initWithSheetHeight:sheetHeight sheetLandscapeWidth:sheetLandscapeWidth];
    if (self){
        [self initUI];
    }
    
    return self;
}

- (void)initUI{
    [self.contentView addSubview:self.titleLable];
    [self.contentView addSubview:self.collectionView];
}

- (void)layoutSubviews{
    [super layoutSubviews];
    
    self.titleLable.frame = CGRectMake(32, 32, 200, 18);
    NSInteger start_x = 32;
    NSInteger start_y = CGRectGetMaxY(self.titleLable.frame) + 20;
    NSInteger height = self.contentView.bounds.size.height - start_y - 34;
    NSInteger width = self.contentView.bounds.size.width - 2*start_x ;
    self.collectionView.frame = CGRectMake(start_x, start_y, width, height);
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

- (void)showImagePicker {
    if (self.collectionView.customImgCoutn >= kMaxCustomImageItem){
        return;;
    }
    PLVImagePickerViewController *imagePickerVC = [[PLVImagePickerViewController alloc] initWithColumnNumber:4];
    imagePickerVC.allowPickingOriginalPhoto = YES;
    imagePickerVC.allowPickingVideo = NO;
    imagePickerVC.allowTakePicture = NO;
    imagePickerVC.allowTakeVideo = NO;
    imagePickerVC.maxImagesCount = 1;
    __weak typeof(self) weakSelf = self;
    
    // 最多添加3张照片
    [imagePickerVC setDidFinishPickingPhotosHandle:^(NSArray<UIImage *> *photos, NSArray *assets, BOOL isSelectOriginalPhoto) {
        //实现图片选择回调
        if (photos.count > 0) {
            [weakSelf.collectionView addUploadedImage:photos.firstObject];
        }
    }];
     
    [imagePickerVC setImagePickerControllerDidCancelHandle:^{
        //实现图片选择取消回调
    }];
    [[self viewController] presentViewController:imagePickerVC animated:YES completion:nil];
}

#pragma mark - PLVVirtualBackgroudCollectionViewDelegate

- (void)virtualBackgroudCollectionView:(PLVVirtualBackgroudCollectionView *)collectionView data:(nonnull PLVVirtualBackgroudModel *)model {
    // 处理选择虚拟背景的逻辑
    // 根据选中的类型和索引进行相应操作
    if (model.type == PLVVirtualBackgroudCellDefault){
        // 不抠像
        if (self.delegate && [self.delegate respondsToSelector:@selector(virtualBackgroudSheet:matType:image:)]){
            [self.delegate virtualBackgroudSheet:self matType:PLVVirtualBackgroudMatTypeNone image:nil];
        }
    }
    else if (model.type == PLVVirtualBackgroudCellBlur){
        // 抠像 背景模糊
        if (self.delegate && [self.delegate respondsToSelector:@selector(virtualBackgroudSheet:matType:image:)]){
            [self.delegate virtualBackgroudSheet:self matType:PLVVirtualBackgroudMatTypeBlur image:nil];
        }
    }
    else{
        // 抠像 填充背景
        if (self.delegate && [self.delegate respondsToSelector:@selector(virtualBackgroudSheet:matType:image:)]){
            UIImage *image = nil;
            if (model.type == PLVVirtualBackgroudCellCustomPicture){
                image = model.image;
            }
            else if (model.type == PLVVirtualBackgroudCellInnerPicture){
                NSString *imageSource = model.imageSourceName;
                BOOL isFullscreen = [UIScreen mainScreen].bounds.size.width > [UIScreen mainScreen].bounds.size.height;
                if (isFullscreen)
                    imageSource = model.landscapeImageSourceName;
                image =  [PLVVirtualBackgroundUtil imageForResource:imageSource];;
            }
            
            [self.delegate virtualBackgroudSheet:self matType:PLVVirtualBackgroudMatTypeCustomImage image:image];
        }
    }
}

- (void)virtualBackgroudCollectionViewDidClickUploadButton:(PLVVirtualBackgroudCollectionView *)collectionView {
    // 处理上传按钮点击的逻辑
    [self showImagePicker];
}

#pragma mark -- getter
- (PLVVirtualBackgroudCollectionView *)collectionView{
    if (!_collectionView){
        _collectionView = [[PLVVirtualBackgroudCollectionView alloc] init];
        _collectionView.delegate = self; // 设置代理
    }
    return _collectionView;
}

- (UILabel *)titleLable{
    if (!_titleLable){
        _titleLable = [[UILabel alloc] init];
        _titleLable.text = @"虚拟背景";
        _titleLable.font = [UIFont systemFontOfSize:18];
        _titleLable.textColor = [UIColor whiteColor];
        
    }
    return _titleLable;
}

@end
