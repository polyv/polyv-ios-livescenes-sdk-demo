//
//  PLVLCPlaybackListViewController.h
//  PLVLiveScenesDemo
//
//  Created by Dhan on 2021/11/30.
//  Copyright © 2021 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <PLVLiveScenesSDK/PLVPlaybackListModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface PLVLCPlaybackListViewController : UIViewController

- (instancetype)initWithPlaybackList:(PLVPlaybackListModel *)playbackList;

@end
NS_ASSUME_NONNULL_END
