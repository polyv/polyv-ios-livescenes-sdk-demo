//
//  PLVLinkMicOnlineUser+SA.m
//  PolyvLiveScenesDemo
//
//  Created by Lincal on 2021/4/10.
//  Copyright © 2021 polyv. All rights reserved.
//

#import "PLVLinkMicOnlineUser+SA.h"
#import <objc/runtime.h>

@implementation PLVLinkMicOnlineUser (SA)

- (PLVSALinkMicCanvasView *)canvasView {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setCanvasView:(PLVSALinkMicCanvasView *)canvasView {
    objc_setAssociatedObject(self, @selector(canvasView), canvasView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
