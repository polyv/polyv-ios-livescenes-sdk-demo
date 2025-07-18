//
//  PLVLiveSearchBar.h
//  PLVLiveScenesDemo
//
//  Created by Dhan on 2025/6/25.
//  Copyright © 2025 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class PLVLiveSearchBar;

@protocol PLVLiveSearchBarDelegate <NSObject>

@optional
/// 搜索文本变化回调
/// @param searchBar 搜索框
/// @param searchText 搜索文本
- (void)searchBar:(PLVLiveSearchBar *)searchBar didChangeSearchText:(NSString *)searchText;

/// 搜索框开始编辑
/// @param searchBar 搜索框
- (void)searchBarDidBeginEditing:(PLVLiveSearchBar *)searchBar;

/// 搜索框结束编辑
/// @param searchBar 搜索框
- (void)searchBarDidEndEditing:(PLVLiveSearchBar *)searchBar;

/// 清除按钮点击
/// @param searchBar 搜索框
- (void)searchBarDidTapClearButton:(PLVLiveSearchBar *)searchBar;

@end

@interface PLVLiveSearchBar : UIView

/// 代理
@property (nonatomic, weak) id<PLVLiveSearchBarDelegate> delegate;

/// 搜索文本
@property (nonatomic, copy, readonly) NSString *searchText;

/// 占位符文本
@property (nonatomic, copy) NSString *placeholder;

/// 是否显示清除按钮
@property (nonatomic, assign) BOOL showsClearButton;

/// 搜索框是否处于编辑状态
@property (nonatomic, assign, readonly) BOOL isEditing;

/// 背景颜色
@property (nonatomic, strong) UIColor *backgroundColor;

/// 文本颜色
@property (nonatomic, strong) UIColor *textColor;

/// 占位符颜色
@property (nonatomic, strong) UIColor *placeholderColor;

/// 图标颜色
@property (nonatomic, strong) UIColor *iconColor;

/// 圆角半径
@property (nonatomic, assign) CGFloat cornerRadius;

/// 初始化方法
/// @param frame 框架
- (instancetype)initWithFrame:(CGRect)frame;

/// 设置搜索文本
/// @param searchText 搜索文本
- (void)setSearchText:(NSString *)searchText;

/// 清除搜索文本
- (void)clearSearchText;

/// 开始编辑
- (void)beginEditing;

/// 结束编辑
- (void)endEditing;

/// 设置防抖延迟时间（默认500ms）
/// @param delay 延迟时间（秒）
- (void)setDebounceDelay:(NSTimeInterval)delay;

@end

NS_ASSUME_NONNULL_END 
