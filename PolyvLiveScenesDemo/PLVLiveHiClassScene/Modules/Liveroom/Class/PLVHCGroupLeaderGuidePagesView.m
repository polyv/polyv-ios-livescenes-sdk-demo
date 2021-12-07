//
//  PLVHCGroupLeaderGuidePagesView.m
//  PLVLiveScenesDemo
//
//  Created by lijingtong on 2021/11/1.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVHCGroupLeaderGuidePagesView.h"

// 工具类
#import "PLVHCUtils.h"

//模块
#import "PLVRoomDataManager.h"

// 依赖库
#import <PLVFoundationSDK/PLVFoundationSDK.h>

static NSString *const kPLVUserDefaultGroupLeaderGuidePagesLoaded = @"kPLVUserDefaultGroupLeaderGuidePagesLoaded";

/// 引导页结束回调
typedef void (^PLVHCGroupLeaderGuidePagesViewEndBlock)(void);

typedef NS_ENUM(NSInteger, PLVHCGroupLeaderGuidePagesType) {
    PLVHCGroupLeaderGuidePagesTypeCalling,
    PLVHCGroupLeaderGuidePagesTypeCancelCalling
};

@interface PLVHCGroupLeaderGuidePagesView()

#pragma mark UI
@property (nonatomic, strong) UIImageView *bgImageView;
@property (nonatomic, strong) UILabel *bgTitleLabel;
@property (nonatomic, strong) UIImageView *guideImageView;

#pragma mark 数据
@property (nonatomic, assign) PLVHCGroupLeaderGuidePagesType guidePagesType;
@property (nonatomic, copy) PLVHCGroupLeaderGuidePagesViewEndBlock endBlock;

@end

@implementation PLVHCGroupLeaderGuidePagesView

#pragma mark - [ Life Cycle ]

- (instancetype)init {
    self = [super init];
    if (self) {
        [self addSubview:self.bgImageView];
        [self addSubview:self.guideImageView];
        [self.bgImageView addSubview:self.bgTitleLabel];
        
        self.userInteractionEnabled = YES;
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureAction)];
        [self addGestureRecognizer:tap];
        
        self.guidePagesType = PLVHCGroupLeaderGuidePagesTypeCalling;
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    UIEdgeInsets edgeInsets = [PLVHCUtils sharedUtils].areaInsets;
    CGFloat edgeInsetsRight = edgeInsets.right > 35 ? edgeInsets.right :35;
    edgeInsetsRight -= 8;
    NSInteger linkNumber = [PLVRoomDataManager sharedManager].roomData.linkNumber;
    CGFloat linkMicHeight = linkNumber > 6 ? 85 : 60;
    self.guideImageView.center = CGPointMake(CGRectGetWidth(self.bounds) - edgeInsetsRight - CGRectGetWidth(self.guideImageView.bounds)/2, linkMicHeight + 8 + CGRectGetHeight(self.guideImageView.bounds)/2);
    self.bgImageView.center = CGPointMake(self.guideImageView.frame.origin.x - CGRectGetWidth(self.bgImageView.bounds)/2 - 10, self.guideImageView.center.y);
    self.bgTitleLabel.frame = self.bgImageView.bounds;
}

#pragma mark - [ Public Methods ]

+ (void)showGuidePagesViewinView:(UIView *)view endBlock:(void (^)(void))endBlock {
    //判断是否加载过
    BOOL isLoaded = [PLVHCGroupLeaderGuidePagesView guidePagesLoadRecord];
    if (isLoaded) {
        endBlock ? endBlock() : nil;
        return;
    }
    PLVHCGroupLeaderGuidePagesView *guidePagesView = [[PLVHCGroupLeaderGuidePagesView alloc] init];
    guidePagesView.backgroundColor = [UIColor colorWithRed:0/255.0 green:0/255.0 blue:0/255.0 alpha:0.75/1.0];
    //设置frame
    UIEdgeInsets edgeInsets = [PLVHCUtils sharedUtils].areaInsets;
    CGFloat edgeInsetsTop = edgeInsets.top + 24;
    guidePagesView.frame = CGRectMake(0, edgeInsetsTop, CGRectGetWidth(view.bounds), CGRectGetHeight(view.bounds) - edgeInsetsTop);
    guidePagesView.endBlock = endBlock;
    [view addSubview:guidePagesView];
}

#pragma mark - [ Private Methods ]
#pragma mark Getter

- (UIImageView *)bgImageView {
    if (!_bgImageView) {
        _bgImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 159, 46)];
        _bgImageView.image = [PLVHCUtils imageForLiveroomResource:@"plvhc_liveroom_guide_callingteacher_bg"];
    }
    return _bgImageView;
}

- (UILabel *)bgTitleLabel {
    if (!_bgTitleLabel) {
        _bgTitleLabel = [[UILabel alloc] init];
        _bgTitleLabel.textColor = [UIColor whiteColor];
        _bgTitleLabel.textAlignment = NSTextAlignmentCenter;
        _bgTitleLabel.text = @"点击可以呼叫老师";
        if (@available(iOS 8.2, *)) {
            _bgTitleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
        } else {
            _bgTitleLabel.font = [UIFont boldSystemFontOfSize:14];
        }
    }
    return _bgTitleLabel;
}

- (UIImageView *)guideImageView {
    if (!_guideImageView) {
        _guideImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 52, 52)];
        _guideImageView.image = [PLVHCUtils imageForLiveroomResource:@"plvhc_liveroom_guied_callingteacher_normal"];
    }
    return _guideImageView;
}

#pragma mark 缓存

+ (BOOL)guidePagesLoadRecord {
    return PLV_SafeBoolForValue([[NSUserDefaults standardUserDefaults] objectForKey:kPLVUserDefaultGroupLeaderGuidePagesLoaded]);
}

- (void)saveGuidePagesLoadRecord {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:@(YES) forKey:kPLVUserDefaultGroupLeaderGuidePagesLoaded];
    [userDefaults synchronize];
}

#pragma mark - [ Event ]
#pragma mark Gesture

- (void)tapGestureAction {
    if (self.guidePagesType == PLVHCGroupLeaderGuidePagesTypeCalling) {
        self.guidePagesType = PLVHCGroupLeaderGuidePagesTypeCancelCalling;
        
        CGRect bgFrame = self.bgImageView.frame;
        bgFrame.origin.x += 172 - bgFrame.origin.x;
        bgFrame.size.width = 172;
        self.bgImageView.frame = bgFrame;
        
        self.bgTitleLabel.text = @"再次点击可以取消操作";
        self.guideImageView.image = [PLVHCUtils imageForLiveroomResource:@"plvhc_liveroom_guied_callingteacher_cancel"];
    } else {
        [self removeFromSuperview];
        [self saveGuidePagesLoadRecord];
        self.endBlock ? self.endBlock() : nil;
    }
}

@end
