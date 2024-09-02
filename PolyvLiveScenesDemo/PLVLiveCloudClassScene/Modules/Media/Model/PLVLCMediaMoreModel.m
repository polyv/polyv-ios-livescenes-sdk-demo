//
//  PLVLCMediaMoreModel.m
//  PLVLiveScenesDemo
//
//  Created by Lincal on 2020/9/29.
//  Copyright © 2020 PLV. All rights reserved.
//

#import "PLVLCMediaMoreModel.h"

#import <PLVFoundationSDK/PLVFoundationSDK.h>
#import <PLVLiveScenesSDK/PLVConsoleLogger.h>

@interface PLVLCMediaMoreModel ()

///  选项当前的模式
@property (nonatomic, assign) PLVLCMediaMoreModelMode mediaMoreModelMode;

/// 具体选项标题数组
@property (nonatomic, strong) NSArray <NSString *> * optionItemsArray;

/// 当前选中的选项名
@property (nonatomic, copy) NSString * currentSelectedItemString;

/// 功能开关未选中图片
@property (nonatomic, strong) UIImage * switchNormalImage;

/// 功能开关选中图片
@property (nonatomic, strong) UIImage * switchSelectedImage;


@end

@implementation PLVLCMediaMoreModel

#pragma mark - [ Public Methods ]
- (NSInteger)selectedIndex{
    if (_selectedIndex >= self.optionItemsArray.count && self.mediaMoreModelMode == PLVLCMediaMoreModelMode_Options) {
        PLV_LOG_ERROR(PLVConsoleLogModuleTypePlayer,@"PLVLCMediaMoreModel - selectedIndex illegal:%ld, when optionItemsArray.count:%ld",_selectedIndex,self.optionItemsArray.count);
        return (self.optionItemsArray.count - 1);
    }else{
        return _selectedIndex;
    }
}

- (NSString *)currentSelectedItemString{
    if (self.selectedIndex < self.optionItemsArray.count) {
        return self.optionItemsArray[self.selectedIndex];
    }else{
        PLV_LOG_ERROR(PLVConsoleLogModuleTypePlayer,@"PLVLCMediaMoreModel - currentSelectedItemString read failed, _selectedIndex illegal:%ld, when optionItemsArray.count:%ld",_selectedIndex,self.optionItemsArray.count);
        return @"";
    }
}

+ (instancetype)modelWithOptionTitle:(NSString *)optionTitle optionItemsArray:(NSArray<NSString *> *)optionItemsArray{
    return [self modelWithOptionTitle:optionTitle optionItemsArray:optionItemsArray selectedIndex:0];
}

+ (instancetype)modelWithOptionTitle:(NSString *)optionTitle optionItemsArray:(NSArray<NSString *> *)optionItemsArray selectedIndex:(NSInteger)selectedIndex{
    PLVLCMediaMoreModel * model = [[PLVLCMediaMoreModel alloc] init];
    if ([PLVFdUtil checkStringUseable:optionTitle]) {
        model.optionTitle = optionTitle;
    }else{
        PLV_LOG_ERROR(PLVConsoleLogModuleTypePlayer,@"PLVLCMediaMoreModel - modelWithOptionTitle failed, set optionTitle failed, optionTitle:%@",optionTitle);
        return nil;
    }
    if ([PLVFdUtil checkArrayUseable:optionItemsArray]) {
        model.optionItemsArray = optionItemsArray;
    }else{
        PLV_LOG_ERROR(PLVConsoleLogModuleTypePlayer,@"PLVLCMediaMoreModel - modelWithOptionTitle failed, set optionItemsArray failed, optionItemsArray:%@",optionItemsArray);
        return nil;
    }
    model.mediaMoreModelMode = PLVLCMediaMoreModelMode_Options;
    model.selectedIndex = selectedIndex;
    return model;
}

+ (instancetype)modelWithSwitchTitle:(NSString *)switchTitle normalImage:(UIImage *)normalImage selectedImage:(UIImage *)selectedImage selected:(BOOL)selected{
    PLVLCMediaMoreModel * model = [[PLVLCMediaMoreModel alloc] init];
    if ([PLVFdUtil checkStringUseable:switchTitle]) {
        model.optionTitle = switchTitle;
    } else {
        PLV_LOG_ERROR(PLVConsoleLogModuleTypePlayer,@"PLVLCMediaMoreModel - modelWithSwitchTitle failed, set optionTitle failed, optionTitle:%@",switchTitle);
        return nil;
    }
    
    if (normalImage && [normalImage isKindOfClass:UIImage.class]) {
        model.switchNormalImage = normalImage;
    }
    
    if (selectedImage && [selectedImage isKindOfClass:UIImage.class]) {
        model.switchSelectedImage = selectedImage;
    }
    model.mediaMoreModelMode = PLVLCMediaMoreModelMode_Switch;
    model.selectedIndex = selected ? 1 : 0;
    return model;
}

- (BOOL)matchOtherMoreModel:(PLVLCMediaMoreModel *)otherMoreModel{
    if ([otherMoreModel.optionTitle isEqualToString:self.optionTitle] && [PLVFdUtil checkArrayUseable:otherMoreModel.optionItemsArray]) {
        return YES;
    }else{
        return NO;
    }
}

- (void)setSelectedIndexWithOptionItemString:(NSString *)optionItemString{
    if ([PLVFdUtil checkStringUseable:optionItemString]) {
        for (int i = 0; i < self.optionItemsArray.count; i ++) {
            NSString * optionItemStringInArray = self.optionItemsArray[i];
            if ([optionItemString isEqualToString:optionItemStringInArray]) {
                self.selectedIndex = i;
                break;
            }
        }
    }else{
        PLV_LOG_ERROR(PLVConsoleLogModuleTypePlayer,@"PLVLCMediaMoreModel - setSelectedIndexWithOptionItemString failed, optionItemString:%@",optionItemString);
    }
}

@end
