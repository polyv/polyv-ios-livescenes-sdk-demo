//
//  PLVSACameraAndMicphoneStateView.h
//  PLVLiveScenesDemo
//
//  Created by lijingtong on 2021/6/10.
//  Copyright © 2021 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
/// 摄像头与麦克风状态视图
@interface PLVSACameraAndMicphoneStateView : UIView


/// 更新数据，刷新视图
/// @param cameraOpen 摄像头开启情况
/// @param micphoneOpen 麦克风开启情况
- (void)updateCameraOpen:(BOOL)cameraOpen micphoneOpen:(BOOL)micphoneOpen;

@end

NS_ASSUME_NONNULL_END
