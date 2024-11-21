//
//  PLVBeautyViewModel.h
//  PolyvLiveScenesDemo
//
//  Created by juno on 2022/8/12.
//  Copyright © 2022 PLV. All rights reserved.
//  美颜 viewmodel

#import <Foundation/Foundation.h>
#import <Foundation/Foundation.h>
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>

NS_ASSUME_NONNULL_BEGIN
typedef NS_ENUM(NSInteger, PLVBeautyType) {
    PLVBeautyTypeWhiten, // 美白
    PLVBeautyTypeFilter, // 滤镜
    PLVBeautyTypeFace // 脸部细节
};

typedef NS_ENUM(NSInteger, PLVBeautySDKType){
    PLVBeautySDKTypeProfessional = 1,
    PLVBeautySDKTypeLight
};

@class PLVBeautyViewModel;
@protocol PLVBeautyViewModelDelegate <NSObject>

/// 切换 美颜、滤镜类型 时触发
/// @param intensity 当前强度
/// @param defaultIntensity 默认强度
- (void)beautyViewModel:(PLVBeautyViewModel *)beautyViewModel didChangeIntensity:(CGFloat)intensity defaultIntensity:(CGFloat) defaultIntensity;

/// 切换 滤镜类型 时触发
- (void)beautyViewModel:(PLVBeautyViewModel *)beautyViewModel didChangeFilterName:(NSString *)filterName;

@end

@interface PLVBeautyViewModel : NSObject

/// 代理
@property (nonatomic, weak) id<PLVBeautyViewModelDelegate> delegate;
/// 当前 美颜是否已就绪
@property (nonatomic, assign, readonly) BOOL beautyIsReady;
/// 当前 美颜是否开启
@property (nonatomic, assign, readonly) BOOL beautyIsOpen;
/// 当前 是否选中原图滤镜
@property (nonatomic, assign, getter=isSelectedOriginFilter ,readonly) BOOL selectedOriginFilter;
/// 滤镜模型
@property (nonatomic, strong, readonly) NSMutableArray<PLVBFilterOption *> *filterOptionArray;
/// 当前选择了什么美颜类型
@property (nonatomic, assign, readonly) PLVBeautyType beautyType;
/// 美颜sdk类型 1:高级美颜 2 保利威轻美颜
@property (nonatomic, assign, readonly) PLVBeautySDKType beautySDKType;

/// 单例方法
+ (instancetype)sharedViewModel;

/// 开启美颜
- (void)startBeautyWithManager:(PLVBeautyManager *)beautyManager sdkType:(PLVBeautySDKType )type;

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
- (void)selectBeautyType:(PLVBeautyType)beautyType;

/// 获取缓存选中的滤镜
- (PLVBFilterOption *)getCacheSelectFilterOption;

@end

NS_ASSUME_NONNULL_END
