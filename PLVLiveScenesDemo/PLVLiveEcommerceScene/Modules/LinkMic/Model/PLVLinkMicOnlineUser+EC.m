//
//  PLVLinkMicOnlineUser+EC.m
//  PolyvLiveScenesDemo
//
//  Created by Sakya on 2021/10/11.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVLinkMicOnlineUser+EC.h"
#import <objc/runtime.h>

@implementation PLVLinkMicOnlineUser (EC)

- (PLVECLinkMicCanvasView *)canvasView {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setCanvasView:(PLVECLinkMicCanvasView *)canvasView{
    objc_setAssociatedObject(self, @selector(canvasView), canvasView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
