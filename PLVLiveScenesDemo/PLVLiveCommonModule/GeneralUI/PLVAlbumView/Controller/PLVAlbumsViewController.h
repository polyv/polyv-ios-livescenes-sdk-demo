//
//  PLVAlbumsViewController.h
//  zPic
//
//  Created by zykhbl on 2017/7/22.
//  Copyright © 2017年 zykhbl. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PLVPicDefine.h"
#import "PLVAlbumInfo.h"

@protocol PLVAlbumsViewControllerDelegate;

@interface PLVAlbumsViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, assign) id<PLVAlbumsViewControllerDelegate> delegate;
@property (nonatomic, assign) PickerModer pcikerModer;
@property (nonatomic, strong) NSMutableArray *albums;
@property (nonatomic, strong) UITableView *tableView;

- (void)loadingAlbumInfos;

@end

@protocol PLVAlbumsViewControllerDelegate <NSObject>

- (void)PLVAlbumsViewController:(PLVAlbumsViewController*)zalbumsVC didSelect:(PLVAlbumInfo*)albumInfo;

@end
