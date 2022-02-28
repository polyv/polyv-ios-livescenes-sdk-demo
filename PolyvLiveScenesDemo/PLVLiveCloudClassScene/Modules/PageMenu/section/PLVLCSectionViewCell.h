//
//  PLVLCSectionViewCell.h
//  PLVLiveScenesDemo
//
//  Created by Dhan on 2021/12/7.
//  Copyright © 2021 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <PLVLiveScenesSDK/PLVLivePlaybackSectionModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface PLVLCSectionViewCell : UITableViewCell

/// 回放数据模型
@property (nonatomic, weak) PLVLivePlaybackSectionModel *section;

@end

NS_ASSUME_NONNULL_END
