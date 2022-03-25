//
//  PLVSAProhibitWordTipView.h
//  PLVLiveScenesDemo
//
//  Created by lijingtong on 2021/6/6.
//  Copyright © 2021 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, PLVSAProhibitWordTipType) {
        PLVSAProhibitWordTipTypeText, // 文字类型
        PLVSAProhibitWordTipTypeImage // 图片类型
};

typedef void (^PLVSAProhibitWordTipViewDismissBlock) (void);

// 消息提示视图，用于提示消息有违规
@interface PLVSAProhibitWordTipView : UIView

@property (nonatomic, copy) PLVSAProhibitWordTipViewDismissBlock dismissBlock;

/// 显示视图,三秒后自动消失
- (void)show;

/// 关闭menu
- (void)dismiss;


/// 设置违规类型、违规词
/// @param tipType 违规类型
/// @param prohibitWord 违规词，文字类型此字段不可为空，图片类型为空
- (void)setTipType:(PLVSAProhibitWordTipType)tipType prohibitWord:(NSString * _Nullable )prohibitWord;

@end

NS_ASSUME_NONNULL_END
