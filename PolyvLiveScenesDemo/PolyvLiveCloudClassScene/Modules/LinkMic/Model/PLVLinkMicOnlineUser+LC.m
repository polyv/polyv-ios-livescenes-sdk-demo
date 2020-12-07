//
//  PLVLinkMicOnlineUser+LC.m
//  PolyvLiveScenesDemo
//
//  Created by Lincal on 2020/10/23.
//  Copyright © 2020 polyv. All rights reserved.
//

#import "PLVLinkMicOnlineUser+LC.h"
#import <objc/runtime.h>

@implementation PLVLinkMicOnlineUser (LC)

- (PLVLCLinkMicCanvasView *)canvasView {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setCanvasView:(PLVLCLinkMicCanvasView *)canvasView{
    objc_setAssociatedObject(self, @selector(canvasView), canvasView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
