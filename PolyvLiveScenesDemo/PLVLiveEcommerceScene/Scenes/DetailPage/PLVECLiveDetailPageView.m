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

@interface PLVECLiveDetailPageView () <PLVECCardViewDelegate, PLVECLiveIntroductionCardViewDelegate>

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) PLVECBulletinCardView *bulletinCardView;
@property (nonatomic, strong) PLVECLiveIntroductionCardView *liveInfoCardView;
@property (nonatomic, assign) CGFloat liveInfoCardViewHeight;

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
        self.bulletinCardView.delegate = self;
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
        self.liveInfoCardView.frame = CGRectMake(0, CGRectGetHeight(self.scrollView.bounds)-liveInfoHeight, CGRectGetWidth(self.scrollView.bounds), liveInfoHeight);
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
    self.bulletinCardView.content = content;
    
    CGSize newSize = [self.bulletinCardView.contentTextView sizeThatFits:CGSizeMake(CGRectGetWidth(self.scrollView.bounds)-30, MAXFLOAT)];
    CGFloat bulletinHeight =  newSize.height + 66;
    self.bulletinCardView.frame = CGRectMake(0, CGRectGetMinY(self.liveInfoCardView.frame)-bulletinHeight-8, CGRectGetWidth(self.scrollView.bounds), bulletinHeight);
}

- (void)removeBulletinCardView {
    self.bulletinCardView.hidden = YES;
    self.bulletinCardView.content = nil;
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
        CGRect newFrame = self.liveInfoCardView.frame;
        newFrame.size.height = CGRectGetMinY(self.liveInfoCardView.webView.frame) + height + 10;
        self.liveInfoCardViewHeight = newFrame.size.height;
        self.liveInfoCardView.frame = newFrame;

        self.scrollView.contentSize = CGSizeMake(CGRectGetWidth(self.scrollView.bounds), CGRectGetMaxY(cardView.frame));
    }
}

@end
