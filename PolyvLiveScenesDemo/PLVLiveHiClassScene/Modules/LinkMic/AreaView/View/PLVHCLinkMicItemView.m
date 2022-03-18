//
//  PLVHCLinkMicItemView.m
//  PolyvLiveScenesDemo
//
//  Created by lijingtong on 2021/11/16.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVHCLinkMicItemView.h"

// 工具
#import "PLVHCUtils.h"

// UI
#import"PLVHCLinkMicPlaceholderView.h"

// 模块
#import "PLVLinkMicOnlineUser+HC.h"
#import "PLVHCLinkMicWindowCupView.h"
#import "PLVLinkMicOnlineUser.h"

/// 依赖库
#import <PLVFoundationSDK/PLVFoundationSDK.h>

@interface PLVHCLinkMicItemView ()

#pragma mark UI
/// view hierarchy
///
/// (PLVHCLinkMicItemView) self
///      ├── (UIView) contentBackgroudView (lowest)
///      │   └── (PLVHCLinkMicCanvasView) canvasView
///      │
///      ├── (CAGradientLayer) bottomShadowLayer
///      ├── (PLVHCLinkMicWindowCupView) cupView
///      ├── (UILabel) maxNicknameLabel
///      ├── (UILabel) minNicknameLabel
///      ├── (UIImageView) micImageView
///      ├── (UIImageView) brushImageView
///      ├── (UIImageView) handUpImageView
///      └── (PLVHCLinkMicPlaceholderView) placeholderView (top)

@property (nonatomic, strong) UIView * contentBackgroudView; // 内容背景视图 (负责承载 [RTC画面]，直接决定了’内容画面‘在Cell中的布局、图层、圆角)
@property (nonatomic, strong) CAGradientLayer *bottomShadowLayer;//底部阴影
@property (nonatomic, strong) PLVHCLinkMicWindowCupView *cupView; //奖杯
@property (nonatomic, strong) UILabel *maxNicknameLabel; //大昵称
@property (nonatomic, strong) UILabel *minNicknameLabel; //小昵称
@property (nonatomic, strong) UIImageView *micImageView; //麦克风
@property (nonatomic, strong) UIImageView *brushImageView; //画笔
@property (nonatomic, strong) UIImageView *handUpImageView; //举手
@property (nonatomic, strong) PLVHCLinkMicPlaceholderView *placeholderView; //讲师断开直播的占位图

#pragma mark 数据
@property (nonatomic, weak) PLVLinkMicOnlineUser *userModel;
@property (nonatomic, strong) PLVLinkMicOnlineUserGrantCupCountChangedBlock grantCupCountChangedBlock;
@property (nonatomic, strong) PLVLinkMicOnlineUserBrushAuthChangedBlock brushAuthChangedBlock;
@property (nonatomic, strong) PLVLinkMicOnlineUserMicOpenChangedBlock micOpenChangedBlock;
@property (nonatomic, strong) PLVLinkMicOnlineUserCameraShouldShowChangedBlock cameraShouldShowChangedBlock;

@end

@implementation PLVHCLinkMicItemView

#pragma mark - [ Life Cycle ]

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.contentBackgroudView.frame = self.bounds;
    self.contentBackgroudView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    self.bottomShadowLayer.frame = CGRectMake(0, CGRectGetHeight(self.bounds) - CGRectGetHeight(self.bottomShadowLayer.frame), CGRectGetWidth(self.bounds), CGRectGetHeight(self.bottomShadowLayer.frame));
    [CATransaction commit];
    self.brushImageView.center = CGPointMake(4 + CGRectGetWidth(self.brushImageView.frame)/2, 4 + CGRectGetHeight(self.brushImageView.frame)/2);
    self.maxNicknameLabel.center = self.contentBackgroudView.center;
    self.placeholderView.frame = self.bounds;
    
    self.micImageView.frame = CGRectMake(2, CGRectGetHeight(self.frame) - 2 - CGRectGetHeight(self.micImageView.frame),  CGRectGetWidth(self.micImageView.frame), CGRectGetHeight(self.micImageView.frame));
    self.minNicknameLabel.frame = CGRectMake(CGRectGetMaxX(self.micImageView.frame) + 2, CGRectGetMinY(self.micImageView.frame), CGRectGetWidth(self.frame) - CGRectGetMaxX(self.micImageView.frame) - 4, 10);
    
    self.handUpImageView.frame = CGRectMake(CGRectGetWidth(self.bounds) - CGRectGetWidth(self.handUpImageView.frame) - 14, CGRectGetHeight(self.bounds) - CGRectGetHeight(self.handUpImageView.frame), CGRectGetWidth(self.handUpImageView.frame), CGRectGetHeight(self.handUpImageView.frame));
    [self updateWindowCellLayout];
}

#pragma mark Getter & Setter

- (CAGradientLayer *)bottomShadowLayer {
    if (!_bottomShadowLayer) {
        _bottomShadowLayer = [CAGradientLayer layer];
        _bottomShadowLayer.colors = @[(__bridge id)[PLVColorUtil colorFromHexString:@"#1B202D" alpha:0.0].CGColor, (__bridge id)[PLVColorUtil colorFromHexString:@"#1B202D" alpha:0.8].CGColor];
        _bottomShadowLayer.locations = @[@0.0, @1.0];
        _bottomShadowLayer.startPoint = CGPointMake(0, 0);
        _bottomShadowLayer.endPoint = CGPointMake(0, 1.0);
    }
    return _bottomShadowLayer;
}

- (UIView *)contentBackgroudView{
    if (!_contentBackgroudView) {
        _contentBackgroudView = [[UIView alloc]init];
        _contentBackgroudView.clipsToBounds = YES;
    }
    return _contentBackgroudView;
}

- (PLVHCLinkMicWindowCupView *)cupView {
    if (!_cupView) {
        _cupView = [[PLVHCLinkMicWindowCupView alloc] init];
        _cupView.hidden = YES;
    }
    return _cupView;
}

- (UILabel *)minNicknameLabel {
    if (!_minNicknameLabel) {
        _minNicknameLabel = [[UILabel alloc] init];
        _minNicknameLabel.textColor = [PLVColorUtil colorFromHexString:@"#FFFFFF"];
    }
    return _minNicknameLabel;
}

- (UILabel *)maxNicknameLabel {
    if (!_maxNicknameLabel) {
        _maxNicknameLabel = [[UILabel alloc] init];
        _maxNicknameLabel.textColor = [PLVColorUtil colorFromHexString:@"#FFFFFF"];
        _maxNicknameLabel.textAlignment = NSTextAlignmentCenter;
        _maxNicknameLabel.numberOfLines = 2;
    }
    return _maxNicknameLabel;
}

- (UIImageView *)micImageView {
    if (!_micImageView) {
        _micImageView = [[UIImageView alloc] init];
        _micImageView.image = [PLVHCUtils imageForLinkMicResource:@"plvhc_linkmic_micopen_icon"];
    }
    return _micImageView;
}

- (UIImageView *)brushImageView {
    if (!_brushImageView) {
        _brushImageView = [[UIImageView alloc] init];
        _brushImageView.image = [PLVHCUtils imageForLinkMicResource:@"plvhc_linkmic_brush_icon"];
        _brushImageView.hidden = YES;
    }
    return _brushImageView;
}

- (UIImageView *)handUpImageView {
    if (!_handUpImageView) {
        _handUpImageView = [[UIImageView alloc] init];
        _handUpImageView.image = [PLVHCUtils imageForLinkMicResource:@"plvhc_linkmic_handup_icon"];
        _handUpImageView.hidden = YES;
    }
    return _handUpImageView;
}

- (PLVHCLinkMicPlaceholderView *)placeholderView {
    if (!_placeholderView) {
        _placeholderView = [[PLVHCLinkMicPlaceholderView alloc] init];
        _placeholderView.hidden = YES;
    }
    return _placeholderView;
}

- (PLVLinkMicOnlineUserGrantCupCountChangedBlock)grantCupCountChangedBlock {
    if (!_grantCupCountChangedBlock) {
        __weak typeof(self) weakSelf = self;
        _grantCupCountChangedBlock = ^(PLVLinkMicOnlineUser * _Nonnull onlineUser) {
            if ([onlineUser.userId isEqualToString:weakSelf.userModel.userId]) {
                [weakSelf updateCupViewCount:onlineUser.currentCupCount];
            }
        };
    }
    return _grantCupCountChangedBlock;
}

- (PLVLinkMicOnlineUserBrushAuthChangedBlock)brushAuthChangedBlock {
    if (!_brushAuthChangedBlock) {
        __weak typeof(self) weakSelf = self;
        _brushAuthChangedBlock = ^(PLVLinkMicOnlineUser * _Nonnull onlineUser) {
            if ([onlineUser.userId isEqualToString:weakSelf.userModel.userId]) {
                [weakSelf updateAuthBrushViewShow:onlineUser.currentBrushAuth];
            }
        };
    }
    return _brushAuthChangedBlock;
}

- (PLVLinkMicOnlineUserMicOpenChangedBlock)micOpenChangedBlock {
    if (!_micOpenChangedBlock) {
        __weak typeof(self) weakSelf = self;
        _micOpenChangedBlock = ^(PLVLinkMicOnlineUser * _Nonnull onlineUser) {
            if ([onlineUser.userId isEqualToString:weakSelf.userModel.userId]) {
                [weakSelf setMicImageWithMicOpen:onlineUser.currentMicOpen];
            }
        };
    }
    return _micOpenChangedBlock;
}

- (PLVLinkMicOnlineUserCameraShouldShowChangedBlock)cameraShouldShowChangedBlock {
    if (!_cameraShouldShowChangedBlock) {
        __weak typeof(self) weakSelf = self;
       _cameraShouldShowChangedBlock = ^(PLVLinkMicOnlineUser * _Nonnull onlineUser) {
           if ([onlineUser.userId isEqualToString:weakSelf.userModel.userId]) {
               [weakSelf updateRTCViewWithUser:onlineUser];
           }
       };
    }
    return _cameraShouldShowChangedBlock;
}

#pragma mark - [ Public Method ]

- (void)updateOnlineUser:(PLVLinkMicOnlineUser *)userModel {
    self.userModel = userModel;
    
    // 占位图
    [self.placeholderView setupNicknameWithUserModel:userModel];
    
    userModel.canvasView.frame = self.contentBackgroudView.bounds;
    userModel.canvasView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.contentBackgroudView addSubview:userModel.canvasView];
    
    BOOL isTeacher = userModel.userType == PLVSocketUserTypeTeacher;
    if (userModel.streamLeaveRoom && isTeacher) { // 讲师断开直播 时显示占位图
        self.placeholderView.hidden = NO;
        self.micImageView.hidden = YES;
        [userModel.canvasView removeFromSuperview];
    } else {
        self.placeholderView.hidden = YES;
        self.micImageView.hidden = NO;
    }
        
    NSString *actor = userModel.userType == PLVSocketUserTypeTeacher ? @"老师-" : @"";
    /// 昵称文本
    NSString *nickname = [PLVFdUtil checkStringUseable:userModel.nickname] ? [NSString stringWithFormat:@"%@%@",actor,userModel.nickname] : [NSString stringWithFormat:@"unknown%@",userModel.userId];
    self.minNicknameLabel.text = nickname;
    self.maxNicknameLabel.text = nickname;
    
    /// 麦克风图标
    [self setMicImageWithMicOpen:userModel.currentMicOpen];
    /// 摄像画面
    [self updateRTCViewWithUser:userModel];
    ///授予奖杯
    [self updateCupViewCount:userModel.currentCupCount];
    ///授予画笔，讲师不显示
    [self updateAuthBrushViewShow:userModel.currentBrushAuth && !isTeacher];
    ///举手
    [self updateHandUpViewState:userModel.currentHandUp];

    [self addUserInfoChangedBlock:userModel];
}

#pragma mark - [ Private Method ]

- (void)setupUI {
    [self addSubview:self.contentBackgroudView];
    [self.layer addSublayer:self.bottomShadowLayer];
    [self addSubview:self.brushImageView];
    [self addSubview:self.cupView];
    [self addSubview:self.micImageView];
    [self addSubview:self.minNicknameLabel];
    [self addSubview:self.maxNicknameLabel];
    [self addSubview:self.handUpImageView];
    [self addSubview:self.placeholderView];
}

- (void)setMicImageWithMicOpen:(BOOL)micOpen {
    NSString *micImageName = micOpen ? @"plvhc_linkmic_micopen_icon" : @"plvhc_linkmic_micclose_icon";
    self.micImageView.image = [PLVHCUtils imageForLinkMicResource:micImageName];
}

- (void)updateRTCViewWithUser:(PLVLinkMicOnlineUser * _Nonnull)onlineUser {
    [onlineUser.canvasView rtcViewShow:onlineUser.currentCameraShouldShow];
    if (onlineUser.currentCameraShouldShow) { //显示rtc
        self.minNicknameLabel.hidden = NO;
        self.maxNicknameLabel.hidden = YES;
    } else {
        self.minNicknameLabel.hidden = YES;
        self.maxNicknameLabel.hidden = NO;
    }
    
    if (!self.placeholderView.hidden) { // 显示讲师占位图时，昵称文本均隐藏
        self.minNicknameLabel.hidden = YES;
        self.maxNicknameLabel.hidden = YES;
    }
}

- (void)updateHandUpViewState:(BOOL)handUp {
    self.handUpImageView.hidden = !handUp;
}

- (void)updateCupViewCount:(NSInteger)count {
    [self.cupView updateCupCount:count];
    self.cupView.hidden = !(count > 0);
    [self updateWindowCellLayout];
}

- (void)updateAuthBrushViewShow:(BOOL)show {
    self.brushImageView.hidden = !show;
    [self updateWindowCellLayout];
}

- (void)updateWindowCellLayout {
    if (self.brushImageView.isHidden) {
        self.cupView.center = CGPointMake(4 + CGRectGetWidth(self.cupView.frame)/2, 4 + CGRectGetHeight(self.cupView.frame)/2);
    } else {
        CGPoint cupViewCenter = CGPointMake(CGRectGetMaxX(self.brushImageView.frame) + 4 + CGRectGetWidth(self.cupView.frame)/2, CGRectGetMidY(self.brushImageView.frame));
        self.cupView.center = cupViewCenter;
    }
}

- (void)addUserInfoChangedBlock:(PLVLinkMicOnlineUser *)user {
    //麦克风
    [user addMicOpenChangedBlock:self.micOpenChangedBlock blockKey:self];
    //摄像画面
    [user addCameraShouldShowChangedBlock:self.cameraShouldShowChangedBlock blockKey:self];
    __weak typeof(self) weakSelf = self;
    user.grantCupCountChangedBlock = ^(PLVLinkMicOnlineUser * _Nonnull onlineUser) {
        if ([onlineUser.userId isEqualToString:weakSelf.userModel.userId]) {
            [weakSelf updateCupViewCount:onlineUser.currentCupCount];
        }
    };
    user.handUpChangedBlock = ^(PLVLinkMicOnlineUser * _Nonnull onlineUser) {
        if ([onlineUser.userId isEqualToString:weakSelf.userModel.userId]) {
            [weakSelf updateHandUpViewState:onlineUser.currentHandUp];
        }
    };
    user.brushAuthChangedBlock = ^(PLVLinkMicOnlineUser * _Nonnull onlineUser) {
        if ([onlineUser.userId isEqualToString:weakSelf.userModel.userId]) {
            [weakSelf updateAuthBrushViewShow:onlineUser.currentBrushAuth];
        }
    };
}

@end
