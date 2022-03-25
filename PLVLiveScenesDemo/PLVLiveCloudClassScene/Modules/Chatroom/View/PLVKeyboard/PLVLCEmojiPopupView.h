//
//  PLVLCEmojiPopupView.h
//  PLVLiveScenesDemo
//
//  Created by Sakya on 2021/7/15.
//  Copyright © 2021 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class PLVImageEmotion;

@interface PLVLCEmojiPopupView : UIView

//弹出视图的位置对象 必传
@property (nonatomic, strong) UIView *relyView;
//表情数据模型
@property (nonatomic, strong) PLVImageEmotion *imageEmotion;

///显示弹窗
- (void)showPopupView;

///主动清除弹窗
- (void)dismissView;

@end

NS_ASSUME_NONNULL_END
