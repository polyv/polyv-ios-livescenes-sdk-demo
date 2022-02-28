//
//  PLVECPlaybackListCell.h
//  PLVLiveScenesDemo
//
//  Created by Duhan on 2021/12/9.
//  Copyright © 2021 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <PLVLiveScenesSDK/PLVPlaybackListModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface PLVECPlaybackListCell : UICollectionViewCell

- (void)setModel:(PLVPlaybackVideoModel *)videoModel;

@end

NS_ASSUME_NONNULL_END
