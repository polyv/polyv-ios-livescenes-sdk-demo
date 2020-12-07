//
//  PLVKeyboardMoreView.m
//  PolyvLiveScenesDemo
//
//  Created by MissYasiky on 2020/9/27.
//  Copyright © 2020 polyv. All rights reserved.
//

#import "PLVKeyboardMoreView.h"
#import "PLVKeyboardUtils.h"

static NSString *kMoreViewCellIdentifier = @"kMoreViewCellIdentifier";
static NSInteger kItemCountPerSection = 1;

static CGFloat kCellButtonWidth = 52.0;
static CGFloat kCellButtonHeight = 74.0;
static CGFloat kCellImageLabelMargin = 8.0;

typedef NS_ENUM(NSInteger, PLVKeyboardMoreButtonType) {
    PLVKeyboardMoreButtonTypeUnknow = -1,
    PLVKeyboardMoreButtonTypeOnlyTeacher = 0,
    PLVKeyboardMoreButtonTypeOpenCamera,
    PLVKeyboardMoreButtonTypeOpenAlbum,
    PLVKeyboardMoreButtonTypeOpenBulletin,
};

@interface PLVMoreCollectionViewCell : UICollectionViewCell

@property (nonatomic, strong) UIButton *moreBtn;

@property (nonatomic, assign) PLVKeyboardMoreButtonType type;

@end

@implementation PLVMoreCollectionViewCell

#pragma mark - Life Cycle

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.moreBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        self.moreBtn.frame = CGRectMake(0.0, 0.0, kCellButtonWidth, kCellButtonHeight);
        self.moreBtn.titleLabel.font = [UIFont systemFontOfSize:12.0];
        [self.moreBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        
        self.moreBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
         
        [self addSubview:self.moreBtn];
    }
    return self;
}

#pragma mark - Public Method

- (void)setType:(PLVKeyboardMoreButtonType)type {
    _type = type;
    switch (type) {
        case PLVKeyboardMoreButtonTypeOnlyTeacher:
            [self.moreBtn setImage:[PLVKeyboardUtils imageForKeyboardResource:@"plv_keyboard_onlyteacher"] forState:UIControlStateNormal];
            [self.moreBtn setImage:[PLVKeyboardUtils imageForKeyboardResource:@"plv_keyboard_seeall"] forState:UIControlStateSelected];
            [self.moreBtn setTitle:@"只看讲师" forState:UIControlStateNormal];
            [self.moreBtn setTitle:@"查看全部" forState:UIControlStateSelected];
            break;
        case PLVKeyboardMoreButtonTypeOpenAlbum:
            [self.moreBtn setImage:[PLVKeyboardUtils imageForKeyboardResource:@"plv_keyboard_album"] forState:UIControlStateNormal];
            [self.moreBtn setTitle:@"发送图片" forState:UIControlStateNormal];
            break;
        case PLVKeyboardMoreButtonTypeOpenCamera:
            [self.moreBtn setImage:[PLVKeyboardUtils imageForKeyboardResource:@"plv_keyboard_camera"] forState:UIControlStateNormal];
            [self.moreBtn setTitle:@"拍照" forState:UIControlStateNormal];
            break;
        case PLVKeyboardMoreButtonTypeOpenBulletin:
            [self.moreBtn setImage:[PLVKeyboardUtils imageForKeyboardResource:@"plv_keyboard_notice"] forState:UIControlStateNormal];
            [self.moreBtn setTitle:@"公告" forState:UIControlStateNormal];
            break;
        default:
            break;
    }
    
    CGSize ivSize = self.moreBtn.imageView.frame.size;
    CGSize lbSize = self.moreBtn.titleLabel.frame.size;
    [self.moreBtn setTitleEdgeInsets:UIEdgeInsetsMake(ivSize.height + kCellImageLabelMargin / 2.0f,
                                                      -ivSize.width - 2,
                                                      0.0, 0.0)];
    [self.moreBtn setImageEdgeInsets:UIEdgeInsetsMake(-lbSize.height - kCellImageLabelMargin / 2.0f,
                                                      (kCellButtonWidth - ivSize.width) / 2.0f - 2,
                                                      0.0,
                                                      lbSize.width)];
}

@end

@interface PLVKeyboardMoreView () <UICollectionViewDataSource, UICollectionViewDelegate>

@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) UICollectionViewFlowLayout *flowLayout;

@end

@implementation PLVKeyboardMoreView

#pragma mark - Life Cycle

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _sendImageEnable = YES;
        
        self.backgroundColor = [UIColor colorWithRed:0x2b/255.0 green:0x2c/255.0 blue:0x35/255.0 alpha:1.0];
        
        self.flowLayout = [[UICollectionViewFlowLayout alloc] init];
        self.flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        self.flowLayout.itemSize = CGSizeMake(kCellButtonWidth, kCellButtonHeight);
        
        float totalPadding = [UIScreen mainScreen].bounds.size.width - kCellButtonWidth * 4;
        float paddingScale = totalPadding / 159.0;
        float padding = 15.9 * paddingScale;
        self.flowLayout.sectionInset = UIEdgeInsetsMake(15.9, padding, 15.9, padding);
        
        CGRect rect = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 24 + kCellButtonHeight + 24);
        self.collectionView = [[UICollectionView alloc] initWithFrame:rect collectionViewLayout:self.flowLayout];
        self.collectionView.backgroundColor = [UIColor clearColor];
        [self.collectionView registerClass:[PLVMoreCollectionViewCell class] forCellWithReuseIdentifier:kMoreViewCellIdentifier];
        self.collectionView.dataSource = self;
        self.collectionView.delegate = self;
        self.collectionView.showsHorizontalScrollIndicator = NO;
        self.collectionView.showsVerticalScrollIndicator = NO;
        [self addSubview:self.collectionView];
    }
    return self;
}

#pragma mark - Getterr & Setter

- (void)setSendImageEnable:(BOOL)sendImageEnable {
    if (_sendImageEnable == sendImageEnable) {
        return;;
    }
    _sendImageEnable = sendImageEnable;
    [self.collectionView reloadData];
}

- (void)setHiddenBulletin:(BOOL)hiddenBulletin {
    if (_hiddenBulletin == hiddenBulletin) {
        return;;
    }
    _hiddenBulletin = hiddenBulletin;
    [self.collectionView reloadData];
}

#pragma mark - UICollectionView DataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView*)collectionView {
    NSUInteger count = 4;
    if (!self.sendImageEnable) {
        count -= 2;
    }
    if (self.hiddenBulletin) {
        count--;
    }
    return count;
}

- (NSInteger)collectionView:(UICollectionView*)collectionView numberOfItemsInSection:(NSInteger)section {
    return kItemCountPerSection;
}

- (UICollectionViewCell *)collectionView:(UICollectionView*)collectionView cellForItemAtIndexPath:(NSIndexPath*)indexPath {
    PLVMoreCollectionViewCell *cell = [self.collectionView dequeueReusableCellWithReuseIdentifier:kMoreViewCellIdentifier
                                                                                     forIndexPath:indexPath];
    NSInteger index = indexPath.row + indexPath.section * kItemCountPerSection;
    PLVKeyboardMoreButtonType type = [self typeOfIndex:index];
    if (type == PLVKeyboardMoreButtonTypeOnlyTeacher) {
        [cell.moreBtn addTarget:self action:@selector(onlyTeacher:) forControlEvents:UIControlEventTouchUpInside];
    } else if (type == PLVKeyboardMoreButtonTypeOpenAlbum) {
        [cell.moreBtn addTarget:self action:@selector(openAlbum:) forControlEvents:UIControlEventTouchUpInside];
    } else if (type == PLVKeyboardMoreButtonTypeOpenCamera) {
        [cell.moreBtn addTarget:self action:@selector(openCamera:) forControlEvents:UIControlEventTouchUpInside];
    } else if (type == PLVKeyboardMoreButtonTypeOpenBulletin) {
        [cell.moreBtn addTarget:self action:@selector(openBulletin:) forControlEvents:UIControlEventTouchUpInside];
    }
    cell.type = type;
    return cell;
}

#pragma mark - Action

- (void)openCamera:(id)sender
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(keyboardMoreView_openCamera:)]) {
        [self.delegate keyboardMoreView_openCamera:self];
    }
}

- (IBAction)openAlbum:(id)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(keyboardMoreView_openAlbum:)]) {
        [self.delegate keyboardMoreView_openAlbum:self];
    }
}

- (IBAction)openBulletin:(id)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(keyboardMoreView_openBulletin:)]) {
        [self.delegate keyboardMoreView_openBulletin:self];
    }
}

- (IBAction)onlyTeacher:(id)sender {
    UIButton *button = (UIButton *)sender;
    button.selected = !button.selected;
    if (self.delegate && [self.delegate respondsToSelector:@selector(keyboardMoreView_onlyTeacher:on:)]) {
        [self.delegate keyboardMoreView_onlyTeacher:self on:button.selected];
    }
}

#pragma mark - UICollectionViewDelegate FlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
    CGSize size = CGSizeMake(0.0, self.collectionView.bounds.size.height);
    if (section == 0) {
        size = CGSizeMake(self.flowLayout.sectionInset.left, self.collectionView.bounds.size.height);
    }
    return size;
}

- (CGSize)collectionView:(UICollectionView*)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section {
    CGSize size = CGSizeMake(0.0, self.collectionView.bounds.size.height);
    return size;
}

#pragma mark - Private Method

- (PLVKeyboardMoreButtonType)typeOfIndex:(NSInteger)index {
    if (index == 0) {
        return PLVKeyboardMoreButtonTypeOnlyTeacher;
    }
    if (self.sendImageEnable) {
        if (index == 1) {
            return PLVKeyboardMoreButtonTypeOpenAlbum;
        } else if (index == 2) {
            return PLVKeyboardMoreButtonTypeOpenCamera;
        } else if (index == 3 && !self.hiddenBulletin) {
            return PLVKeyboardMoreButtonTypeOpenBulletin;
        }
    } else {
        if (index == 1 && !self.hiddenBulletin) {
            return PLVKeyboardMoreButtonTypeOpenBulletin;
        }
    }
    
    return PLVKeyboardMoreButtonTypeUnknow;
}

@end
