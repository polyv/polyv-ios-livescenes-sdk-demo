//
//  PLVBeautyViewModel.m
//  PolyvLiveScenesDemo
//
//  Created by juno on 2022/8/12.
//  Copyright © 2022 PLV. All rights reserved.
//

#import "PLVBeautyViewModel.h"

@interface PLVBeautyViewModel()

@property (nonatomic, weak) PLVBeautyManager *beautyManager; // 美颜管理对象，弱引用

@property (nonatomic, strong) NSMutableArray<PLVBFilterOption *> *filterOptionArray; // 滤镜数组
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *beautyOptionDict; // 美颜特效字典，记录每一个特效的强度
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *beautyFilterOptionDict; // 滤镜字典，记录每一个滤镜的强度
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *beautyOptionDefaultDict; // 美颜特效字典，记录默认每一个特效的 默认 强度

@property (nonatomic, assign) PLVBBeautyOption currentBeautyOption; // 当前美颜类型
@property (nonatomic, strong) PLVBFilterOption *currentFilterOption; // 当前滤镜类型
@property (nonatomic, strong) PLVBFilterOption *defaultFilterOption; // 默认滤镜类型
@property (nonatomic, assign) PLVBeautyType beautyType; // 当前选择了什么美颜类型

@property (nonatomic, assign) BOOL beautyIsReady; // 当前 美颜是否已就绪
@property (nonatomic, assign) BOOL beautyIsOpen; // 当前 美颜是否开启
@property (nonatomic, assign, getter=isSelectedOriginFilter) BOOL selectedOriginFilter; // 当前 是否选中原图滤镜

@end

static NSString *kBeautyOptionDictKey = @"kPLVBeautyOptionDictKey";
static NSString *kBeautyFilterOptionDictKey = @"kPLVBeautyFilterOptionDictKey";
static NSString *kBeautyFilterSelectKey = @"kPLVBeautyFilterSelectKey";
static NSString *kBeautyOpenKey = @"kPLVBeautyopenKey";
static CGFloat kBeautyFilterOptionDefaultIntensity = 0.5;

@implementation PLVBeautyViewModel

#pragma mark - [ Public Method ]

+ (instancetype)sharedViewModel {
    static dispatch_once_t onceToken;
    static PLVBeautyViewModel *viewModel = nil;
    dispatch_once(&onceToken, ^{
        viewModel = [[PLVBeautyViewModel alloc] init];
    });
    return viewModel;
}

- (void)startBeautyWithManager:(PLVBeautyManager *)beautyManager {
    self.beautyManager = beautyManager;
    self.beautyIsReady = YES;
    self.beautyIsOpen = [self getBeautyOpenStatus];
    [self initFilterOption];
    [self initBeautyOption];
}

- (void)clear {
    self.beautyManager = nil;
    self.beautyIsReady = NO;
    self.beautyIsOpen = NO;
}

- (void)beautyOpen:(BOOL)open {
    self.beautyIsOpen = open;
    [self saveBeautyOpenStatus:open];
    if (open) {
        [self initBeautyOption];
        [self selectBeautyFilterOption:self.currentFilterOption];
        [self selectBeautyOption:self.currentBeautyOption];
    }
}

- (void)updateBeautyOptionWithIntensity:(CGFloat)intensity {
    if ((self.beautyType == PLVBeautyTypeWhiten ||
        self.beautyType == PLVBeautyTypeFace) &&
        self.currentBeautyOption != -1) { // 特效模式
        [self.beautyManager updateBeautyOption:self.currentBeautyOption withIntensity:intensity];
        plv_dict_set(self.beautyOptionDict, [NSString stringWithFormat:@"%zd", self.currentBeautyOption], @(intensity));
        
        // 缓存在本地
        [[NSUserDefaults standardUserDefaults] setObject:self.beautyOptionDict forKey:kBeautyOptionDictKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
    } else if (self.currentFilterOption) { // 滤镜模式
        [self.beautyManager setFilterOption:self.currentFilterOption withIntensity:intensity];
        plv_dict_set(self.beautyFilterOptionDict, self.currentFilterOption.filterSpellName, @(intensity));
        
        // 缓存在本地
        [[NSUserDefaults standardUserDefaults] setObject:self.beautyFilterOptionDict forKey:kBeautyFilterOptionDictKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

- (void)resetBeautyOptionIntensity { // 将全部美颜强度设置为默认值并缓存
        // 特效模式
        CGFloat defaultIntensity = PLV_SafeFloatForDictKey(self.beautyOptionDefaultDict, [NSString stringWithFormat:@"%zd", self.currentBeautyOption]);
        [self notifyListenerDidChangeIntensity:defaultIntensity defaultIntensity:defaultIntensity];
    
        // 滤镜模式
        CGFloat intensity = -1;
        [self.beautyManager setFilterOption:self.defaultFilterOption withIntensity:intensity];
        if (self.beautyType == PLVBeautyTypeFilter) {
            [self notifyListenerDidChangeIntensity:intensity defaultIntensity:intensity];
        }
    
    [self resetBeauty];
}

- (void)selectBeautyOption:(PLVBBeautyOption)option {
    // 缓存当前选择的模型
    self.currentBeautyOption = option;
    // 未开启美颜 或 当前选择的是滤镜 不继续处理
    if (!self.beautyIsOpen ||
        self.beautyType == PLVBeautyTypeFilter) {
        return;
    }
    
    CGFloat intensity = PLV_SafeFloatForDictKey(self.beautyOptionDict, [NSString stringWithFormat:@"%zd", option]);
    CGFloat defaultIntensity = PLV_SafeFloatForDictKey(self.beautyOptionDefaultDict, [NSString stringWithFormat:@"%zd", option]);
    [self notifyListenerDidChangeIntensity:intensity defaultIntensity:defaultIntensity]; // 刷新强度UI
}

- (void)selectBeautyFilterOption:(PLVBFilterOption *)filterOption {
    // 缓存当前选择的滤镜
    self.currentFilterOption = filterOption;
    [self saveBeautyFilterSelect:filterOption];
    
    // 未开启美颜 或 当前选择的不是滤镜 不继续处理
    if (!self.beautyIsOpen ||
        !filterOption ||
        ![filterOption isKindOfClass:NSClassFromString(@"PLVBFilterOption")]) {
        return;
    }
    
    CGFloat intensity;
    if (![PLVFdUtil checkStringUseable:filterOption.filterKey]) { // 原图filterKey为空，隐藏强度滑动视图
        intensity = -1;
    } else {
        intensity = PLV_SafeFloatForDictKey(self.beautyFilterOptionDict, filterOption.filterSpellName);
    }
    
    [self.beautyManager setFilterOption:filterOption withIntensity:intensity];
    
    if (self.beautyType != PLVBeautyTypeFilter) { // 当前没有选中滤镜模式，静默设置滤镜
        return;
    }
    
    [self notifyListenerDidChangeIntensity:intensity defaultIntensity:kBeautyFilterOptionDefaultIntensity];
    [self notifyListenerDidChangeFilterName];
}

- (void)selectBeautyType:(PLVBeautyType)beautyType {
    self.beautyType = beautyType;
}

- (BOOL)isSelectedOriginFilter {
    BOOL isSelectedOriginFilter = (self.beautyType == PLVBeautyTypeFilter) && (self.currentFilterOption &&![PLVFdUtil checkStringUseable:self.currentFilterOption.filterKey]);
    return isSelectedOriginFilter;
}

- (PLVBFilterOption *)getCacheSelectFilterOption {
    NSString *spellName = [self getSelectedBeautyFilterSpellName];
    if (![PLVFdUtil checkStringUseable:spellName] ||
        !self.filterOptionArray) {
        return nil;
    }
    for (PLVBFilterOption *filter in self.filterOptionArray) {
        if ([filter.filterSpellName isEqualToString:spellName]) {
            return filter;
        }
    }
    return nil;
}

#pragma mark - [ Private Method ]
#pragma mark Getter

- (NSMutableDictionary<NSString *,NSNumber *> *)beautyOptionDefaultDict {
    if (!_beautyOptionDefaultDict) {
        _beautyOptionDefaultDict = [NSMutableDictionary dictionary];
        [_beautyOptionDefaultDict setObject:@(0.70) forKey:[NSString stringWithFormat:@"%zd", PLVBBeautyOption_BeautyWhiten]];
        [_beautyOptionDefaultDict setObject:@(0.25) forKey:[NSString stringWithFormat:@"%zd", PLVBBeautyOption_BeautySharp]];
        [_beautyOptionDefaultDict setObject:@(0.85) forKey:[NSString stringWithFormat:@"%zd", PLVBBeautyOption_BeautySmooth]];
        [_beautyOptionDefaultDict setObject:@(0.35) forKey:[NSString stringWithFormat:@"%zd", PLVBBeautyOption_ReshapeDeformOverAll]];
        [_beautyOptionDefaultDict setObject:@(0.25) forKey:[NSString stringWithFormat:@"%zd", PLVBBeautyOption_ReshapeDeformEye]];
        [_beautyOptionDefaultDict setObject:@(0.30) forKey:[NSString stringWithFormat:@"%zd", PLVBBeautyOption_ReshapeDeformNose]];
        [_beautyOptionDefaultDict setObject:@(0.20) forKey:[NSString stringWithFormat:@"%zd", PLVBBeautyOption_ReshapeDeformZoomMouth]];
        [_beautyOptionDefaultDict setObject:@(0.40) forKey:[NSString stringWithFormat:@"%zd", PLVBBeautyOption_ReshapeDeformForeHead]];
        [_beautyOptionDefaultDict setObject:@(0.20) forKey:[NSString stringWithFormat:@"%zd", PLVBBeautyOption_ReshapeDeformZoomJawbone]];
        [_beautyOptionDefaultDict setObject:@(0.35) forKey:[NSString stringWithFormat:@"%zd", PLVBBeautyOption_ReshapeBeautyWhitenTeeth]];
        [_beautyOptionDefaultDict setObject:@(0.65) forKey:[NSString stringWithFormat:@"%zd", PLVBBeautyOption_ReshapeBeautyBrightenEye]];
    }
    return _beautyOptionDefaultDict;
}

- (PLVBFilterOption *)defaultFilterOption {
    if (!_defaultFilterOption) {
        _defaultFilterOption = [[NSClassFromString(@"PLVBFilterOption") alloc] init];
        _defaultFilterOption.filterName = @"原图";
        _defaultFilterOption.filterSpellName = @"origin";
        _defaultFilterOption.filterKey = @"";
    }
    return _defaultFilterOption;
}

- (BOOL)beautyIsOpen {
    if (self.beautyManager) {
        return _beautyIsOpen;
    }
    return [self getBeautyOpenStatus];
}

#pragma mark 初始化美颜

- (void)initFilterOption {
    
    self.filterOptionArray = [NSMutableArray array];
    if (self.defaultFilterOption) {
        [self.filterOptionArray addObject:self.defaultFilterOption];
    }
    
    NSArray *array = [self.beautyManager getSupportFilterOptions];
    if ([PLVFdUtil checkArrayUseable:array]) {
        [self.filterOptionArray addObjectsFromArray:array];
    }
    // 初始化滤镜字典
    NSDictionary *beautyFilterOptionDict = [[NSUserDefaults standardUserDefaults] objectForKey:kBeautyFilterOptionDictKey];
    if ([PLVFdUtil checkDictionaryUseable:beautyFilterOptionDict]) { // 从本地取缓存
        self.beautyFilterOptionDict = [NSMutableDictionary dictionaryWithDictionary:beautyFilterOptionDict];
    } else { // 默认配置
        self.beautyFilterOptionDict = [NSMutableDictionary dictionary];
        [self.filterOptionArray enumerateObjectsUsingBlock:^(PLVBFilterOption *filterOption, NSUInteger idx, BOOL * _Nonnull stop) {
            NSString *key = filterOption.filterSpellName;
            NSNumber *value = [NSNumber numberWithFloat:kBeautyFilterOptionDefaultIntensity];
            plv_dict_set(self.beautyFilterOptionDict, key, value);
        }];
    }
    
    PLVBFilterOption *cacheFilter = [self getCacheSelectFilterOption];
    if (cacheFilter) {
        [self selectBeautyFilterOption:cacheFilter];
    }
    
    [self saveBeautyFilterOptionDict];
}

- (void)initBeautyOption {
    NSDictionary *beautyOptionDict = [[NSUserDefaults standardUserDefaults] objectForKey:kBeautyOptionDictKey];
    if ([PLVFdUtil checkDictionaryUseable:beautyOptionDict]) { // 从本地取缓存
        _beautyOptionDict = [NSMutableDictionary dictionaryWithDictionary:beautyOptionDict];
    } else { // 默认配置
        _beautyOptionDict = [NSMutableDictionary dictionaryWithDictionary:self.beautyOptionDefaultDict];
    }
    for (NSString *string in self.beautyOptionDict) {
        PLVBBeautyOption option =  (PLVBBeautyOption)string.integerValue;
        NSNumber *value = self.beautyOptionDict[string];
        CGFloat intensity = value.floatValue;
        [self.beautyManager updateBeautyOption:option withIntensity:intensity];
    }
    [self saveBeautyOptionDict];
}

- (void)saveBeautyOptionDict {
    [[NSUserDefaults standardUserDefaults] setObject:self.beautyOptionDict forKey:kBeautyOptionDictKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)removeBeautyOptionDict {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kBeautyOptionDictKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)saveBeautyFilterOptionDict {
    [[NSUserDefaults standardUserDefaults] setObject:self.beautyFilterOptionDict forKey:kBeautyFilterOptionDictKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)removeBeautyFilterOptionDict {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kBeautyFilterOptionDictKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)saveBeautyFilterSelect:(PLVBFilterOption *)filter {
    if ([PLVFdUtil checkStringUseable:filter.filterSpellName]) {
        [[NSUserDefaults standardUserDefaults] setObject:filter.filterSpellName forKey:kBeautyFilterSelectKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

- (NSString *)getSelectedBeautyFilterSpellName {
    return [[NSUserDefaults standardUserDefaults] objectForKey:kBeautyFilterSelectKey];
}

- (void)removeBeautyFilterSelect {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kBeautyFilterSelectKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)saveBeautyOpenStatus:(BOOL)open {
    [[NSUserDefaults standardUserDefaults] setObject:open ? @"1" : @"2" forKey:kBeautyOpenKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL)getBeautyOpenStatus {
    NSString *open = [[NSUserDefaults standardUserDefaults] objectForKey:kBeautyOpenKey];
    if ([PLVFdUtil checkStringUseable:open]) {
        return [open isEqualToString:@"1"] ? YES : NO;
    }
    return YES;
}

- (void)resetBeauty {
    [self removeBeautyOptionDict];
    [self removeBeautyFilterOptionDict];
    [self removeBeautyFilterSelect];
    [self initBeautyOption];
    [self initFilterOption];
}

#pragma mark NotifyListener
- (void)notifyListenerDidChangeIntensity:(CGFloat)intensity defaultIntensity:(CGFloat)defaultIntensity{
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(beautyViewModel:didChangeIntensity:defaultIntensity:)]) {
        plv_dispatch_main_async_safe(^{
            [self.delegate beautyViewModel:self didChangeIntensity:intensity defaultIntensity:defaultIntensity];
        });
        
    }
}

- (void)notifyListenerDidChangeFilterName {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(beautyViewModel:didChangeFilterName:)]) {
        plv_dispatch_main_async_safe(^{
            [self.delegate beautyViewModel:self didChangeFilterName:self.currentFilterOption.filterName];
        })
    }
}

@end
