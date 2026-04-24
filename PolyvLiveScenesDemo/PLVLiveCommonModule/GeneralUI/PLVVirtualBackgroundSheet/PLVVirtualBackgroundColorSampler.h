//
//  PLVVirtualBackgroundColorSampler.h
//  PolyvLiveScenesDemo
//
//  Created by Codex on 2026/4/21.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

NS_INLINE UIColor * _Nullable PLVVirtualBackgroundSampleColor(UIImage *image, CGPoint normalizedPoint) {
    CGImageRef cgImage = image.CGImage;
    if (!cgImage) {
        return nil;
    }
    
    size_t width = CGImageGetWidth(cgImage);
    size_t height = CGImageGetHeight(cgImage);
    if (width == 0 || height == 0) {
        return nil;
    }
    
    CGFloat x = MIN(MAX(normalizedPoint.x, 0.0), 1.0);
    CGFloat y = MIN(MAX(normalizedPoint.y, 0.0), 1.0);
    size_t px = (size_t)(x * (CGFloat)(width - 1));
    size_t py = (size_t)(y * (CGFloat)(height - 1));
    
    CGRect sampleRect = CGRectMake((CGFloat)px, (CGFloat)py, 1, 1);
    CGImageRef sampleImageRef = CGImageCreateWithImageInRect(cgImage, sampleRect);
    if (!sampleImageRef) {
        return nil;
    }
    
    unsigned char pixelData[4] = {0, 0, 0, 0};
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pixelData, 1, 1, 8, 4, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(colorSpace);
    if (!context) {
        CGImageRelease(sampleImageRef);
        return nil;
    }
    
    CGContextDrawImage(context, CGRectMake(0, 0, 1, 1), sampleImageRef);
    CGContextRelease(context);
    CGImageRelease(sampleImageRef);
    
    CGFloat r = pixelData[0] / 255.0;
    CGFloat g = pixelData[1] / 255.0;
    CGFloat b = pixelData[2] / 255.0;
    return [UIColor colorWithRed:r green:g blue:b alpha:1.0];
}

NS_ASSUME_NONNULL_END
