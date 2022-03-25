//
//  PLVAlbumInfo.h
//  zPic
//
//  Created by zykhbl on 2017/7/22.
//  Copyright © 2017年 zykhbl. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Photos/Photos.h>
DEPRECATED_MSG_ATTRIBUTE("已废弃，该模块与PLVImagePickerControllernen能力重复，后续请使用PLVImagePickerController")
@interface PLVAlbumInfo : NSObject

@property (nonatomic, strong) PHAssetCollection *assetCollection;
@property (nonatomic, strong) PHFetchResult<PHAsset*> *assets;
@property (nonatomic, strong) UIImage *albumImg;
@property (nonatomic, assign) NSUInteger photoCount;
@property (nonatomic, assign) NSUInteger videoCount;

@end
