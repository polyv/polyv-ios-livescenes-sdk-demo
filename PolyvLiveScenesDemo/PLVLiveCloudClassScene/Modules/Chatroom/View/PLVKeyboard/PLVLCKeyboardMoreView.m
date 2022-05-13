//
//  PLVKeyboardMoreView.m
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2020/9/27.
//  Copyright © 2020 PLV. All rights reserved.
//

#import "PLVLCKeyboardMoreView.h"
#import "PLVLCUtils.h"

static NSString *kMoreViewCellIdentifier = @"kMoreViewCellIdentifier";
static NSInteger kItemCountPerSection = 1;

static CGFloat kCellButtonWidth = 52.0;
static CGFloat kCellButtonHeight = 74.0;
static CGFloat kCellImageLabelMargin = 8.0;

typedef NS_ENUM(NSInteger, PLVLCKeyboardMoreButtonType) {
    PLVLCKeyboardMoreButtonTypeUnknow = -1,
    PLVLCKeyboardMoreButtonTypeOnlyTeacher = 0,
    PLVLCKeyboardMoreButtonTypeOpenCamera,
    PLVLCKeyboardMoreButtonTypeOpenAlbum,
    PLVLCKeyboardMoreButtonTypeOpenBulletin,
    PLVLCKeyboardMoreButtonTypeOpenLotteryWinRecord
};

@interface PLVLCMoreCollectionViewCell : UICollectionViewCell

@property (nonatomic, strong) UIButton *moreBtn;

@property (nonatomic, assign) PLVLCKeyboardMoreButtonType type;

@end

@implementation PLVLCMoreCollectionViewCell

#pragma mark - Life Cycle

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.moreBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        self.moreBtn.frame = CGRectMake(0.0, 0.0, kCellButtonWidth, kCellButtonHeight);
        self.moreBtn.titleLabel.font = [UIFont systemFontOfSize:12.0];
        [self.moreBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        
        self.moreBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
         
        [self.contentView addSubview:self.moreBtn];
    }
    return self;
}

#pragma mark - Public Method

- (void)setType:(PLVLCKeyboardMoreButtonType)type {
    _type = type;
    switch (type) {
        case PLVLCKeyboardMoreButtonTypeOnlyTeacher:
            [self.moreBtn setImage:[PLVLCUtils imageForChatroomResource:@"plvlc_keyboard_onlyteacher"] forState:UIControlStateNormal];
            [self.moreBtn setImage:[PLVLCUtils imageForChatroomResource:@"plvlc_keyboard_seeall"] forState:UIControlStateSelected];
            [self.moreBtn setTitle:@"只看主持" forState:UIControlStateNormal];
            [self.moreBtn setTitle:@"查看全部" forState:UIControlStateSelected];
            break;
        case PLVLCKeyboardMoreButtonTypeOpenAlbum:
            [self.moreBtn setImage:[PLVLCUtils imageForChatroomResource:@"plvlc_keyboard_album"] forState:UIControlStateNormal];
            [self.moreBtn setImage:[PLVLCUtils imageForChatroomResource:@"plvlc_keyboard_album"] forState:UIControlStateSelected];
            [self.moreBtn setTitle:@"发送图片" forState:UIControlStateNormal];
            [self.moreBtn setTitle:@"发送图片" forState:UIControlStateSelected];
            break;
        case PLVLCKeyboardMoreButtonTypeOpenCamera:
            [self.moreBtn setImage:[PLVLCUtils imageForChatroomResource:@"plvlc_keyboard_camera"] forState:UIControlStateNormal];
            [self.moreBtn setImage:[PLVLCUtils imageForChatroomResource:@"plvlc_keyboard_camera"] forState:UIControlStateSelected];
            [self.moreBtn setTitle:@"拍照" forState:UIControlStateNormal];
            [self.moreBtn setTitle:@"拍照" forState:UIControlStateSelected];
            break;
        case PLVLCKeyboardMoreButtonTypeOpenBulletin:
            [self.moreBtn setImage:[PLVLCUtils imageForChatroomResource:@"plvlc_keyboard_notice"] forState:UIControlStateNormal];
            [self.moreBtn setImage:[PLVLCUtils imageForChatroomResource:@"plvlc_keyboard_notice"] forState:UIControlStateSelected];
            [self.moreBtn setTitle:@"公告" forState:UIControlStateNormal];
            [self.moreBtn setTitle:@"公告" forState:UIControlStateSelected];
            break;
        case PLVLCKeyboardMoreButtonTypeOpenLotteryWinRecord:
            [self.moreBtn setImage:[PLVLCUtils imageForChatroomResource:@"plvlc_keyboard_lottery_normal"] forState:UIControlStateNormal];
            [self.moreBtn setImage:[PLVLCUtils imageForChatroomResource:@"plvlc_keyboard_lottery_newMessage"] forState:UIControlStateSelected];
            [self.moreBtn setTitle:@"消息" forState:UIControlStateNormal];
            [self.moreBtn setTitle:@"消息" forState:UIControlStateSelected];
            break;
        default:
            break;
    }
    
    [self.moreBtn setTitleEdgeInsets:UIEdgeInsetsMake(0, - self.moreBtn.imageView.frame.size.width, - self.moreBtn.imageView.frame.size.height - kCellImageLabelMargin / 2.0f, 0)];
    [self.moreBtn setImageEdgeInsets:UIEdgeInsetsMake(- self.moreBtn.titleLabel.intrinsicContentSize.height - kCellImageLabelMargin / 2.0f, 0, 0, - self.moreBtn.titleLabel.intrinsicContentSize.width)];
}

@end

@interface PLVLCKeyboardMoreView () <UICollectionViewDataSource>

@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) UICollectionViewFlowLayout *flowLayout;

@end

@implementation PLVLCKeyboardMoreView

#pragma mark - Life Cycle

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _sendImageEnable = YES;
        _hideLotteryWinRecord = YES;
        _isNewLotteryMessage = NO;
        
        self.backgroundColor = [UIColor colorWithRed:0x2b/255.0 green:0x2c/255.0 blue:0x35/255.0 alpha:1.0];
        
        self.flowLayout = [[UICollectionViewFlowLayout alloc] init];
        self.flowLayout.scrollDirection = UICollectionViewScrollDirectionVertical;
        self.flowLayout.itemSize = CGSizeMake(kCellButtonWidth, kCellButtonHeight);
        
        float totalPadding = [UIScreen mainScreen].bounds.size.width - kCellButtonWidth * 4;
        float paddingScale = totalPadding / 159.0;
        float padding = 15.9 * paddingScale;
        float commonPadding = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad ? 23.0 : padding ;
        self.flowLayout.sectionInset = UIEdgeInsetsMake(15.9, commonPadding, 15.9, commonPadding);
        
        CGRect rect = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 24 + kCellButtonHeight + 24);
        self.collectionView = [[UICollectionView alloc] initWithFrame:rect collectionViewLayout:self.flowLayout];
        self.collectionView.backgroundColor = [UIColor clearColor];
        [self.collectionView registerClass:[PLVLCMoreCollectionViewCell class] forCellWithReuseIdentifier:kMoreViewCellIdentifier];
        self.collectionView.dataSource = self;
        self.collectionView.showsHorizontalScrollIndicator = NO;
        self.collectionView.showsVerticalScrollIndicator = NO;
        [self addSubview:self.collectionView];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGRect rect = CGRectMake(0, 0, self.frame.size.width, 24 + kCellButtonHeight + 24);
    self.collectionView.frame = rect;
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

- (void)setHideLotteryWinRecord:(BOOL)hideLotteryWinRecord {
    if (_hideLotteryWinRecord == hideLotteryWinRecord) {
        return;
    }
    _hideLotteryWinRecord = hideLotteryWinRecord;
    [self.collectionView reloadData];
}

- (void)setIsNewLotteryMessage:(BOOL)isNewLotteryMessage {
    if (_isNewLotteryMessage == isNewLotteryMessage) {
        return;
    }
    _isNewLotteryMessage = isNewLotteryMessage;
    [self.collectionView reloadData];
}

#pragma mark - UICollectionView DataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView*)collectionView {
    return kItemCountPerSection;
}

- (NSInteger)collectionView:(UICollectionView*)collectionView numberOfItemsInSection:(NSInteger)section {
    NSUInteger count = 5;
    if (!self.sendImageEnable) {
        count -= 2;
    }
    if (self.hiddenBulletin) {
        count--;
    }
    if (self.hideLotteryWinRecord) {
        count--;
    }
    return count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView*)collectionView cellForItemAtIndexPath:(NSIndexPath*)indexPath {
    PLVLCMoreCollectionViewCell *cell = [self.collectionView dequeueReusableCellWithReuseIdentifier:kMoreViewCellIdentifier
                                                                                     forIndexPath:indexPath];

    PLVLCKeyboardMoreButtonType type = [self typeOfIndex:indexPath.item];
    if (type == PLVLCKeyboardMoreButtonTypeOpenLotteryWinRecord) {
        cell.moreBtn.selected = self.isNewLotteryMessage;
    }
    
    [cell.moreBtn addTarget:self action:@selector(moreBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    cell.type = type;
    cell.moreBtn.tag = (NSInteger)cell.type;
    
    return cell;
}

#pragma mark - Action
- (void)moreBtnAction:(UIButton *)button {
    if (button.tag == 0) {
        button.selected = !button.selected;
        if (self.delegate && [self.delegate respondsToSelector:@selector(keyboardMoreView_onlyTeacher:on:)]) {
            [self.delegate keyboardMoreView_onlyTeacher:self on:button.selected];
        }
    } else if (button.tag == 1) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(keyboardMoreView_openAlbum:)]) {
            [self.delegate keyboardMoreView_openCamera:self];
        }
    } else if (button.tag == 2) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(keyboardMoreView_openCamera:)]) {
            [self.delegate keyboardMoreView_openAlbum:self];
        }
    } else if (button.tag == 3) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(keyboardMoreView_openBulletin:)]) {
            [self.delegate keyboardMoreView_openBulletin:self];
        }
    } else if (button.tag == 4) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(keyboardMoreView_openLotteryRecord:)]) {
            [self.delegate keyboardMoreView_openLotteryRecord:self];
        }
    }
}

#pragma mark - Private Method

- (PLVLCKeyboardMoreButtonType)typeOfIndex:(NSInteger)index {
    if (index == 0) {
        return PLVLCKeyboardMoreButtonTypeOnlyTeacher;
    }
    if (self.sendImageEnable) {
        if (index == 1) {
            return PLVLCKeyboardMoreButtonTypeOpenAlbum;
        } else if (index == 2) {
            return PLVLCKeyboardMoreButtonTypeOpenCamera;
        } else if (index == 3 && !self.hiddenBulletin) {
            return PLVLCKeyboardMoreButtonTypeOpenBulletin;
        } else if (index == 4 && !self.hideLotteryWinRecord) {
            return PLVLCKeyboardMoreButtonTypeOpenLotteryWinRecord;
        }
    } else {
        if (index == 1 && !self.hiddenBulletin) {
            return PLVLCKeyboardMoreButtonTypeOpenBulletin;
        } else if (index == 2 && !self.hideLotteryWinRecord) {
            return PLVLCKeyboardMoreButtonTypeOpenLotteryWinRecord;
        }
    }
    
    return PLVLCKeyboardMoreButtonTypeUnknow;
}

@end
