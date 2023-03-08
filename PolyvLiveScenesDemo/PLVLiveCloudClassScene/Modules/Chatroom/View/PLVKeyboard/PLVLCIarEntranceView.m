//
//  PLVLCIarEntranceView.m
//  PolyvLiveScenesDemo
//
//  Created by Dhan on 2023/2/21.
//  Copyright © 2023 PLV. All rights reserved.
//

#import "PLVLCIarEntranceView.h"
#import "PLVLCUtils.h"
#import <SDWebImage/UIButton+WebCache.h>
#import <PLVFoundationSDK/PLVFoundationSDK.h>

static NSString *kIarEntranceViewCellIdentifier = @"kIarEntranceViewCellIdentifier";
static NSInteger kItemCountPerSection = 1;
static CGFloat kCellButtonWidth = 68.0;
static CGFloat kCellButtonHeight = 28.0;
static CGFloat kCellLabelPadding = 4.0;

@interface PLVLCLCIarEntranceCollectionViewCell : UICollectionViewCell

@property (nonatomic, strong) UIButton *iarEntranceButton;

@end

@implementation PLVLCLCIarEntranceCollectionViewCell

#pragma mark - Life Cycle

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.iarEntranceButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.iarEntranceButton.frame = CGRectMake(0.0, 0.0, kCellButtonWidth, kCellButtonHeight);
        self.iarEntranceButton.titleLabel.font = [UIFont systemFontOfSize:12.0];
        [self.iarEntranceButton setBackgroundColor:PLV_UIColorFromRGBA(@"#000000", 0.16)];
        [self.iarEntranceButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        self.iarEntranceButton.imageView.contentMode = UIViewContentModeScaleAspectFit;;
        self.iarEntranceButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
        [self.iarEntranceButton setTitleEdgeInsets:UIEdgeInsetsMake(0, kCellLabelPadding, 0, 0)];
        [self.iarEntranceButton setImageEdgeInsets:UIEdgeInsetsMake(0, 0, 0, kCellLabelPadding)];
        self.iarEntranceButton.layer.masksToBounds = YES;
        self.iarEntranceButton.layer.cornerRadius = 12;
        
        [self.contentView addSubview:self.iarEntranceButton];
    }
    return self;
}

@end

@interface PLVLCIarEntranceView () <UICollectionViewDataSource>

@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) UICollectionViewFlowLayout *flowLayout;
@property (nonatomic, strong) NSArray *dynamicDataArray;

@end

@implementation PLVLCIarEntranceView

#pragma mark - Life Cycle

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        
        self.backgroundColor = [UIColor colorWithRed:0x1a/255.0 green:0x1b/255.0 blue:0x1f/255.0 alpha:1.0];
        self.flowLayout = [[UICollectionViewFlowLayout alloc] init];
        self.flowLayout.scrollDirection = UICollectionViewScrollDirectionVertical;
        self.flowLayout.itemSize = CGSizeMake(kCellButtonWidth, kCellButtonHeight);
        self.flowLayout.minimumInteritemSpacing = 8.0;
        self.flowLayout.sectionInset = UIEdgeInsetsMake(0, 16, 0, 0);
        
        CGRect rect = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, kCellButtonHeight);
        self.collectionView = [[UICollectionView alloc] initWithFrame:rect collectionViewLayout:self.flowLayout];
        self.collectionView.backgroundColor = [UIColor clearColor];
        [self.collectionView registerClass:[PLVLCLCIarEntranceCollectionViewCell class] forCellWithReuseIdentifier:kIarEntranceViewCellIdentifier];
        self.collectionView.dataSource = self;
        self.collectionView.showsHorizontalScrollIndicator = NO;
        self.collectionView.showsVerticalScrollIndicator = NO;
        [self addSubview:self.collectionView];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGRect rect = CGRectMake(0, 0, self.frame.size.width, kCellButtonHeight);
    self.collectionView.frame = rect;
}

#pragma mark - [ Public Method ]

- (void)updateIarEntranceButtonDataArray:(NSArray *)dataArray {
    NSMutableArray *showDataArray = [NSMutableArray array];
    for (NSInteger index = 0; index < dataArray.count; index++) {
        NSDictionary *dict = dataArray[index];
        if ([PLVFdUtil checkDictionaryUseable:dict]) {
            BOOL isShow = PLV_SafeBoolForDictKey(dict, @"isShow");
            NSString *title = PLV_SafeStringForDictKey(dict, @"title");
            if (isShow && [PLVFdUtil checkStringUseable:title] && [title isEqualToString:@"问卷"]) {
                [showDataArray addObject:dict];
            }
        }
    }
    _dynamicDataArray = showDataArray;
    self.hidden = !showDataArray.count;
    [self.collectionView reloadData];
}

#pragma mark - UICollectionView DataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView*)collectionView {
    return kItemCountPerSection;
}

- (NSInteger)collectionView:(UICollectionView*)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.dynamicDataArray.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView*)collectionView cellForItemAtIndexPath:(NSIndexPath*)indexPath {
    PLVLCLCIarEntranceCollectionViewCell *cell = [self.collectionView dequeueReusableCellWithReuseIdentifier:kIarEntranceViewCellIdentifier forIndexPath:indexPath];
    cell.iarEntranceButton.tag = indexPath.item;
    [self updateIarEntranceButton:cell.iarEntranceButton];
    [cell.iarEntranceButton addTarget:self action:@selector(iarEntranceButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    
    return cell;
}

#pragma mark - Action

- (void)iarEntranceButtonAction:(UIButton *)button {
    NSInteger index = button.tag;
    NSDictionary *dict = self.dynamicDataArray[index];
    NSString *eventName = PLV_SafeStringForDictKey(dict, @"event");
    if (self.delegate && [self.delegate respondsToSelector:@selector(iarEntranceView_openInteractApp:eventName:)]) {
        [self.delegate iarEntranceView_openInteractApp:self eventName:eventName];
    }
}

#pragma mark - Private Method

- (void)updateIarEntranceButton:(UIButton *)button {
    NSInteger index = button.tag;
    NSDictionary *dict = self.dynamicDataArray[index];
    NSString *buttonTitle = PLV_SafeStringForDictKey(dict, @"title");
    [button setTitle:buttonTitle forState:UIControlStateNormal];
    [button setTitle:buttonTitle forState:UIControlStateSelected];
    if (![PLVFdUtil checkStringUseable:buttonTitle]) {
        return;
    } else if ([buttonTitle isEqualToString:@"问卷"]) {
        [button setImage:[PLVLCUtils imageForChatroomResource:@"plvlc_iarentrance_questionnaire"] forState:UIControlStateNormal];
        [button setImage:[PLVLCUtils imageForChatroomResource:@"plvlc_iarentrance_questionnaire"] forState:UIControlStateNormal];
    }
}

@end
