//
//  PLVLSBeautyCellModel.h
//  PolyvLiveScenesDemo
//
//  Created by JTom on 2022/4/15.
//  Copyright © 2022 PLV. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>

NS_ASSUME_NONNULL_BEGIN
@interface PLVLSBeautyCellModel : NSObject

/// 标题
@property (nonatomic, copy, readonly) NSString *title;
/// 图片名字
@property (nonatomic, copy, readonly) NSString *imageName;
/// 是否选中
@property (nonatomic, assign, readonly) BOOL selected;
/// 美颜特效类型
@property (nonatomic, assign, readonly) PLVBBeautyOption beautyOption;
/// 滤镜模型
@property (nonatomic, strong, readonly) PLVBFilterOption *filerOption;

- (instancetype)initWithTitle:(NSString *)title imageName:(NSString *)imageName beautyOption:(PLVBBeautyOption)beautyOption;

- (instancetype)initWithTitle:(NSString *)title imageName:(NSString *)imageName beautyOption:(PLVBBeautyOption)beautyOption selected:(BOOL)selected;

- (instancetype)initWithTitle:(NSString *)title imageName:(NSString *)imageName beautyOption:(PLVBBeautyOption)beautyOption selected:(BOOL)selected filterOption:(PLVBFilterOption * _Nullable)filterOption;

- (void)updateSelected:(BOOL) selected;

@end

NS_ASSUME_NONNULL_END
