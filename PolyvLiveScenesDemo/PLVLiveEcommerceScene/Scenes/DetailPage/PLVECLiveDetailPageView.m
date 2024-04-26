//
//  PLVECLiveDetailPageView.m
//  PLVLiveEcommerceDemo
//
//  Created by ftao on 2020/5/21.
//  Copyright © 2020 PLV. All rights reserved.
//

#import "PLVECLiveDetailPageView.h"
#import "PLVECBulletinCardView.h"
#import "PLVECLiveIntroductionCardView.h"
#import "PLVECUtils.h"
#import <PLVFoundationSDK/PLVFdUtil.h>

@interface PLVECLiveDetailPageView () <PLVECBulletinCardViewDelegate, PLVECLiveIntroductionCardViewDelegate>

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) PLVECBulletinCardView *bulletinCardView;
@property (nonatomic, strong) PLVECLiveIntroductionCardView *liveInfoCardView;
@property (nonatomic, assign) CGFloat liveInfoCardViewHeight;
@property (nonatomic, assign) CGFloat bulletinCardViewHeight;

@end

@implementation PLVECLiveDetailPageView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.scrollView = [[UIScrollView alloc] init];
        self.scrollView.showsVerticalScrollIndicator = NO;
        self.scrollView.showsHorizontalScrollIndicator = NO;
        self.scrollView.alwaysBounceVertical = YES;
        [self addSubview:self.scrollView];
        
        self.bulletinCardView = [[PLVECBulletinCardView alloc] init];
        self.bulletinCardView.bulletinDelegate = self;
        self.bulletinCardView.hidden = YES;
        [self.scrollView addSubview:self.bulletinCardView];
        
        self.liveInfoCardView = [[PLVECLiveIntroductionCardView alloc] init];
        self.liveInfoCardView.liDelegate = self;
        [self.scrollView addSubview:self.liveInfoCardView];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat ratioY = 0.3f;
    CGFloat liveInfoHeight = 220 + P_SafeAreaBottomEdgeInsets();
    
    self.scrollView.frame = CGRectMake(15, CGRectGetHeight(self.bounds)*ratioY, CGRectGetWidth(self.bounds)-30, CGRectGetHeight(self.bounds)*(1-ratioY)-10);
    if (self.liveInfoCardViewHeight == 0) {
        self.liveInfoCardViewHeight = liveInfoHeight;
        self.liveInfoCardView.frame = CGRectMake(0, CGRectGetHeight(self.scrollView.bounds)-liveInfoHeight, CGRectGetWidth(self.scrollView.bounds), liveInfoHeight);
    }
    if (self.bulletinCardViewHeight == 0) {
        CGFloat bulletinHeight = 66;
        self.bulletinCardViewHeight = bulletinHeight;
        self.bulletinCardView.frame = CGRectMake(0, CGRectGetMinY(self.liveInfoCardView.frame)- bulletinHeight -8, CGRectGetWidth(self.scrollView.bounds), bulletinHeight);
    }
}

#pragma mark - Public

- (void)addLiveInfoCardView:(NSString *)content {
    if ([content isKindOfClass:NSString.class]) {
        self.liveInfoCardViewHeight = 0;
        self.liveInfoCardView.htmlCont = content;
    }
}

- (void)addBulletinCardView:(NSString *)content {
    self.bulletinCardView.hidden = NO;
    self.bulletinCardViewHeight = 0;
    self.bulletinCardView.content = content;
}

- (void)removeBulletinCardView {
    self.bulletinCardView.hidden = YES;
    self.bulletinCardView.content = nil;
}

#pragma mark - Pravite

- (void)layoutCardViews {
    CGRect bulletinNewFrame = self.bulletinCardView.frame;
    CGFloat bulletinNewFrameY = CGRectGetMinY(self.liveInfoCardView.frame) - self.bulletinCardViewHeight - 8;
    bulletinNewFrame.size.height = self.bulletinCardViewHeight;
    bulletinNewFrame.origin.y = MAX(0, bulletinNewFrameY);
    self.bulletinCardView.frame = bulletinNewFrame;
   
    CGRect infoNewFrame = self.liveInfoCardView.frame;
    infoNewFrame.size.height = self.liveInfoCardViewHeight;
    infoNewFrame.origin.y = bulletinNewFrameY > 0 ? infoNewFrame.origin.y : CGRectGetMaxY(bulletinNewFrame) + 8;
    self.liveInfoCardView.frame = infoNewFrame;
    
    self.scrollView.contentSize = CGSizeMake(CGRectGetWidth(self.scrollView.bounds), CGRectGetMaxY(self.liveInfoCardView.frame));
}

#pragma mark - <PLVECCardViewDelegate>

- (void)cardView:(PLVECCardView *)cardView didInteractWithURL:(NSURL *)URL {
    NSLog(@"%@ %@", NSStringFromSelector(_cmd),URL);
    if ([cardView isKindOfClass:PLVECBulletinCardView.class]) {
        [[UIApplication sharedApplication] openURL:URL];
    } else if ([cardView isKindOfClass:PLVECLiveIntroductionCardView.class]) {
        [[UIApplication sharedApplication] openURL:URL];
    }
}

#pragma mark - <PLVECLiveIntroductionCardViewDelegate>

- (void)cardView:(PLVECLiveIntroductionCardView *)cardView didLoadWebViewHeight:(CGFloat)height {
    if (height > CGRectGetHeight(cardView.webView.bounds)) {
        self.liveInfoCardViewHeight = CGRectGetMinY(self.liveInfoCardView.webView.frame) + height + 10;
        plv_dispatch_main_async_safe(^{
            [self layoutCardViews];
        })
    }
}

#pragma mark - <PLVECBulletinCardViewDelegate>

- (void)bulletinCardView:(PLVECBulletinCardView *)cardView didLoadWebViewHeight:(CGFloat)height {
    if (height > 0) {
        self.bulletinCardViewHeight = CGRectGetMinY(self.bulletinCardView.webView.frame) + height + 5;
        plv_dispatch_main_async_safe(^{
            [self layoutCardViews];
        })
    }
}

@end
