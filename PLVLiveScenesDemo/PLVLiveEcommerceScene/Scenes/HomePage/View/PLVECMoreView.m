//
//  PLVECMoreView.m
//  PLVLiveScenesDemo
//
//  Created by ftao on 2020/7/2.
//  Copyright © 2020 PLV. All rights reserved.
//

#import "PLVECMoreView.h"
#import "PLVECUtils.h"

@interface PLVECMoreViewItem ()

@property (nonatomic, assign) NSUInteger tag;

@end

@implementation PLVECMoreViewItem

@end

@interface PLVECMoreView ()

@property (nonatomic, copy) NSArray<PLVECMoreViewItem *> *items;

@end

@implementation PLVECMoreView

#pragma mark - Public

- (void)reloadData {
    if (self.delegate) {
        NSArray *items = [self.delegate dataSourceOfMoreView:self];
        [self setupUIWithItems:items];
    }
}

- (void)removeMoreViewItems {
    for (PLVECMoreViewItem *item in self.items) {
        UIView *subView = [self viewWithTag:item.tag];
        [subView removeFromSuperview];
    }
}

#pragma mark - Private

- (void)setupUIWithItems:(NSArray<PLVECMoreViewItem *> *)item {
    [self removeMoreViewItems];
    self.items = item;
    for (int i = 0; i < self.items.count; i++) {
        PLVECMoreViewItem *item = self.items[i];
        item.tag = 200 + i;

        UIButton *itemBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        itemBtn.frame = CGRectMake(12 + 72*i, 46, 50, 54);
        itemBtn.tag = item.tag;
        itemBtn.selected = item.isSelected;
        [itemBtn setTitle:item.title forState:UIControlStateNormal];
        if (item.selectedTitle) {
            [itemBtn setTitle:item.selectedTitle forState:UIControlStateSelected];
        }
        [itemBtn setTitleEdgeInsets:UIEdgeInsetsMake(42, -35, 0, 0)];
        
        UIImage *image = [PLVECUtils imageForWatchResource:item.iconImageName];
        [itemBtn setImage:image forState:UIControlStateNormal];
        if (item.selectedIconImageName) {
            UIImage *selectImage = [PLVECUtils imageForWatchResource:item.selectedIconImageName];
            [itemBtn setImage:selectImage forState:UIControlStateSelected];
        }
        [itemBtn setImageEdgeInsets:UIEdgeInsetsMake(0, 9, 22, 9)];
        
        itemBtn.titleLabel.font = [UIFont systemFontOfSize:12.0];
        itemBtn.titleLabel.textColor = [UIColor colorWithWhite:205/255.0 alpha:1];
        [itemBtn addTarget:self action:@selector(switchItemButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:itemBtn];
    }
}

- (void)switchItemButtonAction:(UIButton *)button {
    NSUInteger selectedIndex = button.tag - 200;
    if (selectedIndex > self.items.count - 1) {
        selectedIndex = self.items.count - 1;
    }
    PLVECMoreViewItem *item = self.items[selectedIndex];
    item.selected = button.selected = !button.isSelected;
    if ([self.delegate respondsToSelector:@selector(moreView:didSelectItem:index:)]) {
        [self.delegate moreView:self didSelectItem:item index:selectedIndex];
    }
}

@end
