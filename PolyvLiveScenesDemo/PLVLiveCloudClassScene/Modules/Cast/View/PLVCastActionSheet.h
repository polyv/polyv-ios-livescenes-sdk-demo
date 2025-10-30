//
//  PLVCastActionSheet.h
//  PLVCastActionSheet
//
//  Created by Lincal on 2019/10/18.
//  Copyright © 2019 plv. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class PLVCastActionSheet;

/**
 * Block回调事件定义
 *
 * @param actionSheet PLVCastActionSheet 对象本身
 * @param index       被点击按钮索引
 */
typedef void(^PLVCastActionSheetBlock)(PLVCastActionSheet * actionSheet, NSInteger index);

@interface PLVCastActionSheet : UIView

/**
 * 创建PLVCastActionSheet对象
 *
 * @param otherBtnTitles      其他按钮文本
 * @param selectedIndex        已选中按钮 
 * @param actionSheetBlock  点击事件Block
 *
 * @return PLVCastActionSheet对象
 */
- (instancetype)initWithBtnTitles:(NSArray * _Nullable)otherBtnTitles
                    selectedIndex:(NSInteger)selectedIndex
                          handler:(PLVCastActionSheetBlock _Nullable)actionSheetBlock NS_DESIGNATED_INITIALIZER;

/**
 * 创建PLVCastActionSheet对象(类方法)
 *
 * @param otherBtnTitles      其他按钮文本
 * @param selectedIndex        已选中按钮
 * @param actionSheetBlock  点击事件Block
 *
 * @return PLVCastActionSheet对象
 */
+ (instancetype)actionSheetWithBtnTitles:(NSArray * _Nullable)otherBtnTitles
                           selectedIndex:(NSInteger)selectedIndex
                                 handler:(PLVCastActionSheetBlock _Nullable)actionSheetBlock;

/**
 * 弹出PLVCastActionSheet视图
 *
 * @param otherBtnTitles      其他按钮文本
 * @param selectedIndex        已选中按钮
 * @param actionSheetBlock  点击事件Block
 */
+ (void)showActionSheetWithBtnTitles:(NSArray * _Nullable)otherBtnTitles
                       selectedIndex:(NSInteger)selectedIndex
                             handler:(PLVCastActionSheetBlock _Nullable)actionSheetBlock;

/**
 * 弹出视图
 */
- (void)show;

@end

NS_ASSUME_NONNULL_END
