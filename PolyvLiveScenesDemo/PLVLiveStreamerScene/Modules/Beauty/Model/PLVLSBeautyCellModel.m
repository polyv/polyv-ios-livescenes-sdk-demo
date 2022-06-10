//
//  PLVLSBeautyCellModel.m
//  PolyvLiveScenesDemo
//
//  Created by JTom on 2022/4/15.
//  Copyright © 2022 PLV. All rights reserved.
//

#import "PLVLSBeautyCellModel.h"

@interface PLVLSBeautyCellModel()

@property (nonatomic, copy) NSString *title; // 标题
@property (nonatomic, copy) NSString *imageName; // 图片名字
@property (nonatomic, assign) BOOL selected; // 是否选中
@property (nonatomic, assign) PLVBBeautyOption beautyOption; // 美颜特效类型
@property (nonatomic, strong) PLVBFilterOption *filerOption; // 滤镜模型

@end

@implementation PLVLSBeautyCellModel

- (instancetype)initWithTitle:(NSString *)title imageName:(NSString *)imageName beautyOption:(PLVBBeautyOption)beautyOption{
    return [self initWithTitle:title imageName:imageName beautyOption:beautyOption selected:NO];
}

- (instancetype)initWithTitle:(NSString *)title imageName:(NSString *)imageName beautyOption:(PLVBBeautyOption)beautyOption selected:(BOOL)selected {
    return [self initWithTitle:title imageName:imageName beautyOption:beautyOption selected:selected filterOption:nil];
}

- (instancetype)initWithTitle:(NSString *)title imageName:(NSString *)imageName beautyOption:(PLVBBeautyOption)beautyOption selected:(BOOL)selected filterOption:(PLVBFilterOption *)filterOption {
    self = [super init];
    if (self) {
        self.title = title;
        self.imageName = imageName;
        self.beautyOption = beautyOption;
        self.selected = selected;
        self.filerOption = filterOption;
    }
    return self;
}

- (void)updateSelected:(BOOL)selected {
    self.selected = selected;
}

@end
