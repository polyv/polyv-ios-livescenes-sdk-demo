//
//  PLVLCDownloadedCell.h
//  PolyvLiveScenesDemo
//
//  Created by junotang on 2022/5/26.
//  Copyright © 2022 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <PLVLiveScenesSDK/PLVDownloadPlaybackTaskInfo.h>

NS_ASSUME_NONNULL_BEGIN

@interface PLVLCDownloadedCell : UITableViewCell

/// 点击cell里面删除按钮事件
@property (nonatomic, copy) void (^clickDeleteButtonBlock)(void);

- (void)configModel:(PLVDownloadPlaybackTaskInfo *)model;

/// 根据消息数据模型、cell宽度计算cell高度
+ (CGFloat)cellHeightWithModel:(NSString *)model cellWidth:(CGFloat)cellWidth;

@end

NS_ASSUME_NONNULL_END
