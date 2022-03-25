//
//  PLVActionSheet.m
//  PLVActionSheet
//
//  Created by Lincal on 2019/10/18.
//  Copyright © 2019 plv. All rights reserved.
//

#import "PLVActionSheet.h"

#import <PLVFoundationSDK/PLVFoundationSDK.h>

static const CGFloat kRowH = 48.0f;
static const CGFloat kRowLineH = 0.5f;
static const CGFloat kSeparatorH = 6.0f;
static const CGFloat kTitleFontSize = 14.0f;
static const CGFloat kBtnTitleFontSize = 18.0f;
static const NSTimeInterval kAnimateDuration = 0.3f;

#define bgColor [UIColor colorWithRed:43/255.0 green:44/255.0 blue:53/255.0 alpha:1.0] // 按钮背景色
#define bgColorSelected [UIColor colorWithRed:34/255.0 green:35/255.0 blue:42/255.0 alpha:1.0] // 按钮高亮背景色

@interface PLVActionSheet ()

// 背景视图
@property (nonatomic, strong) UIView * bgV;
// 弹出视图
@property (nonatomic, strong) UIView * actionSheetV;
// 弹出视图原高度
@property (nonatomic, assign) float oriActionSheetH;
// 取消按钮
@property (nonatomic, strong) UIButton * cancelBtn;
// 回调
@property (nonatomic, strong) PLVActionSheetBlock actionSheetBlock;

// 文本
@property (nonatomic, copy) NSString * title;
@property (nonatomic, copy) NSString * cancelBtnTitle;
@property (nonatomic, copy) NSString * destructiveBtnTitle;
@property (nonatomic, copy) NSArray <NSString *> * otherBtnTitles;

// 收起视图
- (void)dismiss;

@end

@implementation PLVActionSheet

#pragma mark - Init
- (instancetype)initWithFrame:(CGRect)frame{
    return [self initWithTitle:nil cancelBtnTitle:nil destructiveBtnTitle:nil otherBtnTitles:nil handler:nil];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder{
    return [self initWithTitle:nil cancelBtnTitle:nil destructiveBtnTitle:nil otherBtnTitles:nil handler:nil];
}

- (instancetype)initWithTitle:(NSString * _Nullable)title
               cancelBtnTitle:(NSString * _Nullable)cancelBtnTitle
          destructiveBtnTitle:(NSString * _Nullable)destructiveBtnTitle
               otherBtnTitles:(NSArray * _Nullable)otherBtnTitles
                      handler:(PLVActionSheetBlock _Nullable)actionSheetBlock{
    if (self = [super initWithFrame:CGRectZero]){
        self.frame = CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, [[UIScreen mainScreen] bounds].size.height);
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        self.title = title;
        self.cancelBtnTitle = cancelBtnTitle;
        self.destructiveBtnTitle = destructiveBtnTitle;
        self.otherBtnTitles = otherBtnTitles;
        self.actionSheetBlock = actionSheetBlock;
        
        [self initUI];
    }
    return self;
}

- (void)initUI{
    CGFloat actionSheetH = 0;
    
    self.bgV = [[UIView alloc] initWithFrame:self.frame];
    self.bgV.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.bgV.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.4f];
    self.bgV.alpha = 0;
    [self addSubview:self.bgV];
    
    self.actionSheetV = [[UIView alloc] initWithFrame:CGRectMake(0, self.frame.size.height, self.frame.size.width, 0)];
    self.actionSheetV.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
    self.actionSheetV.backgroundColor = [UIColor colorWithRed:26/255.0 green:27/255.0 blue:31/255.0 alpha:1.0];
    [self addSubview:self.actionSheetV];
    
    UIImage * normalImg = [PLVColorUtil createImageWithColor:bgColor];
    UIImage * highlightedImg = [PLVColorUtil createImageWithColor:bgColorSelected];
    
    NSString * title = self.title;
    NSString * destructiveBtnTitle = self.destructiveBtnTitle;
    NSArray * otherBtnTitles = self.otherBtnTitles;
    NSString * cancelBtnTitle = self.cancelBtnTitle;
    
    if (title && title.length > 0)
    {
        CGFloat titleHeight = ceil([title boundingRectWithSize:CGSizeMake(self.frame.size.width, MAXFLOAT)
                                                       options:NSStringDrawingUsesLineFragmentOrigin
                                                    attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:kTitleFontSize]}
                                                       context:nil].size.height) + 15 * 2;
        
        UILabel * titleLb = [[UILabel alloc] initWithFrame:CGRectMake(0, actionSheetH, self.frame.size.width, titleHeight)];
        titleLb.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        titleLb.text = title;
        titleLb.backgroundColor = bgColor;
        titleLb.textColor = [UIColor colorWithRed:153/255.0 green:153/255.0 blue:153/255.0 alpha:1.0];
        titleLb.textAlignment = NSTextAlignmentCenter;
        titleLb.font = [UIFont fontWithName:@"PingFang SC" size:kTitleFontSize];
        titleLb.numberOfLines = 0;
        [_actionSheetV addSubview:titleLb];
        
        actionSheetH += titleHeight;
    }
    
    if (destructiveBtnTitle && destructiveBtnTitle.length > 0)
    {
        actionSheetH += kRowLineH;
        
        UIButton * destructiveBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        destructiveBtn.frame = CGRectMake(0, actionSheetH, self.frame.size.width, kRowH);
        destructiveBtn.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        destructiveBtn.tag = -1;
        destructiveBtn.titleLabel.font = [UIFont fontWithName:@"PingFang SC" size:kBtnTitleFontSize];
        [destructiveBtn setTitle:destructiveBtnTitle forState:UIControlStateNormal];
        [destructiveBtn setTitleColor:[UIColor colorWithRed:242/255.0 green:68/255.0 blue:83/255.0 alpha:1.0] forState:UIControlStateNormal];
        [destructiveBtn setBackgroundImage:normalImg forState:UIControlStateNormal];
        [destructiveBtn setBackgroundImage:highlightedImg forState:UIControlStateHighlighted];
        [destructiveBtn addTarget:self action:@selector(btnAction:) forControlEvents:UIControlEventTouchUpInside];
        [_actionSheetV addSubview:destructiveBtn];
        
        actionSheetH += kRowH;
    }
    
    if (otherBtnTitles && [otherBtnTitles count] > 0)
    {
        for (int i = 0; i < otherBtnTitles.count; i++)
        {
            actionSheetH += kRowLineH;
            
            UIButton * btn = [UIButton buttonWithType:UIButtonTypeCustom];
            btn.frame = CGRectMake(0, actionSheetH, self.frame.size.width, kRowH);
            btn.autoresizingMask = UIViewAutoresizingFlexibleWidth;
            btn.tag = i + 1;
            btn.titleLabel.font = [UIFont fontWithName:@"PingFang SC" size:kBtnTitleFontSize];
            [btn setTitle:otherBtnTitles[i] forState:UIControlStateNormal];
            [btn setTitleColor:[UIColor colorWithRed:64.0f/255.0f green:64.0f/255.0f blue:64.0f/255.0f alpha:1.0f] forState:UIControlStateNormal];
            [btn setBackgroundImage:normalImg forState:UIControlStateNormal];
            [btn setBackgroundImage:highlightedImg forState:UIControlStateHighlighted];
            [btn addTarget:self action:@selector(btnAction:) forControlEvents:UIControlEventTouchUpInside];
            [_actionSheetV addSubview:btn];
            
            actionSheetH += kRowH;
        }
    }
    
    if (cancelBtnTitle && cancelBtnTitle.length > 0)
    {
        actionSheetH += kSeparatorH;
        
        UIButton * cancelBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        cancelBtn.frame = CGRectMake(0, actionSheetH, self.frame.size.width, kRowH);
        cancelBtn.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        cancelBtn.tag = 0;
        cancelBtn.titleLabel.font = [UIFont fontWithName:@"PingFang SC" size:kBtnTitleFontSize];
        [cancelBtn setTitle:cancelBtnTitle ?: @"取消" forState:UIControlStateNormal];
        [cancelBtn setTitleColor:[UIColor colorWithRed:173/255.0 green:173/255.0 blue:192/255.0 alpha:1.0] forState:UIControlStateNormal];
        [cancelBtn setBackgroundImage:normalImg forState:UIControlStateNormal];
        [cancelBtn setBackgroundImage:highlightedImg forState:UIControlStateHighlighted];
        [cancelBtn addTarget:self action:@selector(btnAction:) forControlEvents:UIControlEventTouchUpInside];
        [_actionSheetV addSubview:cancelBtn];
        self.cancelBtn = cancelBtn;
        
        actionSheetH += kRowH;
    }
        
    self.oriActionSheetH = actionSheetH;
    _actionSheetV.frame = CGRectMake(0, self.frame.size.height, self.frame.size.width, actionSheetH);
}


#pragma mark - Private Methods
- (void)layoutSubviews{
    
    float visualOffset = 8;
    float bottomInset = P_SafeAreaBottomEdgeInsets() + visualOffset;
    
    CGRect cancelBtnFrame = self.cancelBtn.frame;
    cancelBtnFrame.size.height = kRowH + bottomInset;
    self.cancelBtn.frame = cancelBtnFrame;
    self.cancelBtn.titleEdgeInsets = UIEdgeInsetsMake(0, 0, bottomInset, 0);
    
    CGRect actionSheetVFrame = _actionSheetV.frame;
    actionSheetVFrame.size.height = self.oriActionSheetH + bottomInset;
    self.actionSheetV.frame = actionSheetVFrame;

    [UIView animateWithDuration:kAnimateDuration delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.7f options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.bgV.alpha = 1.0f;
        self.actionSheetV.frame = CGRectMake(0, self.frame.size.height - self.actionSheetV.frame.size.height + visualOffset, self.frame.size.width, self.actionSheetV.frame.size.height);
    } completion:nil];
}

- (void)dismiss{
    [UIView animateWithDuration:kAnimateDuration delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.bgV.alpha = 0.0f;
        self.actionSheetV.frame = CGRectMake(0, self.frame.size.height, self.frame.size.width, self.actionSheetV.frame.size.height);
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
}

- (void)dealloc{
    NSLog(@"PLVActionSheet - Dealloc");
}


#pragma mark - Event
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    UITouch * touch = [touches anyObject];
    CGPoint point = [touch locationInView:self.bgV];
    if (!CGRectContainsPoint(self.actionSheetV.frame, point)){
        if (self.actionSheetBlock){ self.actionSheetBlock(self, 0); }
        [self dismiss];
    }
}

- (void)btnAction:(UIButton *)btn{
    if (self.actionSheetBlock){ self.actionSheetBlock(self, btn.tag); }
    [self dismiss];
}


#pragma mark - Public Method
+ (instancetype)actionSheetWithTitle:(NSString *)title cancelBtnTitle:(NSString *)cancelBtnTitle destructiveBtnTitle:(NSString *)destructiveBtnTitle otherBtnTitles:(NSArray *)otherBtnTitles handler:(PLVActionSheetBlock)actionSheetBlock{
    return [[self alloc] initWithTitle:title cancelBtnTitle:cancelBtnTitle destructiveBtnTitle:destructiveBtnTitle otherBtnTitles:otherBtnTitles handler:actionSheetBlock];
}

+ (void)showActionSheetWithTitle:(NSString *)title cancelBtnTitle:(NSString *)cancelBtnTitle destructiveBtnTitle:(NSString *)destructiveBtnTitle otherBtnTitles:(NSArray *)otherBtnTitles handler:(PLVActionSheetBlock)actionSheetBlock{
    PLVActionSheet * actionSheet = [self actionSheetWithTitle:title cancelBtnTitle:cancelBtnTitle destructiveBtnTitle:destructiveBtnTitle otherBtnTitles:otherBtnTitles handler:actionSheetBlock];
    [actionSheet show];
}

- (void)show{
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
