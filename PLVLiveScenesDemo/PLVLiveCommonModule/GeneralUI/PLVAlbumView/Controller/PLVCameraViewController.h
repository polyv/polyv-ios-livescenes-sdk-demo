//
//  PLVCameraViewController.h
//  zPin_Pro
//
//  Created by zykhbl on 2017/12/17.
//  Copyright © 2017年 zykhbl. All rights reserved.
//

#import <UIKit/UIKit.h>
DEPRECATED_MSG_ATTRIBUTE("已废弃，该模块与PLVImagePickerControllernen能力重复，后续请使用PLVImagePickerController")
@protocol PLVCameraViewControllerDelegate;

@interface PLVCameraViewController : UIViewController

@property (nonatomic, weak) id<PLVCameraViewControllerDelegate> delegate;

@end

@protocol PLVCameraViewControllerDelegate <NSObject>

- (void)cameraViewController:(PLVCameraViewController *)cameraVC uploadImage:(UIImage *)uploadImage;

- (void)dismissCameraViewController:(PLVCameraViewController*)cameraVC;

@end
