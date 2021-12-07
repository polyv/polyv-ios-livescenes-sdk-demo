//
//  PLVHCHiClassToast.m
//  PLVLiveScenesDemo
//
//  Created by Sakya on 2021/8/4.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVHCHiClassToast.h"
#import "PLVHCUtils.h"

#import <PLVFoundationSDK/PLVColorUtil.h>

/// Toast最大dismiss  Delay
static double KPLVToastDefaultDismissDelay = 1.5;

@interface PLVHCHiClassToast ()

#pragma mark UI
///toast需要添加到的window
@property (nonatomic, strong, readonly) UIWindow *frontWindow;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UILabel *messageLabel;

#pragma mark 数据
@property (nonatomic, assign) CGSize imageViewSize; // 图片尺寸默认20x20 pt
///淡出的时间器
@property (nonatomic, strong) NSTimer *fadeOutTimer;
///淡入动画时间
@property (nonatomic, assign) NSTimeInterval fadeInAnimationDuration;
///淡出动画时间
@property (nonatomic, assign) NSTimeInterval fadeOutAnimationDuration;
///toast持续时间，默认 KPLVToastDefaultDismissDelay 1.5s
@property (nonatomic, assign) NSTimeInterval dismissTimeInterval;
@property (nonatomic, strong) UIColor *toastBackgroundColor;

@end


@implementation PLVHCHiClassToast

#pragma mark - [ Life Cycle ]

//初始化弹窗主窗口,弹窗底层管理所有弹窗显示隐藏
+ (PLVHCHiClassToast *)sharedView {
    
    static dispatch_once_t once;
    static PLVHCHiClassToast *sharedView;
    
    dispatch_once( &once, ^{
        sharedView = [[self alloc] initWithFrame:[[[UIApplication sharedApplication] delegate] window].bounds];
    });

    return sharedView;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if((self = [super initWithFrame:frame])) {
        self.contentView.alpha = 0.0f;
        self.imageView.alpha = 0.0f;
        self.messageLabel.alpha = 0.0f;
        self.backgroundColor = [UIColor clearColor];

        _dismissTimeInterval = KPLVToastDefaultDismissDelay;
        _imageViewSize = CGSizeMake(20, 20);
        _fadeInAnimationDuration = 0.15;
        _fadeOutAnimationDuration = 0.15;
        _toastBackgroundColor = [PLVColorUtil colorFromHexString:@"#2D3452" alpha:1.0];
    }
    return self;
}

#pragma mark - [ Override ]

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *hitView = [super hitTest:point withEvent:event];
    if (hitView == self) {
        return nil;
    }
    return hitView;
}

#pragma mark - Getter && Setter

- (UIView *)contentView {
    if (!_contentView) {
        _contentView = [UIView new];
        _contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _contentView.layer.cornerRadius = 21.0f;
    }
    if (!_contentView.superview) {
        [self addSubview:_contentView];
    }
    return _contentView;
}

- (UIImageView *)imageView {
    if(_imageView && !CGSizeEqualToSize(_imageView.bounds.size, _imageViewSize)) {
        [_imageView removeFromSuperview];
        _imageView = nil;
    }
    
    if(!_imageView) {
        _imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, _imageViewSize.width, _imageViewSize.height)];
        _imageView.contentMode = UIViewContentModeScaleAspectFill;
    }
    if(!_imageView.superview) {
        [self.contentView addSubview:_imageView];
    }
    
    return _imageView;
}

- (UILabel*)messageLabel {
    if(!_messageLabel) {
        _messageLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _messageLabel.backgroundColor = [UIColor clearColor];
        _messageLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:14.0f];
        _messageLabel.textColor = [PLVColorUtil colorFromHexString:@"#FFFFFF"];
        _messageLabel.textAlignment = NSTextAlignmentCenter;
        _messageLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
        _messageLabel.numberOfLines = 0;
    }
    if(!_messageLabel.superview) {
      [self.contentView addSubview:_messageLabel];
    }

    return _messageLabel;
}

- (UIWindow *)frontWindow {
    if ([UIApplication sharedApplication].delegate.window) {
        return [UIApplication sharedApplication].delegate.window;
    } else {
        if (@available(iOS 13.0, *)) { // iOS 13.0+
            NSArray *array = [[[UIApplication sharedApplication] connectedScenes] allObjects];
            UIWindowScene *windowScene = (UIWindowScene *)array[0];
            UIWindow *window = [windowScene valueForKeyPath:@"delegate.window"];
            if (!window) {
                window = [UIApplication sharedApplication].windows.firstObject;
            }
            return window;
        } else {
            return [UIApplication sharedApplication].keyWindow;
        }
    }
}

- (void)setFadeOutTimer:(NSTimer*)timer {
    if(_fadeOutTimer) {
        [_fadeOutTimer invalidate];
        _fadeOutTimer = nil;
    }
    if(timer) {
        _fadeOutTimer = timer;
    }
}

#pragma mark - [Public]
#pragma mark Show Methods

+ (void)showToastWithMessage:(NSString *)message {
    [[self sharedView] showToastWithType:PLVHCToastTypeText message:message];
}

+ (void)showToastWithType:(PLVHCToastType)type message:(NSString *)message {
    [[self sharedView] showToastWithType:type message:message];
}

+ (void)showToastWithMessage:(NSString *)message delay:(NSTimeInterval)delay {
    [[self sharedView] showToastWithType:PLVHCToastTypeText message:message delay:delay];
}

#pragma mark - [Private]
#pragma mark Show Methods

- (void)showToastWithType:(PLVHCToastType)type message:(NSString *)message {
    [self showToastWithType:type message:message delay:KPLVToastDefaultDismissDelay];
}

- (void)showToastWithType:(PLVHCToastType)type message:(NSString *)message delay:(NSTimeInterval)delay {
    self.dismissTimeInterval = delay;
    UIImage *image = [self imageWithType:type];
    [self showToastWithImage:image message:message];
}

- (void)showToastWithImage:(UIImage * _Nullable)image message:(NSString *)message {
    __weak PLVHCHiClassToast *weakSelf = self;
    [[NSOperationQueue mainQueue]  addOperationWithBlock:^{
        __strong PLVHCHiClassToast *strongSelf = weakSelf;
        if (strongSelf) {
            strongSelf.fadeOutTimer = nil;
            [strongSelf updateViewHierarchy];
            [strongSelf updateToastFrame];
            strongSelf.imageView.hidden = YES;
            if (image) {
                strongSelf.imageView.hidden = NO;
                strongSelf.imageView.image = image;
            }
            strongSelf.messageLabel.text = message;
            [strongSelf fadeIn:@(strongSelf.dismissTimeInterval)];
        }
    }];
}

- (void)fadeIn:(id)data {
    [self updateToastFrame];
    [self positionToast];
    id duration = [data isKindOfClass:[NSTimer class]] ? ((NSTimer *)data).userInfo : data;
    if (self.contentView.alpha != 1.0f) {
        [UIView animateWithDuration:self.fadeInAnimationDuration
                              delay:0
                            options:(UIViewAnimationOptions) (UIViewAnimationOptionAllowUserInteraction | UIViewAnimationCurveEaseIn | UIViewAnimationOptionBeginFromCurrentState)
                         animations:^{
            [self fadeInEffects];
                         } completion:^(BOOL finished) {
                             if(self.contentView.alpha == 1.0f){
                                 if(duration){
                                     self.fadeOutTimer = [NSTimer timerWithTimeInterval:[(NSNumber *)duration doubleValue] target:self selector:@selector(dismiss) userInfo:nil repeats:NO];
                                     [[NSRunLoop mainRunLoop] addTimer:self.fadeOutTimer forMode:NSRunLoopCommonModes];
                                 }
                             }
                         }];
    } else {
        if(duration){
            self.fadeOutTimer = [NSTimer timerWithTimeInterval:[(NSNumber *)duration doubleValue] target:self selector:@selector(dismiss) userInfo:nil repeats:NO];
            [[NSRunLoop mainRunLoop] addTimer:self.fadeOutTimer forMode:NSRunLoopCommonModes];
        }
    }
}

- (UIImage *)imageWithType:(PLVHCToastType)type {
    NSString *imageName;
    switch (type) {
        case PLVHCToastTypeIcon_OnStage:
            imageName = @"plvhc_liveroom_toast_onstage_icon";
            break;
        case PLVHCToastTypeIcon_OpenMic:
            imageName = @"plvhc_liveroom_toast_openmic_icon";
            break;
        case PLVHCToastTypeIcon_CloseMic:
        case PLVHCToastTypeIcon_MicAllAanned:
            imageName = @"plvhc_liveroom_toast_closemic_icon";
            break;
        case PLVHCToastTypeIcon_OpenCamera:
            imageName = @"plvhc_liveroom_toast_opencamera_icon";
            break;
        case PLVHCToastTypeIcon_CloseCamera:
            imageName = @"plvhc_liveroom_toast_closecamera_icon";
            break;
        case PLVHCToastTypeIcon_AuthBrush:
            imageName = @"plvhc_liveroom_toast_authbrush_icon";
            break;
        case PLVHCToastTypeIcon_CancelAuthBrush:
            imageName = @"plvhc_liveroom_toast_cancelauthbrush_icon";
            break;
        case PLVHCToastTypeIcon_MicDamage:
            imageName = @"plvhc_liveroom_toast_micdamage_icon";
            break;
        case PLVHCToastTypeIcon_CameraDamage:
            imageName = @"plvhc_liveroom_toast_cameradamage_icon";
            break;
        case PLVHCToastTypeIcon_DocumentCountOver:
        case PLVHCToastTypeIcon_NetworkError:
            imageName = @"plvhc_liveroom_toast_exceptionwarning_icon";
            break;
        case PLVHCToastTypeIcon_CoursewareDelete:
            imageName = @"plvhc_liveroom_toast_delete_icon";
            break;
        case PLVHCToastTypeIcon_AllStepDown:
        case PLVHCToastTypeIcon_StudentStepDown:
            imageName = @"plvhc_liveroom_toast_allstepdown_icon";
            break;
        case PLVHCToastTypeIcon_StudentOnStage:
            imageName = @"plvhc_liveroom_toast_studentonstage_icon";
            break;
        case PLVHCToastTypeIcon_NoStudentOnStage:
            imageName = @"plvhc_liveroom_toast_nostudentonstage_icon";
            break;
        case PLVHCToastTypeIcon_MuteOpen:
            imageName = @"plvhc_liveroom_toast_muteopen_icon";
            break;
        case PLVHCToastTypeIcon_MuteClose:
            imageName = @"plvhc_liveroom_toast_muteclose_icon";
            break;
        case PLVHCToastTypeIcon_StudentMoveOut:
            imageName = @"plvhc_liveroom_toast_studentmoveout_icon";
            break;
        case PLVHCToastTypeIcon_AwardTrophy:
            imageName = @"plvhc_liveroom_toast_awardtrophy_icon";
            break;
        case PLVHCToastTypeIcon_StartGroup:
            imageName = @"plvhc_liveroom_toast_onstage_icon";
        default:
            break;
    }
    if (!imageName) return nil;
    return [PLVHCUtils imageForLiveroomResource:imageName];
}

#pragma mark Dismiss Methods

- (void)dismiss {
    [self dismissWithDelay:0.0 completion:nil];
}

- (void)dismissWithDelay:(NSTimeInterval)delay completion:(void (^)(void))completion {
    __weak PLVHCHiClassToast *weakSelf = self;
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        __strong PLVHCHiClassToast *strongSelf = weakSelf;
        if(strongSelf){
            dispatch_time_t dipatchTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC));
            dispatch_after(dipatchTime, dispatch_get_main_queue(), ^{
                [UIView animateWithDuration:strongSelf.fadeOutAnimationDuration
                                      delay:0
                                    options:(UIViewAnimationOptions) (UIViewAnimationOptionAllowUserInteraction | UIViewAnimationCurveEaseOut | UIViewAnimationOptionBeginFromCurrentState)
                                 animations:^{
                    [strongSelf fadeOutEffects];
                                 } completion:^(BOOL finished) {
                                     if(self.contentView.alpha == 0.0f){
                                         [strongSelf.contentView removeFromSuperview];
                                         [strongSelf removeFromSuperview];
                                                
                                         completion ? completion() : nil;
                                     }
                                 }];
            });
            
            [strongSelf setNeedsDisplay];
        }
    }];
}

- (void)updateToastFrame {
    BOOL imageUsed = (self.imageView.image) && !(self.imageView.hidden);
    
    CGRect labelRect = CGRectZero;
    CGFloat labelHeight = 0.0f;
    CGFloat labelWidth = 0.0f;
    CGFloat toastHorizontalSpacing = 13.0f;
    CGFloat toastVerticalSpacing = 11.0f;
    CGFloat toastLabelSpacing = 9.0f;

    if(self.messageLabel.text) {
        CGSize constraintSize = CGSizeMake(250.0f, CGRectGetHeight(self.bounds)/2);
        labelRect = [self.messageLabel.text boundingRectWithSize:constraintSize
                                                        options:(NSStringDrawingOptions)(NSStringDrawingUsesFontLeading | NSStringDrawingTruncatesLastVisibleLine | NSStringDrawingUsesLineFragmentOrigin)
                                                     attributes:@{NSFontAttributeName: self.messageLabel.font}
                                                        context:NULL];
        labelHeight = ceilf(CGRectGetHeight(labelRect));
        labelWidth = ceilf(CGRectGetWidth(labelRect));
    }
    if (labelHeight > 20) {
        self.contentView.layer.cornerRadius = 8.0f;
    } else {
        self.contentView.layer.cornerRadius = 20.0f;
    }
  
    CGFloat contentWidth = 0.0f;
    CGFloat contentHeight = 0.0f;
    if(imageUsed) {
        contentWidth = CGRectGetWidth(self.imageView.frame);
        contentHeight = CGRectGetHeight(self.imageView.frame);
    }
    contentWidth = contentWidth + labelWidth + toastHorizontalSpacing * 2;
    contentHeight = MAX(contentHeight, labelHeight) + toastVerticalSpacing * 2;
    if(self.messageLabel.text && imageUsed){
        contentWidth += toastLabelSpacing;
    }
    self.contentView.bounds = CGRectMake(0.0f, 0.0f, contentWidth, contentHeight);
    self.contentView.center = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame));
    
    if (imageUsed) {
        self.imageView.center = CGPointMake(CGRectGetMidX(self.imageView.bounds) + toastHorizontalSpacing, CGRectGetMidY(self.contentView.bounds));
    }
    self.messageLabel.frame = labelRect;
    if (imageUsed && self.messageLabel.text) {
        CGFloat centerX = CGRectGetMaxX(self.imageView.frame) + toastLabelSpacing +  CGRectGetMidX(self.messageLabel.bounds);
        self.messageLabel.center = CGPointMake(centerX, CGRectGetMidY(self.contentView.bounds));
    } else {
        self.messageLabel.center = CGPointMake(CGRectGetWidth(self.contentView.bounds)/2, CGRectGetHeight(self.contentView.bounds)/2);
    }
    
}

- (void)updateViewHierarchy {
    if(!self.contentView.superview) {
        [self addSubview:self.contentView];
    }
    if(!self.superview) {
        [self.frontWindow addSubview:self];
    }
}

- (void)positionToast {
    self.frame = [[[UIApplication sharedApplication] delegate] window].bounds;
}

- (void)fadeInEffects {
    self.contentView.backgroundColor = self.toastBackgroundColor;
    self.contentView.alpha = 1.0f;
    self.imageView.alpha = 1.0f;
    self.messageLabel.alpha = 1.0f;
}

- (void)fadeOutEffects {
    self.contentView.backgroundColor = [UIColor clearColor];
    self.contentView.alpha = 0.0f;
    self.imageView.alpha = 0.0f;
    self.messageLabel.alpha = 0.0f;
}

@end
