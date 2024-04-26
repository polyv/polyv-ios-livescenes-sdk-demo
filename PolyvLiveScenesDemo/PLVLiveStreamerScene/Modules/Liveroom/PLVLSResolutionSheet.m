//
//  PLVLSResolutionSheet.m
//  PLVLiveStreamerDemo
//
//  Created by MissYasiky on 2021/3/5.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVLSResolutionSheet.h"
#import "PLVLSSettingSheetCell.h"
#import "PLVLSUtils.h"
#import "PLVMultiLanguageManager.h"
#import "PLVRoomDataManager.h"
#import <PLVFoundationSDK/PLVFdUtil.h>

static NSString *kResolutionCellIdentifier = @"resolutionCellIdentifier";
static NSString *const kSettingResolutionKey = @"settingResolutionKey";
static NSString *const kSettingResolutionLevelKey = @"settingResolutionLevelKey";

@interface PLVLSResolutionSheet ()<
UITableViewDataSource,
UITableViewDelegate
>

/// UI
@property (nonatomic, strong) UILabel *sheetTitleLabel; // 弹层顶部标题
@property (nonatomic, strong) UIView *titleSplitLine; // 标题底部分割线
@property (nonatomic, strong) UITableView *tableView; // 设置项列表

/// 数据
@property (nonatomic, strong) NSArray *resolutionTypeArray; // 可选清晰度枚举值数组
@property (nonatomic, strong) NSArray <NSString *>*resolutionStringArray; // 可选清晰度字符串数组
@property (nonatomic, assign) CGFloat sheetWidth; // 父类数据
@property (nonatomic, strong) NSArray<PLVClientPushStreamTemplateVideoParams *> *resolutionDataArray;
@property (nonatomic, assign, readonly) BOOL isPushStreamTemplateEnable;

@end

@implementation PLVLSResolutionSheet

@synthesize sheetWidth = _sheetWidth;

#pragma mark - Life Cycle

- (instancetype)initWithSheetWidth:(CGFloat)sheetWidth {
    self = [super initWithSheetWidth:sheetWidth];
    if (self) {
        [self.contentView addSubview:self.sheetTitleLabel];
        [self.contentView addSubview:self.titleSplitLine];
        [self.contentView addSubview:self.tableView];
        [self setupDefaultSelectQuality];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    BOOL isPad = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
    CGFloat sheetTitleLabelTop = 14;
    CGFloat titleSplitLineTop = 44;
    CGFloat logoutButtonHeight = 48;

    if (isPad) {
        sheetTitleLabelTop += PLVLSUtils.safeTopPad;
        titleSplitLineTop += PLVLSUtils.safeTopPad;
        logoutButtonHeight = 60;
    }
    
    CGFloat originX = 16;
    self.sheetTitleLabel.frame = CGRectMake(originX, sheetTitleLabelTop, self.sheetWidth - originX * 2, 22);
    self.titleSplitLine.frame = CGRectMake(originX, titleSplitLineTop, self.sheetWidth - originX * 2, 1);
    
    CGFloat tableViewOriginY = CGRectGetMaxY(self.titleSplitLine.frame) + 35;
    CGFloat tableViewHeight = self.contentView.frame.size.height - tableViewOriginY - 30;
    CGFloat rightPad = PLVLSUtils.safeSidePad;
    self.tableView.frame = CGRectMake(originX, tableViewOriginY, self.sheetWidth - originX - rightPad, tableViewHeight);
}

#pragma mark - Override
- (void)showInView:(UIView *)parentView{
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    BOOL isPad = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
    CGFloat scale = isPad ? 0.43 : 0.52;
    self.sheetWidth = screenWidth * scale;
    [super showInView:parentView]; /// TODO: 改造初始化该类的过程
}

#pragma mark - Getter

- (UILabel *)sheetTitleLabel {
    if (!_sheetTitleLabel) {
        _sheetTitleLabel = [[UILabel alloc] init];
        _sheetTitleLabel.textColor = [UIColor colorWithRed:0xf0/255.0 green:0xf1/255.0 blue:0xf5/255.0 alpha:1];
        _sheetTitleLabel.font = [UIFont boldSystemFontOfSize:16];
        _sheetTitleLabel.text = PLVLocalizedString(@"清晰度");
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

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] init];
        _tableView.backgroundColor = [UIColor clearColor];
        _tableView.allowsSelection = self.isPushStreamTemplateEnable;
        _tableView.showsVerticalScrollIndicator = NO;
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableView.tableFooterView = [UIView new];
        
        // 不同设置项之间的cell不考虑复用
        [_tableView registerClass:[PLVLSSettingSheetCell class] forCellReuseIdentifier:kResolutionCellIdentifier];
        
        _tableView.dataSource = self;
        _tableView.delegate = self;
        
    }
    return _tableView;
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
            NSString *string = [self stringWithResolutionType:resolutionType];
            if ([PLVLiveVideoConfig sharedInstance].clientPushStreamTemplateEnabled) {
                string = [self qualityNameWithResolutionType:resolutionType];
            }
            [muArray addObject:string];
        }
        _resolutionStringArray = [muArray copy];
    }
    return _resolutionStringArray;
}

- (NSArray *)resolutionDataArray {
    if (!_resolutionDataArray) {
        NSArray *videoParams = [PLVLiveVideoConfig sharedInstance].videoParams;
        _resolutionDataArray = [videoParams sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
            PLVClientPushStreamTemplateVideoParams *videoParams1 = obj1;
            PLVClientPushStreamTemplateVideoParams *videoParams2 = obj2;
            if (videoParams2.videoResolution.height != videoParams1.videoResolution.height) {
                return [@(videoParams2.videoResolution.height) compare:@(videoParams1.videoResolution.height)];
            } else if (videoParams2.videoBitrate != videoParams1.videoBitrate) {
                return [@(videoParams2.videoBitrate) compare:@(videoParams1.videoBitrate)];
            } else {
                return [@(videoParams2.videoFrameRate) compare:@(videoParams1.videoFrameRate)];
            }
        }];
    }
    return _resolutionDataArray;
}

- (BOOL)isPushStreamTemplateEnable {
    return [PLVLiveVideoConfig sharedInstance].clientPushStreamTemplateEnabled;
}

- (NSString *)defaultQualityLevel {
    if ([PLVLiveVideoConfig sharedInstance].clientPushStreamTemplateEnabled) {
        PLVRoomUserType viewerType = [PLVRoomDataManager sharedManager].roomData.roomUser.viewerType;
        if (viewerType == PLVRoomUserTypeTeacher) {
            return [PLVLiveVideoConfig sharedInstance].teacherDefaultQualityLevel;
        } else if (viewerType == PLVRoomUserTypeGuest) {
            return [PLVLiveVideoConfig sharedInstance].guestDefaultQualityLevel;
        }
    }
    return nil;
}

#pragma mark - UITableView DataSource & Delegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.isPushStreamTemplateEnable) {
        return self.resolutionDataArray.count;
    }
    return 1; // 目前只有一个清晰度设置，所以为1
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.isPushStreamTemplateEnable) {
        static NSString *cellIdentifier = @"PLVLSResolutionLevelSheetCellID";
        PLVLSResolutionLevelSheetCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        if (!cell) {
            cell = [[PLVLSResolutionLevelSheetCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        }
        if (self.resolutionDataArray.count > indexPath.row) {
            [cell setupVideoParams:self.resolutionDataArray[indexPath.row]];
        }
        return cell;
    } else if (indexPath.row == 0) { // 清晰度设置
        PLVLSSettingSheetCell *cell = (PLVLSSettingSheetCell *)[tableView dequeueReusableCellWithIdentifier:kResolutionCellIdentifier];
        NSInteger selectedIndex = [self selectedResolutionIndex];
        [cell setOptionsArray:self.resolutionStringArray selectedIndex:selectedIndex];
        __weak typeof(self) weakSelf = self;
        [cell setDidSelectedAtIndex:^(NSInteger index) {
            PLVResolutionType resolutionType = [weakSelf.resolutionTypeArray[index] integerValue];
            [weakSelf saveSelectedResolution:resolutionType];
            if (weakSelf.delegate) {
                [weakSelf.delegate settingSheet_didChangeResolution:resolutionType];
            }
        }];
        return cell;
    } else {
        return [UITableViewCell new];
    }
}

#pragma mark - UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.isPushStreamTemplateEnable) {
        return 96;        
    }
    return [PLVLSSettingSheetCell cellHeight];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.isPushStreamTemplateEnable) {
        PLVClientPushStreamTemplateVideoParams *videoParams = self.resolutionDataArray[indexPath.row];
        if (self.delegate && [self.delegate respondsToSelector:@selector(settingSheet_didSelectStreamQualityLevel:)]) {
            [self.delegate settingSheet_didSelectStreamQualityLevel:videoParams.qualityLevel];
        }
    }
}

#pragma mark - Public

- (PLVResolutionType)resolution{
    NSInteger index = [self selectedResolutionIndex];
    PLVResolutionType resolutionType = [self.resolutionTypeArray[index] integerValue];
    return resolutionType;
}


#pragma mark - Private

- (void)setupDefaultSelectQuality {
    if (self.isPushStreamTemplateEnable &&
        [PLVFdUtil checkStringUseable:self.defaultQualityLevel]) {
        [self.resolutionDataArray enumerateObjectsUsingBlock:^(PLVClientPushStreamTemplateVideoParams * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([self.defaultQualityLevel isEqualToString:obj.qualityLevel]) {
                [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:idx inSection:0] animated:NO scrollPosition:UITableViewScrollPositionNone];
                *stop = YES;
            }
        }];
    }
}

/// 将清晰度枚举值转换成字符串
- (NSString *)stringWithResolutionType:(PLVResolutionType)resolutionType {
    NSString *string = nil;
    switch (resolutionType) {
        case PLVResolutionType1080P:
            string = PLVLocalizedString(@"超高清");
            break;
        case PLVResolutionType720P:
            string = PLVLocalizedString(@"超清");
            break;
        case PLVResolutionType480P:
            string = PLVLocalizedString(@"高标清");
            break;
        case PLVResolutionType360P:
            string = PLVLocalizedString(@"高清");
            break;
        case PLVResolutionType180P:
            string = PLVLocalizedString(@"标清");
            break;
    }
    return string;
}

/// 将清晰度枚举值转换成字符串
- (NSString *)qualityNameWithResolutionType:(PLVResolutionType)resolutionType {
    NSString *string = nil;
    NSArray<PLVClientPushStreamTemplateVideoParams *> *videoParams = [PLVLiveVideoConfig sharedInstance].videoParams;
    int i = (int)resolutionType / 4.0;
    if ([PLVLiveVideoConfig sharedInstance].clientPushStreamTemplateEnabled && [PLVFdUtil checkArrayUseable:videoParams] && i < videoParams.count && i >= 0) {
        string = videoParams[i].qualityName;
    }
    return string;
}

/// 把缓存的清晰度转换成当前索引
- (NSInteger)selectedResolutionIndex {
    NSInteger selectedIndex = 0;
    NSInteger resolutionTypeArrayCount = [self.resolutionTypeArray count];
    if (resolutionTypeArrayCount <= 0) { return selectedIndex; }
    
    NSString * saveResolutionString = [[NSUserDefaults standardUserDefaults] objectForKey:kSettingResolutionKey];
    PLVResolutionType saveResolution;
    if ([PLVLiveVideoConfig sharedInstance].clientPushStreamTemplateEnabled) {
        saveResolutionString = [[NSUserDefaults standardUserDefaults] objectForKey:kSettingResolutionLevelKey];
    }
    
    if (![PLVFdUtil checkStringUseable:saveResolutionString]) {
        /// 若无本地记录，则默认360P
        saveResolution = [PLVRoomDataManager sharedManager].roomData.defaultResolution;
    }else{
        saveResolution = saveResolutionString.integerValue;
    }
    for (int i = 0; i < [self.resolutionTypeArray count]; i++) {
        PLVResolutionType resolutionType = [self.resolutionTypeArray[i] integerValue];
        if (resolutionType == saveResolution) {
            selectedIndex = i;
            break;
        }
    }
    return selectedIndex;
}

/// 保存当前选择的清晰度到本地
- (void)saveSelectedResolution:(PLVResolutionType)resolutionType {
    if ([PLVLiveVideoConfig sharedInstance].clientPushStreamTemplateEnabled) {
        [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"%ld",(long)resolutionType] forKey:kSettingResolutionLevelKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
    } else {
        [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"%ld",(long)resolutionType] forKey:kSettingResolutionKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

@end
