//
//  PLVLSDocumentPagesView.m
//  PLVLiveStreamerDemo
//
//  Created by Hank on 2021/3/9.
//  Copyright © 2021 PLV. All rights reserved.
//  文档页面列表

#import "PLVLSDocumentPagesView.h"

#import <PLVFoundationSDK/PLVFoundationSDK.h>

#import "PLVLSUtils.h"
#import "PLVLSDocumentPagesCell.h"

static NSString *DocPagesCellIdentifier = @"DocumentPagesCellIdentifier";

@interface PLVLSDocumentPagesView ()
<
UICollectionViewDataSource,
UICollectionViewDelegate
>

@property (nonatomic, strong) UIButton *btnBack;                        // 返回按钮
@property (nonatomic, strong) UILabel *lbTitle;                         // 文档名称
@property (nonatomic, strong) UILabel *lbCount;                         // 页面数量
@property (nonatomic, strong) UIView *viewLine;                         // 分割线
@property (nonatomic, strong) UICollectionView *collectionView;         // 页面列表
@property (nonatomic, strong) UIButton *btnBackTip;                     // 返回提示

@property (nonatomic, assign) CGSize cellSize;                          // 列表Item宽度

@property (nonatomic, strong) NSMutableArray<NSString *> *docPageDatas; // 页面数据
@property (nonatomic, assign) NSInteger selectPageIndex;                // 选择的文档页面序号
@property (nonatomic, strong) NSTimer *timerTip;                        // 返回提示倒计时

@end

@implementation PLVLSDocumentPagesView

#pragma mark - [ Life Period ]

- (void)dealloc {
    [self hiddenBackTip];
}

- (instancetype)init {
    if (self = [super init]) {
        _docPageDatas = [NSMutableArray arrayWithCapacity:6];
        
        [self setupUI];
        [self showBackTip];
    }
    
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGSize selfSize = self.bounds.size;
    CGFloat margin = 28;
    
    self.btnBack.frame = CGRectMake(margin, 0, 20, 22);
    self.lbTitle.frame = CGRectMake(margin + 20, 0, selfSize.width - 2 * margin - 20, 22);
    self.lbCount.frame = CGRectMake(selfSize.width - margin - 100, 0, 100, 22);
    self.viewLine.frame = CGRectMake(margin, 30, selfSize.width - 2 * margin, 1);
    self.collectionView.frame = CGRectMake(0, 31, selfSize.width, selfSize.height - 31);

}

#pragma mark - [ Public Methods ]

- (void)setTitle:(NSString *)title {
    _title = title;
    NSString *fileName = [title stringByDeletingPathExtension];
    NSString *fileType = [title pathExtension];
    self.lbTitle.text = [self getTitle:fileName fileType:fileType cutCount:0];
}

- (void)setPagesViewDatas:(NSArray<NSString *> *)imageUrls {
    [self.docPageDatas removeAllObjects];
    [self.docPageDatas addObjectsFromArray:imageUrls];
    
    self.lbCount.text = [NSString stringWithFormat:@"共%ld个", (long)self.docPageDatas.count];
    [self.collectionView reloadData];
    
    [self setSelectPageIndex:0];
}

- (void)setSelectPageIndex:(NSInteger)index {
    _selectPageIndex = index;
    [self.collectionView selectItemAtIndexPath:[NSIndexPath indexPathForItem:index inSection:0]
                                  animated:NO
                            scrollPosition:UICollectionViewScrollPositionNone];
}

#pragma mark - [ Private Methods ]

- (void)setupUI {
    [self addSubview:self.btnBack];
    [self addSubview:self.lbTitle];
    [self addSubview:self.lbCount];
    [self addSubview:self.viewLine];
    [self addSubview:self.collectionView];
}

// 标题省略号处理
- (NSString *)getTitle:(NSString *)fileName fileType:(NSString *)fileType cutCount:(NSInteger)cutCount {
    NSString *string = [NSString stringWithFormat:@"%@.%@", fileName, fileType];
    if (cutCount > 0) {
        string = [NSString stringWithFormat:@"%@...%@", fileName, fileType];
    }
    
    CGFloat width = [string boundingRectWithSize:CGSizeMake(MAXFLOAT, self.lbTitle.frame.size.height)
                                        options:NSStringDrawingUsesLineFragmentOrigin
                                     attributes:@{NSFontAttributeName:self.lbTitle.font}
                                        context:nil].size.width;
    
    if (width > self.bounds.size.width - 72) {
        fileName = [fileName substringToIndex:fileName.length - 1];
        return [self getTitle:fileName fileType:fileType cutCount:cutCount + 1];;
    }
    
    return string;
}

- (void)showBackTip {
    NSString *PLVIsShowDocPagesTip_KEY = @"PLVIsShowDocPagesTip_KEY";
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    BOOL isShowDocPagesTip = [userDefaults boolForKey:PLVIsShowDocPagesTip_KEY];
    if (isShowDocPagesTip) {
        return;
    }
    
    UIImage *imgBg = [PLVLSUtils imageForDocumentResource:@"plvls_doc_pages_back_tip"];
    _btnBackTip = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.btnBackTip setBackgroundImage:imgBg forState:UIControlStateNormal];
    self.btnBackTip.titleLabel.font = [UIFont systemFontOfSize:12];
    [self.btnBackTip setTitleColor:PLV_UIColorFromRGB(@"#F0F1F5") forState:UIControlStateNormal];
    [self.btnBackTip setTitle:@"返回查看所有文档" forState:UIControlStateNormal];
    self.btnBackTip.titleEdgeInsets = UIEdgeInsetsMake(8, 0, 0, 0);
    self.btnBackTip.userInteractionEnabled = NO;
    
    [self addSubview:self.btnBackTip];
    self.btnBackTip.frame = CGRectMake(20, 31, 120, 40);
    
    [userDefaults setBool:YES forKey:PLVIsShowDocPagesTip_KEY];
    
    _timerTip = [NSTimer scheduledTimerWithTimeInterval:3.0f target:[PLVFWeakProxy proxyWithTarget:self]
                                               selector:@selector(hiddenBackTip) userInfo:nil repeats:NO];
}

- (void)hiddenBackTip {
    if (self.timerTip) {
        [self.timerTip invalidate];
        self.timerTip = nil;
    }
    
    if (self.btnBackTip) {
        [self.btnBackTip removeFromSuperview];
        self.btnBackTip = nil;
    }
}

- (CGSize)cellSize {
    if (_cellSize.width == 0) {
        CGSize defaultSize = CGSizeMake(144, 80);
        CGFloat collectionViewWidth = self.collectionView.bounds.size.width;
        
        
        UICollectionViewFlowLayout *cvfLayout = (UICollectionViewFlowLayout *)self.collectionView.collectionViewLayout;
        
        CGFloat itemWidth = (collectionViewWidth - self.collectionView.contentInset.left - self.collectionView.contentInset.right - cvfLayout.minimumInteritemSpacing * 3) / 4;
        
        _cellSize = CGSizeMake(itemWidth, itemWidth * defaultSize.height / defaultSize.width);
    }
    
    return _cellSize;
}

#pragma mark - [ Getter ]

- (UIButton *)btnBack {
    if (! _btnBack) {
        _btnBack = [UIButton buttonWithType:UIButtonTypeCustom];
        [_btnBack setImage:[PLVLSUtils imageForDocumentResource:@"plvls_doc_btn_back"] forState:UIControlStateNormal];
        [_btnBack addTarget:self action:@selector(backButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return _btnBack;
}

- (UILabel *)lbTitle {
    if (! _lbTitle) {
        _lbTitle = [[UILabel alloc] init];
        _lbTitle.font = [UIFont boldSystemFontOfSize:16];
        _lbTitle.textColor = PLV_UIColorFromRGB(@"#F0F1F5");
    }
    
    return _lbTitle;
}

- (UILabel *)lbCount {
    if (! _lbCount) {
        _lbCount = [[UILabel alloc] init];
        _lbCount.font = [UIFont boldSystemFontOfSize:12];
        _lbCount.textColor = PLV_UIColorFromRGB(@"#CFD1D6");
        _lbCount.textAlignment = NSTextAlignmentRight;
    }
    
    return _lbCount;
}

- (UIView *)viewLine {
    if (! _viewLine) {
        _viewLine = [[UIView alloc] init];
        _viewLine.backgroundColor = PLV_UIColorFromRGBA(@"#F0F1F5", 0.1);
    }
    
    return _viewLine;
}

- (UICollectionView *)collectionView {
    if (! _collectionView) {
        UICollectionViewFlowLayout *cvfLayout = [[UICollectionViewFlowLayout alloc] init];
        cvfLayout.minimumLineSpacing = 28;
        cvfLayout.minimumInteritemSpacing = 28;
        
        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:cvfLayout];
        _collectionView.backgroundColor = [UIColor clearColor];
        _collectionView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
        _collectionView.dataSource = self;
        _collectionView.delegate = self;
        _collectionView.contentInset = UIEdgeInsetsMake(16, 28, PLVLSUtils.safeBottomPad, 28);
        [_collectionView registerClass:PLVLSDocumentPagesCell.class forCellWithReuseIdentifier:DocPagesCellIdentifier];
    }
    
    return _collectionView;
}

#pragma mark - [ Event ]
#pragma mark Action

- (void)backButtonAction:(UIButton *)button {
    if (self.delegate && [self.delegate respondsToSelector:@selector(documentPagesViewDidBackAction:)]) {
        [self.delegate documentPagesViewDidBackAction:self];
    }
}

#pragma mark - UICollectionView DataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.docPageDatas.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    PLVLSDocumentPagesCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:DocPagesCellIdentifier
                                                                            forIndexPath:indexPath];
    [cell setImgUrl:self.docPageDatas[indexPath.item] index:indexPath.item + 1];
    
    return cell;
}

#pragma mark - UICollectionView Delegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger index = indexPath.item;
    
    if (index == self.selectPageIndex) {
        return;
    }
    
    _selectPageIndex = index;
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(documentPagesView:didSelectItemAtIndex:)]) {
        [self.delegate documentPagesView:self didSelectItemAtIndex:index];
    }
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return self.cellSize;
}

@end
