//
//  PLVDanMuLabel.h
//  PolyvLiveScenesDemo
//
//  Created by lijingtong on 2021/4/13.
//  Copyright © 2021 polyv. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, PLVDMLState) {
    PLVDMLStateRunning,
    PLVDMLStateStop,
    PLVDMLStateFinish
};

typedef NS_ENUM(NSUInteger, PLVDMLStyle) {
    PLVDMLRoll,
    PLVDMLFade
};

@protocol PLVDanMuLabelDelegate;

@interface PLVDanMuLabel : UILabel

@property (nonatomic, weak) id<PLVDanMuLabelDelegate> delegate;
@property (nonatomic, assign) PLVDMLState                   plvDMLState;
@property (nonatomic, assign) PLVDMLStyle                   plvDMLStyle;

/* 当前弹幕开始动画时间 */
@property (nonatomic, strong) NSDate                        *startTime;

/* 弹幕滚动速度 */
@property (nonatomic, assign, readonly) CGFloat             dmlSpeed;

/* 弹幕浮动时间 */
@property (nonatomic, assign, readonly) CGFloat             dmlFadeTime;

/* 创建 */
+ (instancetype)dmInitDML:(NSMutableAttributedString *)content dmlOriginY:(CGFloat)dmlOriginY superFrame:(CGRect)superFrame style:(PLVDMLStyle)style;

- (void)makeup:(NSMutableAttributedString *)content dmlOriginY:(CGFloat)dmlOriginY superFrame:(CGRect)superFrame style:(PLVDMLStyle)style;

/* 开始弹幕动画 */
- (void)dmBeginAnimation;

@end

@protocol PLVDanMuLabelDelegate <NSObject>

- (void)endScrollAnimation:(PLVDanMuLabel *)dmLabel;

@end
