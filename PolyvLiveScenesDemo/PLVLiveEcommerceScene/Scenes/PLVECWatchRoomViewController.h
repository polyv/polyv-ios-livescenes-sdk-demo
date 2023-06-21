//
//  PLVECWatchRoomViewController.h
//  PLVLiveScenesDemo
//
//  Created by Lincal on 2020/12/1.
//  Copyright © 2020 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PLVECWatchRoomViewController : UIViewController

/// 是否在iPad上显示全屏按钮
///
/// @note NO-在iPad上竖屏时不显示全屏按钮，YES-显示
///       当项目未适配分屏时，建议设置为YES
@property (nonatomic,assign) BOOL fullScreenButtonShowOnIpad;

@end

NS_ASSUME_NONNULL_END
