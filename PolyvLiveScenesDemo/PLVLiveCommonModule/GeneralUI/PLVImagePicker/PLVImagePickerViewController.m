//
//  PLVImagePickerViewController.m
//  PolyvLiveScenesDemo
//
//  Created by Duhan on 2022/4/6.
//  Copyright © 2022 PLV. All rights reserved.
//

#import "PLVImagePickerViewController.h"
#import <PLVFoundationSDK/PLVFoundationSDK.h>

#pragma mark PLVImagePickerController 分类
@interface PLVImagePickerController (PLVCommonOverwrite)
@end

@implementation PLVImagePickerController (PLVCommonOverwrite)

- (void)setColumnNumber:(NSInteger)columnNumber {
    if (columnNumber <= 2) {
        columnNumber = 2;
    } else if (columnNumber >= 8) {
        columnNumber = 8;
    }

    [self setValue:@(columnNumber) forKey:@"_columnNumber"];
    
    PLVAlbumPickerController *albumPickerVc = [self.childViewControllers firstObject];
    albumPickerVc.columnNumber = columnNumber;
    [PLVImageManager manager].columnNumber = columnNumber;
}

@end

#pragma mark PLVImagePickerViewController
@interface PLVImagePickerViewController ()

@end

@implementation PLVImagePickerViewController

#pragma mark - Public Method

- (instancetype)initWithColumnNumber:(NSInteger)columnNumber{
    self = [super initWithMaxImagesCount:1 columnNumber:columnNumber delegate:nil];
    if (self) {
        [self setupUI];
    }
    return self;
}

#pragma mark - Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
}

#pragma mark - Private

- (void)setupUI{
    self.view.backgroundColor = [PLVColorUtil colorFromHexString:@"#1A1B1F"];
    self.showSelectBtn = YES;
    self.allowTakeVideo = NO;
    self.allowPickingVideo = NO;
    self.allowTakePicture = NO;
    self.allowPickingOriginalPhoto = NO;
    self.showPhotoCannotSelectLayer = YES;
    self.cannotSelectLayerColor = [UIColor colorWithWhite:1.0 alpha:0.6];
            
    self.iconThemeColor = [PLVColorUtil colorFromHexString:@"#366BEE"];
    self.oKButtonTitleColorNormal = UIColor.whiteColor;
    self.naviTitleColor = [UIColor colorWithWhite:0.6 alpha:1];
    self.naviTitleFont = [UIFont systemFontOfSize:14.0];
    self.barItemTextColor = [PLVColorUtil colorFromHexString:@"#366BEE"];
    self.barItemTextFont = [UIFont systemFontOfSize:14.0];
    self.naviBgColor = [PLVColorUtil colorFromHexString:@"#1A1B1F"];
   
    [self setPhotoPickerPageUIConfigBlock:^(UICollectionView *collectionView, UIView *bottomToolBar, UIButton *previewButton, UIButton *originalPhotoButton, UILabel *originalPhotoLabel, UIButton *doneButton, UIImageView *numberImageView, UILabel *numberLabel, UIView *divideLine) {
        divideLine.hidden = YES;
        collectionView.showsHorizontalScrollIndicator = NO;
        collectionView.backgroundColor = [PLVColorUtil colorFromHexString:@"#1A1B1F"];
        bottomToolBar.backgroundColor = [PLVColorUtil colorFromHexString:@"#1A1B1F"];
        bottomToolBar.layer.shadowColor = [UIColor colorWithRed:10/255.0 green:10/255.0 blue:17/255.0 alpha:1.0].CGColor;
        bottomToolBar.layer.shadowOffset = CGSizeMake(0,-1);
        bottomToolBar.layer.shadowOpacity = 1;
        bottomToolBar.layer.shadowRadius = 0;
        
        UIResponder *nextResponder = [collectionView nextResponder];
        if ([nextResponder isKindOfClass:UIView.class]) {
            [(UIView *)nextResponder setBackgroundColor:[PLVColorUtil colorFromHexString:@"#1A1B1F"]];
        }
    }];
    
    [self setPhotoPickerPageDidLayoutSubviewsBlock:^(UICollectionView *collectionView, UIView *bottomToolBar, UIButton *previewButton, UIButton *originalPhotoButton, UILabel *originalPhotoLabel, UIButton *doneButton, UIImageView *numberImageView, UILabel *numberLabel, UIView *divideLine) {
        previewButton.hidden = YES;
        doneButton.layer.cornerRadius = 14.0;
        doneButton.backgroundColor = [PLVColorUtil colorFromHexString:@"#366BEE"];
        doneButton.frame = CGRectMake(CGRectGetMinX(doneButton.frame)-74.0/2, (CGRectGetHeight(doneButton.bounds)-28.0)/2, 74.0, 28.0);
    }];
    
    [self setPhotoPickerPageDidRefreshStateBlock:^(UICollectionView *collectionView, UIView *bottomToolBar, UIButton *previewButton, UIButton *originalPhotoButton, UILabel *originalPhotoLabel, UIButton *doneButton, UIImageView *numberImageView, UILabel *numberLabel, UIView *divideLine) {
        numberLabel.hidden = YES;
        numberImageView.hidden = YES;
           }];
    
    [self setAlbumCellDidLayoutSubviewsBlock:^(PLVAlbumCell *cell, UIImageView *posterImageView, UILabel *titleLabel) {
        titleLabel.textColor = UIColor.lightGrayColor;
        [(UITableViewCell *)cell setBackgroundColor:UIColor.clearColor];
        [(UITableViewCell *)cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        UIResponder *nextResponder = [(UITableViewCell *)cell nextResponder];
        if ([nextResponder isKindOfClass:UIView.class]) {
            [(UIView *)nextResponder setBackgroundColor:[PLVColorUtil colorFromHexString:@"#1A1B1F"]];
        }
        nextResponder = nextResponder.nextResponder;
        if ([nextResponder isKindOfClass:UIView.class]) {
            [(UIView *)nextResponder setBackgroundColor:[PLVColorUtil colorFromHexString:@"#1A1B1F"]];
        }
    }];
}

@end
