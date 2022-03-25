//
//  PLVECWatchRoomScrollView.h
//  PLVLiveScenesDemo
//
//  Created by jiaweihuang on 2021/7/19.
//  Copyright © 2021 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PLVECWatchRoomScrollView : UIScrollView

/// 解决事件传递响应链问题，并无其它业务逻辑
@property (nonatomic, weak) UIView *playerDisplayView;

@end


