//
//  PLVLCUtils.h
//  PLVLiveScenesDemo
//
//  Created by Lincal on 2020/8/7.
//  Copyright © 2020 PLV. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PLVLCUtils : NSObject

+ (void)showHUDWithTitle:(NSString *)title detail:(NSString *)detail view:(UIView *)view;

+ (UIImage *)imageForLiveRoomResource:(NSString *)imageName;

+ (UIImage *)imageForLinkMicResource:(NSString *)imageName;

+ (UIImage *)imageForMediaResource:(NSString *)imageName;

+ (UIImage *)imageForMenuResource:(NSString *)imageName;

+ (UIImage *)imageForChatroomResource:(NSString *)imageName;

@end

NS_ASSUME_NONNULL_END
