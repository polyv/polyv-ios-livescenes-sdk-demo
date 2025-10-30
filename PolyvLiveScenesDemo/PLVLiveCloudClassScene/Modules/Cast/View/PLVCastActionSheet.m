//
//  PLVCastActionSheet.m
//  PLVCastActionSheet
//
//  Created by Lincal on 2019/10/18.
//  Copyright © 2019 plv. All rights reserved.
//

#import "PLVCastActionSheet.h"

static const CGFloat kTopAndBottomPad = 18.0f;
static const CGFloat kRowH = 32.0f;
static const CGFloat kBtnTitleFontSize = 13.0f;
static const NSTimeInterval kAnimateDuration = 0.3f;
static const NSInteger kButtonTagConst = 100;
static NSString *kNormalButtonColor = @"#333333";
static NSString *kSelectedButtonColor = @"#56ACE9";

@interface PLVCastActionSheet ()

// 背景视图
@property (nonatomic, strong) UIView * bgV;
// 弹出视图
@property (nonatomic, strong) UIView * actionSheetV;
// 弹出视图原高度
@property (nonatomic, assign) float oriActionSheetH;
// 回调
@property (nonatomic, strong) PLVCastActionSheetBlock actionSheetBlock;

@property (nonatomic, copy) NSArray <NSString *> * otherBtnTitles;
// 选中按钮
@property (nonatomic, assign) NSInteger selectedIndex;

// 收起视图
- (void)dismiss;

@end

@implementation PLVCastActionSheet

#pragma mark - Life Cycle

- (instancetype)initWithFrame:(CGRect)frame {
    return [self initWithBtnTitles:nil selectedIndex:0 handler:nil];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    return [self initWithBtnTitles:nil selectedIndex:0 handler:nil];
}

#pragma mark - Initialize

- (void)initUI{
    CGFloat actionSheetH = kTopAndBottomPad;
    
    self.bgV = [[UIView alloc] initWithFrame:self.frame];
    self.bgV.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.bgV.backgroundColor = [UIColor colorWithRed:0x33/255.0f green:0x33/255.0f blue:0x33/255.0f alpha:0.5f];
    self.bgV.alpha = 0;
    [self addSubview:self.bgV];
    
    CGRect sheetRect = CGRectMake(0, self.frame.size.height, self.frame.size.width, 0);
    self.actionSheetV = [[UIView alloc] initWithFrame:sheetRect];
    self.actionSheetV.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
    self.actionSheetV.backgroundColor = [UIColor whiteColor];
    [self addSubview:self.actionSheetV];
    
    NSArray * otherBtnTitles = self.otherBtnTitles;
    
    if (otherBtnTitles && [otherBtnTitles count] > 0) {
        for (int i = 0; i < otherBtnTitles.count; i++) {
            UIButton * btn = [UIButton buttonWithType:UIButtonTypeCustom];
            btn.frame = CGRectMake(0, actionSheetH, self.frame.size.width, kRowH);
            btn.autoresizingMask = UIViewAutoresizingFlexibleWidth;
            btn.tag = i + kButtonTagConst;
            btn.titleLabel.font = [UIFont fontWithName:@"PingFang SC" size:kBtnTitleFontSize];
            [btn setTitle:otherBtnTitles[i] forState:UIControlStateNormal];
            NSString *colorHexstring = (self.selectedIndex == i) ? kSelectedButtonColor : kNormalButtonColor;
            [btn setTitleColor:[self colorFromHexString:colorHexstring] forState:UIControlStateNormal];
            [btn addTarget:self action:@selector(btnAction:) forControlEvents:UIControlEventTouchUpInside];
            [_actionSheetV addSubview:btn];
            
            actionSheetH += kRowH;
        }
    }
                                              
    actionSheetH += kTopAndBottomPad;
    self.oriActionSheetH = actionSheetH;
    _actionSheetV.frame = CGRectMake(0, self.frame.size.height, self.frame.size.width, actionSheetH);
    [self drawLayer];
}

#pragma mark - Override

- (void)layoutSubviews {
    float safeBottomPad = 0;
    if (@available(iOS 11, *)) {
        UIEdgeInsets safeAreaInsets = [UIApplication sharedApplication].keyWindow.rootViewController.view.safeAreaInsets;
        safeBottomPad = MAX(0, safeAreaInsets.bottom - kTopAndBottomPad);
    }
    float visualOffset = 8;
    float bottomInset = safeBottomPad + visualOffset;
    
    CGRect actionSheetVFrame = _actionSheetV.frame;
    actionSheetVFrame.size.height = self.oriActionSheetH + bottomInset;
    self.actionSheetV.frame = actionSheetVFrame;

    [UIView animateWithDuration:kAnimateDuration delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.7f options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.bgV.alpha = 1.0f;
        self.actionSheetV.frame = CGRectMake(0, self.frame.size.height - self.actionSheetV.frame.size.height + visualOffset, self.frame.size.width, self.actionSheetV.frame.size.height);
        [self drawLayer];
    } completion:nil];
}

#pragma mark - Private Methods

- (void)drawLayer {
    CGRect bounds = self.actionSheetV.bounds;
    UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:bounds
                                                   byRoundingCorners:UIRectCornerTopLeft|UIRectCornerTopRight
                                                         cornerRadii:CGSizeMake(10, 10)];
    CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
    maskLayer.frame = bounds;
    maskLayer.path = maskPath.CGPath;
    self.actionSheetV.layer.mask = maskLayer;
}

- (void)dismiss {
    [UIView animateWithDuration:kAnimateDuration delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.bgV.alpha = 0.0f;
        self.actionSheetV.frame = CGRectMake(0, self.frame.size.height, self.frame.size.width, self.actionSheetV.frame.size.height);
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
}

- (UIColor *)colorFromHexString:(NSString *)hexString {
    if (!hexString || hexString.length < 6) {
        return [UIColor whiteColor];
    }
    unsigned rgbValue = 0;
    NSScanner *scanner = [NSScanner scannerWithString:hexString];
    if ([hexString rangeOfString:@"#"].location == 0) {
        [scanner setScanLocation:1]; // bypass '#' character
    }
    [scanner scanHexInt:&rgbValue];
    return [UIColor colorWithRed:((rgbValue & 0xFF0000) >> 16)/255.0 green:((rgbValue & 0xFF00) >> 8)/255.0 blue:(rgbValue & 0xFF)/255.0 alpha:1];
}

#pragma mark - Event

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    UITouch * touch = [touches anyObject];
    CGPoint point = [touch locationInView:self.bgV];
    if (!CGRectContainsPoint(self.actionSheetV.frame, point)){
        [self dismiss];
    }
}

- (void)btnAction:(UIButton *)btn {
    if (self.actionSheetBlock) {
        self.actionSheetBlock(self, btn.tag - kButtonTagConst);
    }
    [self dismiss];
}

#pragma mark - Public Method

- (instancetype)initWithBtnTitles:(NSArray * _Nullable)otherBtnTitles
                    selectedIndex:(NSInteger)selectedIndex
                          handler:(PLVCastActionSheetBlock _Nullable)actionSheetBlock {
    if (self = [super initWithFrame:CGRectZero]){
        self.frame = CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, [[UIScreen mainScreen] bounds].size.height);
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        self.otherBtnTitles = otherBtnTitles;
        self.actionSheetBlock = actionSheetBlock;
        self.selectedIndex = MAX(MIN(selectedIndex, self.otherBtnTitles.count), 0);
        
        [self initUI];
    }
    return self;
}

+ (instancetype)actionSheetWithBtnTitles:(NSArray *)otherBtnTitles
                           selectedIndex:(NSInteger)selectedIndex
                                 handler:(PLVCastActionSheetBlock)actionSheetBlock {
    return [[self alloc] initWithBtnTitles:otherBtnTitles selectedIndex:selectedIndex handler:actionSheetBlock];
}

+ (void)showActionSheetWithBtnTitles:(NSArray *)otherBtnTitles
                       selectedIndex:(NSInteger)selectedIndex
                             handler:(PLVCastActionSheetBlock)actionSheetBlock {
    PLVCastActionSheet * actionSheet = [self actionSheetWithBtnTitles:otherBtnTitles
                                                    selectedIndex:selectedIndex
                                                          handler:actionSheetBlock];
    [actionSheet show];
}

- (void)show {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        NSEnumerator * frontToBackWindows = [UIApplication.sharedApplication.windows reverseObjectEnumerator];
        for (UIWindow * window in frontToBackWindows){
            BOOL windowOnMainScreen = window.screen == UIScreen.mainScreen;
            BOOL windowIsVisible = !window.hidden && window.alpha > 0;
            BOOL windowLevelNormal = window.windowLevel == UIWindowLevelNormal;
            
            if(windowOnMainScreen && windowIsVisible && windowLevelNormal){
                [window addSubview:self];
                [self layoutSubviews];
                break;
            }
        }
    }];
}

@end
