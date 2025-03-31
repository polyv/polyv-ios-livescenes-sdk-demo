//
//  PLVSAScreenSharePipCustomView.m
//  PolyvLiveScenesDemo
//
//  Created by Dhan on 2025/3/13.
//  Copyright © 2025 PLV. All rights reserved.
//

#import "PLVSAScreenSharePipCustomView.h"

@interface PLVSAScreenSharePipCustomView () <AVPictureInPictureSampleBufferPlaybackDelegate>

@property (nonatomic, strong) CADisplayLink *displayLink;
@property (nonatomic, assign) NSTimeInterval lastUpdateTime;
@property (nonatomic, strong) AVSampleBufferDisplayLayer *sampleBufferDisplayLayer;

@end

@implementation PLVSAScreenSharePipCustomView

#pragma mark - [ Override ]

+ (Class)layerClass {
    if (@available(iOS 15.0, *)) {
        return [AVSampleBufferDisplayLayer class];
    }
    return [CALayer class];
}

- (AVSampleBufferDisplayLayer *)sampleBufferDisplayLayer {
    if (@available(iOS 15.0, *)) {
        return (AVSampleBufferDisplayLayer *)self.layer;
    }
    return nil;
}

- (void)setContentMode:(UIViewContentMode)contentMode {
    [super setContentMode:contentMode];
    AVLayerVideoGravity videoGravity = AVLayerVideoGravityResizeAspect;
    switch (contentMode) {
        case UIViewContentModeCenter:
        case UIViewContentModeScaleAspectFit:
            videoGravity = AVLayerVideoGravityResizeAspect;
            break;
        case UIViewContentModeScaleAspectFill:
            videoGravity = AVLayerVideoGravityResizeAspectFill;
            break;
        case UIViewContentModeScaleToFill:
            videoGravity = AVLayerVideoGravityResize;
        default:
            break;
    }
    self.sampleBufferDisplayLayer.videoGravity = videoGravity;
}

#pragma mark - [ Life Cycle ]

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        if (@available(iOS 15.0, *)) {
            self.backgroundColor = [UIColor blackColor];
            self.translatesAutoresizingMaskIntoConstraints = NO;
            self.preferredFramesPerSecond = 5;
        }
    }
    return self;
}

- (void)dealloc {
    [self stopDisplayLink];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    if (@available(iOS 15.0, *)) {
        [self layoutPiPLayer];
    }
}

#pragma mark - [ Public Method ]

- (id)pipContentSource API_AVAILABLE(ios(15.0)) {
    return [[AVPictureInPictureControllerContentSource alloc] 
            initWithSampleBufferDisplayLayer:self.sampleBufferDisplayLayer 
            playbackDelegate:self];
}

- (void)wannaUpdateContent {
    if (@available(iOS 15.0, *)) {
        if ([self.delegate respondsToSelector:@selector(pipCustomViewContentWannaUpdate)]) {
            [self.delegate pipCustomViewContentWannaUpdate];
        }
    }
}

- (void)startDisplayLink {
    if (@available(iOS 15.0, *)) {
        [self stopDisplayLink];
        
        self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(displayLinkDidUpdate:)];
        self.displayLink.preferredFramesPerSecond = self.preferredFramesPerSecond;
        [self.displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    }
}

- (void)stopDisplayLink {
    // 确保在主线程执行
        if (![NSThread isMainThread]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self stopDisplayLink];
            });
            return;
        }
    
    if (@available(iOS 15.0, *)) {
        [self.displayLink invalidate];
        self.displayLink = nil;
    }
}


#pragma mark - [ Private Method ]

- (void)layoutPiPLayer API_AVAILABLE(ios(15.0)) {
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    self.sampleBufferDisplayLayer.frame = self.bounds;
    [CATransaction commit];
}

- (void)displayLinkDidUpdate:(CADisplayLink *)displayLink API_AVAILABLE(ios(15.0)) {
    // 计算帧率控制
    NSTimeInterval currentTime = displayLink.timestamp;
    NSTimeInterval deltaTime = currentTime - self.lastUpdateTime;
    NSTimeInterval targetDeltaTime = 1.0 / self.preferredFramesPerSecond;
    
    if (deltaTime >= targetDeltaTime) {
        self.lastUpdateTime = currentTime;
        [self updateSampleBuffer];
        [self wannaUpdateContent];
    }
}

- (void)updateSampleBuffer API_AVAILABLE(ios(15.0)) {
    CMSampleBufferRef sampleBuffer = [self sampleBufferFromLayer:self.layer];
    if (sampleBuffer) {
        if (self.sampleBufferDisplayLayer.status == AVQueuedSampleBufferRenderingStatusFailed) {
            [self.sampleBufferDisplayLayer flush];
        }
        [self.sampleBufferDisplayLayer enqueueSampleBuffer:sampleBuffer];
        CFRelease(sampleBuffer);
    }
}

#pragma mark - [ Helper Method ]

- (UIImage *)imageFromLayer:(CALayer *)layer {
    CGSize size = layer.bounds.size;
    if (size.width <= 0 || size.height <= 0) {
        return nil;
    }
    
    // 使用UIGraphicsImageRenderer创建图像
    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:size];
    UIImage *image = [renderer imageWithActions:^(UIGraphicsImageRendererContext *context) {
        // 将layer渲染到上下文中
        [layer renderInContext:context.CGContext];
    }];
    
    return image;
}

- (CVPixelBufferRef)pixelBufferFromImage:(UIImage *)image {
    NSDictionary *options = @{
        (id)kCVPixelBufferCGImageCompatibilityKey: @(YES),
        (id)kCVPixelBufferCGBitmapContextCompatibilityKey: @(YES)
    };
    
    CVPixelBufferRef pixelBuffer = NULL;
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault,
                                        image.size.width,
                                        image.size.height,
                                        kCVPixelFormatType_32BGRA,
                                        (__bridge CFDictionaryRef)options,
                                        &pixelBuffer);
    
    if (status != kCVReturnSuccess) {
        return NULL;
    }
    
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    void *pixelData = CVPixelBufferGetBaseAddress(pixelBuffer);
    
    if (pixelData) {
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        CGContextRef context = CGBitmapContextCreate(pixelData,
                                                   image.size.width,
                                                   image.size.height,
                                                   8,
                                                   CVPixelBufferGetBytesPerRow(pixelBuffer),
                                                   colorSpace,
                                                   kCGImageAlphaNoneSkipFirst | kCGBitmapByteOrder32Big);
        
        if (context) {
            CGContextDrawImage(context, CGRectMake(0, 0, image.size.width, image.size.height), image.CGImage);
            CGContextRelease(context);
        }
        CGColorSpaceRelease(colorSpace);
    }
    
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    return pixelBuffer;
}

- (CMSampleBufferRef)sampleBufferFromPixelBuffer:(CVPixelBufferRef)pixelBuffer {
    CMFormatDescriptionRef formatDescription;
    CMVideoFormatDescriptionCreateForImageBuffer(kCFAllocatorDefault, pixelBuffer, &formatDescription);
    
    CMSampleBufferRef sampleBuffer;
    CMSampleTimingInfo timingInfo = {0};
    timingInfo.duration = kCMTimeInvalid;
    timingInfo.presentationTimeStamp = kCMTimeZero;
    timingInfo.decodeTimeStamp = kCMTimeInvalid;
    
    CMSampleBufferCreateForImageBuffer(kCFAllocatorDefault,
                                     pixelBuffer,
                                     true,
                                     NULL,
                                     NULL,
                                     formatDescription,
                                     &timingInfo,
                                     &sampleBuffer);
    
    CFRelease(formatDescription);
    return sampleBuffer;
}

- (CMSampleBufferRef)sampleBufferFromLayer:(CALayer *)layer API_AVAILABLE(ios(15.0)) {
    UIImage *image = [self imageFromLayer:layer];
    CVPixelBufferRef pixelBuffer = [self pixelBufferFromImage:image];
    CMSampleBufferRef sampleBuffer = [self sampleBufferFromPixelBuffer:pixelBuffer];
    CVPixelBufferRelease(pixelBuffer);
    return sampleBuffer;
}

#pragma mark - AVPictureInPictureSampleBufferPlaybackDelegate

- (void)pictureInPictureController:(AVPictureInPictureController *)pictureInPictureController setPlaying:(BOOL)playing API_AVAILABLE(ios(15.0)) {
    self.isPaused = !playing;
}

- (CMTimeRange)pictureInPictureControllerTimeRangeForPlayback:(AVPictureInPictureController *)pictureInPictureController API_AVAILABLE(ios(15.0)) {
    return CMTimeRangeMake(kCMTimeNegativeInfinity, kCMTimePositiveInfinity);
}

- (BOOL)pictureInPictureControllerIsPlaybackPaused:(AVPictureInPictureController *)pictureInPictureController API_AVAILABLE(ios(15.0)) {
    return self.isPaused;
}

- (void)pictureInPictureController:(AVPictureInPictureController *)pictureInPictureController didTransitionToRenderSize:(CMVideoDimensions)newRenderSize API_AVAILABLE(ios(15.0)) {
}

- (void)pictureInPictureController:(AVPictureInPictureController *)pictureInPictureController skipByInterval:(CMTime)skipInterval completionHandler:(void (^)(void))completionHandler API_AVAILABLE(ios(15.0)) {
    if (completionHandler) {
        completionHandler();
    }
}

@end 
