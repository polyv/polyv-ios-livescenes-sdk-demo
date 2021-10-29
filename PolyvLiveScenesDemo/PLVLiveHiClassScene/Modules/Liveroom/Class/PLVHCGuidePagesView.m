//
//  PLVHCGuidePagesView.m
//  PLVLiveScenesDemo
//
//  Created by Sakya on 2021/7/1.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVHCGuidePagesView.h"

// 工具类
#import "PLVHCUtils.h"

//模块
#import "PLVRoomDataManager.h"

// 依赖库
#import <PLVFoundationSDK/PLVFoundationSDK.h>

static NSString *const kPLVUserDefaultGuidePagesLoaded = @"kPLVUserDefaultGuidePagesLoaded";

/// 引导页结束回调
typedef void (^PLVGuidePagesViewEndBlock)(void);

@interface PLVHCGuidePagesView ()

@property (nonatomic, strong) UIImageView *guideClassImageView;

@property (nonatomic, strong) UIImageView *guideDeviceImageView;

@property (nonatomic, assign) PLVHCGuidePagesType guidePagesType;

@property (nonatomic, strong) UIImageView *classImageView;

@property (nonatomic, copy, nullable) PLVGuidePagesViewEndBlock endBlock; // 引导页展示结束回调

@end

@implementation PLVHCGuidePagesView

#pragma mark - [ Life Cycle ]

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setupUI];
    }
    return self;
}
- (void)layoutSubviews {
    [super layoutSubviews];
    if (_guidePagesType == PLVHCGuidePagesType_Device) {
        self.guideDeviceImageView.center = CGPointMake(self.center.x + 54, 8 + CGRectGetHeight(self.guideDeviceImageView.bounds)/2);
    } else if (_guidePagesType == PLVHCGuidePagesType_BeginClass) {
        UIEdgeInsets edgeInsets = [PLVHCUtils sharedUtils].areaInsets;
        CGFloat edgeInsetsRight = edgeInsets.right > 35 ? edgeInsets.right :35;
        edgeInsetsRight -= 8;
        NSInteger linkNumber = [PLVRoomDataManager sharedManager].roomData.lessonInfo.linkNumber;
        CGFloat linkMicHeight = linkNumber > 6 ? 85 : 60;
        self.classImageView.center = CGPointMake(CGRectGetWidth(self.bounds) - edgeInsetsRight - CGRectGetWidth(self.classImageView.bounds)/2, linkMicHeight + 8 + CGRectGetHeight(self.classImageView.bounds)/2);
        self.guideClassImageView.center = CGPointMake(self.classImageView.frame.origin.x - CGRectGetWidth(self.guideClassImageView.bounds)/2 - 10, self.classImageView.center.y);
    }
}

#pragma mark Getter & Setter

- (UIImageView *)guideClassImageView {
    if (!_guideClassImageView) {
        _guideClassImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 198, 58)];
        _guideClassImageView.image = [PLVHCUtils imageForLiveroomResource:@"plvhc_liveroom_guide_class_icon"];
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 16, 118, 58 - 16 * 2)];
        titleLabel.text = @"点击可以开始上课";
        titleLabel.textColor = [UIColor whiteColor];
        titleLabel.font = [UIFont systemFontOfSize:14.0f];
        [_guideClassImageView addSubview:titleLabel];
    }
    return _guideClassImageView;
}
- (UIImageView *)guideDeviceImageView {
    if (!_guideDeviceImageView) {
        _guideDeviceImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 250, 86)];
        _guideDeviceImageView.image =  [PLVHCUtils imageForLiveroomResource:@"plvhc_liveroom_guide_device_icon"];
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 22, 160, 86 - 22 * 2)];
        titleLabel.text = @"点击可操作老师或学生的麦克风、摄像头等操作";
        titleLabel.textColor = [UIColor whiteColor];
        titleLabel.font = [UIFont systemFontOfSize:14.0f];
        titleLabel.numberOfLines = 0;
        [_guideDeviceImageView addSubview:titleLabel];
    }
    return _guideDeviceImageView;
}
- (UIImageView *)classImageView {
    if (!_classImageView) {
        _classImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 52, 52)];
        _classImageView.image = [PLVHCUtils imageForLiveroomResource:@"plvhc_liveroom_startclass_normal"];
        _classImageView.layer.masksToBounds = YES;
        _classImageView.layer.cornerRadius = 26.0f;
        _classImageView.layer.borderWidth = 8.0f;
        _classImageView.layer.borderColor = [UIColor whiteColor].CGColor;
    }
    return _classImageView;
}

#pragma mark - [ Public Methods ]

+ (void)showGuidePagesViewinView:(UIView *)view
                        endBlock:(void(^ _Nullable)(void))endBlock {
    //判断是否加载过
    BOOL isLoaded = PLV_SafeBoolForValue([[NSUserDefaults standardUserDefaults] objectForKey:kPLVUserDefaultGuidePagesLoaded]);
    if (isLoaded) {
        endBlock ? endBlock() : nil;
        return;
    }
    PLVHCGuidePagesView *guidePagesView = [[PLVHCGuidePagesView alloc] init];
    guidePagesView.backgroundColor = [UIColor colorWithRed:0/255.0 green:0/255.0 blue:0/255.0 alpha:0.75/1.0];
    //设置出事frame
    UIEdgeInsets edgeInsets = [PLVHCUtils sharedUtils].areaInsets;
    NSInteger linkNumber = [PLVRoomDataManager sharedManager].roomData.lessonInfo.linkNumber;
    CGFloat linkMicHeight = linkNumber > 6 ? 85 : 60;
    CGFloat edgeInsetsTop = edgeInsets.top + 24 + linkMicHeight;
    guidePagesView.frame = CGRectMake(0, edgeInsetsTop, CGRectGetWidth(view.bounds), CGRectGetHeight(view.bounds) - edgeInsetsTop);
    guidePagesView.endBlock = endBlock;
    [view addSubview:guidePagesView];
}

#pragma mark - [ Private Methods ]

- (void)setupUI {
    _guidePagesType = PLVHCGuidePagesType_Device;
    UITapGestureRecognizer *tapGusture = [[UITapGestureRecognizer alloc]  initWithTarget:self action:@selector(tapGestureAction)];
    [self addGestureRecognizer:tapGusture];
    [self addSubview:self.guideDeviceImageView];
}

- (void)saveGuidePagesLoadRecord {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:@(YES) forKey:kPLVUserDefaultGuidePagesLoaded];
    [userDefaults synchronize];
}

#pragma mark - [ Event ]

#pragma mark Action

- (void)tapGestureAction {
    if (_guidePagesType == PLVHCGuidePagesType_Device) {
        _guidePagesType = PLVHCGuidePagesType_BeginClass;
        UIEdgeInsets edgeInsets = [PLVHCUtils sharedUtils].areaInsets;
        NSInteger linkNumber = [PLVRoomDataManager sharedManager].roomData.lessonInfo.linkNumber;
        CGFloat linkMicHeight = linkNumber > 6 ? 85 : 60;
        self.frame = CGRectMake(0, edgeInsets.top + 24, CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds) + linkMicHeight);
        [self.guideDeviceImageView removeFromSuperview];
        [self addSubview:self.guideClassImageView];
        [self addSubview:self.classImageView];
    } else if (_guidePagesType == PLVHCGuidePagesType_BeginClass) {
        [self removeFromSuperview];
        [self saveGuidePagesLoadRecord];
        self.endBlock ? self.endBlock() : nil;
    }
}

@end
