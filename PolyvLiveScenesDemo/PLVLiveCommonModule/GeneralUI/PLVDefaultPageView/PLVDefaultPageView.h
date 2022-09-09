//
//  PLVDefaultPageView.h
//  PolyvLiveScenesDemo
//
//  Created by Dhan on 2022/8/19.
//  Copyright © 2022 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 缺省页样式
typedef NS_ENUM(NSUInteger, PLVDefaultPageViewType) {
    /// 样式1，只显示错误码
    PLVDefaultPageViewTypeErrorCode = 0,
    /// 样式2，显示刷新按钮
    PLVDefaultPageViewTypeRefresh = 1,
    /// 样式3，显示刷新和切换线路按钮
    PLVDefaultPageViewTypeRefreshAndSwitchLine = 2
};

@class PLVDefaultPageView;

@protocol PLVDefaultPageViewDelegate <NSObject>

- (void)plvDefaultPageViewWannaRefresh:(PLVDefaultPageView *)defaultPageView;

- (void)plvDefaultPageViewWannaSwitchLine:(PLVDefaultPageView *)defaultPageView;

@end

@interface PLVDefaultPageView : UIView

/// Delegate
@property (nonatomic, weak) id <PLVDefaultPageViewDelegate> delegate;

/// 刷新按钮
@property (nonatomic, readonly) UIButton *refreshButton;

/// 切换线路按钮
@property (nonatomic, readonly) UIButton *switchLineButton;

/// 显示缺省页 (只显示错误信息)
///
/// @param message 错误信息
/// @param type 缺省页样式
///
/// @note 当显示时 显示样式的优先级：样式3>样式2>样式1，即当前显示样式3缺省页时 再次调用显示样式1，不会显示样式1
- (void)showWithErrorMessage:(NSString * _Nullable)message type:(PLVDefaultPageViewType)type;

/// 显示缺省页
///
/// @param errorCode 错误码，type为PLVDefaultPageViewTypeRefresh、PLVDefaultPageViewTypeRefreshAndSwitching时，不显示
/// @param message 错误信息
/// @param type 缺省页样式
///
/// @note 当显示时 显示样式的优先级：样式3>样式2>样式1，即当前显示样式3缺省页时 再次调用显示样式1，不会显示样式1
- (void)showWithErrorCode:(NSInteger)errorCode message:(NSString * _Nullable)message type:(PLVDefaultPageViewType)type;

@end

NS_ASSUME_NONNULL_END
