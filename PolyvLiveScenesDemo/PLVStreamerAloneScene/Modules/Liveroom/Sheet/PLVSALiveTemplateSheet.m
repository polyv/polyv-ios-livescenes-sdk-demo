//
//  PLVSALiveTemplateSheet.m
//  PLVLiveScenesDemo
//
//  Created by Cursor on 2026/3/26.
//

#import "PLVSALiveTemplateSheet.h"
#import "PLVSAUtils.h"
#import "PLVMultiLanguageManager.h"
#import <PLVFoundationSDK/PLVFoundationSDK.h>

@interface PLVSALiveTemplateCell : UICollectionViewCell
@property (nonatomic, strong) UIImageView *coverImageView;
@property (nonatomic, strong) UILabel *titleLabel;
- (void)updateWithModel:(PLVMobileTemplateModel *)model;
@end

@implementation PLVSALiveTemplateCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.contentView.backgroundColor = [PLVColorUtil colorFromHexString:@"#1E1F26"];
        self.contentView.layer.cornerRadius = 10;
        self.contentView.layer.masksToBounds = YES;

        _coverImageView = [[UIImageView alloc] init];
        _coverImageView.contentMode = UIViewContentModeScaleAspectFill;
        _coverImageView.clipsToBounds = YES;
        _coverImageView.backgroundColor = [PLVColorUtil colorFromHexString:@"#2E3038"];
        [self.contentView addSubview:_coverImageView];

        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = [UIFont systemFontOfSize:13];
        _titleLabel.textColor = [UIColor whiteColor];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        [self.contentView addSubview:_titleLabel];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.coverImageView.frame = CGRectMake(0, 0, self.contentView.bounds.size.width, self.contentView.bounds.size.height - 30);
    self.titleLabel.frame = CGRectMake(8, CGRectGetMaxY(self.coverImageView.frame) + 4, self.contentView.bounds.size.width - 16, 20);
}

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    self.contentView.layer.borderWidth = selected ? 2.0 : 0.0;
    self.contentView.layer.borderColor = [PLVColorUtil colorFromHexString:@"#4D8DFF"].CGColor;
}

- (void)updateWithModel:(PLVMobileTemplateModel *)model {
    self.titleLabel.text = [PLVFdUtil checkStringUseable:model.name] ? model.name : @"-";
    UIImage *placeholder = [PLVSAUtils imageForLiveroomResource:@"plvsa_liveroom_btn_virtual_bg"];
    if ([PLVFdUtil checkStringUseable:model.coverUrl]) {
        [PLVSAUtils setImageView:self.coverImageView url:[NSURL URLWithString:model.coverUrl] placeholderImage:placeholder];
    } else {
        self.coverImageView.image = placeholder;
    }
}

@end

@interface PLVSALiveTemplateSheet()<UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *stateLabel;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) UIButton *cancelButton;
@property (nonatomic, strong) UIButton *applyButton;
@property (nonatomic, strong) UIButton *retryButton;
@property (nonatomic, strong) NSArray<PLVMobileTemplateModel *> *templateList;
@property (nonatomic, assign) NSInteger selectedIndex;
@end

@implementation PLVSALiveTemplateSheet

- (instancetype)init {
    CGFloat maxWH = MAX([UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width);
    self = [super initWithSheetHeight:maxWH * 0.43 sheetLandscapeWidth:maxWH * 0.45];
    if (self) {
        self.selectedIndex = NSNotFound;
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    [self.contentView addSubview:self.titleLabel];
    [self.contentView addSubview:self.stateLabel];
    [self.contentView addSubview:self.collectionView];
    [self.contentView addSubview:self.retryButton];
    [self.contentView addSubview:self.cancelButton];
    [self.contentView addSubview:self.applyButton];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat width = self.contentView.bounds.size.width;
    CGFloat height = self.contentView.bounds.size.height;
    self.titleLabel.frame = CGRectMake(20, 16, width - 40, 24);
    self.stateLabel.frame = CGRectMake(20, 52, width - 40, 20);
    self.collectionView.frame = CGRectMake(16, 80, width - 32, MAX(120, height - 148));
    self.retryButton.frame = CGRectMake((width - 100) / 2.0, CGRectGetMidY(self.collectionView.frame) - 18, 100, 36);
    self.cancelButton.frame = CGRectMake(20, height - 52, 88, 36);
    self.applyButton.frame = CGRectMake(width - 108, height - 52, 88, 36);
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.text = PLVLocalizedString(@"开播模板");
        _titleLabel.font = [UIFont boldSystemFontOfSize:16];
        _titleLabel.textColor = [UIColor whiteColor];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _titleLabel;
}

- (UILabel *)stateLabel {
    if (!_stateLabel) {
        _stateLabel = [[UILabel alloc] init];
        _stateLabel.font = [UIFont systemFontOfSize:13];
        _stateLabel.textColor = [PLVColorUtil colorFromHexString:@"#A5A8B3"];
        _stateLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _stateLabel;
}

- (UICollectionView *)collectionView {
    if (!_collectionView) {
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        layout.minimumLineSpacing = 12;
        layout.sectionInset = UIEdgeInsetsMake(0, 0, 0, 0);
        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
        _collectionView.backgroundColor = [UIColor clearColor];
        _collectionView.showsHorizontalScrollIndicator = NO;
        _collectionView.pagingEnabled = NO;
        _collectionView.dataSource = self;
        _collectionView.delegate = self;
        [_collectionView registerClass:[PLVSALiveTemplateCell class] forCellWithReuseIdentifier:@"PLVSALiveTemplateCell"];
    }
    return _collectionView;
}

- (UIButton *)cancelButton {
    if (!_cancelButton) {
        _cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _cancelButton.layer.cornerRadius = 18;
        _cancelButton.layer.borderWidth = 1;
        _cancelButton.layer.borderColor = [PLVColorUtil colorFromHexString:@"#4C5160"].CGColor;
        [_cancelButton setTitle:PLVLocalizedString(@"取消") forState:UIControlStateNormal];
        _cancelButton.titleLabel.font = [UIFont systemFontOfSize:14];
        [_cancelButton addTarget:self action:@selector(cancelButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _cancelButton;
}

- (UIButton *)applyButton {
    if (!_applyButton) {
        _applyButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _applyButton.layer.cornerRadius = 18;
        _applyButton.backgroundColor = [PLVColorUtil colorFromHexString:@"#4D8DFF"];
        [_applyButton setTitle:PLVLocalizedString(@"应用") forState:UIControlStateNormal];
        _applyButton.titleLabel.font = [UIFont systemFontOfSize:14];
        [_applyButton addTarget:self action:@selector(applyButtonAction) forControlEvents:UIControlEventTouchUpInside];
        _applyButton.enabled = NO;
        _applyButton.alpha = 0.5;
    }
    return _applyButton;
}

- (UIButton *)retryButton {
    if (!_retryButton) {
        _retryButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _retryButton.layer.cornerRadius = 18;
        _retryButton.layer.borderWidth = 1;
        _retryButton.layer.borderColor = [PLVColorUtil colorFromHexString:@"#4D8DFF"].CGColor;
        [_retryButton setTitle:PLVLocalizedString(@"重试") forState:UIControlStateNormal];
        [_retryButton addTarget:self action:@selector(retryButtonAction) forControlEvents:UIControlEventTouchUpInside];
        _retryButton.hidden = YES;
    }
    return _retryButton;
}

- (void)showLoading {
    self.retryButton.hidden = YES;
    self.collectionView.hidden = YES;
    self.stateLabel.hidden = NO;
    self.stateLabel.text = PLVLocalizedString(@"加载中...");
    self.applyButton.enabled = NO;
    self.applyButton.alpha = 0.5;
}

- (void)showError:(NSString *)errorMessage {
    self.collectionView.hidden = YES;
    self.stateLabel.hidden = NO;
    self.stateLabel.text = [PLVFdUtil checkStringUseable:errorMessage] ? errorMessage : PLVLocalizedString(@"加载失败");
    self.retryButton.hidden = NO;
    self.applyButton.enabled = NO;
    self.applyButton.alpha = 0.5;
}

- (void)updateTemplateList:(NSArray<PLVMobileTemplateModel *> *)templateList {
    self.templateList = templateList;
    self.retryButton.hidden = YES;
    if (![PLVFdUtil checkArrayUseable:templateList]) {
        self.collectionView.hidden = YES;
        self.stateLabel.hidden = NO;
        self.stateLabel.text = PLVLocalizedString(@"暂无已发布模板");
        self.applyButton.enabled = NO;
        self.applyButton.alpha = 0.5;
        self.selectedIndex = NSNotFound;
        return;
    }

    self.collectionView.hidden = NO;
    self.stateLabel.hidden = YES;
    self.selectedIndex = 0;
    [self.collectionView reloadData];
    if (self.templateList.count > 0) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:0];
        [self.collectionView selectItemAtIndexPath:indexPath animated:NO scrollPosition:UICollectionViewScrollPositionLeft];
    }
    self.applyButton.enabled = YES;
    self.applyButton.alpha = 1.0;
}

- (void)cancelButtonAction {
    [self dismiss];
}

- (void)applyButtonAction {
    if (self.selectedIndex >= 0 && self.selectedIndex < self.templateList.count && self.applyHandler) {
        self.applyHandler(self.templateList[self.selectedIndex]);
    }
}

- (void)retryButtonAction {
    if (self.retryHandler) {
        self.retryHandler();
    }
}

#pragma mark UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.templateList.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    PLVSALiveTemplateCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"PLVSALiveTemplateCell" forIndexPath:indexPath];
    [cell updateWithModel:self.templateList[indexPath.item]];
    return cell;
}

#pragma mark UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    self.selectedIndex = indexPath.item;
}

#pragma mark UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat width = MIN(180, collectionView.bounds.size.width * 0.48);
    return CGSizeMake(width, collectionView.bounds.size.height - 6);
}

@end
