//
//  PLVECSeparateLinkMicView.m
//  PolyvLiveScenesDemo
//
//  Created by Sakya on 2023/6/21.
//  Copyright © 2023 PLV. All rights reserved.
//

#import "PLVECSeparateLinkMicView.h"
#import "PLVECUtils.h"
#import "PLVLinkMicOnlineUser+EC.h"

@interface PLVECSeparateLinkMicView ()

#pragma mark 数据
@property (nonatomic, weak) PLVLinkMicOnlineUser *onlineUser;

#pragma mark UI
@property (nonatomic, weak) UIView *externalView; // 存放单独连麦视图 弱引用
@property (nonatomic, strong) UIView *contentBackgroudView; // 内容背景视图
@property (nonatomic, strong) UILabel *nickNameLabel; // 昵称文本框 (负责展示 用户昵称)
@property (nonatomic, strong) UIImageView *micImageView; // 麦克风视图

@end

@implementation PLVECSeparateLinkMicView

#pragma mark - [ Life Cycle ]
- (instancetype)init {
    self = [super init];
    if (self) {
        self.clipsToBounds = YES;
        self.layer.cornerRadius = 8.0f;
        [self addSubview:self.contentBackgroudView];
        [self addSubview:self.micImageView];
        [self addSubview:self.nickNameLabel];
        self.contentBackgroudView.backgroundColor = [UIColor whiteColor];
        self.frame = CGRectMake([UIScreen mainScreen].bounds.size.width - 90 - 8, [UIScreen mainScreen].bounds.size.height - P_SafeAreaBottomEdgeInsets() - 160 - 148, 90, 160);
        
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureAction:)];
        [self addGestureRecognizer:pan];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];

    CGFloat leftPadding = 8;
    self.contentBackgroudView.frame = self.bounds;
    self.externalView.frame = self.contentBackgroudView.bounds;
    self.micImageView.frame = CGRectMake(leftPadding, self.bounds.size.height - 12 - 14, 14, 14);
    CGFloat nickNameLabelWidth = self.bounds.size.width -  CGRectGetMaxX(self.micImageView.frame) - leftPadding * 2;
    self.nickNameLabel.frame = CGRectMake(CGRectGetMaxX(self.micImageView.frame) + leftPadding, CGRectGetMinY(self.micImageView.frame), nickNameLabelWidth, 14);
}

#pragma mark - [ Public Methods ]
- (void)setUserModel:(PLVLinkMicOnlineUser *)aOnlineUser {
    // 设置数据模型
    self.onlineUser = aOnlineUser;
    // 设置昵称文本
    if (self.onlineUser.actor) {
        self.nickNameLabel.text = [NSString stringWithFormat:@"%@-%@", self.onlineUser.actor, self.onlineUser.nickname];
    } else {
        self.nickNameLabel.text = [NSString stringWithFormat:@"%@%@", self.onlineUser.localUser ? @"(我)" : @"", self.onlineUser.nickname];
    }
    
    __weak typeof(self) weakSelf = self;
    // 设置麦克风开启或关闭状态及状态实时更新block
    self.micImageView.highlighted = !aOnlineUser.currentMicOpen;
    [aOnlineUser addMicOpenChangedBlock:^(PLVLinkMicOnlineUser * _Nonnull onlineUser) {
        plv_dispatch_main_async_safe(^{
            if ([onlineUser.linkMicUserId isEqualToString:weakSelf.onlineUser.linkMicUserId]) {
                weakSelf.micImageView.highlighted = !onlineUser.currentMicOpen;
            }
        })
    } blockKey:self];
    
    // 设置麦克风音量及音量实时更新block
    [self updateMicButtonWithVolume:self.onlineUser.currentVolume];
    aOnlineUser.volumeChangedBlock = ^(PLVLinkMicOnlineUser * _Nonnull onlineUser) {
        if ([onlineUser.linkMicUserId isEqualToString:weakSelf.onlineUser.linkMicUserId]) {
            [weakSelf updateMicButtonWithVolume:onlineUser.currentVolume];
        }
    };
    
    // 摄像画面
    [self displayExternalView:self.onlineUser.canvasView];
    [aOnlineUser.canvasView rtcViewShow:aOnlineUser.currentCameraShouldShow];
    aOnlineUser.cameraShouldShowChangedBlock = ^(PLVLinkMicOnlineUser * _Nonnull onlineUser) {
        [onlineUser.canvasView rtcViewShow:onlineUser.currentCameraShouldShow];
    };
}

- (void)displayExternalView:(UIView *)externalView {
    if (externalView) {
        self.externalView = externalView;
        [self removeSubviewOfView:self.contentBackgroudView];
        [self.contentBackgroudView addSubview:externalView];
        externalView.frame = self.contentBackgroudView.bounds;
        externalView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }
}

#pragma mark - [ Private Methods ]
- (void)removeSubviewOfView:(UIView *)superview{
    for (UIView * subview in superview.subviews) {
        [subview removeFromSuperview];
    }
}

/// 根据音量更新 mic 图标
- (void)updateMicButtonWithVolume:(CGFloat)volume {
    int volumeLevel = ((int)(volume * 100 / 10)) * 10;
    NSString *micImageName = [NSString stringWithFormat:@"plvec_linkmic_mic_volume_%d",volumeLevel];
    UIImage *micImage = [PLVECUtils imageForWatchResource:micImageName];
    [self.micImageView setImage:micImage];
}

#pragma mark - Getter
- (UIView *)contentBackgroudView{
    if (!_contentBackgroudView) {
        _contentBackgroudView = [[UIView alloc]init];
    }
    return _contentBackgroudView;
}

- (UIImageView *)micImageView {
    if (!_micImageView) {
        _micImageView = [[UIImageView alloc] init];
        UIImage *normalImage = [PLVECUtils imageForWatchResource:@"plvec_linkmic_mic_volume_0"];
        UIImage *selectedImage = [PLVECUtils imageForWatchResource:@"plvec_linkmic_window_mic_close"];
        [_micImageView setImage:normalImage];
        [_micImageView setHighlightedImage:selectedImage];
        _micImageView.highlighted= YES;
    }
    return _micImageView;
}

- (UILabel *)nickNameLabel {
    if (!_nickNameLabel) {
        _nickNameLabel = [[UILabel alloc] init];
        _nickNameLabel.font = [UIFont systemFontOfSize:12];
        _nickNameLabel.textColor = [UIColor whiteColor];
    }
    return _nickNameLabel;
}

#pragma mark - [ Event ]
#pragma mark Gesture
- (void)panGestureAction:(UIPanGestureRecognizer *)gesture {
    CGSize screenSize = self.superview.bounds.size;
    CGPoint translatedPoint = [gesture translationInView:[UIApplication sharedApplication].keyWindow];
    CGFloat x = gesture.view.center.x + translatedPoint.x;
    CGFloat y = gesture.view.center.y + translatedPoint.y;
    
    if (gesture.state == UIGestureRecognizerStateBegan || gesture.state == UIGestureRecognizerStateChanged) {
        gesture.view.center = CGPointMake(x, y);
        [gesture setTranslation:CGPointMake(0, 0) inView:[UIApplication sharedApplication].keyWindow];
        return;
    }
    
    CGFloat navigationHeight = [[UIApplication sharedApplication] statusBarFrame].size.height;
    CGFloat width = self.frame.size.width;
    CGFloat height = self.frame.size.height;
    
    // 上下限制 安全距离
    CGFloat maxPointY = screenSize.height - height * 0.5 - P_SafeAreaBottomEdgeInsets();
    CGFloat minPointY = height * 0.5 + navigationHeight;
    if (y > maxPointY) { // 不允许拖离屏幕底部
        y = maxPointY;
    } else if (y < minPointY) { // 不允许往上拖到挡住导航栏
        y = minPointY;
    }
    
    // 左右限制 - 吸边
    if (x < screenSize.width * 0.5) {
        x = 8 + width * 0.5;
    } else {
        x = screenSize.width - width * 0.5 - 8;
    }
    
    gesture.view.center = CGPointMake(x, y);
    [gesture setTranslation:CGPointMake(0, 0) inView:[UIApplication sharedApplication].keyWindow];
}

@end
