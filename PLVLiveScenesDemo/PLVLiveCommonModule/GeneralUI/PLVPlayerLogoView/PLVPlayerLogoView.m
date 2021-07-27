//
//  PLVPlayerLogo.m
//  PLVLiveScenesDemo
//
//  Created by jiaweihuang on 2020/12/21.
//  Copyright © 2020 PLV. All rights reserved.
//

#import "PLVPlayerLogoView.h"

@implementation PLVPlayerLogoParam

#pragma mark - Life Cycle

- (instancetype)init
{
    self = [super init];
    if (self) {
        _position = PLVPlayerLogoPositionRightUp;
        _logoAlpha = 1.0;
        _xOffsetScale = 0.03;
        _yOffsetScale = 0.06;
    }
    return self;
}

#pragma mark - Getter & Setter

- (void)setLogoUrl:(NSString *)logoUrl {
    NSString *urlString = [logoUrl copy];
    if ([urlString hasPrefix:@"http://"]) {
        urlString = [logoUrl stringByReplacingCharactersInRange:NSMakeRange(0, 4) withString:@"https"];
    }
    _logoUrl = urlString;
}

- (void)setLogoAlpha:(CGFloat)logoAlpha {
    _logoAlpha = MAX(MIN(logoAlpha, 1), 0);
}

- (void)setLogoWidthScale:(CGFloat)logoWidthScale {
    _logoWidthScale = MAX(MIN(logoWidthScale, 1), 0);
}

- (void)setLogoHeightScale:(CGFloat)logoHeightScale {
    _logoHeightScale = MAX(MIN(logoHeightScale, 1), 0);
}


@end

@interface PLVPlayerLogoView ()

@property (nonatomic, strong) UIView *container;

@property (nonatomic, strong) NSMutableArray <UIImageView *> *logos;
@property (nonatomic, strong) NSMutableArray <PLVPlayerLogoParam *> *logoParams;

@end

@implementation PLVPlayerLogoView

#pragma mark - Life Cycle

- (instancetype)init {
    self = [super init];
    if (self) {
        self.clipsToBounds = YES;
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        _logos = [[NSMutableArray alloc] initWithCapacity:2];
        _logoParams = [[NSMutableArray alloc] initWithCapacity:2];
    }
    return self;
}

- (void)layoutSubviews {
    for (int i = 0; i < [self.logos count]; i++) {
        UIImageView *imageView = self.logos[i];
        PLVPlayerLogoParam *param = self.logoParams[i];
        CGRect rect = [self getLogoRectWithParam:param imageSize:imageView.image.size];
        imageView.frame = rect;
    }
}

#pragma mark - Public

- (void)insertLogoWithParam:(PLVPlayerLogoParam *)param {
    while ([self.logos count] >= 2) { // 超过2个logo时，移除第一个logo
        UIImageView *imageView = self.logos[0];
        [imageView removeFromSuperview];
        [self.logos removeObjectAtIndex:0];
        [self.logoParams removeObjectAtIndex:0];
    }
    
    if (param.position == PLVPlayerLogoPositionNone) {
        return;
    }
    
    if (param.logoWidth == 0 && param.logoHeight == 0 &&
        param.logoWidthScale == 0 && param.logoHeightScale == 0) {
        return;
    }
    
    NSString *encodedString = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)param.logoUrl, (CFStringRef)@"!$&'()*+,-./:;=?@_~%#[]", NULL, kCFStringEncodingUTF8));
    NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:encodedString]];
    if (!data) {
        return;
    }
    
    UIImage *image = [UIImage imageWithData:data];
    if (!image) {
        return;
    }
    
    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
    imageView.contentMode = UIViewContentModeScaleToFill;
    imageView.alpha = param.logoAlpha;
    [self addSubview:imageView];
    [self.logos addObject:imageView];
    [self.logoParams addObject:param];
}

- (void)addAtView:(UIView *)container {
    self.frame = container.bounds;
    self.container = container;
    [self.container addSubview:self];
}

#pragma mark - Private

/// 计算 logo frame 值
- (CGRect)getLogoRectWithParam:(PLVPlayerLogoParam *)param imageSize:(CGSize)imageSize {
    CGSize logoSize = [self getLogoSizeWithParam:param imageSize:imageSize];
    CGSize containerSize = self.container.bounds.size;
    CGPoint origin = CGPointZero;
    CGFloat xOffset = self.superview.frame.size.width * param.xOffsetScale;
    CGFloat yOffset = self.superview.frame.size.height * param.yOffsetScale;
    switch (param.position) {
        case PLVPlayerLogoPositionLeftUp:
            origin = CGPointMake(xOffset, yOffset);
            break;
        case PLVPlayerLogoPositionRightUp:
            origin = CGPointMake(containerSize.width - logoSize.width - xOffset, yOffset);
            break;
        case PLVPlayerLogoPositionLeftDown:
            origin = CGPointMake(xOffset, containerSize.height - logoSize.height - yOffset);
            break;
        case PLVPlayerLogoPositionRightDown:
            origin = CGPointMake(containerSize.width - logoSize.width - xOffset, containerSize.height - logoSize.height - yOffset);
            break;
        default:
            break;
    }
    CGRect rect = CGRectMake(origin.x, origin.y, logoSize.width, logoSize.height);
    return rect;
}

/// 计算 logo 大小
- (CGSize)getLogoSizeWithParam:(PLVPlayerLogoParam *)param imageSize:(CGSize)imageSize {
    CGFloat imageScale = imageSize.width / imageSize.height;
    CGSize logoSize = CGSizeZero;
    if (param.logoWidth > 0 && param.logoHeight > 0) { // 获取 logo 尺寸
        logoSize.width = param.logoWidth;
        logoSize.height = param.logoHeight;
    } else if (param.logoWidthScale > 0 && param.logoHeightScale > 0) {
        CGSize containerSize = self.container.bounds.size;
        logoSize.width = containerSize.width * param.logoWidthScale;
        logoSize.height = containerSize.height * param.logoHeightScale;
    }
    
    if (logoSize.width / logoSize.height != imageScale) { // 调整 logo 比例
        CGFloat width = logoSize.height * imageScale;
        CGFloat height = logoSize.width / imageScale;
        if (width <= logoSize.width) {
            logoSize.width = width;
        } else {
            logoSize.height = height;
        }
    }
    return logoSize;
}

@end
