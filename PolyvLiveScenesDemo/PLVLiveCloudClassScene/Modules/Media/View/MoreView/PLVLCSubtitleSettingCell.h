//
//  PLVLCSubtitleSettingCell.h
//  PolyvLiveScenesDemo
//
//  Created by Dhan on 2025/5/9.
//  Copyright © 2025 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PLVLCMediaMoreCell.h"
#import <PLVLiveScenesSDK/PLVPlaybackVideoInfoModel.h>

NS_ASSUME_NONNULL_BEGIN

@class PLVLCSubtitleSettingCell;

@protocol PLVLCSubtitleSettingCellDelegate <NSObject>

- (void)PLVLCSubtitleSettingCell:(PLVLCSubtitleSettingCell *)cell
        didUpdateSubtitleState:(PLVPlaybackSubtitleModel *)originalSubtitle
                translateSubtitle:(PLVPlaybackSubtitleModel *)translateSubtitle;

@end

@interface PLVLCSubtitleSettingCell : UITableViewCell

@property (nonatomic, weak) id<PLVLCSubtitleSettingCellDelegate> delegate;

- (void)setupWithSubtitleList:(NSArray<NSDictionary *> *)subtitleList;

@end

NS_ASSUME_NONNULL_END
