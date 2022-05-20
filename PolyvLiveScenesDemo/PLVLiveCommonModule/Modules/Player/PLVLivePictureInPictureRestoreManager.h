//
//  PLVLivePictureInPictureRestoreManager.h
//  PolyvLiveScenesDemo
//
//  Created by junotang on 2022/5/16.
//  Copyright © 2022 PLV. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <PLVLiveScenesSDK/PLVLivePictureInPictureManager.h>

NS_ASSUME_NONNULL_BEGIN

/// 画中画恢复功能管理
@interface PLVLivePictureInPictureRestoreManager : NSObject<PLVLivePictureInPictureRestoreDelegate>

#pragma mark - [ 属性 ]

/// 用于开启画中画后离开页面时，持有原来的页面
@property (nonatomic, strong, nullable) UIViewController *holdingViewController;

/// 当使用model方式展示直播间的时候，点击小窗恢复按钮，是present还是dismiss来恢复原直播间
@property (nonatomic, assign) BOOL restoreWithPresent;

#pragma mark - [ 方法 ]

/// 单例方法
+ (instancetype)sharedInstance;

/// 清空恢复管理器的内部属性，在画中画关闭的时候调用，防止内存泄漏
- (void)cleanRestoreManager;

@end

NS_ASSUME_NONNULL_END
