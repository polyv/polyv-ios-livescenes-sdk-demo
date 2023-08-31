//
//  PLVSAMixLayoutSheet.m
//  PLVLiveScenesDemo
//
//  Created by Dhan on 2023/7/25.
//  Copyright © 2023 PLV. All rights reserved.
//

#import "PLVSAMixLayoutSheet.h"
#import "PLVSAUtils.h"

@interface PLVSAMixLayoutSheet()

// UI
@property (nonatomic, strong) UILabel *titleLable;
// 渐变
@property (nonatomic, strong) CAGradientLayer *gradientLayer;


/// 数据
// 可选混流布局枚举值数组
@property (nonatomic, strong) NSArray *mixLayoutTypeArray;
// 可选混流布局字符串数组
@property (nonatomic, strong) NSArray <NSString *>*mixLayoutTypeStringArray;
// 选项按钮数组，只初始化一次
@property (nonatomic, strong) NSArray <UIButton *> *optionsButtonArray;

@end

@implementation PLVSAMixLayoutSheet

#pragma mark - [ Life Cycle ]
- (instancetype)initWithSheetHeight:(CGFloat)sheetHeight sheetLandscapeWidth:(CGFloat)sheetLandscapeWidth {
    self = [super initWithSheetHeight:sheetHeight sheetLandscapeWidth:sheetLandscapeWidth];
    if (self) {
        [self initUI];
    }
    return self;
}

- (void)initUI {
    [self.contentView addSubview:self.titleLable];
}

#pragma mark - [ Override ]

- (void)layoutSubviews {
    [super layoutSubviews];
    BOOL isPad = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
    CGFloat titleLableLeft = 32;
    CGFloat buttonWidth = 88;
    CGFloat buttonHeight = 36;
    CGFloat buttonY = 83;
    CGFloat contentViewWidth = self.contentView.bounds.size.width;
    CGFloat paddingX = (contentViewWidth - self.optionsButtonArray.count * buttonWidth) / (self.optionsButtonArray.count + 1);
    // iPad时的中间和两边边距
    CGFloat middlePadding = 0;
    CGFloat margin = 0;
    BOOL isLandscape = [PLVSAUtils sharedUtils].isLandscape;
    
    if (isPad) {
        titleLableLeft = 56;
        buttonWidth = 120;
        middlePadding = contentViewWidth * 0.052;
        margin = (contentViewWidth - middlePadding * (self.optionsButtonArray.count - 1) - buttonWidth * self.optionsButtonArray.count) / 2;
    }
    self.titleLable.frame = CGRectMake(titleLableLeft, 32, 90, 18);
    
    for (int i = 0; i < self.optionsButtonArray.count; i ++) {
        UIButton *button = self.optionsButtonArray[i];
        CGFloat buttonX = (i * buttonWidth) + (i + 1) * paddingX;
        CGFloat paddingY = 24;
        if (isPad) {
            buttonX = (i * buttonWidth) + margin + (i * middlePadding);
            paddingY = 88;
        }
        if (isLandscape) {
            buttonX = titleLableLeft;
            buttonY = CGRectGetMaxY(self.titleLable.frame) + 31 + (i * buttonHeight) + (i + 1) * paddingY;
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

#pragma mark Getter

- (UILabel *)titleLable {
    if (!_titleLable) {
        _titleLable = [[UILabel alloc] init];
        _titleLable.font = [UIFont fontWithName:@"PingFangSC-Regular" size:18];
        _titleLable.textColor = PLV_UIColorFromRGB(@"#F0F1F5");
        _titleLable.text = @"混流布局";
    }
    return _titleLable;
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
        [PLVSAUtils showToastWithMessage:[NSString stringWithFormat:@"已切换为%@", sender.titleLabel.text] inView:[PLVSAUtils sharedUtils].homeVC.view];
        [self dismiss];
        if (self.delegate && [self.delegate respondsToSelector:@selector(plvsaMixLayoutSheet:mixLayoutButtonClickWithMixLayoutType:)]) {
            PLVMixLayoutType type = [self.mixLayoutTypeArray[sender.tag] integerValue];
            [self.delegate plvsaMixLayoutSheet:self mixLayoutButtonClickWithMixLayoutType:type];
        }
    } else {
        [PLVSAUtils showToastWithMessage:@"网络异常，请恢复网络后重试" inView:[PLVSAUtils sharedUtils].homeVC.view];
        [self dismiss];
    }
}

@end
