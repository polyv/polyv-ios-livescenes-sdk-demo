//
//  PLVPageController.h
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2020/9/24.
//  Copyright © 2020 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PLVLCPageController : UIViewController

- (void)setTitles:(NSArray<NSString *> *)titles controllers:(NSArray<UIViewController *> *)controllers;

- (void)scrollEnable:(BOOL)enable;

@end

NS_ASSUME_NONNULL_END
