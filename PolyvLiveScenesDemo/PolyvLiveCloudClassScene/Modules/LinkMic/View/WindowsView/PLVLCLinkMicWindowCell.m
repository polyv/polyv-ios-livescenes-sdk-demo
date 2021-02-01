//
//  PLVLCLinkMicWindowCell.m
//  PolyvLiveScenesDemo
//
//  Created by Lincal on 2020/8/6.
//  Copyright © 2020 polyv. All rights reserved.
//

#import "PLVLCLinkMicWindowCell.h"

#import "PLVLCUtils.h"
#import "PLVLinkMicOnlineUser+LC.h"
#import <PolyvFoundationSDK/PolyvFoundationSDK.h>

@interface PLVLCLinkMicWindowCell ()

#pragma mark 状态
@property (nonatomic, assign) PLVLCLinkMicWindowCellLayoutType layoutType;

#pragma mark 数据
@property (nonatomic, weak) PLVLinkMicOnlineUser * userModel;

#pragma mark UI
/// view hierarchy
///
/// 状态一 (显示RTC画面时；contentBackgroudView 在昵称等信息的下层级，保证信息不被遮挡):
/// (PLVLCLinkMicWindowCell) self
/// └── (UIView) contentView
///      ├── (UIView) contentBackgroudView (lowest)
///      │   └── (PLVLCLinkMicCanvasView) canvasView
///      │
///      ├── (CAGradientLayer) shadowLayerLeft
///      ├── (CAGradientLayer) shadowLayer
///      ├── (UIButton) micButton
///      └── (UILabel) nicknameLabel (top)
///
/// 状态二 (显示PPT画面时；contentBackgroudView 将移至最上层，并承载一个未知具体类型的外部view):
/// (PLVLCLinkMicWindowCell) self
/// └── (UIView) contentView
///     ├── (CAGradientLayer) shadowLayerLeft (lowest)
///     ├── (CAGradientLayer) shadowLayer
///     ├── (UIButton) micButton
///     ├── (UILabel) nicknameLabel
///     │
///     └── (UIView) contentBackgroudView (top)
///         └── (UIView) unknown external View
@property (nonatomic, strong) UIView * contentBackgroudView;      // 内容背景视图 (负责承载 不同类型的内容画面[RTC画面、PPT画面]；直接决定了’内容画面‘在Cell中的布局、图层、圆角)
@property (nonatomic, strong) CAGradientLayer * shadowLayerLeft;  // 左边阴影背景 (负责展示 阴影背景)
@property (nonatomic, strong) CAGradientLayer * shadowLayer;      // 阴影背景   (负责展示 阴影背景)
@property (nonatomic, strong) UIButton * micButton;               // 麦克风按钮 (负责展示 不同状态下的麦克风图标)
@property (nonatomic, strong) UILabel * nicknameLabel;            // 昵称文本框 (负责展示 用户昵称)

@end

@implementation PLVLCLinkMicWindowCell

#pragma mark - [ Life Period ]
- (void)dealloc{
    NSLog(@"%s",__FUNCTION__);
}

- (instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        [self setupUI];
    }
    return self;
}

- (void)layoutSubviews{
    [super layoutSubviews];
    CGFloat cellWidth = CGRectGetWidth(self.bounds);
    CGFloat cellHeight = CGRectGetHeight(self.bounds);
    
    self.contentBackgroudView.frame = self.contentView.bounds;
    self.contentBackgroudView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    CGFloat shadowLayerLeftWidth = 16.0;
    self.shadowLayerLeft.frame = CGRectMake(0, 0, shadowLayerLeftWidth, cellHeight);
    
    CGFloat shadowLayerHeight = 24.0;
    self.shadowLayer.frame = CGRectMake(0, cellHeight - shadowLayerHeight, cellWidth, shadowLayerHeight);
    
    CGFloat micButtonHeight = 14.0;
    self.micButton.frame = CGRectMake(4, cellHeight - 3 - micButtonHeight, micButtonHeight, micButtonHeight);
    
    CGFloat nicknameLabelHeight = 17.0;
    self.nicknameLabel.frame = CGRectMake(CGRectGetMaxX(self.micButton.frame) + 2,
                                          cellHeight - 2 - nicknameLabelHeight,
                                          cellWidth - 20 - 8,
                                          nicknameLabelHeight);

    BOOL fullScreen = [UIScreen mainScreen].bounds.size.width > [UIScreen mainScreen].bounds.size.height;
    [self windowCellCornerShow:fullScreen];
}


#pragma mark - [ Public Methods ]
- (void)setModel:(PLVLinkMicOnlineUser *)userModel{
    // 设置
    /// 数据模型
    self.userModel = userModel;
    
    /// 昵称文本
    NSString * actor = [PLVFdUtil checkStringUseable:userModel.actor] ? userModel.actor : @"";
    self.nicknameLabel.text = [PLVFdUtil checkStringUseable:userModel.nickname] ? [NSString stringWithFormat:@"%@%@",actor,userModel.nickname] : [NSString stringWithFormat:@"unknown%@",userModel.linkMicUserId];

    /// 麦克风图标
    self.micButton.selected = !userModel.currentMicOpen;
    __weak typeof(self) weakSelf = self;
    userModel.micOpenChangedBlock = ^(PLVLinkMicOnlineUser * _Nonnull onlineUser) {
        if ([onlineUser.linkMicUserId isEqualToString:weakSelf.userModel.linkMicUserId]) {
            weakSelf.micButton.selected = !onlineUser.currentMicOpen;
        }
    };
    
    /// 摄像画面
    [userModel.canvasView rtcViewShow:userModel.currentCameraShouldShow];
    userModel.cameraShouldShowChangedBlock = ^(PLVLinkMicOnlineUser * _Nonnull onlineUser) {
        [onlineUser.canvasView rtcViewShow:onlineUser.currentCameraShouldShow];
    };
    
    /// 音量
    [self setMicButtonNormalImageWithVolume:userModel.currentVolume];
    userModel.volumeChangedBlock = ^(PLVLinkMicOnlineUser * _Nonnull onlineUser) {
        if ([onlineUser.linkMicUserId isEqualToString:weakSelf.userModel.linkMicUserId]) {
            [weakSelf setMicButtonNormalImageWithVolume:onlineUser.currentVolume];
        }
    };
}

/// 切换至 显示默认内容视图
- (void)switchToShowRtcContentView:(UIView *)rtcCanvasView{
    // 移除 contentBackgroudView 上的外部视图
    [self removeSubview:self.contentBackgroudView];
    
    // contentBackgroudView 移至 contentView 的最底层
    [self.contentView sendSubviewToBack:self.contentBackgroudView];
    
    // contentBackgroudView 承载 rtcCanvasView
    [self contentBackgroudViewAddView:rtcCanvasView];
    
    self.layoutType = PLVLCLinkMicWindowCellLayoutType_Default;
}

/// 切换至 显示外部内容视图
- (void)switchToShowExternalContentView:(UIView *)externalContentView{
    // contentBackgroudView 移至 contentView 的最顶层
    [self.contentView bringSubviewToFront:self.contentBackgroudView];
    
    // contentBackgroudView 承载外部未知具体类型的视图
    [self contentBackgroudViewAddView:externalContentView];

    self.layoutType = PLVLCLinkMicWindowCellLayoutType_External;
}


#pragma mark - [ Private Methods ]
- (UIImage *)getImageWithName:(NSString *)imageName{
    return [PLVLCUtils imageForLinkMicResource:imageName];
}

- (void)removeSubview:(UIView *)superview{
    for (UIView * subview in superview.subviews) { [subview removeFromSuperview]; }
}

- (void)contentBackgroudViewAddView:(UIView *)contentView{
    contentView.frame = self.contentBackgroudView.bounds;
    contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.contentBackgroudView addSubview:contentView];
}

- (void)setMicButtonNormalImageWithVolume:(CGFloat)micVolume{
    int volumeLevel = ((int)(micVolume * 100 / 10)) * 10;
    NSString * micImageName = [NSString stringWithFormat:@"plvlc_linkmic_mic_volume_%d",volumeLevel];
    [self.micButton setImage:[self getImageWithName:micImageName] forState:UIControlStateNormal];
}

- (void)windowCellCornerShow:(BOOL)cornerShow{
    if (cornerShow) {
        self.contentBackgroudView.layer.cornerRadius = 8.0;
    }else{
        self.contentBackgroudView.layer.cornerRadius = 0;
    }
}

#pragma mark UI
- (void)setupUI{
    // 添加 视图
    [self.contentView addSubview:self.contentBackgroudView];
    [self.contentView.layer addSublayer:self.shadowLayerLeft];
    [self.contentView.layer addSublayer:self.shadowLayer];
    [self.contentView addSubview:self.micButton];
    [self.contentView addSubview:self.nicknameLabel];
}

#pragma mark Getter
- (UIView *)contentBackgroudView{
    if (!_contentBackgroudView) {
        _contentBackgroudView = [[UIView alloc]init];
        _contentBackgroudView.clipsToBounds = YES;
    }
    return _contentBackgroudView;
}

- (CAGradientLayer *)shadowLayerLeft{
    if (!_shadowLayerLeft) {
        _shadowLayerLeft = [CAGradientLayer layer];
        _shadowLayerLeft.startPoint = CGPointMake(0, 0.5);
        _shadowLayerLeft.endPoint = CGPointMake(1, 0.5);
        _shadowLayerLeft.colors = @[(__bridge id)[UIColor colorWithRed:0/255.0 green:0/255.0 blue:0/255.0 alpha:0.1].CGColor, (__bridge id)[UIColor colorWithRed:0/255.0 green:0/255.0 blue:0/255.0 alpha:0.0].CGColor];
        _shadowLayerLeft.locations = @[@(0), @(1.0f)];
    }
    return _shadowLayerLeft;
}

- (CAGradientLayer *)shadowLayer{
    if (!_shadowLayer) {
        _shadowLayer = [CAGradientLayer layer];
        _shadowLayer.startPoint = CGPointMake(0.5, 0);
        _shadowLayer.endPoint = CGPointMake(0.5, 1);
        _shadowLayer.colors = @[(__bridge id)[UIColor colorWithRed:0/255.0 green:0/255.0 blue:0/255.0 alpha:0.0].CGColor, (__bridge id)[UIColor colorWithRed:0/255.0 green:0/255.0 blue:0/255.0 alpha:0.7].CGColor];
        _shadowLayer.locations = @[@(0), @(1.0f)];
    }
    return _shadowLayer;
}

- (UIButton *)micButton{
    if (!_micButton) {
        _micButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_micButton setImage:[self getImageWithName:@"plvlc_linkmic_window_mic_open"] forState:UIControlStateNormal];
        [_micButton setImage:[self getImageWithName:@"plvlc_linkmic_window_mic_close"] forState:UIControlStateSelected];
    }
    return _micButton;
}

- (UILabel *)nicknameLabel{
    if (!_nicknameLabel) {
        _nicknameLabel = [[UILabel alloc]init];
        _nicknameLabel.text = @"连麦人昵称";
        _nicknameLabel.textColor = [UIColor whiteColor];
        _nicknameLabel.font = [UIFont fontWithName:@"PingFang SC" size:12];
    }
    return _nicknameLabel;
}

@end
