//
//  PLVHCGuidePagesView.h
//  PLVLiveScenesDemo
//
//  Created by Sakya on 2021/7/1.
//  Copyright © 2021 PLV. All rights reserved.
//
// 讲师端引导页


#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, PLVHCGuidePagesType) {
    PLVHCGuidePagesType_Device, //引导页 - 摄像头麦克风设备
    PLVHCGuidePagesType_BeginClass //引导页-开始上课
};

@interface PLVHCGuidePagesView : UIView

/// 显示引导页视图
/// @param view 引导页添加的视图
+ (void)showGuidePagesViewinView:(UIView *)view
                        endBlock:(void(^ _Nullable)(void))endBlock;

@end

NS_ASSUME_NONNULL_END


