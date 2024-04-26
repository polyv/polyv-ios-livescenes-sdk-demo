//
//  PLVRewardDisplayManager.m
//  PolyvCloudClassDemo
//
//  Created by Lincal on 2019/12/5.
//  Copyright © 2019 polyv. All rights reserved.
//

#import "PLVRewardDisplayManager.h"
#import "PLVRewardDisplayTask.h"
#import "PLVRewardSvgaTask.h"

static const NSInteger PLVDisplayRailNum = 2;
static const NSInteger PLVSvgaRailNum = 1;

@interface PLVRewardDisplayManager ()

/// 直播场景
@property (nonatomic, assign) PLVRewardDisplayManagerType liveType;
@property (nonatomic, strong) NSOperationQueue * displayQueue;
@property (nonatomic, strong) NSOperationQueue * svgaQueue;
@property (nonatomic, strong) NSMutableDictionary * displayRailDict;

@end

@implementation PLVRewardDisplayManager

#pragma mark - init
- (instancetype)initWithLiveType:(PLVRewardDisplayManagerType)liveType {
    self = [super init];
    if (self) {
        self.liveType = liveType;
    }
    return self;
}

#pragma mark - [ Private Methods ]
- (NSInteger)arrangeDisplayRailWithItem:(PLVRewardGoodsModel *)model{
    NSInteger index = -1;
    for (int i = 0; i < self.displayRailDict.allKeys.count; i++) {
        NSString * key = self.displayRailDict.allKeys[i];
        id obj = [self.displayRailDict objectForKey:key];
        if ([obj isKindOfClass:NSNull.class]) {
            index = i;
            [self.displayRailDict setValue:model forKey:key];
            break;
        }
    }
    return index;
}

- (void)removeDisplayItemWithRailIndex:(NSInteger)index{
    if (index < self.displayRailDict.allKeys.count) {
        [self.displayRailDict setValue:[NSNull null] forKey:[NSString stringWithFormat:@"%ld",index]];
    }
}

#pragma mark Getter
- (NSOperationQueue *)displayQueue{
    if (!_displayQueue) {
        _displayQueue = [[NSOperationQueue alloc]init];
        _displayQueue.maxConcurrentOperationCount = PLVDisplayRailNum;
        _displayQueue.name = @"com.polyv.displayQueue";
    }
    return _displayQueue;
}

- (NSOperationQueue *)svgaQueue{
    if (!_svgaQueue) {
        _svgaQueue = [[NSOperationQueue alloc]init];
        _svgaQueue.maxConcurrentOperationCount = PLVSvgaRailNum;
        _svgaQueue.name = @"com.polyv.svgaQueue";
    }
    return _svgaQueue;
}

- (NSMutableDictionary *)displayRailDict{
    if (!_displayRailDict) {
        _displayRailDict = [[NSMutableDictionary alloc]init];
        NSInteger i = 0;
        while (i < PLVDisplayRailNum) {
            [_displayRailDict setValue:[NSNull null] forKey:[NSString stringWithFormat:@"%ld",i]];
            i ++;
        }
    }
    return _displayRailDict;
}


#pragma mark - [ Public Methods ]
- (void)addGoodsShowWithModel:(PLVRewardGoodsModel *)model goodsNum:(NSInteger)num personName:(NSString *)peopleName{
    if (!self.superView || ![self.superView isKindOfClass:UIView.class]) { return; }
    
    // 横幅
    PLVRewardDisplayTask * displayTask = [[PLVRewardDisplayTask alloc]init];
    displayTask.model = model;
    displayTask.goodsNum = num;
    displayTask.personName = peopleName;
    displayTask.superView = self.superView;
    displayTask.fullScreenShow = (self.liveType == PLVRewardDisplayManagerTypeEC);
    
    __weak typeof(self) weakSelf = self;
    displayTask.willShowBlock = ^NSInteger(PLVRewardGoodsModel * _Nonnull model) {
        return [weakSelf arrangeDisplayRailWithItem:model];
    };
    
    displayTask.willDeallocBlock = ^(NSInteger index) {
        [weakSelf removeDisplayItemWithRailIndex:index];
    };
    [self.displayQueue addOperation:displayTask];
    
    //  直播带货场景横屏不显示动画
    if (CGRectGetWidth(self.superView.frame) > CGRectGetHeight(self.superView.frame) && self.liveType == PLVRewardDisplayManagerTypeEC) {
        return;
    }
    // 动画
    PLVRewardSvgaTask * svgaTask = [[PLVRewardSvgaTask alloc] init];
    svgaTask.rewardImageUrl = model.goodImgURL;
    svgaTask.superView = self.superView;
    [self.svgaQueue addOperation:svgaTask];
}


@end
