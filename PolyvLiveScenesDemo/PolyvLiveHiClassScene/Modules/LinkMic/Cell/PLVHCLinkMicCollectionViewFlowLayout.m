//
//  PLVHCLinkMicCollectionViewFlowLayout.m
//  PolyvLiveScenesDemo
//
//  Created by Sakya on 2021/9/24.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVHCLinkMicCollectionViewFlowLayout.h"

///模块
#import "PLVRoomDataManager.h"
#import "PLVHCUtils.h"

@interface PLVHCLinkMicCollectionViewFlowLayout ()

@property (nonatomic, assign) CGSize cellSize;
@property (nonatomic, assign) CGRect lastFrame; //记录布局的最后一个frame
@property (nonatomic, assign) NSInteger linkNumber;
@property (nonatomic, strong) NSMutableArray *attributeAttay;//布局的LayoutAttributes
@property (nonatomic, assign) BOOL containTeacher;//连麦布局中是否包含老师(默认不包含)仅在1v16布局中用到

@end

@implementation PLVHCLinkMicCollectionViewFlowLayout

#pragma mark - [ Life Cycle ]

- (instancetype)init {
    self = [super init];
    if (self) {
        self.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        self.minimumLineSpacing = 0;
        self.minimumInteritemSpacing = 0;
        PLVRoomData *roomData = [PLVRoomDataManager sharedManager].roomData;
        self.linkNumber = roomData.lessonInfo.linkNumber;
        self.attributeAttay = [NSMutableArray array];
        self.cellSize = self.linkNumber > 6 ? CGSizeMake(74, 42.5) : CGSizeMake(106, 60);
    }
    return self;
}

#pragma mark - [ Override ]

-(void)prepareLayout{
    [super prepareLayout];
    
    [self updateLayoutAttributes];
}

// 调整当前layout的样式
- (nullable NSArray<__kindof UICollectionViewLayoutAttributes *> *)layoutAttributesForElementsInRect:(CGRect)rect {
    return self.attributeAttay;
}

- (CGSize)collectionViewContentSize {
    return [self getCollectionViewContentSize];
}

#pragma mark - [ Private Method ]

- (void)updateLayoutAttributes {
    [self.attributeAttay removeAllObjects];
    self.lastFrame = CGRectZero;
    self.containTeacher = NO;
    NSInteger itemCount = [self.collectionView numberOfItemsInSection:0];

    for (NSInteger index = 0; index < itemCount; index ++) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:index inSection:0];
        UICollectionViewLayoutAttributes *attris = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
        CGFloat originX = 0.0;
        CGFloat originY = 0.0;
        if (self.linkNumber < 7) { //1V6布局
            originX = CGRectGetMaxX(self.lastFrame);
            attris.frame = CGRectMake(originX, originY, self.cellSize.width, self.cellSize.height);
        } else { //1V16布局
            //通过用户列表的总数计算出老师的位置下标
            BOOL isTeacher = [self.delegate linkMicFlowLayout:self teacherItemAtIndexPath:indexPath];
            if (isTeacher) {
                self.containTeacher = isTeacher;
                //设置讲师item的frame
                attris.frame = CGRectMake(CGRectGetMaxX(self.lastFrame), 0, self.cellSize.width * 2, self.cellSize.height * 2);
            } else {
                //设置学生item的frame
                BOOL singleShow = (NSInteger)(ceil(itemCount/2)) % 2 == 1 && itemCount > 5;
                if (singleShow && index == 1) {
                    // 判断首行需要单个显示，第二行就需要从下一行排列
                    originY = 0;
                    originX = CGRectGetMaxX(self.lastFrame);
                } else {
                    if (CGRectGetMaxY(self.lastFrame) > self.cellSize.height) {
                        //最大Y坐标大于单个高度则上一行已经占满了
                        originY = 0;
                        originX = CGRectGetMaxX(self.lastFrame);
                    } else {
                        originY = CGRectGetMaxY(self.lastFrame);
                        originX = CGRectGetMinX(self.lastFrame);
                    }
                }
                attris.frame = CGRectMake(originX, originY, self.cellSize.width, self.cellSize.height);
            }
        }
        self.lastFrame = attris.frame;
        [self.attributeAttay addObject:attris];
    }
    [self updateCollectionViewFrame];
}

- (void)updateCollectionViewFrame {
    UIEdgeInsets edgeInsets = [PLVHCUtils sharedUtils].areaInsets;
    CGFloat edgeInsetsRight = MAX(edgeInsets.right, 16);
    CGSize windowsViewSize = [self.delegate linkMicFlowLayoutGetWindowsViewSize:self];
    CGSize collectionViewSize = [self getCollectionViewContentSize];
    CGFloat linkMicAreaRealWith = collectionViewSize.width;
    CGFloat linkMicAreaMaxWith = windowsViewSize.width - edgeInsetsRight * 2;
    linkMicAreaRealWith = MIN(linkMicAreaRealWith, linkMicAreaMaxWith);
    if (CGRectGetWidth(self.collectionView.bounds) == linkMicAreaRealWith) {
        return;
    }
    self.collectionView.frame = CGRectMake(0, 0, linkMicAreaRealWith, collectionViewSize.height);
    self.collectionView.center = CGPointMake(windowsViewSize.width/2, windowsViewSize.height/2);
}

- (CGSize)getCollectionViewContentSize {
    if (self.linkNumber > 6) {
        if (self.containTeacher) {
            //1v16包含老师的布局需要始终保持老师在中间
            NSInteger itemCount = [self.collectionView numberOfItemsInSection:0];
            NSInteger scaleNum = itemCount > 1 ? (((itemCount - 2)/4 + 1) * 2) :0;
            //讲师的连麦宽度和学生的连麦宽度
            CGFloat contentWidth = self.cellSize.width * scaleNum + self.cellSize.width * 2;
            return CGSizeMake(contentWidth, self.cellSize.height * 2);
        } else {
            return CGSizeMake(CGRectGetMaxX(self.lastFrame), self.cellSize.height * 2);
        }
    } else {
        return CGSizeMake(CGRectGetMaxX(self.lastFrame), self.cellSize.height);
    }
}
    
@end
