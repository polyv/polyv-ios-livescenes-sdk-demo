//
//  PLVHCProhibitWordTipView.h
//  PLVLiveScenesDemo
//
//  Created by lijingtong on 2021/6/28.
//  Copyright © 2021 PLV. All rights reserved.
//  聊天室 违规消息提示视图
//  用于提示消息有禁言词、违规图片

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, PLVHCProhibitWordTipType) {
        PLVHCProhibitWordTipTypeText, // 文字类型
        PLVHCProhibitWordTipTypeImage // 图片类型
};

typedef void (^PLVHCProhibitWordTipViewDismissBlock) (void);

/// 消息提示视图，用于提示消息有违规
@interface PLVHCProhibitWordTipView : UIView

@property (nonatomic, copy) PLVHCProhibitWordTipViewDismissBlock dismissBlock;

/// 弹出弹层
/// @param view 展示弹层的父视图，弹层会插入到父视图的最顶上
- (void)showInView:(UIView *)view;

/// 关闭提示视图，自动调用dismissBlock回调
- (void)dismiss;

/// 关闭提示视图，无回调
- (void)dismissNoCallblck;

/// 设置违规类型、违规词
/// @param tipType 违规类型
/// @param prohibitWord 违规词，文字类型时，若此字段为空表示违禁词已被替换成*，图片类型时此字段为空
- (void)setTipType:(PLVHCProhibitWordTipType)tipType prohibitWord:(NSString * _Nullable )prohibitWord;

@end

NS_ASSUME_NONNULL_END
