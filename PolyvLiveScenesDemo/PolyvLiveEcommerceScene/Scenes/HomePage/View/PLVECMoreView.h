//
//  PLVECMoreView.h
//  PolyvLiveScenesDemo
//
//  Created by ftao on 2020/7/2.
//  Copyright © 2020 polyv. All rights reserved.
//

#import "PLVECBottomView.h"

NS_ASSUME_NONNULL_BEGIN

@interface PLVECMoreViewItem : NSObject

@property (nonatomic, copy) NSString *title;

@property (nonatomic, copy) NSString *selectedTitle;

@property (nonatomic, strong) NSString *iconImageName;

@property (nonatomic, strong) NSString *selectedIconImageName;

@property (nonatomic, getter=isSelected) BOOL selected;

@end

@class PLVECMoreView;

@protocol PLVECMoreViewDelegate <NSObject>

@required

- (NSArray<PLVECMoreViewItem *> *)dataSourceOfMoreView:(PLVECMoreView *)moreView;

- (void)moreView:(PLVECMoreView *)moreView didSelectItem:(PLVECMoreViewItem *)item index:(NSUInteger)index;

@end

@interface PLVECMoreView : PLVECBottomView

@property (nonatomic, weak) id<PLVECMoreViewDelegate> delegate;

- (void)reloadData;

@end

NS_ASSUME_NONNULL_END
