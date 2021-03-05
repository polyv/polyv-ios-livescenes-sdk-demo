//
//  PLVLCMediaBrightnessView.m
//  PolyvCloudClassDemo
//
//  Created by zykhbl on 2018/8/14.
//  Copyright © 2018年 polyv. All rights reserved.
//

#import "PLVLCMediaBrightnessView.h"
#import "PLVLCUtils.h"

#define BrightnessViewWidth     155.0
#define BrightnessViewHeight    155.0

@interface PLVLCMediaBrightnessView ()

@property (nonatomic, strong) UILabel *title;
@property (nonatomic, strong) UIImageView *backImgView;
@property (nonatomic, strong) UIView *brightnessLevelView;
@property (nonatomic, strong) NSMutableArray *tipArray;
@property (nonatomic, assign) BOOL addedInSubview;

@end

@implementation PLVLCMediaBrightnessView

#pragma mark - singleton
+ (instancetype)sharedBrightnessView {
    static PLVLCMediaBrightnessView *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[PLVLCMediaBrightnessView alloc] init];
    });
    return instance;
}

#pragma mark - life cycle
- (instancetype)init {
    self = [super init];
    if (self) {
        self.layer.masksToBounds = YES;
        self.layer.cornerRadius = 10.0;
        self.alpha = 0.0;
        
        [self setupUI];
        
        [[UIScreen mainScreen] addObserver:self forKeyPath:@"brightness" options:NSKeyValueObservingOptionNew context:nil];
    }
    return self;
}

- (void)dealloc {
    [[UIScreen mainScreen] removeObserver:self forKeyPath:@"brightness"];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - setup
- (void)setupUI {
    UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0.0, 0.0, BrightnessViewWidth, BrightnessViewHeight)];
    toolbar.backgroundColor = [UIColor colorWithRed:120.0 / 255.0 green:120.0 / 255.0 blue:120.0 / 255.0 alpha:1.0f];
    [self addSubview:toolbar];
    
    self.title = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 5.0, BrightnessViewWidth, 30.0)];
    self.title.font  = [UIFont boldSystemFontOfSize:16.0];
    self.title.textColor = [UIColor colorWithRed:0.25f green:0.22f blue:0.21f alpha:1.0f];
    self.title.textAlignment = NSTextAlignmentCenter;
    self.title.text = @"亮度";
    [self addSubview:self.title];
    
    self.backImgView = [[UIImageView alloc] initWithFrame:CGRectMake((BrightnessViewWidth - 79.0) * 0.5, self.title.frame.origin.y + self.title.frame.size.height + 5.0, 79.0, 76.0)];
    self.backImgView.image = [PLVLCUtils imageForMediaResource:@"plvlc_media_skin_brightness"];
    [self addSubview:self.backImgView];
    
    self.brightnessLevelView = [[UIView alloc] initWithFrame:CGRectMake(13.0, 132.0, BrightnessViewWidth - 26.0, 7.0)];
    self.brightnessLevelView.backgroundColor = [UIColor colorWithRed:0.25f green:0.22f blue:0.21f alpha:1.00f];
    [self addSubview:self.brightnessLevelView];
    [self addSubview:self.brightnessLevelView];
    
    self.tipArray = [NSMutableArray arrayWithCapacity:16];
    CGFloat tipW = (self.brightnessLevelView.bounds.size.width - 17) / 16;
    CGFloat tipH = 5.0;
    CGFloat tipY = 1.0;
    for (int i = 0; i < 16; i++) {
        CGFloat tipX = i * (tipW + 1) + 1;
        UIImageView *imgView = [[UIImageView alloc] init];
        imgView.backgroundColor = [UIColor whiteColor];
        imgView.frame = CGRectMake(tipX, tipY, tipW, tipH);
        [self.brightnessLevelView addSubview:imgView];
        [self.tipArray addObject:imgView];
    }
    [self updateBrightnessLevel:[UIScreen mainScreen].brightness];
}

#pragma mark - show / hide
- (void)showBrightnessView {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideBrightnessView) object:nil];
    
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:0.5 animations:^{
        weakSelf.alpha = 1.0;
    } completion:^(BOOL finished) {
        [weakSelf performSelector:@selector(hideBrightnessView) withObject:nil afterDelay:2.0];
    }];
}

- (void)hideBrightnessView {
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:0.5 animations:^{
        weakSelf.alpha = 0.0;
    } completion:^(BOOL finished) {
        self.addedInSubview = NO;
        [self removeFromSuperview];
    }];
}

- (void)setSelfCenter{
    UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
    CGFloat x = 0.0, y = 0.0;
    if (UIDeviceOrientationIsLandscape(orientation)) {
        x = 1.0;
        y = 1.0;
    } else {
        y = -5.0;
    }
    self.center = CGPointMake(self.superview.center.x + x, self.superview.center.y + y);
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    [self setSelfCenter];
}

#pragma mark - observe & update brightness
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (!self.addedInSubview) {
        self.addedInSubview = YES;
        [[UIApplication sharedApplication].keyWindow addSubview:self];
        
        self.frame = CGRectMake(0, 0, BrightnessViewWidth, BrightnessViewHeight);
        [self setSelfCenter];
    }
    
    [self showBrightnessView];
    [self updateBrightnessLevel:[change[@"new"] floatValue]];
}

- (void)updateBrightnessLevel:(CGFloat)brightness {
    NSInteger level = brightness * 15.0;
    for (NSInteger i = 0; i < self.tipArray.count; i++) {
        UIImageView *imgView = self.tipArray[i];
        if (i <= level) {
            imgView.hidden = NO;
        } else {
            imgView.hidden = YES;
        }
    }
}

@end
