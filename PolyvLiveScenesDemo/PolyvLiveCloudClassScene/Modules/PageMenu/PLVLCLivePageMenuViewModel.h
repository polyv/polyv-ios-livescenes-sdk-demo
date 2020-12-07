//
//  PLVLCLivePageMenuViewModel.h
//  PolyvLiveScenesDemo
//
//  Created by MissYasiky on 2020/9/24.
//  Copyright © 2020 polyv. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, PLVLCLivePageMenuType) {
    PLVLCLivePageMenuTypeUnknown = -1,  // 未知
    PLVLCLivePageMenuTypeDesc = 0,      // 直播介绍
    PLVLCLivePageMenuTypeChat,          // 互动聊天
    PLVLCLivePageMenuTypeQuiz,          // 咨询提问
    PLVLCLivePageMenuTypeTuwen,         // 图文直播
    PLVLCLivePageMenuTypeText,          // 自定义图文直播
    PLVLCLivePageMenuTypeIframe,        // 推广外链
};

NS_ASSUME_NONNULL_BEGIN

@interface PLVLCLivePageMenuViewModel : NSObject

/// 将 menu.type 字符串转化为菜单栏类型枚举值
- (PLVLCLivePageMenuType)menuTypeWithMenu:(NSString *)menu;

@end

NS_ASSUME_NONNULL_END
