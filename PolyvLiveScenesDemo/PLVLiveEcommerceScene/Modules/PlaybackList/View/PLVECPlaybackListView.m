//
//  PLVECPlaybackListView.m
//  PLVLiveScenesDemo
//
//  Created by Dhan on 2021/12/9.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVECPlaybackListView.h"
#import "PLVECUtils.h"
#import "PLVECPlaybackListCell.h"
#import <PLVFoundationSDK/PLVFoundationSDK.h>

@interface PLVECPlaybackListView ()

@property (nonatomic, strong) UILabel *titleLabel;

@end

@implementation PLVECPlaybackListView

#pragma mark - [ Life Period ]

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setupUI];
    }
    
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.titleLabel.frame = CGRectMake(16, 18, 100, 17);
    self.collectionView.frame = CGRectMake(16, 55, CGRectGetWidth(self.bounds)-32, CGRectGetHeight(self.bounds)-55);
}

#pragma mark - [ Public Methods ]

- (void)setDataSource:(id<UICollectionViewDataSource>)dataSource {
    self.collectionView.dataSource = dataSource;
}

- (void)setDelegate:(id<UICollectionViewDelegate>)delegate {
    self.collectionView.delegate = delegate;
}

#pragma mark - [ Private Methods ]

- (void)setupUI {
    [self addSubview:self.titleLabel];
    [self addSubview:self.collectionView];
}

#pragma mark Getter

- (UILabel *)titleLabel {
    if (! _titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.textAlignment = NSTextAlignmentLeft;
        _titleLabel.text = @"回放列表";
        _titleLabel.font = [UIFont fontWithName:@"PingFang SC" size:16];
        _titleLabel.textColor= PLV_UIColorFromRGB(@"#FFFFFF");
    }
    
    return _titleLabel;
}

- (UICollectionView *)collectionView {
    if (!_collectionView) {
        UICollectionViewFlowLayout * layout = [[UICollectionViewFlowLayout alloc] init];
        layout.scrollDirection = UICollectionViewScrollDirectionVertical;
        layout.minimumInteritemSpacing = 16;
        layout.minimumLineSpacing = 12;
        layout.headerReferenceSize = CGSizeZero;
        layout.footerReferenceSize = CGSizeZero;
        
        _collectionView = [[UICollectionView alloc] initWithFrame:self.bounds collectionViewLayout:layout];
        _collectionView.backgroundColor = self.backgroundColor;
        _collectionView.bounces = YES;
        _collectionView.showsVerticalScrollIndicator = NO;
        _collectionView.showsHorizontalScrollIndicator = NO;
        _collectionView.alwaysBounceHorizontal = NO;
        _collectionView.alwaysBounceVertical = YES;
        NSString * identifier = [NSString stringWithFormat:@"PLVECPlaybackListCellId"];
        [_collectionView registerClass:[PLVECPlaybackListCell class] forCellWithReuseIdentifier:identifier];

    }
    return _collectionView;

}

@end
