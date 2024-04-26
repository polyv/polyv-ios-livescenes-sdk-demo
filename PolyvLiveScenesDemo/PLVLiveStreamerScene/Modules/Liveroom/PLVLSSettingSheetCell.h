//
//  PLVLSSettingSheetCell.h
//  PLVLiveStreamerDemo
//
//  Created by MissYasiky on 2021/3/5.
//  Copyright © 2021 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PLVRoomDataManager.h"

NS_ASSUME_NONNULL_BEGIN

/// 设置弹层-单个设置项cell
@interface PLVLSSettingSheetCell : UITableViewCell

@property (nonatomic, copy) void(^didSelectedAtIndex)(NSInteger index);

/// 设置 cell 视图
/// 选项文本列表只在第一次设置生效，之后无法更新
/// @param optionsArray 选项文本列表
/// @param selectedIndex 选中索引
- (void)setOptionsArray:(NSArray <NSString *> *)optionsArray selectedIndex:(NSInteger)selectedIndex;

/// 返回 cell 高度
+ (CGFloat)cellHeight;

@end

@interface PLVLSResolutionLevelSheetCell : UITableViewCell

- (void)setupVideoParams:(PLVClientPushStreamTemplateVideoParams *)videoParams;

@end

NS_ASSUME_NONNULL_END
