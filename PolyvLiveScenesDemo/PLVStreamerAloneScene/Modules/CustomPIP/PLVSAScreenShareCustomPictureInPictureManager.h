//
//  PLVSACustomPictureInPictureManager.h
//  PolyvLiveScenesDemo
//
//  Created by Dhan on 2025/3/13.
//  Copyright © 2025 PLV. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AVKit/AVKit.h>
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>

NS_ASSUME_NONNULL_BEGIN

@class PLVSAScreenSharePipCustomView;

API_AVAILABLE(ios(15.0))
@protocol PLVSAScreenShareCustomPictureInPictureManagerDelegate <NSObject>

- (void)PLVSAScreenShareCustomPictureInPictureManager_needUpdateContent;

@end

API_AVAILABLE(ios(15.0))
@interface PLVSAScreenShareCustomPictureInPictureManager : NSObject

@property (nonatomic, assign) BOOL autoEnterPictureInPicture;

@property (nonatomic,weak) id<PLVSAScreenShareCustomPictureInPictureManagerDelegate> delegate;

@property (nonatomic, assign) BOOL pictureInPictureActive;

- (instancetype)initWithDisplaySuperview:(UIView *)displaySuperview;

- (void)updateContent:(NSAttributedString *)content networkState:(PLVBRTCNetworkQuality)networkState;

- (void)startPictureInPicture;

- (void)stopPictureInPicture;

- (void)startPictureInPictureSource;

- (void)stopPictureInPictureSource;

@end

NS_ASSUME_NONNULL_END
