//
//  PLVPopoverView.m
//  PolyvLiveScenesDemo
//
//  Created by jiaweihuang on 2021/2/24.
//  Copyright © 2021 polyv. All rights reserved.
//

#import "PLVPopoverView.h"
#import "PLVGiveRewardPresenter.h"

@interface PLVPopoverView()<PLVGiveRewardViewDelegate>

#pragma mark UI
/// 礼物打赏面板
@property (nonatomic, strong) PLVGiveRewardView *rewardView;
/// 互动视图
@property (nonatomic, strong) PLVInteractGenericView *interactView;

#pragma mark 数据
/// 直播场景
@property (nonatomic, assign) PLVPopoverViewLiveType liveType;
/// 是否是直播房间
@property (nonatomic, assign) BOOL isLiveRoom;
/// 礼物打赏场景类型
@property (nonatomic, assign) PLVRewardViewType rewardType;
/// 互动应用场景类型
@property (nonatomic, assign) PLVInteractGenericViewLiveType interactLiveType;

@end

@implementation PLVPopoverView

#pragma mark - init
- (instancetype)initWithLiveType:(PLVPopoverViewLiveType)liveType liveRoom:(BOOL)liveRoom {
    self = [super init];
    if (self) {
        self.liveType = liveType;
        self.isLiveRoom = liveRoom;
        self.backgroundColor = [UIColor clearColor];
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    [self addSubview:self.interactView];
}

#pragma mark - layout
- (void)layoutSubviews {
    [super layoutSubviews];
    self.interactView.frame = self.bounds;
}

#pragma mark - [ Public Method ]

- (void)loadRewardViewDataWithCompletion:(void (^)(void))completion failure:(void (^)(NSString *))failure {
    [PLVGiveRewardPresenter requestRewardSettingCompletion:^(BOOL rewardEnable, NSString *payWay, NSArray *modelArray, NSString *pointUnit) {
        [self.rewardView layoutIfNeeded];
        self.rewardView.pointUnit = pointUnit;
        [self.rewardView refreshGoods:modelArray];
        if (completion) {
            completion();
        }
        if ([payWay isEqualToString:@"POINT"]) {
            [PLVGiveRewardPresenter requestUserPointCompletion:^(NSString *userPoint) {
                [self.rewardView refreshUserPoint:userPoint];
                if (completion) {
                    completion();
                }
            } failure:^(NSString *error) {
                failure(error);
            }];
        }
    } failure:^(NSString *error) {
        failure(error);
    }];
}

- (void)setRewardViewData:payWay rewardModelArray:(NSArray * _Nullable)modelArray pointUnit:(NSString * _Nullable)pointUnit {
    [self.rewardView layoutIfNeeded];
    self.rewardView.pointUnit = pointUnit;
    self.rewardView.payWay = payWay;
    [self.rewardView refreshGoods:modelArray];
    if ([payWay isEqualToString:@"POINT"]) {
        [PLVGiveRewardPresenter requestUserPointCompletion:^(NSString *userPoint) {
            [self.rewardView refreshUserPoint:userPoint];
        } failure:nil];
    }
}

- (void)showRewardView {
    [self.rewardView showOnView:self];
}

- (void)hidRewardView {
    [self.rewardView hide];
}

#pragma mark - [ Override ]

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *hitView = [super hitTest:point withEvent:event];
    if (hitView == self){
        return nil;
    }
    return hitView;
}

#pragma mark - [ Delegate ]

#pragma mark  PLVGiveRewardViewDelegate

- (void)plvGiveRewardView:(PLVGiveRewardView *)giveRewardView pointRewardWithGoodsModel:(PLVRewardGoodsModel *)goodsModel num:(NSInteger)num {
    [PLVGiveRewardPresenter requestDonatePoint:goodsModel num:num completion:^(NSString *userPoint) {
        [self.rewardView refreshUserPoint:userPoint];
    } failure:^(NSString *error) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(popoverViewDidDonatePointWithError:)]) {
            plv_dispatch_main_async_safe(^{
                [self.delegate popoverViewDidDonatePointWithError:error];
            })
        }
    }];
}

- (void)plvGiveRewardView:(PLVGiveRewardView *)giveRewardView cashRewardWithGoodsModel:(PLVRewardGoodsModel *)goodsModel num:(NSInteger)num {
    [PLVGiveRewardPresenter requestFreeDonate:goodsModel num:num completion:^{
        
    } failure:^(NSString *error) {
            
    }];
}

#pragma mark - [ Private Method ]

#pragma mark Getter

- (PLVGiveRewardView *)rewardView{
    if (!_rewardView) {
        _rewardView = [[PLVGiveRewardView alloc] initWithRewardType:self.rewardType];
        _rewardView.delegate = self;
    }
    return _rewardView;
}

- (PLVInteractGenericView *)interactView {
    if (!_interactView) {
        _interactView = [[PLVInteractGenericView alloc] initWithLiveType:self.interactLiveType liveRoom:self.isLiveRoom];
        _interactView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        [_interactView loadOnlineInteract];
    }
    return _interactView;
}

- (PLVRewardViewType)rewardType {
    return self.liveType == PLVPopoverViewLiveTypeLC ? PLVRewardViewTypeLC : PLVRewardViewTypeEC;
}

- (PLVInteractGenericViewLiveType)interactLiveType {
    return self.liveType == PLVPopoverViewLiveTypeLC ? PLVInteractGenericViewLiveTypeLC : PLVInteractGenericViewLiveTypeEC;
}

@end
