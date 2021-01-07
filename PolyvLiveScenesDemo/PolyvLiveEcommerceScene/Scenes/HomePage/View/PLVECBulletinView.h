//
//  PLVECBulletinView.h
//  PolyvLiveEcommerceDemo
//
//  Created by ftao on 2020/5/21.
//  Copyright © 2020 polyv. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 公告视图
@interface PLVECBulletinView : UIView

@property (nonatomic, copy) NSString *content;

- (void)showBulletinView:(NSString *)content duration:(NSTimeInterval)duration;

@end

NS_ASSUME_NONNULL_END
