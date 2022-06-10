//
//  PLVSABeautyViewModel.h
//  PolyvLiveScenesDemo
//
//  Created by JTom on 2022/4/13.
//  Copyright © 2022 PLV. All rights reserved.
// 美颜viewModel

#import <Foundation/Foundation.h>
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, PLVSABeautyType) {
    PLVSABeautyTypeWhiten, // 美白
    PLVSABeautyTypeFilter, // 滤镜
    PLVSABeautyTypeFace // 脸部细节
};

@class PLVSABeautyViewModel;
@protocol PLVSABeautyViewModelDelegate <NSObject>

/// 切换 美颜、滤镜类型 时触发
/// @param intensity 当前强度
/// @param defaultIntensity 默认强度
- (void)beautyViewModel:(PLVSABeautyViewModel *)beautyViewModel didChangeIntensity:(CGFloat)intensity defaultIntensity:(CGFloat) defaultIntensity;

/// 切换 滤镜类型 时触发
- (void)beautyViewModel:(PLVSABeautyViewModel *)beautyViewModel didChangeFilterName:(NSString *)filterName;

@end

@interface PLVSABeautyViewModel : NSObject

/// 代理
@property (nonatomic, weak) id<PLVSABeautyViewModelDelegate> delegate;
/// 当前 美颜是否已就绪
@property (nonatomic, assign, readonly) BOOL beautyIsReady;
/// 当前 美颜是否开启
@property (nonatomic, assign, readonly) BOOL beautyIsOpen;
/// 当前 是否选中原图滤镜
@property (nonatomic, assign, getter=isSelectedOriginFilter ,readonly) BOOL selectedOriginFilter;
/// 滤镜模型
@property (nonatomic, strong, readonly) NSMutableArray<PLVBFilterOption *> *filterOptionArray;
/// 当前选择了什么美颜类型
@property (nonatomic, assign, readonly) PLVSABeautyType beautyType;

/// 单例方法
+ (instancetype)sharedViewModel;

/// 开启美颜
- (void)startBeautyWithManager:(PLVBeautyManager *)beautyManager;

/// 用于资源释放、状态位清零
- (void)clear;

/// 开启/关闭 美颜
/// @param open YES:开启 NO:关闭
- (void)beautyOpen:(BOOL)open;

/// 更新美颜强度
/// @note 滑动强度视图触发
/// @param intensity 强度，0~1
- (void)updateBeautyOptionWithIntensity:(CGFloat)intensity;

/// 重置美颜强度
/// @note 点击重置按钮触发
- (void)resetBeautyOptionIntensity;

/// 选择美颜特效
/// 点击对应美颜类型触发
/// @param option 特效类型
- (void)selectBeautyOption:(PLVBBeautyOption)option;

/// 选择滤镜
/// 点击对应滤镜触发
/// @param filterOption 滤镜模型
- (void)selectBeautyFilterOption:(PLVBFilterOption *)filterOption;

/// 切换美颜类型分类
/// @param beautyType 美颜类型 
- (void)selectBeautyType:(PLVSABeautyType)beautyType;

@end

NS_ASSUME_NONNULL_END
