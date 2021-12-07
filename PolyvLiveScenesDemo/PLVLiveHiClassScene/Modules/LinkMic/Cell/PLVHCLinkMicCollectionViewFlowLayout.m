//
//  PLVHCLinkMicCollectionViewFlowLayout.m
//  PLVLiveScenesDemo
//
//  Created by Sakya on 2021/9/24.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVHCLinkMicCollectionViewFlowLayout.h"

///模块
#import "PLVRoomDataManager.h"
#import "PLVHCUtils.h"

@interface PLVHCLinkMicCollectionViewFlowLayout ()

@property (nonatomic, assign, readonly) CGSize minCellSize; //不同连麦人数最小的cellsize
@property (nonatomic, assign) CGRect lastFrame; //记录布局的最后一个frame
@property (nonatomic, assign, readonly) NSInteger linkNumber;
@property (nonatomic, strong) NSMutableArray *attributeAttay;//布局的LayoutAttributes

@end

@implementation PLVHCLinkMicCollectionViewFlowLayout

#pragma mark - [ Life Cycle ]

- (instancetype)init {
    self = [super init];
    if (self) {
        self.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        self.minimumLineSpacing = 0;
        self.minimumInteritemSpacing = 0;
        self.attributeAttay = [NSMutableArray array];
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
    NSInteger itemCount = [self.collectionView numberOfItemsInSection:0];

    for (NSInteger index = 0; index < itemCount; index ++) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:index inSection:0];
        UICollectionViewLayoutAttributes *attris = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
        CGFloat originX = 0.0;
        CGFloat originY = 0.0;
        if (self.linkNumber > 6) { //1v16布局
            BOOL isTeacher = [self.delegate linkMicFlowLayout:self teacherItemAtIndexPath:indexPath];
            if (isTeacher) {
                //设置讲师item的frame
                attris.frame = CGRectMake(CGRectGetMaxX(self.lastFrame), 0, self.minCellSize.width * 2, self.minCellSize.height * 2);
            } else {
                //设置学生item的frame
                BOOL singleShow = (NSInteger)(ceil(itemCount/2)) % 2 == 1 && itemCount > 5;
                if (singleShow && index == 1) {
                    // 判断首列需要单个显示，第二个元素就需要从下一列排布
                    originY = 0;
                    originX = CGRectGetMaxX(self.lastFrame);
                } else {
                    if (CGRectGetMaxY(self.lastFrame) > self.minCellSize.height) {
                        //最大Y坐标大于单列高度
                        originY = 0;
                        originX = CGRectGetMaxX(self.lastFrame);
                    } else {
                        originY = CGRectGetMaxY(self.lastFrame);
                        originX = CGRectGetMinX(self.lastFrame);
                    }
                }
                attris.frame = CGRectMake(originX, originY, self.minCellSize.width, self.minCellSize.height);
            }
        } else { //1v6布局
            originX = CGRectGetMaxX(self.lastFrame);
            attris.frame = CGRectMake(originX, originY, self.minCellSize.width, self.minCellSize.height);
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
    CGFloat collectionViewHeight = self.linkNumber > 6 ? self.minCellSize.height * 2 : self.minCellSize.height;
    return CGSizeMake(CGRectGetMaxX(self.lastFrame), collectionViewHeight);
}

#pragma mark Getter

- (NSInteger)linkNumber {
    return [PLVRoomDataManager sharedManager].roomData.linkNumber;
}

- (CGSize)minCellSize {
    return self.linkNumber > 6 ? CGSizeMake(74, 42.5) : CGSizeMake(106, 60);
}
    
@end
