//
//  PLVPageController.h
//  PolyvLiveScenesDemo
//
//  Created by MissYasiky on 2020/9/24.
//  Copyright © 2020 polyv. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PLVPageController : UIViewController

- (void)setTitles:(NSArray<NSString *> *)titles controllers:(NSArray<UIViewController *> *)controllers;

- (void)scrollEnable:(BOOL)enable;

@end

NS_ASSUME_NONNULL_END
