//
//  PLVStickerGestureRecognizer.m
//  PolyvLiveScenesDemo
//
//  Created by polyv on 2025/3/17.
//  Copyright © 2025 PLV. All rights reserved.
//

#import "PLVStickerGestureRecognizer.h"

@interface PLVStickerGestureRecognizer ()

@property (nonatomic, assign) CGPoint startPoint;
@property (nonatomic, assign) CGPoint currentPoint;

@end

@implementation PLVStickerGestureRecognizer

- (instancetype)initWithTarget:(id)target action:(SEL)action anchorView:(UIView *)anchorView {
    self = [super initWithTarget:target action:action];
    if (self) {
        self.anchorView = anchorView;
    }
    return self;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    
    if (touches.count > 1) {
        self.state = UIGestureRecognizerStateFailed;
        return;
    }
    
    UITouch *touch = [touches anyObject];
    self.startPoint = [touch locationInView:self.view.superview];
    self.state = UIGestureRecognizerStateBegan;
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesMoved:touches withEvent:event];
    
    if (self.state == UIGestureRecognizerStateFailed) return;
    
    UITouch *touch = [touches anyObject];
    self.currentPoint = [touch locationInView:self.view.superview];
    self.state = UIGestureRecognizerStateChanged;
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesEnded:touches withEvent:event];
    
    if (self.state == UIGestureRecognizerStateFailed) return;
    
    self.state = UIGestureRecognizerStateEnded;
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesCancelled:touches withEvent:event];
    
    self.state = UIGestureRecognizerStateCancelled;
}

- (void)reset {
    [super reset];
    
    self.startPoint = CGPointZero;
    self.currentPoint = CGPointZero;
}

- (CGPoint)locationInView:(UIView *)view {
    return self.currentPoint;
}

@end
