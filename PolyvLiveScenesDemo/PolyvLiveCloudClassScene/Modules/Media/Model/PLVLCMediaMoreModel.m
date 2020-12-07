//
//  PLVLCMediaMoreModel.m
//  PolyvLiveScenesDemo
//
//  Created by Lincal on 2020/9/29.
//  Copyright © 2020 polyv. All rights reserved.
//

#import "PLVLCMediaMoreModel.h"

#import <PolyvFoundationSDK/PolyvFoundationSDK.h>

@interface PLVLCMediaMoreModel ()

/// 具体选项标题数组
@property (nonatomic, strong) NSArray <NSString *> * optionItemsArray;

/// 当前选中的选项名
@property (nonatomic, copy) NSString * currentSelectedItemString;

@end

@implementation PLVLCMediaMoreModel

#pragma mark - [ Public Methods ]
- (NSInteger)selectedIndex{
    if (_selectedIndex >= self.optionItemsArray.count) {
        NSLog(@"PLVLCMediaMoreModel - selectedIndex illegal:%ld, when optionItemsArray.count:%ld",_selectedIndex,self.optionItemsArray.count);
        return (self.optionItemsArray.count - 1);
    }else{
        return _selectedIndex;
    }
}

- (NSString *)currentSelectedItemString{
    if (self.selectedIndex < self.optionItemsArray.count) {
        return self.optionItemsArray[self.selectedIndex];
    }else{
        NSLog(@"PLVLCMediaMoreModel - currentSelectedItemString read failed, _selectedIndex illegal:%ld, when optionItemsArray.count:%ld",_selectedIndex,self.optionItemsArray.count);
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
        NSLog(@"PLVLCMediaMoreModel - modelWithOptionTitle failed, set optionTitle failed, optionTitle:%@",optionTitle);
        return nil;
    }
    if ([PLVFdUtil checkArrayUseable:optionItemsArray]) {
        model.optionItemsArray = optionItemsArray;
    }else{
        NSLog(@"PLVLCMediaMoreModel - modelWithOptionTitle failed, set optionItemsArray failed, optionItemsArray:%@",optionItemsArray);
        return nil;
    }
    model.selectedIndex = selectedIndex;
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
        NSLog(@"PLVLCMediaMoreModel - setSelectedIndexWithOptionItemString failed, optionItemString:%@",optionItemString);
    }
}

@end
