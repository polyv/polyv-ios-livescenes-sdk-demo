//
//  PLVLCMediaMoreModel.h
//  PLVLiveScenesDemo
//
//  Created by Lincal on 2020/9/29.
//  Copyright © 2020 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, PLVLCMediaMoreModelMode) {
    PLVLCMediaMoreModelMode_Options = 0, // 参数选项模式
    PLVLCMediaMoreModelMode_Switch = 1, // 功能开关模式
    PLVLCMediaMoreModelMode_Custom = 2, // 自定义模式
};

NS_ASSUME_NONNULL_BEGIN

/// 媒体更多视图数据模型
@interface PLVLCMediaMoreModel : NSObject

#pragma mark 可配置项
/// 选项系列总标题，当为功能开关时作为开关标题文本
@property (nonatomic, copy) NSString * optionTitle;

/// 当前选中的下标
///
/// @note 可在创建Model时，配置此值作为默认选项值；
///       或是UI上改变时，同步UI的选项值；
///       当mediaMoreModelMode 为 PLVLCMediaMoreModelMode_Options 时必须小于 optionItemsArray.count；未设置时，默认值为0
@property (nonatomic, assign) NSInteger selectedIndex;

/// 预先指定选项的宽度
///
/// @note 业务上，若希望某个系列的option选项，不按‘文本内容’来动态计算宽度，而按指定宽度来设定，则可利用此值
@property (nonatomic, assign) CGFloat optionSpecifiedWidth;

#pragma mark 数据

/// 选项系列的模式
///
/// @note 创建model时，内部自动配置
@property (nonatomic, assign, readonly) PLVLCMediaMoreModelMode mediaMoreModelMode;
/// 具体选项标题数组
///
/// @note 仅可在创建Model时，配置此值
@property (nonatomic, strong, readonly) NSArray <NSString *> * optionItemsArray;

/// 当前选中的选项名
@property (nonatomic, copy, readonly) NSString * currentSelectedItemString;

/// 功能开关未选中图片
@property (nonatomic, strong, readonly) UIImage * _Nullable switchNormalImage;

/// 功能开关选中图片
@property (nonatomic, strong, readonly) UIImage * _Nullable switchSelectedImage;

/// 自定义字典
///
/// @note 仅可在创建Model自定义时，配置此值
@property (nonatomic, strong, readonly) NSDictionary *customDictionary;

#pragma mark - [ 方法 ]
#pragma mark 创建
/// 创建 Model
///
/// @note 注意:若 optionTitle、optionItemsArray 为nil或值为空，则创建失败返回nil
///
/// @param optionTitle 选项系列总标题
/// @param optionItemsArray 具体选项标题数组
+ (instancetype)modelWithOptionTitle:(NSString *)optionTitle
                    optionItemsArray:(NSArray <NSString *> *)optionItemsArray;

/// 创建 Model
///
/// @note 注意:若 optionTitle、optionItemsArray 为nil或值为空，则创建失败返回nil
///
/// @param optionTitle 选项系列总标题
/// @param optionItemsArray 具体选项标题数组
/// @param selectedIndex 默认选中哪一个 (必须小于 optionItemsArray.count)
+ (instancetype)modelWithOptionTitle:(NSString *)optionTitle
                    optionItemsArray:(NSArray <NSString *> *)optionItemsArray
                       selectedIndex:(NSInteger)selectedIndex;

/// 创建 Model 功能开关
///
/// @note 注意:若 optionTitle为nil或值为空，则创建失败返回nil
///
/// @param switchTitle 功能开关
/// @param normalImage 功能开关未选中图片
/// @param selectedImage 功能开关选中图片
/// @param selected  默认功能开关是否选中
+ (instancetype)modelWithSwitchTitle:(NSString *)switchTitle normalImage:(UIImage *)normalImage selectedImage:(UIImage *)selectedImage selected:(BOOL)selected;

/// 创建Model 自定义
///
/// @param customTitle  自定义标题
/// @param dictionary  自定义字典
+ (instancetype)modelWithCustomTitle:(NSString *)customTitle dictionary:(NSDictionary *)dictionary;

#pragma mark 数据处理
/// 判断两个 moreModel 之间是否属于同一系列
///
/// @note 若 optionTitle选型总标题 相同，则认为属于同一系列
///
/// @param otherMoreModel 需要核对的其他 moreModel
- (BOOL)matchOtherMoreModel:(PLVLCMediaMoreModel *)otherMoreModel;

/// 通过 选项名 来设置“当前选中哪一个”
///
/// @param optionItemString 被选中的选项名
- (void)setSelectedIndexWithOptionItemString:(NSString *)optionItemString;

@end

NS_ASSUME_NONNULL_END
