//
//  PLVGiveRewardView.m
//  PolyvCloudClassDemo
//
//  Created by Lincal on 2019/12/4.
//  Copyright © 2019 polyv. All rights reserved.
//

#import "PLVGiveRewardView.h"
#import <PLVFoundationSDK/PLVFoundationSDK.h>
#import "PLVGiveRewardGoodsButton.h"
#import "PLVLCUtils.h"

#define SCREEN_WIDTH ([UIScreen mainScreen].bounds.size.width)
#define SCREEN_HEIGHT ([UIScreen mainScreen].bounds.size.height)


@interface PLVGiveRewardView ()<UIScrollViewDelegate>

@property (nonatomic, strong) UIView * bgView;
@property (nonatomic, strong) UIView * rewardBgView;

@property (nonatomic, strong) UIView * headerView;
@property (nonatomic, strong) UIButton * backButton;
@property (nonatomic, strong) UILabel * titleLabel;

@property (nonatomic, strong) UIView * prizeBgView;
@property (nonatomic, strong) UILabel * pointsLabel;
@property (nonatomic, strong) UIScrollView * prizeBgScrollView;
@property (nonatomic, strong) UIPageControl *pageControl;

@property (nonatomic, strong) UIView * footerView;
@property (nonatomic, strong) UIScrollView * numButtonScrollView;
@property (nonatomic, strong) UIButton * sendButton;

/// 数据
@property (nonatomic, strong) NSArray <PLVRewardGoodsModel *> * modelArray;
@property (nonatomic, assign) CGFloat rewardBgViewH;
@property (nonatomic, assign) PLVRewardViewType rewardType;
/// 视图是否触发隐藏事件
@property (nonatomic, assign) BOOL isHidden;
@property (nonatomic, assign) BOOL currentLandscape;    // 当前是否横屏 (YES:当前横屏 NO:当前竖屏)
@property (nonatomic, assign) BOOL fullScreenDifferent; // 在更新UI布局之前，横竖屏是否发现了变化 (YES:已变化 NO:没有变化)


/// 状态
@property (nonatomic, strong) UIButton * curSelectedNumButton;
@property (nonatomic, strong) PLVGiveRewardGoodsButton * curSelectedPrizeButton;
@property (nonatomic, strong) PLVRewardGoodsModel * curSelectedPrizeModel;

@end


@implementation PLVGiveRewardView

#pragma mark - [ Init ]
- (instancetype)initWithRewardType:(PLVRewardViewType)rewardType {
    if ([super init]) {
        self.rewardType = rewardType;
        [self initUI];
    }
    return self;
}

- (void)initUI {
    self.rewardBgViewH = 304 + ([self isiPhoneXSeries] ? 34 : 0);
    
    [self addSubview:self.bgView];
    [self addSubview:self.rewardBgView];
    
    [self.rewardBgView addSubview:self.headerView];
    [self.headerView addSubview:self.titleLabel];
    [self.headerView addSubview:self.pointsLabel];

    [self.rewardBgView addSubview:self.prizeBgView];
    [self.prizeBgView addSubview:self.prizeBgScrollView];
    [self.prizeBgView addSubview:self.pageControl];

    [self.rewardBgView addSubview:self.footerView];
    [self.footerView addSubview:self.numButtonScrollView];
    [self.footerView addSubview:self.sendButton];
    self.currentLandscape = [self isFullScreen];
}

#pragma mark - layout
- (void)layoutSubviews {
    if (self.isHidden) {
        [self prizeButtonAction:[self.prizeBgScrollView viewWithTag:200]];
        self.prizeBgScrollView.contentOffset = CGPointMake(0, 0);
    } else {
        [self updateUI];
    }
}

- (void)updateUI {
    BOOL fullScreen = [self isFullScreen];
    self.fullScreenDifferent = (self.currentLandscape != fullScreen);
    self.currentLandscape = fullScreen;
    if (fullScreen) {
        /// 横屏
        CGFloat x = 0;
        if ([self isiPhoneXSeries]) {
            x = self.safeAreaInsets.left;
        }
        self.headerView.frame = CGRectMake(x, 0, SCREEN_WIDTH - x, 50);
        self.prizeBgView.frame = CGRectMake(x, CGRectGetMaxY(self.headerView.frame), SCREEN_WIDTH - x, 124);
        self.prizeBgScrollView.frame = CGRectMake(0, 0, CGRectGetWidth(self.prizeBgView.frame), 124);
        self.pageControl.hidden = YES;
        CGFloat footerViewH = CGRectGetHeight(self.rewardBgView.frame) - 50 - 124;
        self.footerView.frame = CGRectMake(x, CGRectGetMaxY(self.prizeBgView.frame), SCREEN_WIDTH - x, footerViewH);
    } else {
        /// 竖屏
        self.headerView.frame = CGRectMake(0, 0, SCREEN_WIDTH, 50);
        self.prizeBgView.frame = CGRectMake(0, CGRectGetMaxY(self.headerView.frame), SCREEN_WIDTH, 215);
        self.prizeBgScrollView.frame = CGRectMake(0, 0, SCREEN_WIDTH, 196);
        self.pageControl.hidden = NO;
        self.pageControl.frame = CGRectMake(0, CGRectGetMaxY(self.prizeBgScrollView.frame), SCREEN_WIDTH, 16);
        CGFloat footerViewH = 39 + ([self isiPhoneXSeries] ? 34 : 0);
        self.footerView.frame = CGRectMake(0, CGRectGetMaxY(self.prizeBgView.frame), SCREEN_WIDTH, footerViewH);
    }
    [self setupCornerRadius];
    /// 屏幕方向发生变化时，刷新礼物列表布局
    if (self.fullScreenDifferent) {
        [self refreshGoods:self.modelArray];
    }
    self.titleLabel.frame = CGRectMake(16, 16, 64, 22);
    self.numButtonScrollView.frame = CGRectMake(0, 0, SCREEN_WIDTH - 100, CGRectGetHeight(self.footerView.frame));
    [self refreshFooterView];
}

- (void)refreshFooterView {
    for (UIView * subview in self.numButtonScrollView.subviews) {
        [subview removeFromSuperview];
    }
    BOOL isFullScreen = [self isFullScreen];
    CGFloat footerViewH;
    CGFloat numButtonWidth;
    CGFloat numButtonHeight;
    CGFloat numButtonPadding;
    if (isFullScreen) {
        footerViewH = CGRectGetHeight(self.rewardBgView.frame) - 50 - 124;
        numButtonWidth = 44;
        numButtonHeight = 28;
        numButtonPadding = 8;
    } else {
        footerViewH = 39 + ([self isiPhoneXSeries] ? 34 : 0);
        numButtonWidth = 36;
        numButtonHeight = 24;
        numButtonPadding = 4;
    }

    CGFloat y = [self isiPhoneXSeries] ? 12 : (footerViewH - numButtonHeight) / 2;
    NSArray * numArray = @[@"1",@"5",@"10",@"66",@"88",@"666"];
    for (int i = 0; i < numArray.count; i ++) {
        NSString * numString = numArray[i];
        UIButton * numButton = [self createNumButtonWithNumString:numString];
        numButton.tag = 100 + i;
        [self.numButtonScrollView addSubview:numButton];
        
        if (i == 0){
            numButton.selected = YES;
            self.curSelectedNumButton = numButton;
            numButton.frame = CGRectMake(16, y, numButtonWidth, numButtonHeight);
            numButton.layer.borderWidth = 1;
        } else {
            UIButton * lastButton = (UIButton *)[self.numButtonScrollView viewWithTag:numButton.tag - 1];
            numButton.frame = CGRectMake(CGRectGetMaxX(lastButton.frame) + numButtonPadding, y, numButtonWidth, numButtonHeight);
        }

    }
    CGFloat totalWidth = 19 + (numButtonWidth + numButtonPadding) * numArray.count;
    self.numButtonScrollView.contentSize = CGSizeMake(totalWidth, footerViewH);
    CGFloat sendButtonY = [self isiPhoneXSeries] ? 6 : (footerViewH - 32) / 2;
    CGFloat sendButtonWidth = [self isFullScreen] ? 64 : 54;
    CGFloat sendButtonX;
    if (isFullScreen) {
        sendButtonX = CGRectGetWidth(self.footerView.frame) - (16 + sendButtonWidth) - ([self isiPhoneXSeries] ? 30 : 0);
    } else {
        sendButtonX = CGRectGetWidth(self.footerView.frame) - (16 + sendButtonWidth);
    }
    self.sendButton.frame = CGRectMake(sendButtonX, sendButtonY, sendButtonWidth, 32);
}

- (void)setupCornerRadius {
    if (self.rewardType == PLVRewardViewTypeEC) {
        UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:self.rewardBgView.bounds byRoundingCorners:UIRectCornerTopLeft | UIRectCornerTopRight cornerRadii:CGSizeMake(10,10)];
        
        CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
        maskLayer.frame = self.rewardBgView.bounds;
        maskLayer.path = maskPath.CGPath;
        self.rewardBgView.layer.mask = maskLayer;
    }
}

#pragma mark - [ Private Methods ]
- (void)prizeScrollviewRefreshGoods:(NSArray <PLVRewardGoodsModel *> *)prizeModelArray{
    for (UIView * subview in self.prizeBgScrollView.subviews) {
        [subview removeFromSuperview];
    }
    BOOL fullScreen = [self isFullScreen];
    
    NSMutableArray *availablePrizeModelArray = [[NSMutableArray alloc]init];
    for (PLVRewardGoodsModel *model in prizeModelArray) {
        if (model.goodEnabled) {
            [availablePrizeModelArray addObject:model];
        }
    }

    for (int j = 0; j < availablePrizeModelArray.count; j ++) {
        PLVRewardGoodsModel * model = availablePrizeModelArray[j];

        PLVGiveRewardGoodsButton * button = [[PLVGiveRewardGoodsButton alloc]init];
        [button setModel:model pointUnit:self.pointUnit];
        button.tag = 200 + j;
        [button addTarget:self action:@selector(prizeButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        [self.prizeBgScrollView addSubview:button];

        if (j == 0) {
            button.selected = YES;
            self.curSelectedPrizeButton = button;
            self.curSelectedPrizeModel = model;
        }
        
        if (fullScreen) {
            float width = 92.0;
            float height = 124.0;
            float padding = 16;
            float x = width * j + padding;
            float y = 0;
            button.frame = CGRectMake(x, y, width, height);
        } else {
            int row = j % 5;
            int section = j / 10;
            float width = 72.0;
            float height = 98.0;
            float padding = (SCREEN_WIDTH - width * 5) / 2;
            float x = section * SCREEN_WIDTH + padding + row * width;
            float y = 0;
            if(j - section * 10 > 4) {
                y = height;
            }
            button.frame = CGRectMake(x, y, width, height);
        }
    }
}

- (UIButton *)createNumButtonWithNumString:(NSString *)num{
    UIButton * numButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [numButton setTitle:num forState:UIControlStateNormal];
    [numButton setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
    [numButton setTitleColor:[UIColor colorWithRed:173/255.0 green:173/255.0 blue:192/255.0 alpha:1.0] forState:UIControlStateNormal];
    numButton.titleLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:12];
    numButton.layer.masksToBounds = YES;
    if ([self isFullScreen]) {
        numButton.layer.cornerRadius = 14;
    } else {
        numButton.layer.cornerRadius = 12;
    }
    numButton.layer.borderWidth = 0;
    numButton.layer.borderColor = [UIColor colorWithRed:173/255.0 green:173/255.0 blue:192/255.0 alpha:1.0].CGColor;
    [numButton addTarget:self action:@selector(numButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [numButton setBackgroundImage:[PLVColorUtil createImageWithColor:[UIColor colorWithRed:26/255.0 green:27/255.0 blue:31/255.0 alpha:1.0]] forState:UIControlStateNormal];
    [numButton setBackgroundImage:[PLVColorUtil createImageWithColor:[UIColor colorWithRed:62/255.0 green:62/255.0 blue:78/255.0 alpha:1.0]]forState:UIControlStateSelected];
    
    return numButton;
}

#pragma mark - Getter
- (UIView *)bgView{
    if (!_bgView) {
        _bgView = [[UIView alloc]init];
        _bgView.backgroundColor = [UIColor clearColor];
        [_bgView addGestureRecognizer: [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(bgViewTapAction:)]];
    }
    return _bgView;
}

- (UIView *)rewardBgView{
    if (!_rewardBgView) {
         _rewardBgView = [[UIView alloc]init];
        _rewardBgView.backgroundColor = [UIColor colorWithRed:0/255.0 green:0/255.0 blue:0/255.0 alpha:0.8];
     }
     return _rewardBgView;
}

- (UIView *)headerView{
    if (!_headerView) {
        _headerView = [[UIView alloc]init];
    }
    return _headerView;
}

- (UILabel *)titleLabel{
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc]init];
        _titleLabel.text = @"积分打赏";
        _titleLabel.textColor = [UIColor whiteColor];
        _titleLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:16.0];
    }
    return _titleLabel;
}

- (UIView *)prizeBgView{
    if (!_prizeBgView) {
        _prizeBgView = [[UIView alloc]init];
    }
    return _prizeBgView;
}

- (UILabel *)pointsLabel{
    if (!_pointsLabel) {
        _pointsLabel = [[UILabel alloc]init];
        _pointsLabel.font = [UIFont systemFontOfSize:12.0];
        _pointsLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:12.0];
        _pointsLabel.textColor = [UIColor colorWithRed:173/255.0 green:173/255.0 blue:192/255.0 alpha:1.0];
        _pointsLabel.text = @"我的积分：0";
        _pointsLabel.textAlignment = NSTextAlignmentLeft;
    }
    return _pointsLabel;
}

- (UIScrollView *)prizeBgScrollView{
    if (!_prizeBgScrollView) {
        _prizeBgScrollView = [[UIScrollView alloc]init];
        _prizeBgScrollView.showsVerticalScrollIndicator = NO;
        _prizeBgScrollView.showsHorizontalScrollIndicator = NO;
        _prizeBgScrollView.delegate = self;
    }
    return _prizeBgScrollView;
}

- (UIPageControl *)pageControl{
    if (!_pageControl) {
        _pageControl = [[UIPageControl alloc]init];
        _pageControl.currentPage = 0;
        [_pageControl setTransform:CGAffineTransformMakeScale(0.9, 0.9)];
        _pageControl.currentPageIndicatorTintColor = [UIColor colorWithRed:173/255.0 green:173/255.0 blue:192/255.0 alpha:1.0];
        _pageControl.pageIndicatorTintColor = [UIColor colorWithRed:26/255.0 green:27/255.0 blue:31/255.0 alpha:1.0];
        _pageControl.hidesForSinglePage = YES;
        _pageControl.userInteractionEnabled = NO;
    }
    return _pageControl;
}

- (UIView *)footerView{
    if (!_footerView) {
        _footerView = [[UIView alloc]init];
    }
    return _footerView;
}

- (UIScrollView *)numButtonScrollView{
    if (!_numButtonScrollView) {
        _numButtonScrollView = [[UIScrollView alloc]init];
        _numButtonScrollView.showsVerticalScrollIndicator = NO;
        _numButtonScrollView.showsHorizontalScrollIndicator = NO;
    }
    return _numButtonScrollView;
}

- (UIButton *)sendButton{
    if (!_sendButton) {
        _sendButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _sendButton.titleLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:14];
        [_sendButton setTitle:@"打赏" forState:UIControlStateNormal];
        [_sendButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        if (self.rewardType == PLVRewardViewTypeLC) {
            [_sendButton setBackgroundColor:[UIColor colorWithRed:255/255.0 green:106/255.0 blue:93/255.0 alpha:1.0]];
        } else {
            [_sendButton setBackgroundColor:[UIColor colorWithRed:255/255.0 green:166/255.0 blue:17/255.0 alpha:1.0]];
        }
        [_sendButton addTarget:self action:@selector(sendButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        _sendButton.layer.masksToBounds = YES;
        _sendButton.layer.cornerRadius = 16;
    }
    return _sendButton;
}


#pragma mark - [ Delegate ]
#pragma mark UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    if (scrollView.pagingEnabled) {
        int pageNumber = scrollView.contentOffset.x / scrollView.frame.size.width;
        self.pageControl.currentPage = pageNumber;
    }
}


#pragma mark - [ Event ]
- (void)bgViewTapAction:(UITapGestureRecognizer *)tap{
    [self hide];
}

- (void)sendButtonAction:(UIButton *)button{
    NSInteger num = [self.curSelectedNumButton.titleLabel.text integerValue];
    BOOL isPointReward = [self.payWay isEqualToString:@"POINT"];
    if (isPointReward) { /// 积分支付
        if ([self.delegate respondsToSelector:@selector(plvGiveRewardView:pointRewardWithGoodsModel:num:)]) {
            [self.delegate plvGiveRewardView:self pointRewardWithGoodsModel:self.curSelectedPrizeModel num:num];
        }
    } else { /// 现金支付 （移动端不支持现金支付功能，只能打赏免费礼物）
        if ([self.delegate respondsToSelector:@selector(plvGiveRewardView:cashRewardWithGoodsModel:num:)]) {
            [self.delegate plvGiveRewardView:self cashRewardWithGoodsModel:self.curSelectedPrizeModel num:num];
        }
    }

    [self hide];
}

- (void)numButtonAction:(UIButton *)button{
    if (button.selected) { return; }
    
    self.curSelectedNumButton.layer.borderWidth = 0;
    self.curSelectedNumButton.selected = NO;
    self.curSelectedNumButton.userInteractionEnabled = YES;
    self.curSelectedNumButton = button;
    self.curSelectedNumButton.selected = YES;
    self.curSelectedNumButton.userInteractionEnabled = NO;
    self.curSelectedNumButton.layer.borderWidth = 1;
}

- (void)prizeButtonAction:(PLVGiveRewardGoodsButton *)button{
    if (button.selected) { return; }

    self.curSelectedPrizeButton.selected = NO;
    self.curSelectedPrizeButton.userInteractionEnabled = YES;
    self.curSelectedPrizeButton = button;
    self.curSelectedPrizeButton.selected = YES;
    self.curSelectedPrizeButton.userInteractionEnabled = NO;

    PLVRewardGoodsModel * model = self.modelArray[button.tag - 200];
    self.curSelectedPrizeModel = model;
}


#pragma mark - [ Public Methods ]
- (void)refreshGoods:(NSArray<PLVRewardGoodsModel *> *)goodsModelArray{
    if (goodsModelArray.count > 0) {
        [self prizeScrollviewRefreshGoods:goodsModelArray];
        if ([self isFullScreen]) {
            CGFloat padding = 32;
            CGFloat scrollViewWidth = goodsModelArray.count * 92 + padding;
            self.prizeBgScrollView.contentSize = CGSizeMake(scrollViewWidth, 124);
            self.prizeBgScrollView.pagingEnabled = NO;
        } else {
            double page = ceil(goodsModelArray.count / 10.0);
            self.pageControl.numberOfPages = page;
            self.prizeBgScrollView.contentSize = CGSizeMake(SCREEN_WIDTH * page, 196);
            self.prizeBgScrollView.pagingEnabled = YES;
        }

        self.modelArray = goodsModelArray;
    }
}

- (void)refreshUserPoint:(NSString *)userPoint{
    if (userPoint && [userPoint isKindOfClass:NSString.class] && userPoint.length > 0) {
        self.pointsLabel.text = [NSString stringWithFormat:@"我的积分：%@ %@",userPoint,self.pointUnit];
        CGSize labelSize = [self.pointsLabel.text boundingRectWithSize:CGSizeMake(SCREEN_WIDTH - 20, 40) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName: self.pointsLabel.font} context:nil].size;
        self.pointsLabel.frame = CGRectMake(CGRectGetMaxX(self.titleLabel.frame) + 8, 19, labelSize.width + 10, labelSize.height);
    }
}

- (void)showOnView:(UIView *)superView{
    self.frame = superView.bounds;
    self.bgView.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
    CGFloat rewardBgViewH = [self isFullScreen] ? SCREEN_HEIGHT * 0.6 : self.rewardBgViewH;
    self.rewardBgView.frame = CGRectMake(0, SCREEN_HEIGHT + rewardBgViewH, SCREEN_WIDTH, rewardBgViewH);
    [superView addSubview:self];
    
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:0.33 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        weakSelf.alpha = 1;
        weakSelf.rewardBgView.frame = CGRectMake(0, SCREEN_HEIGHT - rewardBgViewH, SCREEN_WIDTH, rewardBgViewH);
        weakSelf.isHidden = NO;
    } completion:nil];
}

- (void)hide{
    if (self.alpha == 0) { return; }
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:0.33 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        weakSelf.alpha = 0;
        weakSelf.rewardBgView.frame = CGRectMake(0, SCREEN_HEIGHT + weakSelf.rewardBgViewH, SCREEN_WIDTH, SCREEN_HEIGHT);
        weakSelf.isHidden = YES;
    } completion:^(BOOL finished) {
        [weakSelf removeFromSuperview];
    }];
}


#pragma mark  [ Setter ]

- (void)setPayWay:(NSString *)payWay {
    _payWay = payWay;
    self.titleLabel.text = [payWay isEqualToString:@"POINT"] ? @"积分打赏" : @"礼物打赏";
}

#pragma mark - util
- (BOOL)isiPhoneXSeries{
    BOOL isPhoneX = NO;
    if (PLV_iOSVERSION_Available_11_0) {
        isPhoneX = [[UIApplication sharedApplication] delegate].window.safeAreaInsets.bottom > 0.0;
    }
    return isPhoneX;
}

- (BOOL)isFullScreen{
    return SCREEN_WIDTH > SCREEN_HEIGHT;
}


@end
