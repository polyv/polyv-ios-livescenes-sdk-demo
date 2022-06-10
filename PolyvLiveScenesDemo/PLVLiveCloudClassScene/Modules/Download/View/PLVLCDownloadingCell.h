//
//  PLVLCDownloadingCell.h
//  PolyvLiveScenesDemo
//
//  Created by junotang on 2022/5/26.
//  Copyright © 2022 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <PLVLiveScenesSDK/PLVDownloadPlaybackTaskInfo.h>

NS_ASSUME_NONNULL_BEGIN

@interface PLVLCDownloadingCell : UITableViewCell

/// 点击cell里面按钮事件。type:0 删除 type:1 下载  type:2  暂停
@property (nonatomic, copy) void (^clickButtonBlock)(NSInteger type);

- (void)configModel:(PLVDownloadPlaybackTaskInfo *)model;

/// 根据消息数据模型、cell宽度计算cell高度
+ (CGFloat)cellHeightWithModel:(NSString *)model cellWidth:(CGFloat)cellWidth;

@end

NS_ASSUME_NONNULL_END
