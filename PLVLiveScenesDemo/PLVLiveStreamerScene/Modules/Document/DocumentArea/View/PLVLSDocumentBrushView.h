//
//  PLVSBrushView.h
//  PLVLiveScenesDemo
//
//  Created by Hank on 2021/3/1.
//  Copyright © 2021 PLV. All rights reserved.
//  画笔工具条

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 类型枚举
typedef NS_ENUM(NSInteger, PLVLSDocumentBrushViewType) {
    PLVLSDocumentBrushViewTypeClearAll,     /// 清除画面
    PLVLSDocumentBrushViewTypeClear,        /// 橡皮擦
    PLVLSDocumentBrushViewTypeArrow,        /// 箭头
    PLVLSDocumentBrushViewTypeText,         /// 文本
    PLVLSDocumentBrushViewTypeFreePen       /// 自由线条
};

@class PLVLSDocumentBrushView;

@protocol PLVLSDocumentBrushViewDelegate <NSObject>

- (void)brushView:(PLVLSDocumentBrushView *)brushView changeType:(PLVLSDocumentBrushViewType)type;

- (void)brushView:(PLVLSDocumentBrushView *)brushView changeColor:(NSString *)color;

@end

@interface PLVLSDocumentBrushView : UIView

@property (nonatomic, weak) id<PLVLSDocumentBrushViewDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
