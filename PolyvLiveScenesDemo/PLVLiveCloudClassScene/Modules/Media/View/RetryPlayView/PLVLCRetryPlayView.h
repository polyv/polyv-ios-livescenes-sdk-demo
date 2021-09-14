//
//  PLVLCRetryPlayView.h
//  PLVLiveScenesDemo
//
//  Created by jiaweihuang on 2021/7/13.
//  Copyright © 2021 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol PLVLCRetryPlayViewDelegate <NSObject>

- (void)plvLCRetryPlayViewReplayButtonClicked;

@end

@interface PLVLCRetryPlayView : UIView

@property (nonatomic, weak) id<PLVLCRetryPlayViewDelegate> delegate;

@end

