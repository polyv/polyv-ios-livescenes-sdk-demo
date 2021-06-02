//
//  PLVLinkMicOnlineUser+LS.m
//  PolyvLiveScenesDemo
//
//  Created by Lincal on 2021/4/10.
//  Copyright © 2021 polyv. All rights reserved.
//

#import "PLVLinkMicOnlineUser+LS.h"
#import <objc/runtime.h>

@implementation PLVLinkMicOnlineUser (LS)

- (PLVLSLinkMicCanvasView *)canvasView {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setCanvasView:(PLVLSLinkMicCanvasView *)canvasView{
    objc_setAssociatedObject(self, @selector(canvasView), canvasView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
