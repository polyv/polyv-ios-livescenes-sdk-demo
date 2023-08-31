//
//  PLVLSMixLayoutSheet.m
//  PLVLiveScenesDemo
//
//  Created by Dhan on 2023/7/25.
//  Copyright © 2023 PLV. All rights reserved.
//

#import "PLVLSMixLayoutSheet.h"
#import "PLVLSSettingSheetCell.h"
#import "PLVLSUtils.h"
#import "PLVRoomDataManager.h"
#import <PLVFoundationSDK/PLVFdUtil.h>

@interface PLVLSMixLayoutSheet()

/// UI
@property (nonatomic, strong) UILabel *sheetTitleLabel; // 弹层顶部标题
@property (nonatomic, strong) UIView *titleSplitLine; // 标题底部分割线
@property (nonatomic, strong) CAGradientLayer *gradientLayer; // 渐变

/// 数据
@property (nonatomic, strong) NSArray *mixLayoutTypeArray; // 可选混流布局枚举值数组
@property (nonatomic, strong) NSArray <NSString *>*mixLayoutTypeStringArray; // 可选混流布局字符串数组
@property (nonatomic, strong) NSArray <UIButton *> *optionsButtonArray;
@property (nonatomic, assign) CGFloat sheetWidth; // 父类数据

@end

@implementation PLVLSMixLayoutSheet

@synthesize sheetWidth = _sheetWidth;

- (instancetype)initWithSheetWidth:(CGFloat)sheetWidth {
    self = [super initWithSheetWidth:sheetWidth];
    if (self) {
        [self.contentView addSubview:self.sheetTitleLabel];
        [self.contentView addSubview:self.titleSplitLine];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    BOOL isPad = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
    CGFloat sheetTitleLabelTop = 14;
    CGFloat titleSplitLineTop = 44;
    CGFloat buttonWidth = 88;
    CGFloat buttonHeight = 36;
    CGFloat buttonY = 83;
    CGFloat contentViewWidth = self.contentView.bounds.size.width;
    CGFloat paddingX = (contentViewWidth - self.optionsButtonArray.count * buttonWidth) / (self.optionsButtonArray.count + 1);
    // iPad时的中间和两边边距
    CGFloat middlePadding = 0;
    CGFloat margin = 0;

    if (isPad) {
        sheetTitleLabelTop += PLVLSUtils.safeTopPad;
        titleSplitLineTop += PLVLSUtils.safeTopPad;
        buttonWidth = 120;
        middlePadding = contentViewWidth * 0.052;
        margin = (contentViewWidth - middlePadding * (self.optionsButtonArray.count - 1) - buttonWidth * self.optionsButtonArray.count) / 2;
    }
    
    CGFloat originX = 16;
    self.sheetTitleLabel.frame = CGRectMake(originX, sheetTitleLabelTop, self.sheetWidth - originX * 2, 22);
    self.titleSplitLine.frame = CGRectMake(originX, titleSplitLineTop, self.sheetWidth - originX * 2, 1);
    for (int i = 0; i < self.optionsButtonArray.count; i ++) {
        UIButton *button = self.optionsButtonArray[i];
        CGFloat buttonX = (i * buttonWidth) + (i + 1) * paddingX;
        if (isPad) {
            buttonX = (i * buttonWidth) + margin + (i * middlePadding);
        }
        button.frame = CGRectMake(buttonX , buttonY, buttonWidth, buttonHeight);
        
        if (button.selected) {
            self.gradientLayer.frame = button.bounds;
        }
    }
}

- (void)setupMixLayoutTypeOptionsWithCurrentMixLayoutType:(PLVMixLayoutType)currentType {
    NSMutableArray *buttonMuArray = [[NSMutableArray alloc] initWithCapacity:[self.mixLayoutTypeStringArray count]];
    for (int i = 0; i < self.mixLayoutTypeStringArray.count; i ++) {
        UIButton *button = [[UIButton alloc] init];
        button.layer.masksToBounds = YES;
        button.layer.cornerRadius = 18;
        button.tag = i;
        button.titleLabel.font = [UIFont fontWithName:@"PingFangSC-Semibold" size:14];
        button.backgroundColor = PLV_UIColorFromRGBA(@"#FFFFFF", 0.2);
        [button setTitleColor:PLV_UIColorFromRGB(@"#FFFFFF") forState:UIControlStateNormal];
        [button setTitle:self.mixLayoutTypeStringArray[i] forState:UIControlStateNormal];
        [button addTarget:self action:@selector(mixLayoutButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        if ([self.mixLayoutTypeArray[i] integerValue] == currentType) {
            button.selected = YES;
            [button.layer insertSublayer:self.gradientLayer atIndex:0];
        }
        [self.contentView addSubview:button];
        [buttonMuArray addObject:button];
    }
    self.optionsButtonArray = [buttonMuArray copy];
}

- (void)updateMixLayoutType:(PLVMixLayoutType)currentType {
    for (UIButton *button in self.optionsButtonArray) {
        button.selected = NO;
        if (button.tag == currentType) {
            button.selected = YES;
            self.gradientLayer.frame = button.bounds;
            [button.layer insertSublayer:self.gradientLayer atIndex:0];
        }
    }
}

#pragma mark - Override
- (void)showInView:(UIView *)parentView{
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    BOOL isPad = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
    CGFloat scale = isPad ? 0.43 : 0.52;
    self.sheetWidth = screenWidth * scale;
    [super showInView:parentView];
}

#pragma mark - Getter

- (UILabel *)sheetTitleLabel {
    if (!_sheetTitleLabel) {
        _sheetTitleLabel = [[UILabel alloc] init];
        _sheetTitleLabel.textColor = [UIColor colorWithRed:0xf0/255.0 green:0xf1/255.0 blue:0xf5/255.0 alpha:1];
        _sheetTitleLabel.font = [UIFont boldSystemFontOfSize:16];
        _sheetTitleLabel.text = @"混流布局";
    }
    return _sheetTitleLabel;
}

- (UIView *)titleSplitLine {
    if (!_titleSplitLine) {
        _titleSplitLine = [[UIView alloc] init];
        _titleSplitLine.backgroundColor = [UIColor colorWithRed:0xf0/255.0 green:0xf1/255.0 blue:0xf5/255.0 alpha:0.1];
    }
    return _titleSplitLine;
}

- (CAGradientLayer *)gradientLayer {
    if (!_gradientLayer) {
        _gradientLayer = [CAGradientLayer layer];
        _gradientLayer.colors = @[(__bridge id)PLV_UIColorFromRGB(@"#0080FF").CGColor, (__bridge id)PLV_UIColorFromRGB(@"#3399FF").CGColor];
        _gradientLayer.locations = @[@0.5, @1.0];
        _gradientLayer.startPoint = CGPointMake(0, 0);
        _gradientLayer.endPoint = CGPointMake(1.0, 0);
    }
    return _gradientLayer;
}

- (NSArray *)mixLayoutTypeArray {
    if (!_mixLayoutTypeArray) {
        _mixLayoutTypeArray = @[@(PLVMixLayoutType_MainSpeaker), @(PLVMixLayoutType_Tile), @(PLVMixLayoutType_Single)];
    }
    return _mixLayoutTypeArray;
}

- (NSArray <NSString *> *)mixLayoutTypeStringArray {
    if (!_mixLayoutTypeStringArray) {
        NSMutableArray *muArray = [[NSMutableArray alloc] initWithCapacity:self.mixLayoutTypeArray.count];
        for (int i = 0; i < [self.mixLayoutTypeArray count]; i++) {
            PLVMixLayoutType mixLayoutType = [self.mixLayoutTypeArray[i] integerValue];
            NSString *string = [PLVRoomData mixLayoutTypeStringWithType:mixLayoutType];
            [muArray addObject:string];
        }
        _mixLayoutTypeStringArray = [muArray copy];
    }
    return _mixLayoutTypeStringArray;
}

#pragma mark - [ Action ]

- (void)mixLayoutButtonAction:(UIButton *)sender {
    PLVNetworkStatus networkStatus = [PLVReachability reachabilityForInternetConnection].currentReachabilityStatus;
    if (networkStatus != PLVNotReachable) {
        for (UIButton *button in self.optionsButtonArray) {
            button.selected = NO;
        }
        sender.selected = YES;
        self.gradientLayer.frame = sender.bounds;
        [sender.layer insertSublayer:self.gradientLayer atIndex:0];
        [self dismiss];
        if (self.delegate && [self.delegate respondsToSelector:@selector(mixLayoutSheet_didChangeMixLayoutType:)]) {
            PLVMixLayoutType type = [self.mixLayoutTypeArray[sender.tag] integerValue];
            [self.delegate mixLayoutSheet_didChangeMixLayoutType:type];
        }
    } else {
        [PLVLSUtils showToastWithMessage:@"网络异常，请恢复网络后重试" inView:[PLVLSUtils sharedUtils].homeVC.view];
        __weak typeof(self) weakSelf = self;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [weakSelf dismiss];
        });
    }
}

@end
