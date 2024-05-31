//
//  PLVStreamerPopoverView.m
//  PolyvLiveScenesDemo
//
//  Created by Sakya on 2024/5/13.
//  Copyright © 2024 PLV. All rights reserved.
//

#import "PLVStreamerPopoverView.h"

@interface PLVStreamerPopoverView()

#pragma mark UI
@property (nonatomic, strong) PLVStreamerInteractGenericView *interactView;

@end

@implementation PLVStreamerPopoverView

#pragma mark - init
- (instancetype)init {
    self = [super init];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    [self addSubview:self.interactView];
}

#pragma mark - layout
- (void)layoutSubviews {
    [super layoutSubviews];
    self.interactView.frame = self.bounds;
}

#pragma mark - [ Override ]

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *hitView = [super hitTest:point withEvent:event];
    if (hitView == self){
        return nil;
    }
    return hitView;
}

#pragma mark - [ Private Method ]

#pragma mark Getter
- (PLVStreamerInteractGenericView *)interactView {
    if (!_interactView) {
        _interactView = [[PLVStreamerInteractGenericView alloc] init];
        _interactView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        [_interactView loadInteractWebView];
    }
    return _interactView;
}

@end
