//
//  PLVECLinkMicCanvasView.m
//  PolyvLiveScenesDemo
//
//  Created by Sakya on 2021/10/11.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVECLinkMicCanvasView.h"

#import <PLVFoundationSDK/PLVFoundationSDK.h>

@interface PLVECLinkMicCanvasView ()
/// view hierarchy
///
/// (PLVECLinkMicCanvasView) self
///  └── (UIView) external rtc View
@property (nonatomic, weak) UIView * rtcView; // rtcView (弱引用；仅用作记录)

@end

@implementation PLVECLinkMicCanvasView

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

#pragma mark - [ Public Methods ]
- (void)addRTCView:(UIView *)rtcView{
    plv_dispatch_main_async_safe(^{
        if (rtcView) {
            rtcView.frame = self.bounds;
            rtcView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            [self addSubview:rtcView];
            self.rtcView = rtcView;
        }else{
            NSLog(@"PLVECLinkMicCanvasView - add rtc view failed, rtcView illegal:%@",rtcView);
        }
    })
}

- (void)removeRTCView{
    for (UIView * subview in self.subviews) { [subview removeFromSuperview]; }
}

- (void)rtcViewShow:(BOOL)rtcViewShow{
    if (self.rtcView) {
        self.rtcView.hidden = !rtcViewShow;
    }else{
        NSLog(@"PLVECLinkMicCanvasView - rtcViewShow failed, rtcView is nil");
    }
}

#pragma mark - [ Private Methods ]
- (void)setupUI{
    self.clipsToBounds = YES;
    self.backgroundColor = PLV_UIColorFromRGB(@"2B3145");
}

@end
