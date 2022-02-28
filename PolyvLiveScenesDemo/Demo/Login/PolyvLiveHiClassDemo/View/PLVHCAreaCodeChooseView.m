//
//  PLVHCAreaCodeChooseView.m
//  PLVLiveScenesDemo
//
//  Created by lijingtong on 2021/9/14.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVHCAreaCodeChooseView.h"

// 工具
#import "PLVHCDemoUtils.h"

// UI
#import "PLVHCAreaCodeChooseTableViewCell.h"

// 依赖库
#import <PLVFoundationSDK/PLVFoundationSDK.h>

@interface PLVHCAreaCodeChooseView()<
UITableViewDelegate,
UITableViewDataSource
>

#pragma mark UI

@property (nonatomic, strong) UIView *topTitleView; // 顶部标题、返回按钮视图
@property (nonatomic, strong) CAShapeLayer *topTitleViewLayer; // 顶部标题、返回按钮 圆角Layer
@property (nonatomic, strong) UIButton *backButton; // 返回按钮
@property (nonatomic, strong) UILabel *titleLabel; // 标题
@property (nonatomic, strong) UITableView *tableView; // 区号列表视图

#pragma mark 数据

@property (nonatomic, strong) NSMutableArray <NSString *>*areaCodeArrayM; //区号数据数组

@end

@implementation PLVHCAreaCodeChooseView

#pragma mark - [ Life Cycle ]

- (instancetype)init {
    self = [super init];
    if (self) {
        self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
        
        [self addSubview:self.topTitleView];
        [self.topTitleView addSubview:self.backButton];
        [self.topTitleView addSubview:self.titleLabel];
        [self addSubview:self.tableView];
        
        // 加载区号数据，给self.areaCodeArrayM赋值
        [self loadAreaCodeList];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat topPadding = 0;
    CGFloat bottomPadding = 0;
    if (@available(iOS 11.0, *)) {
        topPadding = self.safeAreaInsets.top;
        bottomPadding = self.safeAreaInsets.bottom;
    }
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        topPadding = self.bounds.size.height * 0.288;
    }
    
    self.topTitleView.frame = CGRectMake(0, topPadding, self.bounds.size.width, 64);
    self.topTitleView.layer.mask = self.topTitleViewLayer;
    
    self.backButton.frame = CGRectMake(0, 0, 64, 64);
    self.backButton.imageEdgeInsets = UIEdgeInsetsMake(0, -15, 0, 0);
    self.titleLabel.frame = CGRectMake(64, 0, self.bounds.size.width - 64 * 2 , 64);
    
    self.tableView.frame = CGRectMake(0, CGRectGetMaxY(self.topTitleView.frame), self.bounds.size.width, self.bounds.size.height - CGRectGetMaxY(self.topTitleView.frame));
}

#pragma mark - [ Public Method ]

- (void)showInView:(UIView *)view {
    if (view) {
        [view addSubview:self];
    }
    [self.tableView reloadData];
}

#pragma mark - [ Private Method ]
#pragma mark Getter

- (UIView *)topTitleView {
    if (!_topTitleView) {
        _topTitleView = [[UIView alloc] init];
        _topTitleView.backgroundColor = [UIColor whiteColor];
    }
    return _topTitleView;
}

- (CAShapeLayer *)topTitleViewLayer {
    if (!_topTitleViewLayer) {
        UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:self.topTitleView.bounds byRoundingCorners:UIRectCornerTopLeft | UIRectCornerTopRight cornerRadii:CGSizeMake(10, 10)];
        
        _topTitleViewLayer = [[CAShapeLayer alloc] init];
        _topTitleViewLayer.frame = self.topTitleView.bounds;
        _topTitleViewLayer.path = path.CGPath;
    }
    return _topTitleViewLayer;
}

- (UIButton *)backButton {
    if (!_backButton) {
        _backButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_backButton setImage:[PLVHCDemoUtils imageForHiClassResource:@"plvhc_btn_areacode_back"] forState:UIControlStateNormal];
        [_backButton addTarget:self action:@selector(backButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _backButton;
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        if (@available(iOS 8.2, *)) {
            _titleLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightMedium];
        } else {
            _titleLabel.font = [UIFont systemFontOfSize:18];
        }
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.text = @"选择国家地区";
    }
    return _titleLabel;
}

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] init];
        _tableView.backgroundColor = [UIColor clearColor];
        _tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        _tableView.separatorColor = [PLVColorUtil colorFromHexString:@"#E5E5E5"];
        _tableView.separatorInset = UIEdgeInsetsMake(0, 19.5, 0, 29.5);
        _tableView.showsVerticalScrollIndicator = NO;
        _tableView.bounces = NO;
        _tableView.rowHeight = 64;
        _tableView.delegate = self;
        _tableView.dataSource = self;
    }
    return _tableView;
}

- (NSMutableArray<NSString *> *)areaCodeArrayM {
    if (!_areaCodeArrayM) {
        _areaCodeArrayM = [NSMutableArray array];
    }
    return _areaCodeArrayM;
}

#pragma mark Utils

- (void)dissmiss{
    [self removeFromSuperview];
}

- (void)loadAreaCodeList {
    NSDictionary *dict  = [PLVHCDemoUtils plistDictionartForHiClassResource:@"plvhc_areacode_list"];
    if (![PLVFdUtil checkDictionaryUseable:dict]) {
        NSLog(@"plvhc_areacode_list.plist资源不存在");
        return;
    }
    
    NSArray *indexArray  = [NSArray arrayWithArray:[[dict allKeys] sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        return [obj1 compare:obj2];
    }]];
    
    if (![PLVFdUtil checkArrayUseable:indexArray]) {
        NSLog(@"plvhc_areacode_list.plist资源缺少分组");
        return;
    }
    
    for (NSString *key in indexArray) {
        NSArray *codeArray = [dict valueForKey:key];
        [self.areaCodeArrayM addObjectsFromArray:codeArray];
    }
}

#pragma mark - [ Event ]
#pragma mark Action

- (void)backButtonAction {
    [self dissmiss];
}

#pragma mark - [ Delegate ]
#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.areaCodeArrayM.count > indexPath.row) {
        NSString *codeString = self.areaCodeArrayM[indexPath.row];
        NSArray *array = [codeString componentsSeparatedByString:@"+"];
        NSString *code = array.lastObject;
    
        if (self.delegate &&
            [self.delegate respondsToSelector:@selector(areaCodeChooseView:didSelectAreaCode:)]) {
            [self.delegate areaCodeChooseView:self didSelectAreaCode:code];
            
            [self dissmiss];
        }
    }
}

#pragma mark UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.areaCodeArrayM.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *identifier = @"PLVHCAreaCodeChooseTableViewCellIdentifier";
    PLVHCAreaCodeChooseTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell = [[PLVHCAreaCodeChooseTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
    
    if (self.areaCodeArrayM.count > indexPath.row) {
        NSString *codeString = self.areaCodeArrayM[indexPath.row];
        NSArray *array = [codeString componentsSeparatedByString:@"+"];
        NSString *countryName = [array.firstObject stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        NSString *code = array.lastObject;
        
        cell.areaLabel.text = countryName;
        cell.codeLable.text = [NSString stringWithFormat:@"+%@",code];
    }
    
    return cell;
}

@end
