//
//  PLVDanMu.h
//  PLVLiveScenesDemo
//
//  Created by lijingtong on 2021/4/13.
//  Copyright © 2021 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PLVDanMu : UIView

/* 插入弹幕 （随机样式）*/
- (void)insertDML:(NSMutableAttributedString *)content;

/* 插入弹幕 （滚动样式）*/
- (void)insertScrollDML:(NSMutableAttributedString *)content;

/* 重置Frame */
- (void)resetFrame:(CGRect)frame;

@end
