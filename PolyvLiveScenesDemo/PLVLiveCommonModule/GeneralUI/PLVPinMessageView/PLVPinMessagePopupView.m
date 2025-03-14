//
//  PLVPinMessagePopupView.m
//  PolyvLiveScenesDemo
//
//  Created by Sakya on 2024/7/1.
//  Copyright © 2024 PLV. All rights reserved.
//

#import "PLVPinMessagePopupView.h"
#import "PLVEmoticonManager.h"
#import "PLVMultiLanguageManager.h"
#import <PLVFoundationSDK/PLVFoundationSDK.h>
#import <SDWebImage/UIImageView+WebCache.h>

@interface PLVPinMessagePopupView() <UIScrollViewDelegate>

@property (nonatomic, strong) PLVSpeakTopMessage *speakTopMessage;
@property (nonatomic, strong) NSMutableArray<PLVSpeakTopMessage *> *speakTopMessages; // 用于存储消息

#pragma mark UI
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIPageControl *pageControl;
@property (nonatomic, strong) UIButton *closeButton;
@property (nonatomic, strong) UIButton *cancelTopButton;
@property (nonatomic, strong) UIVisualEffectView *effectView; // 高斯模糊效果图

@end

@implementation PLVPinMessagePopupView

#pragma mark - [ Life Period ]

- (instancetype)init {
    self = [super init];
    if (self) {
        _canPinMessage = NO;
        _speakTopMessages = [NSMutableArray array];
        [self setupUI];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat pageControlHeight = 20;
    CGFloat width = self.bounds.size.width;
    CGFloat height = self.bounds.size.height;
    CGFloat pageHeight = height - pageControlHeight;
    
    CGFloat padding = 12.0f;
    self.effectView.frame = self.bounds;
    self.closeButton.frame = CGRectMake(width - 24 - padding, (height - 24)/2, 24, 24);
    self.cancelTopButton.frame = CGRectMake(width - 42 - padding, (height - 24)/2, 42, 24);
    CGFloat contentLabelWidth = (self.closeButton.isHidden ? CGRectGetMinX(self.cancelTopButton.frame) - 8 : CGRectGetMinX(self.closeButton.frame) - 12) - padding;
    self.scrollView.frame = CGRectMake(0, 0, width, pageHeight);
    self.pageControl.frame = CGRectMake(0, pageHeight, width, pageControlHeight);
    NSUInteger index = 0;
    for (UIView *subview in self.scrollView.subviews) {
        subview.frame = CGRectMake(index * width + padding, 0, contentLabelWidth, pageHeight);
        index++;
    }
    self.scrollView.contentSize = CGSizeMake(index * width, pageHeight);
}

#pragma mark - [ Public Methods ]

- (void)updatePopupViewWithMessage:(PLVSpeakTopMessage * _Nullable)message {
    _speakTopMessage = message;
    [self updateTopMessageWithMessage:message];
    [self updateScrollViewContent];
    
    if (!message || (![message.action isEqualToString:@"top"] && ![PLVFdUtil checkArrayUseable:self.speakTopMessages])) {
        self.hidden = YES;
    } else if ([message.action isEqualToString:@"top"]) {
        self.hidden = NO;
    } else {
        [self.scrollView setContentOffset:CGPointMake(0, self.scrollView.contentOffset.y) animated:NO];
    }
}

#pragma mark Setter
- (void)setCanPinMessage:(BOOL)canPinMessage {
    _canPinMessage = canPinMessage;
    self.cancelTopButton.hidden = !canPinMessage;
    self.closeButton.hidden = canPinMessage;
}

#pragma mark - [ Private Methods ]

- (void)setupUI {
    self.layer.cornerRadius = 8.0f;
    self.layer.masksToBounds = YES;
    [self addSubview:self.effectView];
    [self addSubview:self.scrollView];
    [self addSubview:self.pageControl];
    [self addSubview:self.closeButton];
    [self addSubview:self.cancelTopButton];
}

- (void)updateTopMessageWithMessage:(PLVSpeakTopMessage * _Nullable)message {
    if (message) {
        NSMutableArray *array = [NSMutableArray array];
        if ([PLVFdUtil checkArrayUseable:message.others]) {
            for (NSDictionary *dict in message.others) {
                PLVSpeakTopMessage *other = [[PLVSpeakTopMessage alloc] initWithDictionary:dict];
                if (other) {
                    [array addObject:other];
                }
            }
        }
        
        if ([message.action isEqualToString:@"top"]) {
            [array insertObject:message atIndex:0];
            self.speakTopMessages = array;
        } else if ([PLVFdUtil checkStringUseable:message.msgId]) {
            array = [NSMutableArray arrayWithArray:self.speakTopMessages];
            for (PLVSpeakTopMessage *model in array) {
                if ([model.msgId isEqualToString:message.msgId]) {
                    if ([self.speakTopMessages containsObject:model]) {
                        [self.speakTopMessages removeObject:model];
                    }
                }
            }
        }
    }
}

- (void)updateScrollViewContent {
    // 清空现有子视图
    for (UIView *subview in self.scrollView.subviews) {
        [subview removeFromSuperview];
    }
    
    CGFloat padding = 12.0f;
    CGFloat width = self.bounds.size.width;
    CGFloat pageWidth = (self.closeButton.isHidden ? CGRectGetMinX(self.cancelTopButton.frame) - 8 : CGRectGetMinX(self.closeButton.frame) - 12) - padding;
    CGFloat pageHeight = self.bounds.size.height - 20;
    
    if (width == 0 || pageHeight == 0 || ![PLVFdUtil checkArrayUseable:self.speakTopMessages]) {
        return;
    }
    
    NSUInteger messageCount = 0;
    // 添加新消息视图
    for (NSUInteger i = 0; i < self.speakTopMessages.count; i++) {
        PLVSpeakTopMessage *message = self.speakTopMessages[i];
        
        if (![PLVFdUtil checkStringUseable:message.nick] ||
            ![PLVFdUtil checkStringUseable:message.content]) {
            continue;
        }
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(messageCount * width + padding, 0, pageWidth, pageHeight)];
        label.font = [UIFont systemFontOfSize:14];
        label.numberOfLines = 2.0f;
        
        NSDictionary *nickAttributeDict = @{
            NSFontAttributeName: [UIFont systemFontOfSize:12.0f],
            NSForegroundColorAttributeName:[PLVColorUtil colorFromHexString:@"#FFD16B"]
        };
        NSDictionary *contentAttributeDict = @{
            NSFontAttributeName: [UIFont systemFontOfSize:14.0f],
            NSForegroundColorAttributeName:[UIColor whiteColor]
        };
        NSAttributedString *nickAttString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@：", message.nick] attributes:nickAttributeDict];
        NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:message.content attributes:contentAttributeDict];
        NSMutableAttributedString *emojiAttributedString = [[PLVEmoticonManager sharedManager] converEmoticonTextToEmotionFormatText:attributedString font:[UIFont systemFontOfSize:16.0]];
        NSMutableAttributedString *contentString = [[NSMutableAttributedString alloc] init];
        [contentString appendAttributedString:nickAttString];
        [contentString appendAttributedString:emojiAttributedString];
        label.attributedText = contentString;
        label.lineBreakMode = NSLineBreakByTruncatingTail;
        messageCount++;
        [self.scrollView addSubview:label];
    }
    
    NSInteger currentPage = self.pageControl.currentPage;
    // 更新contentSize和PageControl
    self.scrollView.contentSize = CGSizeMake(messageCount * width, pageHeight);
    self.pageControl.numberOfPages = messageCount;
    self.pageControl.hidden = (messageCount <= 1);
}

#pragma mark Getter
- (UIButton *)closeButton {
    if (!_closeButton) {
        _closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _closeButton.hidden = self.canPinMessage;
        UIImage *image = [self imageForShareResource:@"plv_pin_close_btn"];
        [_closeButton setImage:image forState:UIControlStateNormal];
        [_closeButton addTarget:self action:@selector(closeButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _closeButton;
}

- (UIButton *)cancelTopButton {
    if (!_cancelTopButton) {
        _cancelTopButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _cancelTopButton.backgroundColor = [PLVColorUtil colorFromHexString:@"#3F76FC"];
        _cancelTopButton.layer.cornerRadius = 12.0f;
        _cancelTopButton.titleLabel.font = [UIFont systemFontOfSize:12];
        _cancelTopButton.hidden = !self.canPinMessage;
        [_cancelTopButton setTitle:PLVLocalizedString(@"下墙") forState:UIControlStateNormal];
        [_cancelTopButton addTarget:self action:@selector(cancelTopButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _cancelTopButton;
}

- (UIVisualEffectView *)effectView {
    if (!_effectView) {
        UIBlurEffect *effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
        _effectView = [[UIVisualEffectView alloc] initWithEffect:effect];
        _effectView.alpha = 0.9;
    }
    return _effectView;
}

- (UIScrollView *)scrollView {
    if (!_scrollView) {
        _scrollView = [[UIScrollView alloc] init];
        _scrollView.pagingEnabled = YES;
        _scrollView.showsHorizontalScrollIndicator = NO;
        _scrollView.showsVerticalScrollIndicator = NO;
        _scrollView.delegate = self;
    }
    return _scrollView;
}

- (UIPageControl *)pageControl {
    if (!_pageControl) {
        _pageControl = [[UIPageControl alloc] init];
        _pageControl.currentPageIndicatorTintColor = [PLVColorUtil colorFromHexString:@"#FFFFFF" alpha:0.6];
        _pageControl.pageIndicatorTintColor = [PLVColorUtil colorFromHexString:@"#FFFFFF" alpha:0.2];
        _pageControl.enabled = YES;
        [_pageControl addTarget:self action:@selector(pageControlDidChange:) forControlEvents:UIControlEventValueChanged];
    }
    return _pageControl;
}

#pragma mark - Utils

- (UIImage *)imageForShareResource:(NSString *)imageName {
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSBundle *resourceBundle = [NSBundle bundleWithPath:[bundle pathForResource:@"PLVPinMessage" ofType:@"bundle"]];
    return [UIImage imageNamed:imageName inBundle:resourceBundle compatibleWithTraitCollection:nil];
}

#pragma mark - [ Event ]

#pragma mark Action
- (void)closeButtonAction {
    self.hidden = YES;
}

- (void)cancelTopButtonAction {
    if ([PLVFdUtil checkArrayUseable:self.speakTopMessages] && self.pageControl.currentPage < self.speakTopMessages.count && self.pageControl.currentPage >= 0) {
        _cancelTopActionBlock ? _cancelTopActionBlock(self.speakTopMessages[self.pageControl.currentPage]) : nil;
    }
}

- (void)pageControlDidChange:(UIPageControl *)pageControl {
    CGFloat pageWidth = self.scrollView.bounds.size.width;
    CGPoint offset = CGPointMake(pageControl.currentPage * pageWidth, 0);
    [self.scrollView setContentOffset:offset animated:YES];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat pageWidth = scrollView.bounds.size.width;
    NSInteger currentPage = floor((scrollView.contentOffset.x + pageWidth / 2) / pageWidth);
    self.pageControl.currentPage = currentPage;
}

@end
