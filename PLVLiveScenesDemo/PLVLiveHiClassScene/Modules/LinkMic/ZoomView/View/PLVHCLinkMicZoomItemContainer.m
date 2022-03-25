//
//  PLVHCLinkMicZoomItemContainer.m
//  PLVLiveScenesDemo
//
//  Created by lijingtong on 2021/11/15.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVHCLinkMicZoomItemContainer.h"

// UI
#import "PLVHCLinkMicItemView.h"
#import "PLVHCLinkMicTeacherPreView.h"

// 模块
#import "PLVRoomDataManager.h"
#import "PLVHCLinkMicZoomModel.h"


@interface PLVHCLinkMicZoomItemContainer ()

#pragma mark UI

@property (nonatomic, strong) UIView * contentBackgroudView; // 内容背景视图 (负责承载摄像头在放大区域的内容画面)
@property (nonatomic, weak) UIView *externalView; // 存放本地预览视图或连麦视图对象 弱引用

#pragma mark 数据
@property (nonatomic, strong) PLVHCLinkMicZoomModel *zoomModel;

@property (nonatomic, assign) CGPoint lastPoint; // 上一次 移动中心点
@property (nonatomic, assign) CGRect rangeRect; // 用于记录开始时的本视图坐标
@end

@implementation PLVHCLinkMicZoomItemContainer

#pragma mark - [ Life Cycle ]

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.contentBackgroudView.frame = self.bounds;
        self.contentBackgroudView.backgroundColor = PLV_UIColorFromRGB(@"2B3145");
        [self addSubview:self.contentBackgroudView];
        
        if ([PLVRoomDataManager sharedManager].roomData.roomUser.viewerType == PLVRoomUserTypeTeacher) {
            UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureAction:)];
            [self addGestureRecognizer:pan];
            
            UIPinchGestureRecognizer *pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchGestureAction:)];
            [self addGestureRecognizer:pinchGesture];
            
            UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureAction:)];
            [self addGestureRecognizer:tapGesture];
        }
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.contentBackgroudView.frame = self.bounds;
    self.externalView.frame = self.contentBackgroudView.bounds;
}

#pragma mark - [ Override ]
- (void)setTransform:(CGAffineTransform)transform {
    for (UIView *subView in self.subviews) {
        subView.transform = CGAffineTransformInvert(transform); // 子类设置相同的缩放
    }
    [super setTransform:transform];
}

#pragma mark - [ Public Methods ]

- (void)displayExternalView:(UIView *)externalView {
    if (externalView) {
        self.externalView = externalView;
        
        [self removeSubviewOfView:self.contentBackgroudView];
        [self.contentBackgroudView addSubview:externalView];
        externalView.frame = self.contentBackgroudView.bounds;
        externalView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }
}

- (void)setupZoomModel:(PLVHCLinkMicZoomModel *)zoomModel {
    self.zoomModel = zoomModel;
}

#pragma mark - [ Private Methods ]
#pragma mark Getter

- (UIView *)contentBackgroudView{
    if (!_contentBackgroudView) {
        _contentBackgroudView = [[UIView alloc]init];
    }
    return _contentBackgroudView;
}

- (void)removeSubviewOfView:(UIView *)superview{
    for (UIView * subview in superview.subviews) {
        [subview removeFromSuperview];
    }
}

- (void)pinchGestureAction:(UIPinchGestureRecognizer *)pinchGestureRecognizer {
    switch (pinchGestureRecognizer.state) {
        case UIGestureRecognizerStateBegan: // 缩放开始
            [self.superview bringSubviewToFront:self]; // 设置为最最顶层画面
        case UIGestureRecognizerStateChanged: { // 缩放改变
            CGFloat scale = [pinchGestureRecognizer scale]; // 当前的缩放比例
            [pinchGestureRecognizer.view setTransform:CGAffineTransformScale(pinchGestureRecognizer.view.transform, scale, scale)]; // 设置缩放
            [pinchGestureRecognizer setScale:1.0]; // 恢复缩放比例
            
            CGRect rect = self.frame; // 此时已是缩放后的frame
            CGSize superViewSize = self.superview.bounds.size;
            CGFloat viewScale = 16.0 / 9.0;
            CGFloat maxHeight = superViewSize.height; // 初始化最大高度为父视图高度
            CGFloat maxWidth = maxHeight * viewScale;
            CGFloat miniHeight = superViewSize.height * 0.25;
            if (maxWidth > superViewSize.width) { // 最大宽高也需要保证16:9，iPad适配
                maxWidth = superViewSize.width;
                maxHeight = maxWidth / viewScale;
            }
            
            // 不让视图超时父视图处理
            if (rect.origin.x < 0) {
                rect.origin.x = 0;
            }
            
            if (rect.origin.y < 0) {
                rect.origin.y = 0;
            }
            
            if (CGRectGetMaxY(rect) > maxHeight) {
                rect.size.height = maxHeight - rect.origin.y;
            }
            
            if (CGRectGetMaxX(rect) > maxWidth) {
                rect.size.width = maxWidth - rect.origin.x;
            }
            
            // 高度最小值处理
            if (rect.size.height < miniHeight) { // 最小高度
                rect.size.height = miniHeight;
                rect.size.width = miniHeight * viewScale; // 高度
            } else if (rect.size.height >= maxHeight) { // 高度最大值处理
                rect.size.height = maxHeight;
                rect.size.width = maxHeight * viewScale;
                if (rect.size.width > maxWidth) { // 宽度超出最大值处理
                    rect.size.height = maxWidth / viewScale;
                    rect.size.width = maxWidth;
                }
                
                if (rect.origin.x != 0) {
                    rect.origin.x = maxWidth - rect.size.width;
                }
                if (rect.origin.y != 0) {
                    rect.origin.y = maxHeight - rect.size.height;
                }
            } else { // 16:9 等比例缩放
                rect.size.width = rect.size.height * viewScale;
            }
            self.frame = rect;
            [self updateZoomModelFrame:self.frame];
        }
            break;
        case UIGestureRecognizerStateEnded: // 缩放结束
            self.zoomActionBlock ? self.zoomActionBlock(self.zoomModel) : nil;
            break;
            
        default:
            break;
    }
}

- (void)panGestureAction:(UIPanGestureRecognizer *)gestureRecognizer {
    
    CGPoint p = [gestureRecognizer locationInView:self.superview];
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        self.rangeRect = self.superview.bounds;
        [self.superview bringSubviewToFront:self]; // 设置为最最顶层画面
    } else if (gestureRecognizer.state == UIGestureRecognizerStateChanged) {
        CGRect rect = self.frame;
        rect.origin.x += (p.x - self.lastPoint.x);
        rect.origin.y += (p.y - self.lastPoint.y);
        if (rect.origin.x < self.rangeRect.origin.x) {
            rect.origin.x = self.rangeRect.origin.x;
        } else if (rect.origin.x > self.rangeRect.origin.x + self.rangeRect.size.width - rect.size.width) {
            rect.origin.x = self.rangeRect.origin.x + self.rangeRect.size.width - rect.size.width;
        }
        if (rect.origin.y < self.rangeRect.origin.y) {
            rect.origin.y = self.rangeRect.origin.y;
        } else if (rect.origin.y > self.rangeRect.origin.y + self.rangeRect.size.height - rect.size.height) {
            rect.origin.y = self.rangeRect.origin.y + self.rangeRect.size.height - rect.size.height;
        }
        [UIView animateWithDuration:0 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
            self.frame = rect;
            [self updateZoomModelFrame:rect];
        } completion:^(BOOL finished) {}];
        
    } else if(gestureRecognizer.state == UIGestureRecognizerStateEnded) {
        self.moveActionBlock ? self.moveActionBlock(self.zoomModel) : nil;
    }
    self.lastPoint = p;
}

- (void)updateZoomModelFrame:(CGRect)rect{
    self.zoomModel.left = rect.origin.x;
    self.zoomModel.top = rect.origin.y;
    self.zoomModel.width = rect.size.width;
    self.zoomModel.height = rect.size.height;
}

- (void)tapGestureAction:(UITapGestureRecognizer *)gestureRecognizer {
    if (self.tapActionBlock &&
        self.externalView) {
        if ([self.externalView isKindOfClass:[PLVHCLinkMicItemView class]]) {
            PLVHCLinkMicItemView *itemView = (PLVHCLinkMicItemView *)self.externalView;
            self.tapActionBlock(itemView.userModel);
        } else if([self.externalView isKindOfClass:[PLVHCLinkMicTeacherPreView class]]){
            self.tapActionBlock(nil);
        }
    }
}

@end
