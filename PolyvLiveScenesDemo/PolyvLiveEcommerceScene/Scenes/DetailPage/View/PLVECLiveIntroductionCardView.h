//
//  PLVECLiveIntroductionCardView.h
//  PolyvLiveEcommerceDemo
//
//  Created by ftao on 2020/5/21.
//  Copyright © 2020 polyv. All rights reserved.
//

#import "PLVECCardView.h"
#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

@class PLVECLiveIntroductionCardView;
@protocol PLVECLiveIntroductionCardViewDelegate <PLVECCardViewDelegate>

@optional

- (void)cardView:(PLVECLiveIntroductionCardView *)cardView didLoadWebViewHeight:(CGFloat)height;

@end

/// 直播介绍卡片视图
@interface PLVECLiveIntroductionCardView : PLVECCardView

@property (nonatomic, strong) UILabel *backgroundLable;

@property (nonatomic, strong) WKWebView *webView;

@property (nonatomic, weak) id<PLVECLiveIntroductionCardViewDelegate> liDelegate;

@property (nonatomic, copy) NSString *htmlCont;

@end

NS_ASSUME_NONNULL_END
