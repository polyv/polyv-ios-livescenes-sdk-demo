//
//  PLVLCUtils.h
//  PolyvLiveScenesDemo
//
//  Created by Lincal on 2020/8/7.
//  Copyright © 2020 polyv. All rights reserved.
//

#import "PLVLiveUtil.h"

NS_ASSUME_NONNULL_BEGIN

@interface PLVLCUtils : PLVLiveUtil

+ (UIImage *)imageForLiveRoomResource:(NSString *)imageName;

+ (UIImage *)imageForLinkMicResource:(NSString *)imageName;

+ (UIImage *)imageForMediaResource:(NSString *)imageName;

+ (UIImage *)imageForMenuResource:(NSString *)imageName;

+ (UIImage *)imageForChatroomResource:(NSString *)imageName;

@end

NS_ASSUME_NONNULL_END
