//
//  PLVLCMediaRealTimeSubtitleCell.h
//  PolyvLiveScenesDemo
//
//  Created by Dhan on 2026/1/19.
//

#import <UIKit/UIKit.h>

#import "PLVLCMediaMoreModel.h"

NS_ASSUME_NONNULL_BEGIN

@class PLVLCMediaRealTimeSubtitleCell;
@protocol PLVLCMediaRealTimeSubtitleCellDelegate <NSObject>

- (void)plvLCMediaRealTimeSubtitleCell:(PLVLCMediaRealTimeSubtitleCell *)cell didToggle:(BOOL)on model:(PLVLCMediaMoreModel *)model;

@end

@interface PLVLCMediaRealTimeSubtitleCell : UITableViewCell

@property (nonatomic, weak) id<PLVLCMediaRealTimeSubtitleCellDelegate> delegate;

- (void)setupWithModel:(PLVLCMediaMoreModel *)model;

@end

NS_ASSUME_NONNULL_END
