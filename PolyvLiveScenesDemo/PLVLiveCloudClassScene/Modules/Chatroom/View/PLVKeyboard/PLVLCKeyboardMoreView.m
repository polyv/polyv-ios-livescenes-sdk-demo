//
//  PLVKeyboardMoreView.m
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2020/9/27.
//  Copyright © 2020 PLV. All rights reserved.
//

#import "PLVLCKeyboardMoreView.h"
#import "PLVLCUtils.h"
#import <SDWebImage/UIButton+WebCache.h>
#import <PLVFoundationSDK/PLVFoundationSDK.h>

static NSString *kMoreViewCellIdentifier = @"kMoreViewCellIdentifier";
static NSInteger kItemCountPerSection = 1;

static CGFloat kCellButtonWidth = 52.0;
static CGFloat kCellButtonHeight = 74.0;
static CGFloat kCellImageLabelMargin = 8.0;

typedef NS_ENUM(NSInteger, PLVLCKeyboardMoreButtonType) {
    PLVLCKeyboardMoreButtonTypeUnknow = -1,
    PLVLCKeyboardMoreButtonTypeOnlyTeacher = 0,
    PLVLCKeyboardMoreButtonTypeOpenAlbum,
    PLVLCKeyboardMoreButtonTypeOpenCamera,
    PLVLCKeyboardMoreButtonTypeOpenBulletin,
    PLVLCKeyboardMoreButtonTypeSwitchRewardDisplay,
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
        self.moreBtn.imageView.contentMode = UIViewContentModeScaleAspectFit;;
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
        case PLVLCKeyboardMoreButtonTypeSwitchRewardDisplay:
            [self.moreBtn setImage:[PLVLCUtils imageForChatroomResource:@"plvlc_keyboard_hide_reward_display"] forState:UIControlStateNormal];
            [self.moreBtn setImage:[PLVLCUtils imageForChatroomResource:@"plvlc_keyboard_show_reward_display"] forState:UIControlStateSelected];
            [self.moreBtn setTitle:@"屏蔽特效" forState:UIControlStateNormal];
            [self.moreBtn setTitle:@"展示特效" forState:UIControlStateSelected];
            break;
        default:
            break;
    }
    
    if (type == PLVLCKeyboardMoreButtonTypeUnknow) {
        CGFloat imageWidth = 48;
        [self.moreBtn setTitleEdgeInsets:UIEdgeInsetsMake(0, - imageWidth, - imageWidth- kCellImageLabelMargin / 2.0f, 0)];
        [self.moreBtn setImageEdgeInsets:UIEdgeInsetsMake(3.5, (kCellButtonWidth - imageWidth)/2, self.moreBtn.titleLabel.intrinsicContentSize.height + kCellImageLabelMargin, (kCellButtonWidth - imageWidth)/2)];
    } else {
        [self.moreBtn setTitleEdgeInsets:UIEdgeInsetsMake(0, - self.moreBtn.imageView.frame.size.width, - self.moreBtn.imageView.frame.size.height - kCellImageLabelMargin / 2.0f, 0)];
        [self.moreBtn setImageEdgeInsets:UIEdgeInsetsMake(- self.moreBtn.titleLabel.intrinsicContentSize.height - kCellImageLabelMargin / 2.0f, 0, 0, - self.moreBtn.titleLabel.intrinsicContentSize.width)];
    }
}

@end

@interface PLVLCKeyboardMoreView () <UICollectionViewDataSource>

@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) UICollectionViewFlowLayout *flowLayout;
@property (nonatomic, strong) NSArray *dynamicDataArray;

@end

@implementation PLVLCKeyboardMoreView

#pragma mark - Life Cycle

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _sendImageEnable = YES;
        _hideRewardDisplaySwitch = YES;
        
        self.backgroundColor = [UIColor colorWithRed:0x2b/255.0 green:0x2c/255.0 blue:0x35/255.0 alpha:1.0];
        
        self.flowLayout = [[UICollectionViewFlowLayout alloc] init];
        self.flowLayout.scrollDirection = UICollectionViewScrollDirectionVertical;
        self.flowLayout.itemSize = CGSizeMake(kCellButtonWidth, kCellButtonHeight);
        
        float distanceWidth = [UIScreen mainScreen].bounds.size.width - kCellButtonWidth * 4;
        float spacing = distanceWidth / 5;
        self.flowLayout.minimumInteritemSpacing = spacing;
        float padding = distanceWidth - spacing * 4;
        self.flowLayout.sectionInset = UIEdgeInsetsMake(15.9, padding, 15.9, padding);
        
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

#pragma mark - [ Public Method ]

- (void)updateChatButtonDataArray:(NSArray *)dataArray {
    NSMutableArray *showDataArray = [NSMutableArray array];
    for (NSInteger index = 0; index < dataArray.count; index++) {
        NSDictionary *dict = dataArray[index];
        if ([PLVFdUtil checkDictionaryUseable:dict]) {
            BOOL isShow = PLV_SafeBoolForDictKey(dict, @"isShow");
            if (isShow) {
                [showDataArray addObject:dict];
            }
        }
    }
    
    _dynamicDataArray = showDataArray;
    [self.collectionView reloadData];
}

#pragma mark - Getterr & Setter

- (void)setSendImageEnable:(BOOL)sendImageEnable {
    if (_sendImageEnable == sendImageEnable) {
        return;
    }
    _sendImageEnable = sendImageEnable;
    [self.collectionView reloadData];
}

- (void)setHiddenBulletin:(BOOL)hiddenBulletin {
    if (_hiddenBulletin == hiddenBulletin) {
        return;
    }
    _hiddenBulletin = hiddenBulletin;
    [self.collectionView reloadData];
}

- (NSInteger)getNativeAddButtonCount {
    NSInteger buttonCount = 0;
    buttonCount += (self.sendImageEnable ? 3 : 1);
    buttonCount += (!self.hiddenBulletin ? 1 : 0);
    buttonCount += (!self.hideRewardDisplaySwitch ? 1 : 0);
    
    return buttonCount;
}

- (void)setHideRewardDisplaySwitch:(BOOL)hideRewardDisplaySwitch {
    if (_hideRewardDisplaySwitch == hideRewardDisplaySwitch) {
        return;
    }
    // 暂时隐藏屏蔽特效按钮
    _hideRewardDisplaySwitch = YES;
//    _hideRewardDisplaySwitch = hideRewardDisplaySwitch;
}

#pragma mark - UICollectionView DataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView*)collectionView {
    return kItemCountPerSection;
}

- (NSInteger)collectionView:(UICollectionView*)collectionView numberOfItemsInSection:(NSInteger)section {
    NSUInteger count = [self getNativeAddButtonCount];
    count += self.dynamicDataArray.count;
    return count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView*)collectionView cellForItemAtIndexPath:(NSIndexPath*)indexPath {
    PLVLCMoreCollectionViewCell *cell = [self.collectionView dequeueReusableCellWithReuseIdentifier:kMoreViewCellIdentifier
                                                                                     forIndexPath:indexPath];

    PLVLCKeyboardMoreButtonType type = [self typeOfIndex:indexPath.item];
    cell.moreBtn.tag = indexPath.item;
    cell.type = type;
    if (type == PLVLCKeyboardMoreButtonTypeUnknow) {
        [self updateMoreButton:cell.moreBtn];
    }
    [cell.moreBtn addTarget:self action:@selector(moreBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    
    return cell;
}

#pragma mark - Action
- (void)moreBtnAction:(UIButton *)button {
    PLVLCKeyboardMoreButtonType type = [self typeOfIndex:button.tag];
    if (type == PLVLCKeyboardMoreButtonTypeOnlyTeacher) {
        button.selected = !button.selected;
        if (self.delegate && [self.delegate respondsToSelector:@selector(keyboardMoreView_onlyTeacher:on:)]) {
            [self.delegate keyboardMoreView_onlyTeacher:self on:button.selected];
        }
    } else if (type == PLVLCKeyboardMoreButtonTypeOpenCamera) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(keyboardMoreView_openCamera:)]) {
            [self.delegate keyboardMoreView_openCamera:self];
        }
    } else if (type == PLVLCKeyboardMoreButtonTypeOpenAlbum) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(keyboardMoreView_openAlbum:)]) {
            [self.delegate keyboardMoreView_openAlbum:self];
        }
    } else if (type == PLVLCKeyboardMoreButtonTypeOpenBulletin) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(keyboardMoreView_openBulletin:)]) {
            [self.delegate keyboardMoreView_openBulletin:self];
        }
    } else if (type == PLVLCKeyboardMoreButtonTypeSwitchRewardDisplay) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(keyboardMoreView_switchRewardDisplay:on:)]) {
            [self.delegate keyboardMoreView_switchRewardDisplay:self on:button.selected];
            button.selected = !button.selected;
        }
    } else if (type == PLVLCKeyboardMoreButtonTypeUnknow) {
        NSInteger defaultCount = [self getNativeAddButtonCount];
        if (button.tag < defaultCount + self.dynamicDataArray.count) {
            NSInteger index = button.tag - defaultCount;
            NSDictionary *dict = self.dynamicDataArray[index];
            NSString *eventName = PLV_SafeStringForDictKey(dict, @"event");
            if (self.delegate && [self.delegate respondsToSelector:@selector(keyboardMoreView_openInteractApp:eventName:)]) {
                [self.delegate keyboardMoreView_openInteractApp:self eventName:eventName];
            }
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
        } else if (index == 4 && !self.hideRewardDisplaySwitch) {
            return PLVLCKeyboardMoreButtonTypeSwitchRewardDisplay;
        }
    } else {
        if (index == 1 && !self.hiddenBulletin) {
            return PLVLCKeyboardMoreButtonTypeOpenBulletin;
        } else if (index == 2 && !self.hideRewardDisplaySwitch) {
            return PLVLCKeyboardMoreButtonTypeSwitchRewardDisplay;
        }
    }
    return PLVLCKeyboardMoreButtonTypeUnknow;
}

- (void)updateMoreButton:(UIButton *)button {
    NSInteger defaultCount = [self getNativeAddButtonCount];
    if (button.tag < defaultCount + self.dynamicDataArray.count) {
        NSInteger index = button.tag - defaultCount;
        NSDictionary *dict = self.dynamicDataArray[index];
        NSString *imageURLString = PLV_SafeStringForDictKey(dict, @"icon");
        NSString *buttonTitle = PLV_SafeStringForDictKey(dict, @"title");
        if ([PLVFdUtil checkStringUseable:imageURLString]) {
            NSURL *imageURL = [NSURL URLWithString:imageURLString];
            [button sd_setImageWithURL:imageURL forState:UIControlStateNormal];
            [button sd_setImageWithURL:imageURL forState:UIControlStateSelected];
        }
        [button setTitle:buttonTitle forState:UIControlStateNormal];
        [button setTitle:buttonTitle forState:UIControlStateSelected];
    }
}

@end
