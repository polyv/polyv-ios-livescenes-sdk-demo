//
//  PLVSACameraSettingSheet.h
//  PolyvLiveScenesDemo
//
//  Created by Dhan on 2023/10/19.
//  Copyright © 2023 PLV. All rights reserved.
//

#import "PLVSABottomSheet.h"

NS_ASSUME_NONNULL_BEGIN

@class PLVSACameraSettingSheet;

@protocol PLVSACameraSettingSheetDelegate <NSObject>

- (void)plvsaCameraSettingSheet:(PLVSACameraSettingSheet *)cameraSettingSheet didTapCameraOpen:(BOOL)cameraOpen cameraSetting:(BOOL)isPicture placeholderImage:(UIImage * _Nullable)image placeholderImageUrl:(NSString * _Nullable)url;

@end

@interface PLVSACameraSettingSheet : PLVSABottomSheet

@property (nonatomic, weak) id<PLVSACameraSettingSheetDelegate> delegate;

@property (nonatomic, assign) BOOL currentCameraOpen;

- (void)updateCameraSetting:(BOOL)isPicture placeholderImage:(UIImage * _Nullable)image placeholderImageUrl:(NSString * _Nullable)url;

@end

NS_ASSUME_NONNULL_END
