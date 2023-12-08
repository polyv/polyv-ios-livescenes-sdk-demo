//
//  PLVECBulletinCardView.h
//  PLVLiveEcommerceDemo
//
//  Created by ftao on 2020/5/25.
//  Copyright © 2020 PLV. All rights reserved.
//

#import "PLVECCardView.h"
#import <WebKit/WebKit.h>

@class PLVECBulletinCardView;
@protocol PLVECBulletinCardViewDelegate <PLVECCardViewDelegate>

@optional

- (void)bulletinCardView:(PLVECBulletinCardView *)cardView didLoadWebViewHeight:(CGFloat)height;

@end

/// 公告卡片视图
@interface PLVECBulletinCardView : PLVECCardView

@property (nonatomic, weak) id<PLVECBulletinCardViewDelegate> bulletinDelegate;

@property (nonatomic, strong, readonly) WKWebView *webView;

@property (nonatomic, copy) NSString *content;

@end
