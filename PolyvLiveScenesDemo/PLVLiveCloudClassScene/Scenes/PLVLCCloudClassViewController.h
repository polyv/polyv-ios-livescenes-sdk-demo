//
//  PLVLCCloudClassViewController.h
//  PLVLiveScenesDemo
//
//  Created by Lincal on 2020/11/10.
//  Copyright © 2020 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// [云课堂场景] 用于观看 “直播、直播回放” 的控制器
///
/// @note 涵盖如下四种类型
///       直播:三分屏直播(有PPT)、普通直播
///       直播回放:三分屏直播回放(有PPT)、普通直播的直播回放
@interface PLVLCCloudClassViewController : UIViewController

/// 是否在iPad上显示全屏按钮
///
/// @note NO-在iPad上竖屏时不显示全屏按钮，YES-显示
///       当项目未适配分屏时，建议设置为YES
@property (nonatomic,assign) BOOL fullScreenButtonShowOnIpad;

@end

NS_ASSUME_NONNULL_END
