//
//  PLVLCSectionViewController.h
//  PLVLiveScenesDemo
//
//  Created by Dhan on 2021/12/6.
//  Copyright © 2021 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <PLVLiveScenesSDK/PLVLivePlaybackSectionModel.h>

NS_ASSUME_NONNULL_BEGIN

@protocol PLVLCSectionViewControllerDelegate;

@interface PLVLCSectionViewController : UIViewController

@property (nonatomic, weak) id <PLVLCSectionViewControllerDelegate>delegate;

- (void)requestData;

@end

@protocol PLVLCSectionViewControllerDelegate <NSObject>

- (NSTimeInterval)plvLCSectionViewGetPlayerCurrentTime:(PLVLCSectionViewController *)PLVLCSectionViewController;

- (void)plvLCSectionView:(PLVLCSectionViewController *)PLVLCSectionViewController seekTime:(NSTimeInterval)time;

@end

NS_ASSUME_NONNULL_END
