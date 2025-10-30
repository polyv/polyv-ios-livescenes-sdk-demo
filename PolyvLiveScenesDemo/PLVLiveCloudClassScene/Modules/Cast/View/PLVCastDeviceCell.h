//
//  PLVCastDeviceCell.h
//  PLVCloudClassDemo
//
//  Created by MissYasiky on 2020/7/31.
//  Copyright © 2020 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PLVCastDeviceCell : UITableViewCell

+ (CGFloat)cellHeight;

- (void)setDevice:(NSString *)device connected:(BOOL)connected;

@end

NS_ASSUME_NONNULL_END
