//
//  PLVLCDocumentPaintModeView.h
//  PolyvLiveScenesDemo
//
//  Created by Sakya on 2022/12/12.
//  Copyright © 2022 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class PLVLCDocumentPaintModeView;

@protocol PLVLCDocumentPaintModeViewDelegate <NSObject>

/// 画笔模式视图 退出画笔模式的回调
/// @param paintModeView 画笔模式视图
- (void)plvLCDocumentPaintModeViewExitPaintMode:(PLVLCDocumentPaintModeView *)paintModeView;

@end

/// 画笔模式 视图
@interface PLVLCDocumentPaintModeView : UIView

@property (nonatomic, weak)id<PLVLCDocumentPaintModeViewDelegate> delegate;

/// 进入画笔模式
/// @param pptView  白板视图
- (void)enterPaintModeWithPPTView:(UIView *)pptView;

/// 退出画笔模式
- (void)exitPaintMode;

@end

NS_ASSUME_NONNULL_END
