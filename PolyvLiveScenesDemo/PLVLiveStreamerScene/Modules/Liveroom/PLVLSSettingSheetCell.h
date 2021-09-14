//
//  PLVLSSettingSheetCell.h
//  PLVLiveStreamerDemo
//
//  Created by MissYasiky on 2021/3/5.
//  Copyright © 2021 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 设置弹层-单个设置项cell
@interface PLVLSSettingSheetCell : UITableViewCell

@property (nonatomic, copy) void(^didSelectedAtIndex)(NSInteger index);

/// 设置 cell 视图
/// 选项文本列表只在第一次设置生效，之后无法更新
/// @param title 左侧标题文本
/// @param optionsArray 选项文本列表
/// @param selectedIndex 选中索引
- (void)setTitle:(NSString *)title optionsArray:(NSArray <NSString *> *)optionsArray selectedIndex:(NSInteger)selectedIndex;

/// 返回 cell 高度
+ (CGFloat)cellHeight;

@end

NS_ASSUME_NONNULL_END
