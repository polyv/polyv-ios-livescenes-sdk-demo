//
//  PLVHCEmojiSelectView.m
//  PLVLiveScenesDemo
//
//  Created by lijingtong on 2021/6/28.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVHCEmojiSelectView.h"

// Utils
#import "PLVHCUtils.h"

// UI
#import "PLVHCEmojiCollectionViewCell.h"

// Manager
#import "PLVEmoticonManager.h"

// 依赖库
#import <PLVFoundationSDK/PLVFoundationSDK.h>

static NSString *KPLVHCEmojiCollectionViewCellID = @"PLVHCEmojiCollectionViewCellID";
static int kMaxRow = 4;
static int kMaxColumn = 12;

@interface PLVHCEmojiSelectView()<
UICollectionViewDelegate,
UICollectionViewDataSource>

#pragma mark UI
@property (nonatomic, strong) UIButton *deleteButton;
@property (nonatomic, strong) UIButton *sendButton;
@property (nonatomic, strong) UICollectionView *collectionView;

#pragma mark 数据
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, strong) NSArray <PLVEmoticon *>*emojiArray; // 表情数组
@end

@implementation PLVHCEmojiSelectView

#pragma mark - [ Life Cycle ]

- (instancetype)init {
    self = [super init];
    if (self) {
        self.backgroundColor = [PLVColorUtil colorFromHexString:@"#2B2C35"];
        self.emojiArray = [PLVEmoticonManager sharedManager].models;
        [self setupUI];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat buttonWidth = 48.0;
    CGFloat sidePadding = [PLVHCUtils sharedUtils].areaInsets.right + 40;
    CGFloat bottomSide = [PLVHCUtils sharedUtils].areaInsets.bottom;

    self.deleteButton.frame = CGRectMake(CGRectGetWidth(self.bounds)-sidePadding-buttonWidth, 17.0, buttonWidth, buttonWidth);
    self.sendButton.frame = CGRectMake(CGRectGetMinX(self.deleteButton.frame), CGRectGetMaxY(self.deleteButton.frame)+8.0, buttonWidth, 112.0);
    
    self.collectionView.frame = CGRectMake(sidePadding, 0, CGRectGetMinX(self.deleteButton.frame)- sidePadding - 10, CGRectGetHeight(self.bounds) - bottomSide);
}

#pragma mark - [ Public Method ]

- (void)sendButtonEnable:(BOOL)enable {
    self.sendButton.enabled = enable;
}

#pragma mark - [ Private Method ]

#pragma mark Init

- (void)setupUI {
    [self addSubview:self.collectionView];
    
    self.deleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.deleteButton.backgroundColor = PLV_UIColorFromRGB(@"#C6C9CF");
    UIImage *deleteImage = [PLVHCUtils imageForChatroomResource:@"plvhc_chatroom_btn_delete"];
    [self.deleteButton setImage:deleteImage forState:UIControlStateNormal];
    [self.deleteButton addTarget:self action:@selector(deleteButtonTouchBegin)forControlEvents:UIControlEventTouchDown];
    [self.deleteButton addTarget:self action:@selector(deleteButtonTouchEnd)forControlEvents:UIControlEventTouchUpInside];
    [self.deleteButton addTarget:self action:@selector(deleteButtonTouchEnd)forControlEvents:UIControlEventTouchUpOutside];
    self.deleteButton.layer.cornerRadius = 4.0;
    [self addSubview:self.deleteButton];
    
    self.sendButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.sendButton.backgroundColor = PLV_UIColorFromRGB(@"#00B16C");
    [self.sendButton setTitle:@"发送" forState:UIControlStateNormal];
    self.sendButton.titleLabel.font = [UIFont  systemFontOfSize:14.0];
    [self.sendButton addTarget:self action:@selector(sendButtonButtonAction) forControlEvents:UIControlEventTouchUpInside];
    self.sendButton.layer.cornerRadius = 4.0;
    [self addSubview:self.sendButton];
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
    if ([self.delegate respondsToSelector:@selector(emojiSelectView:didReceiveEvent:)]) {
        [self.delegate emojiSelectView:self didReceiveEvent:PLVHCEmojiSelectViewEventSend];
    }
}

- (void)deleteAction {
    if ([self.delegate respondsToSelector:@selector(emojiSelectView:didReceiveEvent:)]) {
        [self.delegate emojiSelectView:self didReceiveEvent:PLVHCEmojiSelectViewEventDelete];
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
            [self.delegate respondsToSelector:@selector(emojiSelectView:didSelectEmoticon:)]) {
            [self.delegate emojiSelectView:self didSelectEmoticon:emojiModel];
        }
    }
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(self.collectionView.frame.size.width/kMaxColumn, self.collectionView.frame.size.height/kMaxRow);
}

@end
