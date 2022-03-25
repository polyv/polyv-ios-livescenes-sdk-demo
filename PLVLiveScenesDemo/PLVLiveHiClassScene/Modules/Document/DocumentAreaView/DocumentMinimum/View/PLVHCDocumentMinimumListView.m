//
//  PLVHCDocumentMinimumListView.m
//  PLVLiveScenesDemo
//
//  Created by lijingtong on 2021/7/9.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVHCDocumentMinimumListView.h"

// 工具
#import "PLVHCUtils.h"

// UI
#import "PLVHCDocumentMinimumCell.h"

// 模块
#import "PLVHCDocumentMinimumModel.h"

// 依赖库
#import <PLVFoundationSDK/PLVFoundationSDK.h>
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>

@interface PLVHCDocumentMinimumListView()<
UITableViewDataSource,
UITableViewDelegate
>

#pragma mark UI
@property (nonatomic, strong) UIView *menuView;
@property (nonatomic, strong) UITableView *tableView;

#pragma mark 数据
@property (nonatomic, assign) CGSize menuSize;
@property (nonatomic, strong) NSMutableArray<PLVHCDocumentMinimumModel *> *documentArray; // 文档数据

@end

@implementation PLVHCDocumentMinimumListView

#pragma mark - [ Life Cycle ]

- (instancetype)init {
    self = [super init];
    if (self) {
        [self.menuView addSubview:self.tableView];
        [self addSubview:self.menuView];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.menuView.frame = self.bounds;
    self.menuSize = self.menuView.frame.size;
    
    UIBezierPath *bezierPath = [self BezierPathWithSize:self.menuSize];
    CAShapeLayer* shapeLayer = [CAShapeLayer layer];
    shapeLayer.path = bezierPath.CGPath;
    self.menuView.layer.mask = shapeLayer;
    
    self.tableView.frame = CGRectMake(20, 0, self.menuSize.width - 20 - 12, self.menuSize.height - 14);
}

#pragma mark - [ Public Method ]

- (void)showInView:(UIView *)parentView {
    if (!parentView) {
        return;
    }
    [parentView addSubview:self];
    [self.tableView reloadData];
}

- (void)dismiss {
    [self removeFromSuperview];
}

- (void)refreshMinimizeContainerDataArray:(NSArray<PLVHCDocumentMinimumModel *> *)dataArray {
    if (dataArray) {
        self.documentArray = [NSMutableArray arrayWithArray:dataArray];
    } else {
        self.documentArray = [NSMutableArray array];
    }
}

- (BOOL)isShowing {
    return self.superview;
}

#pragma mark - [ Private Method ]
#pragma mark Getter

- (UIView *)menuView {
    if (!_menuView) {
        _menuView = [[UIView alloc] init];
        _menuView.layer.masksToBounds = YES;
        _menuView.backgroundColor = [PLVColorUtil colorFromHexString:@"#232840"];
    }
    return _menuView;
}

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.scrollEnabled = NO;
        _tableView.showsVerticalScrollIndicator = NO;
        _tableView.showsHorizontalScrollIndicator = NO;
        _tableView.backgroundColor = [UIColor clearColor];
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableView.estimatedRowHeight = 0;
        _tableView.estimatedSectionFooterHeight = 0;
        _tableView.estimatedSectionHeaderHeight = 0;
        [_tableView registerClass:[PLVHCDocumentMinimumCell class] forCellReuseIdentifier:[PLVHCDocumentMinimumCell cellId]];
        [self.menuView addSubview:self.tableView];
    }
    return _tableView;
}

#pragma mark UIBezierPath
- (UIBezierPath *)BezierPathWithSize:(CGSize)size {
    CGFloat conner = 8.0; // 圆角角度
    CGFloat trangleHeight = 8.0; // 尖角高度
    CGFloat trangleWidth = 6.0; // 尖角半径
    CGFloat leftPadding = 8.0;
    
    UIBezierPath *bezierPath = [UIBezierPath bezierPath];
    // 起点
    [bezierPath moveToPoint:CGPointMake(conner + leftPadding, 0)];
    [bezierPath addLineToPoint:CGPointMake(size.width - leftPadding - conner, 0)];
    
    [bezierPath addQuadCurveToPoint:CGPointMake(size.width, conner) controlPoint:CGPointMake(size.width, 0)];
    [bezierPath addLineToPoint:CGPointMake(size.width, size.height- conner - trangleHeight)];
    [bezierPath addQuadCurveToPoint:CGPointMake(size.width-conner, size.height) controlPoint:CGPointMake(size.width, size.height)];

    [bezierPath addLineToPoint:CGPointMake(conner + leftPadding, size.height)];
    [bezierPath addQuadCurveToPoint:CGPointMake(leftPadding, size.height - conner) controlPoint:CGPointMake(leftPadding, size.height)];
    [bezierPath addLineToPoint:CGPointMake(leftPadding, conner)];
    [bezierPath addQuadCurveToPoint:CGPointMake(conner + leftPadding, 0) controlPoint:CGPointMake(leftPadding, 0)];
    
    // 画尖角
    [bezierPath moveToPoint:CGPointMake(leftPadding, size.height - conner - trangleHeight)];
    // 顶点
    [bezierPath addLineToPoint:CGPointMake(0, size.height - conner - trangleHeight - trangleWidth)];
    
    [bezierPath addLineToPoint:CGPointMake(leftPadding, size.height - conner - trangleHeight - trangleWidth * 2)];
    [bezierPath closePath];
    return bezierPath;
}

- (void)removeHandlerWithModel:(PLVHCDocumentMinimumModel *)model{
    if (!model ||
        ![model isKindOfClass:[PLVHCDocumentMinimumModel class]]) {
        return;
    }
    [self.documentArray removeObject:model];
    
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(documentMinimumListView:didCloseItemModel:)]) {
        [self.delegate documentMinimumListView:self didCloseItemModel:model];
    }
    if (self.documentArray.count == 0) {
        [self dismiss];
    }
    [self.tableView reloadData];
}

- (NSMutableArray<PLVHCDocumentMinimumModel *> *)documentArray {
    if (!_documentArray) {
        _documentArray = [NSMutableArray array];
    }
    return _documentArray;
}

- (NSInteger)minimumNum {
    return self.documentArray.count;
}

#pragma mark - [ Event ]
#pragma mark Gesture

- (void)tapGestureViewGesture {
    [self dismiss];
}

#pragma mark - [ Delegate ]
#pragma mark UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.documentArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    PLVHCDocumentMinimumCell *cell = [tableView dequeueReusableCellWithIdentifier:[PLVHCDocumentMinimumCell cellId] forIndexPath:indexPath];
    __weak typeof(self) weakSelf = self;
    cell.removeHandler = ^(PLVHCDocumentMinimumModel * _Nonnull documentModel) {
        [weakSelf removeHandlerWithModel:documentModel];
    };
    if (self.documentArray.count > indexPath.row) {
        [cell updateWithModel:self.documentArray[indexPath.row] cellWidth:self.menuSize.width - 20 - 12];
    }
    return cell;
}

#pragma mark UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [PLVHCDocumentMinimumCell cellHeight];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(documentMinimumListView:didSelectItemModel:)] &&
        self.documentArray.count > indexPath.row) {
        [self.delegate documentMinimumListView:self didSelectItemModel:self.documentArray[indexPath.row]];
    }
}

@end
