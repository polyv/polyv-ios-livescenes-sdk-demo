//
//  PLVSAMediaPlayerSampleBufferDisplayView.m
//  PLVLiveScenesSDK
//
//  Created by Sakya on 2023/3/22.
//  Copyright © 2023 PLV. All rights reserved.
//

#import "PLVSAMediaPlayerSampleBufferDisplayView.h"
#import <AVFoundation/AVFoundation.h>

//#import "PLVConsoleLogger.h"

@interface PLVSAMediaPlayerSampleBufferDisplayView()

#ifndef PLV_NO_IJK_EXIST

{
    void *previousPixelBuffer;
    BOOL hasAddObserver;
    BOOL firsFrameRendered;
    
    UInt32 _toolBoxFormat;
    UInt32 _FCCNV12Format;
    UInt32 _FCCI420Format;
    
    bool _background;
}
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSValue *> *pixelBufferPoolDict;

#endif

@end

@implementation PLVSAMediaPlayerSampleBufferDisplayView

#ifndef PLV_NO_IJK_EXIST

@synthesize isThirdGLView              = _isThirdGLView;
@synthesize scaleFactor                = _scaleFactor;
@synthesize fps                        = _fps;

#pragma mark - [ Override ]
+ (Class)layerClass {
    return [AVSampleBufferDisplayLayer class];
}

- (AVSampleBufferDisplayLayer *)sampleBufferDisplayLayer {
    return (AVSampleBufferDisplayLayer *)self.layer;
}

#pragma mark - [ Life Cycle ]
- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        // 硬解码 format
        _toolBoxFormat = ((((uint32_t)'_') | (((uint32_t)'V') << 8) | (((uint32_t)'T') << 16) | (((uint32_t)'B') << 24)));
        // NV12 format
        _FCCNV12Format = ((((uint32_t)'N') | (((uint32_t)'V') << 8) | (((uint32_t)'1') << 16) | (((uint32_t)'2') << 24)));
        // I420 format
        _FCCI420Format = ((((uint32_t)'I') | (((uint32_t)'4') << 8) | (((uint32_t)'2') << 16) | (((uint32_t)'0') << 24)));
        [self setupSampleBufferDisplayLayer];
    }
    return self;
}

- (void)dealloc {
    for (NSValue *value in self.pixelBufferPoolDict.allValues) {
        CVPixelBufferPoolRef pool = [value pointerValue];
        CVPixelBufferPoolRelease(pool);
    }
    if (self->previousPixelBuffer){
        CFRelease(self->previousPixelBuffer);
        self->previousPixelBuffer = nil;
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - [ Public Method ]
#pragma mark Getter
- (NSMutableDictionary<NSString *,NSValue *> *)pixelBufferPoolDict {
    if (_pixelBufferPoolDict == nil) {
        _pixelBufferPoolDict = [NSMutableDictionary dictionary];
    }
    return _pixelBufferPoolDict;
}

#pragma mark Setter
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

#pragma mark - [ Private Method ]
- (void)setupSampleBufferDisplayLayer {
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    self.sampleBufferDisplayLayer.frame = self.bounds;
    self.sampleBufferDisplayLayer.position = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
    [CATransaction commit];
    
    [self addObserver];
}

/// 添加通知
- (void)addObserver{
    if (!self->hasAddObserver){
        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
        [notificationCenter removeObserver:self];
        [notificationCenter addObserver:self selector:@selector(didResignActive) 
                                   name:UIApplicationWillResignActiveNotification object:nil];
        [notificationCenter addObserver:self selector:@selector(didEnterBackground)
                                   name:UIApplicationDidEnterBackgroundNotification object:nil];
        [notificationCenter addObserver:self selector:@selector(dieBecomeActive)
                                   name:UIApplicationDidBecomeActiveNotification object:nil];
        self->hasAddObserver = YES;
    }
}

/// 设置占位图片
- (void)setupPlayerBackgroundImage{
    @synchronized(self) {
        if (self->previousPixelBuffer){
            self.image = [self getUIImageFromPixelBuffer:CVBufferRetain(self->previousPixelBuffer)];
            CFRelease(self->previousPixelBuffer);
            self->previousPixelBuffer = nil;
        }
    }
}


/// 包装成 CMSampleBufferRef 送入渲染
-(void)displayPixelBuffer:(CVPixelBufferRef)decodePixelBuffer isToolBox:(BOOL)isToolBox {
    CVPixelBufferRef pixelBuffer = [self fixAndCopyPixelBuffer:decodePixelBuffer];
    if (!pixelBuffer){
//        PLV_LOG_ERROR(PLVConsoleLogModuleTypePlayer, @"PLVPlayer - %s failed, pixel_buffer illegal:%@", __FUNCTION__, decodePixelBuffer);
        return;
    }
    
    @synchronized(self) {
        if (self->previousPixelBuffer){
            CFRelease(self->previousPixelBuffer);
            self->previousPixelBuffer = nil;
        }
        self->previousPixelBuffer = (void *)CFRetain(pixelBuffer);
    }
    
    //已解码，不需要设置具体时间信息。
    CMSampleTimingInfo timing = {kCMTimeInvalid, kCMTimeInvalid, kCMTimeInvalid};
    
    //获取视频信息
    CMVideoFormatDescriptionRef videoInfo = NULL;
    OSStatus result = CMVideoFormatDescriptionCreateForImageBuffer(NULL, pixelBuffer, &videoInfo);
    NSParameterAssert(result == 0 && videoInfo != NULL);
    
    //创建CMSampleBufferRef
    CMSampleBufferRef sampleBuffer = NULL;
    result = CMSampleBufferCreateForImageBuffer(kCFAllocatorDefault,pixelBuffer, true, NULL, NULL, videoInfo, &timing, &sampleBuffer);
    NSParameterAssert(result == 0 && sampleBuffer != NULL);
    CFRelease(pixelBuffer);
    CFRelease(videoInfo);
    if (!isToolBox) {
        CFRelease(decodePixelBuffer);
    }
    
    // 设置参数，让渲染器尽快渲染
    CFArrayRef attachments = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, YES);
    CFMutableDictionaryRef dict = (CFMutableDictionaryRef)CFArrayGetValueAtIndex(attachments, 0);
    CFDictionarySetValue(dict, kCMSampleAttachmentKey_DisplayImmediately, kCFBooleanTrue);
    
    if (sampleBuffer) {
        // 渲染器错误的时候，清空渲染数据
        if (self.sampleBufferDisplayLayer.status == AVQueuedSampleBufferRenderingStatusFailed) {
            [self.sampleBufferDisplayLayer flush];
        }
        
        [self.sampleBufferDisplayLayer enqueueSampleBuffer:sampleBuffer];
        if (self.sampleBufferDisplayLayer.status == AVQueuedSampleBufferRenderingStatusFailed){
//            PLV_LOG_ERROR(PLVConsoleLogModuleTypePlayer, @"PLVPlayer - %s failed, AVSampleBufferDisplayLayer ERROR: %@", __FUNCTION__, self.sampleBufferDisplayLayer.error);
            if (-11847 == self.sampleBufferDisplayLayer.error.code){
                [self rebuildSampleBufferDisplayLayer];
            }
        }
    } else {
//        PLV_LOG_ERROR(PLVConsoleLogModuleTypePlayer, @"PLVPlayer - %s failed, ignore null samplebuffer", __FUNCTION__);

    }
    CFRelease(sampleBuffer);
}

/// 为渲染修正色域、矩阵、传输函数
- (CVPixelBufferRef)fixAndCopyPixelBuffer:(CVPixelBufferRef)decodePixelBuffer {
    if (!decodePixelBuffer){
        return nil;
    }
    
    CVPixelBufferLockBaseAddress(decodePixelBuffer, 0);
    int bufferWidth = (int)CVPixelBufferGetWidth(decodePixelBuffer);
    int bufferHeight = (int)CVPixelBufferGetHeight(decodePixelBuffer);
    
    // 创建包含IOSurfaceProperties的 CVPixelBuffer
    CVPixelBufferRef pixelBuffer = NULL;
    NSDictionary *pixelAttributes = @{(NSString *)kCVPixelBufferIOSurfacePropertiesKey:@{}};
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault, bufferWidth, bufferHeight, kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange, (__bridge CFDictionaryRef)(pixelAttributes), &pixelBuffer);
    if (status != kCVReturnSuccess) {
//        PLV_LOG_ERROR(PLVConsoleLogModuleTypePlayer, @"PLVPlayer - %s failed, Unable to create cvpixelbuffer %d", __FUNCTION__, status);
        CVPixelBufferUnlockBaseAddress(decodePixelBuffer, 0);
        return nil;
    }
    
    // 手动改色域、矩阵、函数为2020
    CVBufferSetAttachment(pixelBuffer, kCVImageBufferChromaLocationBottomFieldKey, kCVImageBufferChromaLocation_Left, kCVAttachmentMode_ShouldPropagate);
    CVBufferSetAttachment(pixelBuffer, kCVImageBufferChromaLocationTopFieldKey, kCVImageBufferChromaLocation_Left, kCVAttachmentMode_ShouldPropagate);
    
    // 逐平面拷贝 pixelBuffer（NV12 格式是 bi-planar，有 Y 平面和 UV 平面）
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    
    size_t planeCount = CVPixelBufferGetPlaneCount(decodePixelBuffer);
    for (size_t planeIndex = 0; planeIndex < planeCount; planeIndex++) {
        size_t height = CVPixelBufferGetHeightOfPlane(decodePixelBuffer, planeIndex);
        size_t srcBytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(decodePixelBuffer, planeIndex);
        size_t dstBytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, planeIndex);
        
        uint8_t *srcPlaneAddress = CVPixelBufferGetBaseAddressOfPlane(decodePixelBuffer, planeIndex);
        uint8_t *dstPlaneAddress = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, planeIndex);
        
        // 逐行拷贝（处理 bytesPerRow 可能不同的情况）
        size_t copyBytesPerRow = MIN(srcBytesPerRow, dstBytesPerRow);
        for (size_t row = 0; row < height; row++) {
            memcpy(dstPlaneAddress + row * dstBytesPerRow, 
                   srcPlaneAddress + row * srcBytesPerRow, 
                   copyBytesPerRow);
        }
    }

    CVPixelBufferUnlockBaseAddress(decodePixelBuffer, 0);
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    
    return pixelBuffer;
}

/// 重建渲染
- (void)rebuildSampleBufferDisplayLayer{
    @synchronized(self) {
        [self teardownSampleBufferDisplayLayer];
        [self setupSampleBufferDisplayLayer];
    }
}

/// 停止渲染
- (void)teardownSampleBufferDisplayLayer {
    if (self.sampleBufferDisplayLayer){
        [self.sampleBufferDisplayLayer stopRequestingMediaData];
    }
}

/// pixelBuffer 渲染为占位图片
- (UIImage*)getUIImageFromPixelBuffer:(CVPixelBufferRef)pixelBuffer {
    UIImage *uiImage = nil;
    if (pixelBuffer){
        CVPixelBufferLockBaseAddress(pixelBuffer, 0);
        
        int bufferWidth = (int)CVPixelBufferGetWidth(pixelBuffer);
        int bufferHeight = (int)CVPixelBufferGetHeight(pixelBuffer);
        CGRect bufferFrame = CGRectMake(0, 0, bufferWidth, bufferHeight);
        
        CIImage *ciImage = [CIImage imageWithCVPixelBuffer:pixelBuffer];
        uiImage = [UIImage imageWithCIImage:ciImage];
        UIGraphicsBeginImageContext(bufferFrame.size);
        [uiImage drawInRect:bufferFrame];
        uiImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    }
    return uiImage;
}

/// 从缓冲池中创建 PixelBuffer
- (CVPixelBufferRef)creatPixelBuffer:(IJKOverlay *)overlay {
    int width = overlay->w;
    int height = overlay->h;
    CVPixelBufferPoolRef pixelBufferPool = NULL;
    NSString *key = [NSString stringWithFormat:@"%d_%d", height, width];
    NSValue *bufferPoolAddress = [self.pixelBufferPoolDict objectForKey:key];
    
    if (!bufferPoolAddress) {
        pixelBufferPool = [self createPixelBufferPoolWithHeight:height width:width];
        bufferPoolAddress = [NSValue valueWithPointer:pixelBufferPool];
        [self.pixelBufferPoolDict setValue:bufferPoolAddress forKey:key];
    }else {
        pixelBufferPool = [bufferPoolAddress pointerValue];
    }
    
    CVPixelBufferRef pixelBuffer = NULL;
    CVReturn ret = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pixelBufferPool, &pixelBuffer);
    if (ret != kCVReturnSuccess || !pixelBuffer) {
        NSLog(@"Failed to create CVPixelBuffer.");
        return NULL;
    }

    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    void *yDestPlane = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
    void *uvDestPlane = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1);
    int yStride = (int) CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0);
    int uvStride = (int) CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 1);
    for (int i = 0; i < height; i++) {
        memcpy(yDestPlane + i * yStride, overlay->pixels[0] + i * overlay->pitches[0], width);
    }
    if (overlay->format == _FCCNV12Format || overlay->planes == 2) {
        for (int i = 0; i < height / 2; i++) {
            memcpy(uvDestPlane + i * uvStride, overlay->pixels[1] + i * overlay->pitches[1], width);
        }
    } else if (overlay->format == _FCCI420Format || overlay->planes == 3) {
        for (int i = 0; i < height / 2; i++) {
            for (int j = 0; j < width / 2; j++) {
                memcpy(uvDestPlane + i * uvStride + j * 2, overlay->pixels[1] + i * overlay->pitches[1] + j, 1);
                memcpy(uvDestPlane + i * uvStride + j * 2 + 1, overlay->pixels[2] + i * overlay->pitches[2] + j, 1);
            }
        }
    }
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);

    return pixelBuffer;
}

/// 创建缓存池
- (CVPixelBufferPoolRef)createPixelBufferPoolWithHeight:(int)height width:(int)width {
    CVPixelBufferPoolRef pool = NULL;
    NSMutableDictionary* attributes = [NSMutableDictionary dictionary];
    
    [attributes setObject:[NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange] forKey:(NSString*)kCVPixelBufferPixelFormatTypeKey];
    [attributes setObject:[NSNumber numberWithInt:width] forKey: (NSString*)kCVPixelBufferWidthKey];
    [attributes setObject:[NSNumber numberWithInt:height] forKey: (NSString*)kCVPixelBufferHeightKey];
        
    CVReturn ret = CVPixelBufferPoolCreate(kCFAllocatorDefault, NULL, (__bridge CFDictionaryRef)attributes, &pool);
    if (ret != kCVReturnSuccess){
        NSLog(@"Create pixbuffer pool failed %d", ret);
        return NULL;
    }
    
    CVPixelBufferRef buffer;
    ret = CVPixelBufferPoolCreatePixelBuffer(NULL, pool, &buffer);
    if (ret != kCVReturnSuccess){
        NSLog(@"Create pixbuffer from pixelbuffer pool failed %d", ret);
        return NULL;
    }
    
    return pool;
}

#pragma mark -- IJKSDLGLViewProtocol --
- (void)display_pixels:(IJKOverlay *)overlay {
//    NSLog(@"display_pixels - overlay- width: %d, height: %d, planes:%d", overlay->w, overlay->h, overlay->planes);
    if (_background && !self.enablePIPInBackground) return;
    
    BOOL isToolBox = YES;
    if (overlay->format != _toolBoxFormat) {
        // 如果软解码，则创建 PixelBuffer
        isToolBox = NO;
        overlay->pixel_buffer = [self creatPixelBuffer:overlay];
    }
    if ([[NSThread currentThread] isMainThread]) {
        [self displayPixelBuffer:overlay->pixel_buffer isToolBox:isToolBox];
    } else {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self displayPixelBuffer:overlay->pixel_buffer isToolBox:isToolBox];
        });
    }
    
    if (!self->firsFrameRendered){
        self->firsFrameRendered = YES;
        if (self.delegate && [self.delegate respondsToSelector:@selector(sampleBufferDisplayViewFirstFrameRendered:)]){
            [self.delegate sampleBufferDisplayViewFirstFrameRendered:self];
        }
    }
}

- (UIImage *)snapshot {
    @synchronized(self) {
        if (self->previousPixelBuffer) {
            // TODO: 注意内存泄露
//            UIImage *image = [self getUIImageFromPixelBuffer:CVBufferRetain(self->previousPixelBuffer)];
            UIImage *image = [self getUIImageFromPixelBuffer:self->previousPixelBuffer];

            // 此处无需释放
//            CFRelease(self->previousPixelBuffer);
//            self->previousPixelBuffer = nil;
            return image;
        }
        return nil;
    }
}

#pragma mark -- NSNotification
- (void)didResignActive {
    [self setupPlayerBackgroundImage];
}

- (void)didEnterBackground{
    _background = YES;
}

- (void)dieBecomeActive{
    _background = NO;
}

#endif

@end
