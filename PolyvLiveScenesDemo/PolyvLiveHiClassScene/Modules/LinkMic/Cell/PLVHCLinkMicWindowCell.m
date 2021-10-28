//
//  PLVHCLinkMicWindowCell.m
//  PolyvLiveScenesDemo
//
//  Created by Sakya on 2021/8/26.
//  Copyright © 2021 polyv. All rights reserved.
//

#import "PLVHCLinkMicWindowCell.h"
#import "PLVHCUtils.h"
#import "PLVLinkMicOnlineUser+HC.h"

/// 依赖库
#import <PLVFoundationSDK/PLVFoundationSDK.h>

@interface PLVHCLinkMicWindowCell ()

#pragma mark UI
/// view hierarchy
///
/// (PLVLCLinkMicWindowCell) self
/// └── (UIView) contentView
///      ├── (UIView) contentBackgroudView (lowest)
///      │   └── (PLVHCLinkMicCanvasView) canvasView
///      │   
///      ├── (CAGradientLayer) bottomShadowLayer
///      ├── (PLVHCLinkMicWindowCupView) cupView
///      ├── (UILabel) maxNicknameLabel
///      ├── (UILabel) minNicknameLabel
///      ├── (UIImageView) micImageView
///      ├── (UIImageView) brushImageView
///      └── (UIImageView) handUpImageView (top)
@property (nonatomic, strong) UIView * contentBackgroudView; // 内容背景视图 (负责承载 [RTC画面]，直接决定了’内容画面‘在Cell中的布局、图层、圆角)
@property (nonatomic, strong) CAGradientLayer *bottomShadowLayer;//底部阴影
@property (nonatomic, strong) PLVHCLinkMicWindowCupView *cupView; //奖杯
@property (nonatomic, strong) UILabel *maxNicknameLabel; //大昵称
@property (nonatomic, strong) UILabel *minNicknameLabel; //小昵称
@property (nonatomic, strong) UIImageView *micImageView; //麦克风
@property (nonatomic, strong) UIImageView *brushImageView; //画笔
@property (nonatomic, strong) UIImageView *handUpImageView; //举手

#pragma mark 数据
@property (nonatomic, weak) PLVLinkMicOnlineUser *userModel;
@property (nonatomic, strong) PLVLinkMicOnlineUserGrantCupCountChangedBlock grantCupCountChangedBlock;
@property (nonatomic, strong) PLVLinkMicOnlineUserBrushAuthChangedBlock brushAuthChangedBlock;
@property (nonatomic, strong) PLVLinkMicOnlineUserMicOpenChangedBlock micOpenChangedBlock;
@property (nonatomic, strong) PLVLinkMicOnlineUserCameraShouldShowChangedBlock cameraShouldShowChangedBlock;

@end

@implementation PLVHCLinkMicWindowCell

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
    
    self.contentBackgroudView.frame = self.contentView.bounds;
    self.contentBackgroudView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    self.bottomShadowLayer.frame = CGRectMake(0, CGRectGetHeight(self.contentView.bounds) - CGRectGetHeight(self.bottomShadowLayer.frame), CGRectGetWidth(self.contentView.bounds), CGRectGetHeight(self.bottomShadowLayer.frame));
    [CATransaction commit];
    self.brushImageView.center = CGPointMake(4 + CGRectGetWidth(self.brushImageView.frame)/2, 4 + CGRectGetHeight(self.brushImageView.frame)/2);
    self.maxNicknameLabel.center = self.contentBackgroudView.center;
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
               [weakSelf updateRTCViewWithUser:onlineUser addView:NO];
           }
       };
    }
    return _cameraShouldShowChangedBlock;
}

#pragma mark - [ Public Method ]

- (void)updateOnlineUser:(PLVLinkMicOnlineUser *)userModel {
    self.userModel = userModel;
 
    NSString *actor = userModel.userType == PLVSocketUserTypeTeacher ? @"老师-" : @"";
    /// 昵称文本
    NSString *nickname = [PLVFdUtil checkStringUseable:userModel.nickname] ? [NSString stringWithFormat:@"%@%@",actor,userModel.nickname] : [NSString stringWithFormat:@"unknown%@",userModel.userId];
    self.minNicknameLabel.text = nickname;
    self.maxNicknameLabel.text = nickname;
    
    /// 麦克风图标
    [self setMicImageWithMicOpen:userModel.currentMicOpen];
    /// 摄像画面
    [self updateRTCViewWithUser:userModel addView:YES];
    ///授予奖杯
    [self updateCupViewCount:userModel.currentCupCount];
    ///授予画笔
    [self updateAuthBrushViewShow:userModel.currentBrushAuth];
    ///举手
    [self updateHandUpViewState:userModel.currentHandUp];

    [self addUserInfoChangedBlock:userModel];
}

#pragma mark - [ Private Method ]

- (void)setupUI {
    [self.contentView addSubview:self.contentBackgroudView];
    [self.contentView.layer addSublayer:self.bottomShadowLayer];
    [self.contentView addSubview:self.brushImageView];
    [self.contentView addSubview:self.cupView];
    [self.contentView addSubview:self.micImageView];
    [self.contentView addSubview:self.minNicknameLabel];
    [self.contentView addSubview:self.maxNicknameLabel];
    [self.contentView addSubview:self.handUpImageView];
}

- (void)setMicImageWithMicOpen:(BOOL)micOpen {
    NSString *micImageName = micOpen ? @"plvhc_linkmic_micopen_icon" : @"plvhc_linkmic_micclose_icon";
    self.micImageView.image = [PLVHCUtils imageForLinkMicResource:micImageName];
}

- (void)updateRTCViewWithUser:(PLVLinkMicOnlineUser * _Nonnull)onlineUser addView:(BOOL)addView {
    [onlineUser.canvasView rtcViewShow:onlineUser.currentCameraShouldShow];
    if (addView) {
        onlineUser.canvasView.frame = self.contentBackgroudView.bounds;
        onlineUser.canvasView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self.contentBackgroudView addSubview:onlineUser.canvasView];
    }
    if (onlineUser.currentCameraShouldShow) { //显示rtc
        self.minNicknameLabel.hidden = NO;
        self.maxNicknameLabel.hidden = YES;
    } else {
        self.minNicknameLabel.hidden = YES;
        self.maxNicknameLabel.hidden = NO;
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
    //授予奖杯
    [user addGrantCupCountChangedBlock:self.grantCupCountChangedBlock blockKey:self];
    //授予画笔
    [user addBrushAuthStateChangedBlock:self.brushAuthChangedBlock blockKey:self];
    //举手
    __weak typeof(self) weakSelf = self;
    user.handUpChangedBlock = ^(PLVLinkMicOnlineUser * _Nonnull onlineUser) {
        [weakSelf updateHandUpViewState:onlineUser.currentHandUp];
    };
}

@end

@interface PLVHCLinkMicWindowCupView ()

#pragma mark UI
@property (nonatomic, strong) UIImageView *imageView; //奖杯
@property (nonatomic, strong) UILabel *countLabel; //奖杯数量
@property (nonatomic, strong) CAGradientLayer *gradientLayer;//背景

@end

@implementation PLVHCLinkMicWindowCupView

#pragma mark - [ Life Cycle ]

- (instancetype)init {
    self = [super init];
    if (self) {
        self.layer.masksToBounds = YES;
        [self.layer addSublayer:self.gradientLayer];
        [self addSubview:self.imageView];
        [self addSubview:self.countLabel];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.layer.cornerRadius = CGRectGetHeight(self.bounds)/2;
    self.gradientLayer.frame = self.bounds;
    self.imageView.frame = CGRectMake(4,(CGRectGetHeight(self.bounds) - 8)/2, 8, 8);
    self.countLabel.frame = CGRectMake(CGRectGetMaxX(self.imageView.frame) + 2 , CGRectGetMinY(self.imageView.frame), 10, 8);
}

#pragma mark Getter & Setter

- (UIImageView *)imageView {
    if (!_imageView) {
        _imageView = [[UIImageView alloc] init];
        _imageView.image = [PLVHCUtils imageForLinkMicResource:@"plvhc_linkmic_cup_icon"];
    }
    return _imageView;
}

- (UILabel *)countLabel {
    if (!_countLabel) {
        _countLabel = [[UILabel alloc] init];
        _countLabel.textColor = [PLVColorUtil colorFromHexString:@"#FFFFFF"];
        _countLabel.font = [UIFont fontWithName:@"DINAlternate-Bold" size:8];
    }
    return _countLabel;
}

- (CAGradientLayer *)gradientLayer {
    if (!_gradientLayer) {
        _gradientLayer = [CAGradientLayer layer];
        _gradientLayer.colors = @[(__bridge id)[PLVColorUtil colorFromHexString:@"#F5BB4B"].CGColor, (__bridge id)[PLVColorUtil colorFromHexString:@"#FFB21F"].CGColor];
        _gradientLayer.locations = @[@0.0, @1.0];
        _gradientLayer.startPoint = CGPointMake(0, 0);
        _gradientLayer.endPoint = CGPointMake(1.0, 0);
    }
    return _gradientLayer;
}

#pragma mark - [ Public Method ]

- (void)updateCupCount:(NSInteger)count {
    count = MIN(99, count);
    self.countLabel.text = [NSString stringWithFormat:@"%ld",(long)count];
}

@end

@implementation PLVHCLinkMicWindowSixCell

#pragma mark - [ Life Cycle ]

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.brushImageView.frame = CGRectMake(0, 0, 14, 14);
        self.cupView.frame = CGRectMake(0, 0, 25, 14);
        self.maxNicknameLabel.frame = CGRectMake(0, 0, 60, 34);
        self.maxNicknameLabel.font = [UIFont systemFontOfSize:14];
        self.minNicknameLabel.font = [UIFont fontWithName:@"PingFangSC-Medium" size:8];
        self.micImageView.frame = CGRectMake(0, 0,  10, 10);
        self.handUpImageView.frame = CGRectMake(0, 0, 22, 24);
        self.bottomShadowLayer.frame = CGRectMake(0, 0, 0, 22);
    }
    return self;
}

#pragma mark - [ Override ]

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.micImageView.frame = CGRectMake(2, CGRectGetHeight(self.bounds) - 2 - CGRectGetHeight(self.micImageView.frame),  CGRectGetWidth(self.micImageView.frame), CGRectGetHeight(self.micImageView.frame));
    self.handUpImageView.frame = CGRectMake(CGRectGetWidth(self.bounds) - CGRectGetWidth(self.handUpImageView.frame) - 14, CGRectGetHeight(self.bounds) - CGRectGetHeight(self.handUpImageView.frame), CGRectGetWidth(self.handUpImageView.frame), CGRectGetHeight(self.handUpImageView.frame));
    self.minNicknameLabel.frame = CGRectMake(CGRectGetMaxX(self.micImageView.frame) + 2, CGRectGetMinY(self.micImageView.frame), CGRectGetWidth(self.bounds) - CGRectGetMaxX(self.micImageView.frame) - 2, CGRectGetHeight(self.micImageView.frame));
}

@end

@implementation PLVHCLinkMicWindowSixteenCell

#pragma mark - [ Life Cycle ]

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.brushImageView.frame = CGRectMake(0, 0, 10, 10);
        self.cupView.frame = CGRectMake(0, 0, 22, 10);
        self.maxNicknameLabel.frame = CGRectMake(0, 0, 38, 30);
        self.maxNicknameLabel.font = [UIFont systemFontOfSize:12];
        self.minNicknameLabel.font = [UIFont fontWithName:@"PingFangSC-Medium" size:7];
        self.micImageView.frame = CGRectMake(0, 0,  8, 8);
        self.handUpImageView.frame = CGRectMake(0, 0, 20, 22);
        self.bottomShadowLayer.frame = CGRectMake(0, 0, 0, 18);
    }
    return self;
}

#pragma mark - [ Override ]

- (void)layoutSubviews {
    [super layoutSubviews];

    self.micImageView.frame = CGRectMake(4, CGRectGetHeight(self.bounds) - 4 - CGRectGetHeight(self.micImageView.frame),  CGRectGetWidth(self.micImageView.frame), CGRectGetHeight(self.micImageView.frame));
    self.handUpImageView.frame = CGRectMake(CGRectGetWidth(self.bounds) - CGRectGetWidth(self.handUpImageView.frame) - 8, CGRectGetHeight(self.bounds) - CGRectGetHeight(self.handUpImageView.frame), CGRectGetWidth(self.handUpImageView.frame), CGRectGetHeight(self.handUpImageView.frame));
    self.minNicknameLabel.frame = CGRectMake(CGRectGetMaxX(self.micImageView.frame) + 2, CGRectGetMinY(self.micImageView.frame), CGRectGetWidth(self.bounds) - CGRectGetMaxX(self.micImageView.frame) - 2, CGRectGetHeight(self.micImageView.frame));
}

@end

@implementation PLVHCLinkMicWindowSixteenTeacherCell

#pragma mark - [ Life Cycle ]

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.maxNicknameLabel.frame = CGRectMake(0, 0, 94, 40);
        self.maxNicknameLabel.font = [UIFont systemFontOfSize:14];
        self.minNicknameLabel.font = [UIFont fontWithName:@"PingFangSC-Medium" size:8];
        self.micImageView.frame = CGRectMake(0, 0,  10, 10);
        self.bottomShadowLayer.frame = CGRectMake(0, 0, 0, 22);
    }
    return self;
}
#pragma mark - [ Override ]

- (void)layoutSubviews {
    [super layoutSubviews];

    self.micImageView.frame = CGRectMake(2, CGRectGetHeight(self.bounds) - 2 - CGRectGetHeight(self.micImageView.frame),  CGRectGetWidth(self.micImageView.frame), CGRectGetHeight(self.micImageView.frame));
    self.minNicknameLabel.frame = CGRectMake(CGRectGetMaxX(self.micImageView.frame) + 2, CGRectGetMinY(self.micImageView.frame), CGRectGetWidth(self.bounds) - CGRectGetMaxX(self.micImageView.frame) - 4, 10);
}

@end
