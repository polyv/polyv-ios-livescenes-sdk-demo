//
//  PLVECMoreView.m
//  PLVLiveScenesDemo
//
//  Created by ftao on 2020/7/2.
//  Copyright © 2020 PLV. All rights reserved.
//

#import "PLVECMoreView.h"
#import "PLVECUtils.h"
#import <PLVFoundationSDK/PLVFdUtil.h>
#import <SDWebImage/UIButton+WebCache.h>

@interface PLVECMoreViewItem ()

@property (nonatomic, assign) NSUInteger tag;

@end

@implementation PLVECMoreViewItem

@end

@interface PLVECMoreView ()

@property (nonatomic, copy) NSArray<PLVECMoreViewItem *> *items;

@property (nonatomic, strong) UIScrollView *scrollView;

@end

@implementation PLVECMoreView

#pragma mark - Life Cycle

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self addSubview:self.scrollView];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self layoutItemButtons];
}

- (CGFloat)preferredPortraitHeight {
    CGFloat width = CGRectGetWidth(self.bounds);
    if (width <= 0) {
        width = CGRectGetWidth(UIScreen.mainScreen.bounds);
    }
    NSInteger columns = [self columnCountForWidth:width];
    NSInteger rows = [self rowCountForItemCount:self.items.count columns:columns];
    CGFloat bottomInset = P_SafeAreaBottomEdgeInsets();
    CGFloat height = 46 + [self contentHeightForRows:rows] + 24 + bottomInset;
    return MAX(130 + bottomInset, height);
}

#pragma mark - Public

- (void)reloadData {
    if (self.delegate) {
        NSArray *items = [self.delegate dataSourceOfMoreView:self];
        [self setupUIWithItems:items];
        [self updatePortraitFrameIfNeeded];
    }
}

- (void)removeMoreViewItems {
    for (PLVECMoreViewItem *item in self.items) {
        UIView *subView = [self.scrollView viewWithTag:item.tag];
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
        itemBtn.tag = item.tag;
        itemBtn.selected = item.isSelected;
        [itemBtn setTitle:item.title forState:UIControlStateNormal];
        if (item.selectedTitle) {
            [itemBtn setTitle:item.selectedTitle forState:UIControlStateSelected];
        }
        [itemBtn setTitleEdgeInsets:UIEdgeInsetsMake(42, -38, 0, -5)];
        
        if (item.iconURLString) {
            NSURL *iconURL = [NSURL URLWithString:item.iconURLString];
            [itemBtn sd_setImageWithURL:iconURL forState:UIControlStateNormal];
        } else {
            UIImage *image = [PLVECUtils imageForWatchResource:item.iconImageName];
            [itemBtn setImage:image forState:UIControlStateNormal];
            if (item.selectedIconImageName) {
                UIImage *selectImage = [PLVECUtils imageForWatchResource:item.selectedIconImageName];
                [itemBtn setImage:selectImage forState:UIControlStateSelected];
            }
        }
        [itemBtn setImageEdgeInsets:UIEdgeInsetsMake(0, 19, 22, 9)];
        
        itemBtn.titleLabel.font = [UIFont systemFontOfSize:12.0];
        itemBtn.titleLabel.textColor = [UIColor colorWithWhite:205/255.0 alpha:1];
        [itemBtn addTarget:self action:@selector(switchItemButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        [self.scrollView addSubview:itemBtn];
    }
    [self layoutItemButtons];
}

- (void)layoutItemButtons {
    CGFloat width = CGRectGetWidth(self.bounds);
    if (width <= 0) {
        return;
    }
    NSInteger columns = [self columnCountForWidth:width];
    NSInteger rows = [self rowCountForItemCount:self.items.count columns:columns];
    CGFloat scrollHeight = MAX(60, CGRectGetHeight(self.bounds) - 46);
    self.scrollView.frame = CGRectMake(0, 46, width, scrollHeight);
    self.scrollView.contentSize = CGSizeMake(width, [self contentHeightForRows:rows]);
    for (NSInteger i = 0; i < self.items.count; i++) {
        UIView *button = [self.scrollView viewWithTag:self.items[i].tag];
        NSInteger column = i % columns;
        NSInteger row = i / columns;
        button.frame = CGRectMake(12 + 72 * column, [self rowOriginY:row], 70, 54);
    }
}

- (CGFloat)rowOriginY:(NSInteger)row {
    return row * 65.0;
}

- (CGFloat)contentHeightForRows:(NSInteger)rows {
    if (rows <= 1) {
        return 60.0;
    }
    return 60.0 + (rows - 1) * 65.0;
}

- (void)updatePortraitFrameIfNeeded {
    if ([PLVECUtils sharedUtils].isLandscape) {
        return;
    }
    CGFloat height = [self preferredPortraitHeight];
    CGRect frame = self.frame;
    if (fabs(CGRectGetHeight(frame) - height) < 0.5) {
        return;
    }
    CGFloat maxY = CGRectGetMaxY(frame);
    frame.size.height = height;
    frame.origin.y = maxY - height;
    self.frame = frame;
}

- (NSInteger)columnCountForWidth:(CGFloat)width {
    NSInteger columns = (NSInteger)floor((width - 12) / 72.0);
    return MAX(columns, 1);
}

- (NSInteger)rowCountForItemCount:(NSInteger)count columns:(NSInteger)columns {
    if (count <= 0 || columns <= 0) {
        return 1;
    }
    return (count + columns - 1) / columns;
}

- (void)switchItemButtonAction:(UIButton *)button {
    NSUInteger selectedIndex = button.tag - 200;
    if (selectedIndex > self.items.count - 1) {
        selectedIndex = self.items.count - 1;
    }
    PLVECMoreViewItem *item = self.items[selectedIndex];
    item.selected = button.selected = !button.isSelected;
    if ([self.delegate respondsToSelector:@selector(moreView:didSelectItem:)]) {
        [self.delegate moreView:self didSelectItem:item];
    }
}

#pragma mark - Getter & Setter
- (UIScrollView *)scrollView {
    if (!_scrollView) {
        _scrollView = [[UIScrollView alloc] init];
        _scrollView.showsHorizontalScrollIndicator = NO;
        _scrollView.showsHorizontalScrollIndicator = NO;
    }
    return _scrollView;
}

@end
