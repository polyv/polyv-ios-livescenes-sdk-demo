//
//  PLVDanMu.m
//  PLVLiveScenesDemo
//
//  Created by lijingtong on 2021/4/13.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVDanMu.h"
#import "PLVDanMuLabel.h"
#import "PLVDanMuDefine.h"

#import <PLVFoundationSDK/PLVFoundationSDK.h>

@interface PLVDanMu () <PLVDanMuLabelDelegate>

@property (nonatomic, assign) NSUInteger            rollChannel;
@property (nonatomic, strong) NSMutableDictionary   *rollChannelDict;
@property (nonatomic, strong) NSMutableDictionary   *fadeChannelDict;
@property (nonatomic, assign) CGRect                currentFrame;
@property (nonatomic, strong) NSMutableArray *dmLabelArray;
@property (nonatomic, strong) NSMutableArray *dmLabelTempArray;
@property (nonatomic, strong) NSTimer * timer;

@end

@implementation PLVDanMu

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.currentFrame = frame;
        self.dmLabelArray = [[NSMutableArray alloc] initWithCapacity:100];
        self.dmLabelTempArray = [[NSMutableArray alloc] initWithCapacity:100];
        [self dmInitChannel];
        
    }
    return self;
}

-(void)dealloc {
    if (_timer) {
        [_timer invalidate];
        _timer = nil;
    }
}

/* 初始化航道信息 */
- (void)dmInitChannel
{
    // 计算航道
    if (self.currentFrame.size.height < 30) {
        return;
    }
    self.rollChannel = floorf((self.currentFrame.size.height - 10)/KPLVDMHEIGHT);
    
    // 初始化航道队列
    self.rollChannelDict = [NSMutableDictionary dictionaryWithCapacity:self.rollChannel];
    self.fadeChannelDict = [NSMutableDictionary dictionaryWithCapacity:self.rollChannel];
    
    for (int i = 0; i < self.rollChannel; i ++) {
        NSArray *array = [NSArray array];
        [self.rollChannelDict setObject:array forKey:@(i)];
        [self.fadeChannelDict setObject:array forKey:@(i)];
    }
}

- (void)insertScrollDML:(NSMutableAttributedString *)content {
    NSUInteger bestChannel = [self dmBestRollChannel];
    PLVDanMuLabel *plvDML = nil;
    @synchronized (self) {
        if (self.dmLabelArray.count > 0) {
            plvDML = self.dmLabelArray[self.dmLabelArray.count - 1];
            [self.dmLabelArray removeLastObject];
        }
    }
    
    if (plvDML != nil) {
        plvDML.startTime = [NSDate date];
        [plvDML makeup:content dmlOriginY:bestChannel * KPLVDMHEIGHT + 5 superFrame:self.currentFrame style:PLVDMLRoll];
    } else {
        CGFloat animateDuration = [self callbackForDanmuSpeed];
        plvDML = [PLVDanMuLabel dmInitDML:content dmlOriginY:bestChannel * KPLVDMHEIGHT + 5 superFrame:self.currentFrame style:PLVDMLRoll animateDuration:animateDuration];
        NSUInteger bestChannel = [self dmBestRollChannelWithDanMuLable:plvDML];
        if (bestChannel < 0) {
            plvDML.startTime = [NSDate date];
            [self addTempArray:plvDML];
            return;
        }
        [plvDML resetOriginY:bestChannel * KPLVDMHEIGHT + 5];
        plvDML.delegate = self;
    }
    
    [self addSubview:plvDML];
    [plvDML dmBeginAnimation];
    [self insertDMQueue:plvDML channel:bestChannel];
}

/* 插入弹幕 */
- (void)insertDML:(NSMutableAttributedString *)content
{
    PLVDMLStyle dmlStyle = PLVDMLRoll;
    
    // 计算最佳航道
    NSUInteger bestChannel = 0;
    CGFloat animateDuration = [self callbackForDanmuSpeed];
    // 初始化弹幕
    PLVDanMuLabel *plvDML = [PLVDanMuLabel dmInitDML:content dmlOriginY:bestChannel * KPLVDMHEIGHT + 5 superFrame:self.currentFrame style:dmlStyle animateDuration:animateDuration];
    bestChannel = [self dmBestRollChannelWithDanMuLable:plvDML];
    if (bestChannel < 0) {
        plvDML.startTime = [NSDate date];
        [self addTempArray:plvDML];
        return;
    }
    [plvDML resetOriginY:bestChannel * KPLVDMHEIGHT + 5];
    
    [self addSubview:plvDML];
    
    [plvDML dmBeginAnimation];
    
    // 插入弹幕队列
    [self insertDMQueue:plvDML channel:bestChannel];
}

/* 加入弹幕队列 */
- (void)insertDMQueue:(PLVDanMuLabel *)dml channel:(NSUInteger)channel
{
    if (dml.plvDMLStyle == PLVDMLRoll) {
        NSMutableArray *array = [NSMutableArray arrayWithArray:[self.rollChannelDict objectForKey:@(channel)]];
        
        // 清除当前弹幕航道的所有信息后再加入最新的弹幕
        [array removeAllObjects];
        [array addObject:dml];
        [self.rollChannelDict setObject:array forKey:@(channel)];
    } else {
        NSMutableArray *array = [NSMutableArray arrayWithArray:[self.fadeChannelDict objectForKey:@(channel)]];
        
        // 清除当前弹幕航道的所有信息后再加入最新的弹幕
        [array removeAllObjects];
        [array addObject:dml];
        [self.fadeChannelDict setObject:array forKey:@(channel)];
    }
    
}

/* 计算滚动最佳航道 */
- (NSUInteger)dmBestRollChannel
{
    for (NSUInteger i = 0; i < self.rollChannel; i ++) {
        
        NSMutableArray *array = [NSMutableArray arrayWithArray:[self.rollChannelDict objectForKey:@(i)]];
        PLVDanMuLabel *dml = [array lastObject];
        
        if (dml) {
            
            NSTimeInterval duration = [[NSDate date] timeIntervalSinceDate:dml.startTime];
            
            if (duration * dml.dmlSpeed >= dml.frame.size.width + 5 + arc4random_uniform(40)) {
                
                return i;
            }
            
        } else {
            
            return i;
            
        }
        
    }
    
    // 如果航道铺满整屏，则随机选择航道直接显示
    return arc4random_uniform((u_int32_t)self.rollChannel);
}

/* 计算滚动最佳航道-适配弹幕速度变化 */
- (NSUInteger)dmBestRollChannelWithDanMuLable:(PLVDanMuLabel *)danMuLable
{
    for (NSUInteger i = 0; i < self.rollChannel; i ++) {
        
        NSMutableArray *array = [NSMutableArray arrayWithArray:[self.rollChannelDict objectForKey:@(i)]];
        PLVDanMuLabel *dml = [array lastObject];
        
        if (dml) {
            
            NSTimeInterval duration = [[NSDate date] timeIntervalSinceDate:dml.startTime];
            
            if (duration * dml.dmlSpeed >= dml.frame.size.width + 5 + arc4random_uniform(40)) {
                // 当航道原有弹幕速度大于新弹幕速度 或者 新弹幕追及不上旧弹幕时
                if (dml.dmlSpeed > danMuLable.dmlSpeed ||
                    danMuLable.animateDuration < ((duration * dml.dmlSpeed - (dml.frame.size.width + 5)) / (danMuLable.dmlSpeed - dml.dmlSpeed))) {
                    return i;
                }
            }
        } else {
            
            return i;
            
        }
        
    }
    
    // 如果航道铺满整屏，则返回-1
    return -1;
}

/* 计算浮动最佳航道 */
- (NSUInteger)dmBestFadeChannel
{
    for (NSUInteger i = 0; i < self.rollChannel; i ++) {
        
        NSMutableArray *array = [NSMutableArray arrayWithArray:[self.fadeChannelDict objectForKey:@(i)]];
        PLVDanMuLabel *dml = [array lastObject];
        
        if (dml) {
            
            NSTimeInterval duration = [[NSDate date] timeIntervalSinceDate:dml.startTime];
            
            if (duration >= dml.dmlFadeTime + 0.2f) {
                
                return i;
            }
            
        } else {
            
            return i;
            
        }
        
    }
    
    // 如果航道铺满整屏，则随机选择航道直接显示
    return arc4random_uniform((u_int32_t)self.rollChannel);
}

/* 重置Frame */
- (void)resetFrame:(CGRect)frame
{
    self.currentFrame = frame;
    
    [self dmInitChannel];
}

- (CGFloat)callbackForDanmuSpeed {
    CGFloat danmuSpeed = 20;
    if (self.delegate && [self.delegate respondsToSelector:@selector(plvDanMuGetSpeed:)]) {
        danmuSpeed = [self.delegate plvDanMuGetSpeed:self];
    }
    return danmuSpeed;
}

- (void)addTempArray:(PLVDanMuLabel*)model {
    if (!self.timer) {
        self.timer = [NSTimer scheduledTimerWithTimeInterval:0.15
                                                      target:[PLVFWeakProxy proxyWithTarget:self]
                                                    selector:@selector(timerEvent:)
                                                    userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
    }
    [self.dmLabelTempArray addObject:model];
}

#pragma mark - [ Event ]

- (void)timerEvent:(NSTimer *)timer{
    for (PLVDanMuLabel *model in self.dmLabelTempArray) {
        NSTimeInterval duration = [[NSDate date] timeIntervalSinceDate:model.startTime];
        if (duration >= 5) {
            [self.dmLabelTempArray removeObject:model];// 超过5秒未显示则舍弃弹幕
            continue;
        }
        NSUInteger bestChannel = [self dmBestRollChannelWithDanMuLable:model];
        if (bestChannel > -1) {
            [self.dmLabelTempArray removeObject:model];
            [model resetOriginY:bestChannel * KPLVDMHEIGHT + 5];
            [self addSubview:model];
            [model dmBeginAnimation];
            // 插入弹幕队列
            [self insertDMQueue:model channel:bestChannel];
        }
    }
    if (![PLVFdUtil checkArrayUseable:self.dmLabelTempArray]) {
        [self.timer invalidate];
        self.timer = nil;
    }
}

#pragma mark - plvDanMuLabelDelegate
- (void)endScrollAnimation:(PLVDanMuLabel *)dmLabel {
    @synchronized (self) {
        [self.dmLabelArray addObject:dmLabel];
    }
}

@end
