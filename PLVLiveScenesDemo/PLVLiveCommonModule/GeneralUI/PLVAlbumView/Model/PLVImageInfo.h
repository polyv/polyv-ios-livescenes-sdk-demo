//
//  PLVImageInfo.h
//  zPic
//
//  Created by zykhbl on 2017/7/11.
//  Copyright © 2017年 zykhbl. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <Photos/Photos.h>
DEPRECATED_MSG_ATTRIBUTE("已废弃，该模块与PLVImagePickerControllernen能力重复，后续请使用PLVImagePickerController")
@interface PLVImageInfo : NSObject

@property (nonatomic, assign) PHImageRequestID requestID;
@property (nonatomic, strong) PHAsset *asset;
@property (nonatomic, assign) CGSize pixelSize;
@property (atomic, weak) UIImageView *imgView;
@property (nonatomic, strong) UIImage *originImg;
@property (nonatomic, strong) UIImage *bitmapImg;

@property (nonatomic, assign) BOOL video;
@property (nonatomic, assign) NSTimeInterval duration;
@property (nonatomic, assign) CGFloat frameTimeStamp;
@property (nonatomic, assign) CMTime frameTime;

@end
