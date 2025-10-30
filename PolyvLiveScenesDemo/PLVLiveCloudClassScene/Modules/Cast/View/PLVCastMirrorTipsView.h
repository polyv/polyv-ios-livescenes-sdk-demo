//
//  PLVCastMirrorTipsView.h
//  PLVLiveScenesDemo
//
//  Created by jiaweihuang on 2021/9/10.
//  Copyright © 2021 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PLVCastMirrorTipsView : UIView

@property (nonatomic, assign) BOOL needShow;

- (void)showOnView:(UIView *)superView;


@end

NS_ASSUME_NONNULL_END
