//
//  PLVLinkMicOnlineUser+HC.m
//  PolyvLiveScenesDemo
//
//  Created by Sakya on 2021/8/26.
//  Copyright © 2021 polyv. All rights reserved.
//

#import "PLVLinkMicOnlineUser+HC.h"
#import <objc/runtime.h>

@implementation PLVLinkMicOnlineUser (HC)

- (PLVHCLinkMicCanvasView *)canvasView {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setCanvasView:(PLVHCLinkMicCanvasView *)canvasView {
    objc_setAssociatedObject(self, @selector(canvasView), canvasView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
