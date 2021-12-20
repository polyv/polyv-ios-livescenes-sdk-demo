//
//  PLVLCDocumentToolView.m
//  PolyvLiveScenesDemo
//
//  Created by lijingtong on 2021/10/19.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVLCDocumentToolView.h"

// 工具
#import "PLVLCUtils.h"

// UI
#import "PLVLCDocumentToolViewPopup.h"

@interface PLVLCDocumentToolView()

#pragma mark UI
@property (nonatomic, strong) UIButton *previousButton; // 上一个按钮
@property (nonatomic, strong) UIButton *nextButton; // 下一个按钮
@property (nonatomic, strong) UIButton *pageNumButton; // 页码视图
@property (nonatomic, strong) PLVLCDocumentToolViewPopup *guiedPopup; // 提示弹层

#pragma mark 数据
@property (nonatomic, assign) CGFloat viewWidth; // 视图宽度，动态计算
@property (nonatomic, assign) NSUInteger currentNum; // 当前页码
@property (nonatomic, assign) NSUInteger currentOriginNum; // 当前服务器页码
@property (nonatomic, assign) NSUInteger totalNum; // 总页码
@property (nonatomic, assign) NSUInteger maxNextNumber; // 最大的下一页
@property (nonatomic, assign) CGFloat pageNumLabelWidth; // 页码宽度
@property (nonatomic, assign) BOOL showGuied; // 是否已经显示新手引导
@property (nonatomic, assign) BOOL mainSpeakerPPTOnMain; // 直播场景中 主讲的PPT 当前是否在主屏


@end

@implementation PLVLCDocumentToolView

#pragma mark - [ Life Cycle ]

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.viewWidth = 0;
        self.hidden = YES;
        self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
        self.layer.cornerRadius = 18;
        self.layer.masksToBounds = YES;
        
        [self addSubview:self.previousButton];
        [self addSubview:self.pageNumButton];
        [self addSubview:self.nextButton];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat viewWidth = [UIScreen mainScreen].bounds.size.width;
    if (@available(iOS 11, *)) {
        viewWidth -= self.safeAreaInsets.left - self.safeAreaInsets.right;
    }
    CGFloat buttonWidth = 20;
    CGFloat padding = 8;
    CGFloat labelHeight = 17;
    CGFloat viewHeight = self.bounds.size.height;
    self.previousButton.frame = CGRectMake(padding, (viewHeight - buttonWidth ) / 2, buttonWidth, buttonWidth);
    self.pageNumButton.frame = CGRectMake(CGRectGetMaxX(self.previousButton.frame) + padding, (viewHeight - labelHeight ) / 2, self.pageNumLabelWidth, labelHeight);
    self.nextButton.frame = CGRectMake(CGRectGetMaxX(self.pageNumButton.frame) + padding, (viewHeight - buttonWidth ) / 2, buttonWidth, buttonWidth);
}

#pragma mark - [ Public Methods ]

- (void)setupPageNumber:(NSUInteger)pageNumber totalPage:(NSUInteger)totalPage maxNextNumber:(NSUInteger)maxNextNumber {
    
    NSUInteger currNum = pageNumber;
    NSUInteger totalNum = totalPage;
    
    currNum += 1;
    maxNextNumber += 1;
    self.currentNum = currNum;
    self.totalNum = totalNum;
    self.maxNextNumber = maxNextNumber;
    
    // PPT当前在主屏才显示
    self.hidden = !self.mainSpeakerPPTOnMain;
    
    self.previousButton.enabled = currNum > 1;
    self.nextButton.enabled = currNum < maxNextNumber;
    
    [self setupPageNum:currNum totalNum:totalNum];
    
    [self setNeedsLayout];
    [self.superview setNeedsLayout];
}

- (void)setupMainSpeakerPPTOnMain:(BOOL)mainSpeakerPPTOnMain {
    self.mainSpeakerPPTOnMain = mainSpeakerPPTOnMain;
    self.hidden = !(mainSpeakerPPTOnMain && self.totalNum > 0);
}

#pragma mark - [ Private Method ]
#pragma mark Getter

- (UIButton *)previousButton {
    if (!_previousButton) {
        _previousButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_previousButton setImage:[PLVLCUtils imageForMediaResource:@"plvlc_media_skin_ppt_previous"] forState:UIControlStateNormal];
        [_previousButton setImage:[PLVLCUtils imageForMediaResource:@"plvlc_media_skin_ppt_previous_disable"] forState:UIControlStateDisabled];
        [_previousButton addTarget:self action:@selector(previousButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _previousButton;
}

- (UIButton *)nextButton {
    if (!_nextButton) {
        _nextButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_nextButton setImage:[PLVLCUtils imageForMediaResource:@"plvlc_media_skin_ppt_next"] forState:UIControlStateNormal];
        [_nextButton setImage:[PLVLCUtils imageForMediaResource:@"plvlc_media_skin_ppt_next_disable"] forState:UIControlStateDisabled];
        [_nextButton addTarget:self action:@selector(nextButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _nextButton;
}

- (UIButton *)pageNumButton {
    if (!_pageNumButton) {
        _pageNumButton = [UIButton buttonWithType:UIButtonTypeCustom];
                          
        _pageNumButton.titleLabel.textColor = [UIColor whiteColor];
        _pageNumButton.titleLabel.font = [UIFont systemFontOfSize:14];
        _pageNumButton.titleLabel.textAlignment = NSTextAlignmentCenter;
        [_pageNumButton addTarget:self action:@selector(pageNumButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _pageNumButton;
}

- (PLVLCDocumentToolViewPopup *)guiedPopup {
    if (!_guiedPopup) {
        //在self顶部并居中
        CGFloat menuHeight = 34;
        CGFloat centerX = self.center.x;
        CGFloat originY = self.frame.origin.y - menuHeight - 2;
        CGFloat menuWidth = 100;
        CGRect rect = CGRectMake(centerX - menuWidth / 2.0, originY, menuWidth, menuHeight); // 此坐标已基于self.superView
        _guiedPopup = [[PLVLCDocumentToolViewPopup alloc] initWithMenuFrame:rect];
    }
    return _guiedPopup;
}

#pragma mark 工具

- (void)setupPageNum:(NSUInteger)currNum totalNum:(NSUInteger)totalNum {
    CGFloat buttonWidth = 20;
    CGFloat padding = 8;
    
    NSString *pageNumString = [NSString stringWithFormat:@"%zd/%zd", currNum, totalNum];
    NSAttributedString *attr = [[NSAttributedString alloc] initWithString:pageNumString attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:12]}];
    CGFloat pageNumWidth = [attr boundingRectWithSize:CGSizeMake(self.bounds.size.width, self.bounds.size.height)  options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading context:nil].size.width;
    
    
    self.pageNumLabelWidth = pageNumWidth + 16;
    self.viewWidth = buttonWidth * 2 + self.pageNumLabelWidth + padding * 4;
    [self.pageNumButton setTitle:pageNumString forState:UIControlStateNormal];
}

- (void)showGuiedView {
    if (self.showGuied) {
        return;
    }
    self.showGuied = YES;
    [self.guiedPopup showInView:self.superview];
}

#pragma mark - [ Event ]
#pragma mark Action

- (void)previousButtonAction {
    NSInteger currentNum = self.currentNum - 1;
    if (currentNum < 0) {
        self.previousButton.enabled = NO;
        return;
    }
    
    currentNum -= 1;
    self.currentNum = currentNum;
    self.previousButton.enabled = currentNum > 1;
    
    // 显示新手引导
    [self showGuiedView];
    
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(documentToolView:didChangePageWithType:)]) {
        [self.delegate documentToolView:self didChangePageWithType:PLVChangePPTPageTypePreviousStep];
    }
}

- (void)nextButtonAction {
    NSInteger currentNum = self.currentNum - 1;
    if (currentNum < 0 ||
        currentNum + 1 >= self.maxNextNumber) {
        self.nextButton.enabled = NO;
        return;
    }
 
    self.currentNum = currentNum;
    self.nextButton.enabled = currentNum < self.maxNextNumber;
    
    // 显示新手引导
    [self showGuiedView];
    
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(documentToolView:didChangePageWithType:)]) {
        [self.delegate documentToolView:self didChangePageWithType:PLVChangePPTPageTypeNextStep];
    }
}

- (void)pageNumButtonAction {
    [self.guiedPopup dismiss];
    
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(documentToolView:didChangePageWithType:)]) {
        [self.delegate documentToolView:self didChangePageWithType:PLVChangePPTPageTypePPTBtnBack];
    }
}

@end
