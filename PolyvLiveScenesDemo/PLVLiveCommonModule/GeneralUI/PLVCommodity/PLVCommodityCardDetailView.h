//
//  PLVCommodityCardDetailView.h
//  PolyvLiveScenesDemo
//
//  Created by Sakya on 2022/7/6.
//  Copyright © 2022 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 当前页面跳转的webview 商品卡片详情视图
@interface PLVCommodityCardDetailView : UIView

- (void)loadWebviewWithCardURL:(NSURL *)url;

- (void)showOnView:(UIView *)superView frame:(CGRect)frame;

- (void)hiddenCardDetailView;

@end

NS_ASSUME_NONNULL_END
