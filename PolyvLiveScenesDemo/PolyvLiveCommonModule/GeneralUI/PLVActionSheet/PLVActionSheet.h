//
//  PLVActionSheet.h
//  PLVActionSheet
//
//  Created by Lincal on 2019/10/18.
//  Copyright © 2019 plv. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class PLVActionSheet;

/**
 * Block回调事件定义
 *
 * @param actionSheet PLVActionSheet 对象本身
 * @param index       被点击按钮标识值（删除:-1，取消:0，其他:1、2、3...）
 */
typedef void(^PLVActionSheetBlock)(PLVActionSheet * actionSheet, NSInteger index);

@interface PLVActionSheet : UIView

/**
 * 创建PLVActionSheet对象
 *
 * @param title                  提示文本
 * @param cancelBtnTitle      取消按钮文本
 * @param destructiveBtnTitle 删除按钮文本
 * @param otherBtnTitles      其他按钮文本
 * @param actionSheetBlock  点击事件Block
 *
 * @return PLVActionSheet对象
 */
- (instancetype)initWithTitle:(NSString * _Nullable)title
               cancelBtnTitle:(NSString * _Nullable)cancelBtnTitle
          destructiveBtnTitle:(NSString * _Nullable)destructiveBtnTitle
               otherBtnTitles:(NSArray * _Nullable)otherBtnTitles
                      handler:(PLVActionSheetBlock _Nullable)actionSheetBlock NS_DESIGNATED_INITIALIZER;

/**
 * 创建PLVActionSheet对象(类方法)
 *
 * @param title                  提示文本
 * @param cancelBtnTitle      取消按钮文本
 * @param destructiveBtnTitle 删除按钮文本
 * @param otherBtnTitles      其他按钮文本
 * @param actionSheetBlock  点击事件Block
 *
 * @return PLVActionSheet对象
 */
+ (instancetype)actionSheetWithTitle:(NSString * _Nullable)title
                      cancelBtnTitle:(NSString * _Nullable)cancelBtnTitle
                 destructiveBtnTitle:(NSString * _Nullable)destructiveBtnTitle
                      otherBtnTitles:(NSArray * _Nullable)otherBtnTitles
                             handler:(PLVActionSheetBlock _Nullable)actionSheetBlock;

/**
 * 弹出PLVActionSheet视图
 *
 * @param title                  提示文本
 * @param cancelBtnTitle      取消按钮文本
 * @param destructiveBtnTitle 删除按钮文本
 * @param otherBtnTitles      其他按钮文本
 * @param actionSheetBlock  点击事件Block
 */
+ (void)showActionSheetWithTitle:(NSString * _Nullable)title
                  cancelBtnTitle:(NSString * _Nullable)cancelBtnTitle
             destructiveBtnTitle:(NSString * _Nullable)destructiveBtnTitle
                  otherBtnTitles:(NSArray * _Nullable)otherBtnTitles
                         handler:(PLVActionSheetBlock _Nullable)actionSheetBlock;

/**
 * 弹出视图
 */
- (void)show;

@end

NS_ASSUME_NONNULL_END
