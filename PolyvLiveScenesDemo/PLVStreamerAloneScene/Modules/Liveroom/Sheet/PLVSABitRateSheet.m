//
//  PLVSABitRateSheet.m
//  PLVLiveScenesDemo
//
//  Created by jiaweihuang on 2021/5/27.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVSABitRateSheet.h"
#import <PLVFoundationSDK/PLVFoundationSDK.h>
#import "PLVSAUtils.h"
#import "PLVMultiLanguageManager.h"

@interface PLVSABitRateSheet()

// UI
@property (nonatomic, strong) UILabel *titleLable;
// 渐变
@property (nonatomic, strong) CAGradientLayer *gradientLayer;


/// 数据
// 可选清晰度枚举值数组
@property (nonatomic, strong) NSArray *resolutionTypeArray;
// 可选清晰度字符串数组
@property (nonatomic, strong) NSArray <NSString *>*resolutionStringArray;
// 选项按钮数组，只初始化一次
@property (nonatomic, strong) NSArray <UIButton *> *optionsButtonArray;

@end

@implementation PLVSABitRateSheet


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


#pragma mark - [ Public Method ]

- (void)setupBitRateOptionsWithCurrentBitRate:(PLVResolutionType)currentBitRate {
    NSMutableArray *buttonMuArray = [[NSMutableArray alloc] initWithCapacity:[self.resolutionStringArray count]];
    for (int i = 0; i < self.resolutionStringArray.count; i ++) {
        UIButton *button = [[UIButton alloc] init];
        button.layer.masksToBounds = YES;
        button.layer.cornerRadius = 18;
        button.tag = i;
        button.titleLabel.font = [UIFont fontWithName:@"PingFangSC-Semibold" size:14];
        button.backgroundColor = PLV_UIColorFromRGBA(@"#FFFFFF", 0.2);
        [button setTitleColor:PLV_UIColorFromRGB(@"#FFFFFF") forState:UIControlStateNormal];
        [button setTitle:self.resolutionStringArray[i] forState:UIControlStateNormal];
        [button addTarget:self action:@selector(bitRateButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        if ([self.resolutionTypeArray[i] integerValue] == currentBitRate) {
            button.selected = YES;
            [button.layer insertSublayer:self.gradientLayer atIndex:0];
        }
        [self.contentView addSubview:button];
        [buttonMuArray addObject:button];
    }
    self.optionsButtonArray = [buttonMuArray copy];
}


#pragma mark Getter

- (UILabel *)titleLable {
    if (!_titleLable) {
        _titleLable = [[UILabel alloc] init];
        _titleLable.font = [UIFont fontWithName:@"PingFangSC-Regular" size:18];
        _titleLable.textColor = PLV_UIColorFromRGB(@"#F0F1F5");
        _titleLable.text = PLVLocalizedString(@"清晰度设置");
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

- (NSArray *)resolutionTypeArray {
    if (!_resolutionTypeArray) {
        PLVRoomData *roomData = [PLVRoomDataManager sharedManager].roomData;
        NSArray *videoParams = [PLVLiveVideoConfig sharedInstance].videoParams;
        if ([PLVLiveVideoConfig sharedInstance].clientPushStreamTemplateEnabled && [PLVFdUtil checkArrayUseable:videoParams]) {
            NSMutableArray * resolutionLevelArray = [NSMutableArray array];
            for (int i = 0; i < videoParams.count; i++) {
                int reolutionType = (int) i * 4;
                [resolutionLevelArray addObject:@(reolutionType)];
            }
            _resolutionTypeArray = resolutionLevelArray;
        } else if (roomData.maxResolution == PLVResolutionType1080P) {
            _resolutionTypeArray = @[@(PLVResolutionType1080P), @(PLVResolutionType720P), @(PLVResolutionType360P)];
        } else if (roomData.maxResolution == PLVResolutionType720P) {
            _resolutionTypeArray = @[@(PLVResolutionType720P), @(PLVResolutionType360P), @(PLVResolutionType180P)];
        } else if (roomData.maxResolution == PLVResolutionType360P) {
            _resolutionTypeArray = @[@(PLVResolutionType360P), @(PLVResolutionType180P)];
        } else {
            _resolutionTypeArray = @[@(PLVResolutionType180P)];
        }
    }
    return _resolutionTypeArray;
}

- (NSArray <NSString *> *)resolutionStringArray {
    if (!_resolutionStringArray) {
        NSMutableArray *muArray = [[NSMutableArray alloc] initWithCapacity:self.resolutionTypeArray.count];
        for (int i = 0; i < [self.resolutionTypeArray count]; i++) {
            PLVResolutionType resolutionType = [self.resolutionTypeArray[i] integerValue];
            NSString *string = [PLVRoomData resolutionStringWithType:resolutionType];
            if ([PLVLiveVideoConfig sharedInstance].clientPushStreamTemplateEnabled) {
                string = [self qualityNameWithResolutionType:resolutionType];
            }
            [muArray addObject:string];
        }
        _resolutionStringArray = [muArray copy];
    }
    return _resolutionStringArray;
}

#pragma mark - Private

// 将清晰度枚举值转换成字符串
- (NSString *)qualityNameWithResolutionType:(PLVResolutionType)resolutionType {
    NSString *string = nil;
    NSArray<PLVClientPushStreamTemplateVideoParams *> *videoParams = [PLVLiveVideoConfig sharedInstance].videoParams;
    int i = (int)resolutionType / 4.0;
    if ([PLVLiveVideoConfig sharedInstance].clientPushStreamTemplateEnabled && [PLVFdUtil checkArrayUseable:videoParams] && i < videoParams.count && i >= 0) {
        string = videoParams[i].qualityName;
    }
    return string;
}

#pragma mark - [ Action ]

- (void)bitRateButtonAction:(UIButton *)sender {
    for (UIButton *button in self.optionsButtonArray) {
        button.selected = NO;
    }
    sender.selected = YES;
    self.gradientLayer.frame = sender.bounds;
    [sender.layer insertSublayer:self.gradientLayer atIndex:0];
    [PLVSAUtils showToastWithMessage:[NSString stringWithFormat:PLVLocalizedString(@"已切换为%@"), sender.titleLabel.text] inView:[PLVSAUtils sharedUtils].homeVC.view];
    [self dismiss];
    if (self.delegate && [self.delegate respondsToSelector:@selector(plvsaBitRateSheet:bitRateButtonClickWithBitRate:)]) {
        PLVResolutionType bitRate = [self.resolutionTypeArray[sender.tag] integerValue];
        [self.delegate plvsaBitRateSheet:self bitRateButtonClickWithBitRate:bitRate];
    }
}


@end
