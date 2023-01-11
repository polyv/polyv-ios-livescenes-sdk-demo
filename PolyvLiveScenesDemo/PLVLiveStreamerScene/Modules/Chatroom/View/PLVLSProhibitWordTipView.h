//
//  PLVLSProhibitWordTipView.h
//  PolyvLiveScenesDemo
//
//  Created by lijingtong on 2021/12/20.
//  Copyright © 2021 PLV. All rights reserved.
// 聊天消息含有违禁词或违规图片 消息提示视图

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, PLVLSProhibitWordTipType) {
        PLVLSProhibitWordTipTypeText, // 文字类型
        PLVLSProhibitWordTipTypeImage // 图片类型
};

typedef void (^PLVLSProhibitWordTipViewDismissBlock) (void);

@interface PLVLSProhibitWordTipView : UIView

@property (nonatomic, copy) PLVLSProhibitWordTipViewDismissBlock dismissBlock;

/// 显示视图,三秒后自动消失
/// @param superView 显示的父类
- (void)showWithSuperView:(UIView *)superView;

/// 关闭menu
- (void)dismiss;


/// 设置违规类型、违规词
/// @param tipType 违规类型
/// @param prohibitWord 违规词，文字类型时，若此字段为空表示违禁词已被替换成*，图片类型时此字段为空
- (void)setTipType:(PLVLSProhibitWordTipType)tipType prohibitWord:(NSString * _Nullable )prohibitWord;

@end

NS_ASSUME_NONNULL_END
