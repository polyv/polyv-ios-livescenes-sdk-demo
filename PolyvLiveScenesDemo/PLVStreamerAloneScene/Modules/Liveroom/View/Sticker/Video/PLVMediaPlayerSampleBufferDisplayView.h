//
//  PLVMediaPlayerSampleBufferDisplayView.h
//  PLVLiveScenesSDK
//
//  Created by Sakya on 2023/3/22.
//  Copyright © 2023 PLV. All rights reserved.
//
//  ijk第三方渲染视图，负责使用SampleBuffer 渲染 ijk 软硬解数据

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

#if __has_include(<PLVIJKPlayer/PLVIJKPlayer.h>)
    #import <PLVIJKPlayer/PLVIJKFFMoviePlayerController.h>
    typedef UIImageView<PLVIJKSDLGLViewProtocol> PLVIJKSDLGLThirdView;
#elif __has_include(<IJKMediaFramework/IJKMediaFramework.h>)
    #import <IJKMediaFramework/IJKMediaFramework.h>
    typedef UIImageView<IJKSDLGLViewProtocol> PLVIJKSDLGLThirdView;
#else
    typedef UIImageView PLVIJKSDLGLThirdView;
    #ifndef PLV_NO_IJK_EXIST
    #define PLV_NO_IJK_EXIST
    #endif
#endif

NS_ASSUME_NONNULL_BEGIN

@protocol PLVMediaPlayerSampleBufferDisplayViewDelegate ;

@interface PLVMediaPlayerSampleBufferDisplayView : PLVIJKSDLGLThirdView

@property (nonatomic, strong) AVSampleBufferDisplayLayer *sampleBufferDisplayLayer;
@property (nonatomic, weak) id<PLVMediaPlayerSampleBufferDisplayViewDelegate> delegate;
@property (nonatomic, assign) BOOL enablePIPInBackground;

- (id) initWithFrame:(CGRect)frame;

@end

@protocol PLVMediaPlayerSampleBufferDisplayViewDelegate <NSObject>

/// 首帧渲染回调
- (void)sampleBufferDisplayViewFirstFrameRendered:(PLVMediaPlayerSampleBufferDisplayView *) displayView;

@end

NS_ASSUME_NONNULL_END
