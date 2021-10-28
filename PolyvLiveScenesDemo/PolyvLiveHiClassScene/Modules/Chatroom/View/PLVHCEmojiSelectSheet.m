//
//  PLVHCEmojiSelectSheet.m
//  PolyvLiveScenesDemo
//
//  Created by lijingtong on 2021/6/28.
//  Copyright © 2021 polyv. All rights reserved.
//

#import "PLVHCEmojiSelectSheet.h"

// 工具类
#import "PLVHCUtils.h"
 
// UI
#import "PLVHCEmojiCollectionViewCell.h"

// Manager
#import "PLVEmoticonManager.h"

// 依赖库
#import <PLVFoundationSDK/PLVFoundationSDK.h>

static NSString *KPLVHCEmojiCollectionViewCellID = @"PLVHCEmojiCollectionViewCellID";
static int kMaxRow = 3;
static int kMaxColumn = 4;

@interface PLVHCEmojiSelectSheet()<
UICollectionViewDelegate,
UICollectionViewDataSource>

#pragma mark UI
@property (nonatomic, strong) UIView *menuView;
@property (nonatomic, strong) UIButton *deleteButton;
@property (nonatomic, strong) UIButton *sendButton;
@property (nonatomic, strong) UICollectionView *collectionView;

#pragma mark 数据
@property (nonatomic, assign) CGSize menuSize;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, strong) NSArray <PLVEmoticon *>*emojiArray; // 表情数组

@end

@implementation PLVHCEmojiSelectSheet

#pragma mark - [ Life Cycle ]

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.emojiArray = [PLVEmoticonManager sharedManager].models;
        [self setupUI];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat buttonWidth = 40.0;
    CGFloat sidePadding = 8;
    CGFloat bottomSide = 8;

    self.deleteButton.frame = CGRectMake(CGRectGetWidth(self.bounds)-sidePadding-buttonWidth, sidePadding, buttonWidth, buttonWidth);
    self.sendButton.frame = CGRectMake(CGRectGetMinX(self.deleteButton.frame), CGRectGetMaxY(self.deleteButton.frame)+8.0, buttonWidth, 62);
    
    self.collectionView.frame = CGRectMake(sidePadding, sidePadding, CGRectGetMinX(self.deleteButton.frame)- sidePadding - 10, CGRectGetHeight(self.bounds) - bottomSide * 2);

    CGRect frame = self.bounds;
    self.menuSize = frame.size;
    self.menuView.frame = frame;
        
    UIBezierPath *bezierPath = [self BezierPathWithSize:self.menuSize];
    CAShapeLayer* shapeLayer = [CAShapeLayer layer];
    shapeLayer.path = bezierPath.CGPath;
    self.menuView.layer.mask = shapeLayer;
}

#pragma mark - [ Public Method ]

- (void)sendButtonEnable:(BOOL)enable {
    self.sendButton.enabled = enable;
}

#pragma mark - [ Private Method ]
#pragma mark Init

- (void)setupUI {
    self.menuView = [[UIView alloc] init];
    self.menuView.layer.masksToBounds = YES;
    self.menuView.backgroundColor = [PLVColorUtil colorFromHexString:@"#2D3452"];
    [self addSubview:self.menuView];

    [self.menuView addSubview:self.collectionView];
    
    self.deleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.deleteButton.backgroundColor = PLV_UIColorFromRGB(@"#C6C9CF");
    UIImage *deleteImage = [PLVHCUtils imageForChatroomResource:@"plvhc_chatroom_btn_delete"];
    [self.deleteButton setImage:deleteImage forState:UIControlStateNormal];
    [self.deleteButton addTarget:self action:@selector(deleteButtonTouchBegin)forControlEvents:UIControlEventTouchDown];
    [self.deleteButton addTarget:self action:@selector(deleteButtonTouchEnd)forControlEvents:UIControlEventTouchUpInside];
    [self.deleteButton addTarget:self action:@selector(deleteButtonTouchEnd)forControlEvents:UIControlEventTouchUpOutside];
    self.deleteButton.layer.cornerRadius = 4.0;
    [self.menuView addSubview:self.deleteButton];
    
    self.sendButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.sendButton.backgroundColor = PLV_UIColorFromRGB(@"#00B16C");
    [self.sendButton setTitle:@"发送" forState:UIControlStateNormal];
    self.sendButton.titleLabel.font = [UIFont  systemFontOfSize:14.0];
    [self.sendButton addTarget:self action:@selector(sendButtonButtonAction) forControlEvents:UIControlEventTouchUpInside];
    self.sendButton.layer.cornerRadius = 4.0;
    [self.menuView addSubview:self.sendButton];
}

#pragma mark Getter
- (UICollectionView *)collectionView {
    if (!_collectionView) {
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        layout.scrollDirection = UICollectionViewScrollDirectionVertical;
        layout.minimumLineSpacing = 0;
        layout.minimumInteritemSpacing = 0;
        
        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
        _collectionView.backgroundColor = [UIColor clearColor];
        [_collectionView registerClass:[PLVHCEmojiCollectionViewCell class] forCellWithReuseIdentifier:KPLVHCEmojiCollectionViewCellID];
    }
    return _collectionView;
}

- (UIBezierPath *)BezierPathWithSize:(CGSize)size {
    CGFloat conner = 8.0; // 圆角角度
    CGFloat trangleHeight = 8.0; // 尖角高度
    CGFloat trangleWidth = 6.0; // 尖角半径
    
    UIBezierPath *bezierPath = [UIBezierPath bezierPath];
    // 起点
    [bezierPath moveToPoint:CGPointMake(conner, 0)];
    [bezierPath addLineToPoint:CGPointMake(size.width - conner, 0)];
    
    [bezierPath addQuadCurveToPoint:CGPointMake(size.width, conner) controlPoint:CGPointMake(size.width, 0)];
    [bezierPath addLineToPoint:CGPointMake(size.width, size.height- conner - trangleHeight)];
    [bezierPath addQuadCurveToPoint:CGPointMake(size.width-conner, size.height - trangleHeight) controlPoint:CGPointMake(size.width, size.height - trangleHeight)];

    [bezierPath addLineToPoint:CGPointMake(conner, size.height - trangleHeight)];
    [bezierPath addQuadCurveToPoint:CGPointMake(0, size.height - conner - trangleHeight) controlPoint:CGPointMake(0, size.height - trangleHeight)];
    [bezierPath addLineToPoint:CGPointMake(0, conner)];
    [bezierPath addQuadCurveToPoint:CGPointMake(conner, 0) controlPoint:CGPointMake(0, 0)];
    
    // 画尖角
    [bezierPath moveToPoint:CGPointMake(conner, size.height - trangleHeight)];
    [bezierPath addLineToPoint:CGPointMake( 24 - conner, size.height - trangleHeight)];
    // 顶点
    [bezierPath addLineToPoint:CGPointMake(24, size.height)];
    [bezierPath addLineToPoint:CGPointMake(24 + trangleWidth, size.height - trangleHeight)];
    [bezierPath closePath];
    return bezierPath;
}

#pragma mark Action

- (void)deleteButtonTouchBegin {
    if (!self.timer) {
        self.timer = [NSTimer scheduledTimerWithTimeInterval:0.3 target:self selector:@selector(deleteAction) userInfo:nil repeats:YES];
        [self.timer fire];
    }
}

- (void)deleteButtonTouchEnd {
    [self.timer invalidate];
    self.timer = nil;
}

- (void)sendButtonButtonAction {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(emojiSelectSheet:didReceiveEvent:)]) {
        [self.delegate emojiSelectSheet:self didReceiveEvent:PLVHCEmojiSelectSheetEventSend];
    }
}

- (void)deleteAction {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(emojiSelectSheet:didReceiveEvent:)]) {
        [self.delegate emojiSelectSheet:self didReceiveEvent:PLVHCEmojiSelectSheetEventDelete];
    }
}

#pragma mark - [ Delegate ]
#pragma mark CollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.emojiArray.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    PLVHCEmojiCollectionViewCell *cell  = [collectionView dequeueReusableCellWithReuseIdentifier:KPLVHCEmojiCollectionViewCellID forIndexPath:indexPath];
    if (self.emojiArray.count > indexPath.item) {
        PLVEmoticon *emojiModel = [self.emojiArray objectAtIndex:indexPath.item];
        //不用异步加载第一次进入界面滑动会卡顿
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            UIImage *emojiImage = [[PLVEmoticonManager sharedManager] imageForEmoticonName:emojiModel.imageName];
            dispatch_async(dispatch_get_main_queue(), ^{
                cell.imageView.image = emojiImage;
            });
        });
    }
    return cell;
}

#pragma mark CollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (self.emojiArray.count > indexPath.item) {
        PLVEmoticon *emojiModel = [self.emojiArray objectAtIndex:indexPath.item];
        if (self.delegate &&
            [self.delegate respondsToSelector:@selector(emojiSelectSheet:didSelectEmoticon:)]) {
            [self.delegate emojiSelectSheet:self didSelectEmoticon:emojiModel];
        }
    }
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(self.collectionView.frame.size.width/kMaxColumn, self.collectionView.frame.size.height/kMaxRow);
}

@end
