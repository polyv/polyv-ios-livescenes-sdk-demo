//
//  PLVLCMediaDanmuSettingCell.h
//  PolyvLiveScenesDemo
//
//  Created by Dhan on 2023/4/25.
//  Copyright © 2023 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol PLVLCMediaDanmuSettingCellDelegate;

/// 弹幕设置视图TableviewCell
@interface PLVLCMediaDanmuSettingCell : UITableViewCell

@property (nonatomic, weak) id <PLVLCMediaDanmuSettingCellDelegate> delegate;

/// 设置标题和对应的节点数据
- (void)setDanmuSpeedCellWithTitle:(NSString *)title scaleValueArray:(NSArray<NSNumber *> *)scaleValueArray scaleTitleArray:(NSArray<NSString *> *)scaleTitleArray defaultScaleIndex:(NSNumber *)defaultScaleIndex;

@end

@protocol PLVLCMediaDanmuSettingCellDelegate <NSObject>

- (void)plvLCMediaDanmuSettingCell:(PLVLCMediaDanmuSettingCell *)cell updateSelectedScaleValue:(NSNumber *)scalevalue;

@end

NS_ASSUME_NONNULL_END
