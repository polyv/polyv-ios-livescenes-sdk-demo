//
//  PLVLCLinkMicCanvasView.m
//  PolyvLiveScenesDemo
//
//  Created by Lincal on 2020/9/22.
//  Copyright © 2020 polyv. All rights reserved.
//

#import "PLVLCLinkMicCanvasView.h"

#import "PLVLCUtils.h"
#import <PolyvFoundationSDK/PolyvFoundationSDK.h>

@interface PLVLCLinkMicCanvasView ()

/// view hierarchy
///
/// (PLVLCLinkMicCanvasView) self
///  ├── (UIImageView) placeholderImageView
///  └── (UIView) external rtc View
@property (nonatomic, strong) UIImageView * placeholderImageView; // 背景视图 (负责展示 占位图)
@property (nonatomic, weak) UIView * rtcView; // rtcView (弱引用；仅用作记录)

@end

@implementation PLVLCLinkMicCanvasView

#pragma mark - [ Life Period ]
- (void)dealloc{
    NSLog(@"%s",__FUNCTION__);
}

- (instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        [self setupUI];
    }
    return self;
}


- (void)layoutSubviews{
    CGFloat viewWidth = CGRectGetWidth(self.bounds);
    CGFloat viewHeight = CGRectGetHeight(self.bounds);
    
    CGFloat placeholderImageViewHeight = viewHeight * 0.485;
    self.placeholderImageView.frame = CGRectMake((viewWidth - placeholderImageViewHeight) / 2.0,
                                                 (viewHeight - placeholderImageViewHeight) / 2.0,
                                                 placeholderImageViewHeight,
                                                 placeholderImageViewHeight);
}


#pragma mark - [ Public Methods ]
- (void)addRTCView:(UIView *)rtcView{
    plv_dispatch_main_async_safe(^{
        if (rtcView) {
            rtcView.frame = self.bounds;
            rtcView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            [self addSubview:rtcView];
            self.rtcView = rtcView;
        }else{
            NSLog(@"PLVLCLinkMicWindowCanvasView - add rtc view failed, rtcView illegal:%@",rtcView);
        }
    })
}

- (void)removeRTCView{
    for (UIView * subview in self.subviews) { [subview removeFromSuperview]; }
    [self addSubview:self.placeholderImageView];
}

- (void)rtcViewShow:(BOOL)rtcViewShow{
    if (self.rtcView) {
        self.rtcView.hidden = !rtcViewShow;
    }else{
        NSLog(@"PLVLCLinkMicCanvasView - rtcViewShow failed, rtcView is nil");
    }
}


#pragma mark - [ Private Methods ]
- (void)setupUI{
    self.clipsToBounds = YES;
    self.backgroundColor = UIColorFromRGB(@"2B3145");
    
    /// 添加视图
    [self addSubview:self.placeholderImageView];
}

- (UIImage *)getImageWithName:(NSString *)imageName{
    return [PLVLCUtils imageForLinkMicResource:imageName];
}

#pragma mark Getter
- (UIImageView *)placeholderImageView{
    if (!_placeholderImageView) {
        _placeholderImageView = [[UIImageView alloc]init];
        _placeholderImageView.image = [self getImageWithName:@"plvlc_linkmic_window_placeholder"];
    }
    return _placeholderImageView;
}

@end
