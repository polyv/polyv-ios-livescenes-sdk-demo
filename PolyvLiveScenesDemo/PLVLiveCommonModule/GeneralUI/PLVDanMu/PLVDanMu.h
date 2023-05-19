//
//  PLVDanMu.h
//  PLVLiveScenesDemo
//
//  Created by lijingtong on 2021/4/13.
//  Copyright © 2021 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol PLVDanMuDelegate;

@interface PLVDanMu : UIView

@property (nonatomic, weak) id <PLVDanMuDelegate> delegate;

/* 插入弹幕 （滚动样式-弹幕不重叠）*/
- (void)insertDML:(NSMutableAttributedString *)content;

/* 插入弹幕 （滚动样式）*/
- (void)insertScrollDML:(NSMutableAttributedString *)content;

/* 重置Frame */
- (void)resetFrame:(CGRect)frame;

@end

@protocol PLVDanMuDelegate <NSObject>

- (CGFloat)plvDanMuGetSpeed:(PLVDanMu *)danmuView;

@end
