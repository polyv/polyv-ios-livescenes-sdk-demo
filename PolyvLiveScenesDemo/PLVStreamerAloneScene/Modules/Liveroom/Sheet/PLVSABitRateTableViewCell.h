//
//  PLVSABitRateTableViewCell.h
//  PolyvLiveScenesDemo
//
//  Created by Sakya on 2023/12/26.
//  Copyright © 2023 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PLVRoomDataManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface PLVSABitRateTableViewCell : UITableViewCell

- (void)setupVideoParams:(PLVClientPushStreamTemplateVideoParams *)videoParams;

@end

NS_ASSUME_NONNULL_END
