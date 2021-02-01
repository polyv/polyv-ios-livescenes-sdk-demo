//
//  PLVECSwitchView.m
//  PolyvLiveEcommerceDemo
//
//  Created by ftao on 2020/5/21.
//  Copyright © 2020 polyv. All rights reserved.
//

#import "PLVECSwitchView.h"

@interface PLVECSwitchView ()

@property (nonatomic, copy) NSArray<NSString *> *items;

@end

@implementation PLVECSwitchView

#pragma mark - Life Cycle

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.titleLable = [[UILabel alloc] initWithFrame:CGRectMake(15, 20, 80, 18)];
        self.titleLable.textColor = UIColor.whiteColor;
        self.titleLable.font = [UIFont systemFontOfSize:14];
        [self addSubview:self.titleLable];
    }
    return self;
}

#pragma mark - Public

- (void)reloadData {
    self.hidden = NO;
    
    if (self.delegate) {
        NSArray *items = [self.delegate dataSourceOfSwitchView:self];
        [self setupUIWithItems:items];
    }
}

#pragma mark - Private

- (void)setupUIWithItems:(NSArray<NSString *> *)items {
    for (int i = 0; i < self.items.count; i++) {
        UIView *item = [self viewWithTag:100 + i];
        [item removeFromSuperview];
    }
    
    CGFloat width = (CGRectGetWidth(self.bounds) - 30) / (items.count>5 ? 5 : items.count);
    for (int i = 0; i < items.count; i++) {
        UIButton *itemBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        itemBtn.frame = CGRectMake(15 + (width-66)/2 + width*i, 68, 66, 26);
        itemBtn.layer.cornerRadius = 13.0;
        itemBtn.layer.masksToBounds = YES;
        itemBtn.tag = 100 + i;
        [itemBtn setTitle:items[i] forState:UIControlStateNormal];
        itemBtn.titleLabel.font = [UIFont systemFontOfSize:14.0];
        [itemBtn addTarget:self action:@selector(itemButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:itemBtn];
        
        [self setItemButton:itemBtn selected:i==self.selectedIndex];
    }
    self.items = items;
}

- (void)setItemButton:(UIButton *)button selected:(BOOL)selected {
    if (selected) {
        UIColor *selectColor = [UIColor colorWithRed:1.0 green:200/255.0 blue:21/255.0 alpha:1.0];
        button.layer.borderWidth = 1.0;
        button.layer.borderColor = selectColor.CGColor;
        [button setTitleColor:selectColor forState:UIControlStateNormal];
    } else {
        button.layer.borderWidth = 0;
        button.layer.borderColor = UIColor.whiteColor.CGColor;
        [button setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    }
}

#pragma makr - Acttion

- (void)itemButtonAction:(UIButton *)button {
    self.hidden = YES;
    
    NSUInteger selectedIndex = button.tag - 100;
    if (selectedIndex == self.selectedIndex) {
        return;
    }
    self.selectedIndex = selectedIndex;
    
    for (int i = 0; i < self.items.count; i++) {
        UIButton *itemBtn = [self viewWithTag:100+i];
        if ([itemBtn isKindOfClass:UIButton.class]) {
            [self setItemButton:itemBtn selected:button.tag==itemBtn.tag];
        }
    }
    if ([self.delegate respondsToSelector:@selector(playerSwitchView:didSelectedIndex:selectedItem:)]) {
        [self.delegate playerSwitchView:self didSelectedIndex:self.selectedIndex selectedItem:button.titleLabel.text];
    }
}

@end
