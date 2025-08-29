//
//  PLVStickerTextTemplateView.m
//  PolyvLiveScenesDemo
//
//  Created by polyv on 2023/9/15.
//  Copyright © 2023 PLV. All rights reserved.
//

#import "PLVStickerTextTemplateView.h"
#import <PLVFoundationSDK/PLVColorUtil.h>
#import "PLVSAUtils.h"
#import "PLVMultiLanguageManager.h"

@interface PLVStickerTextTemplateCell : UICollectionViewCell

@property (nonatomic, strong) UIImageView *imageView;

- (void)setupWithImage:(UIImage *)image;

@end

@implementation PLVStickerTextTemplateCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [PLVColorUtil colorFromHexString:@"#46474C"];
        self.layer.cornerRadius = 8;
        self.layer.borderWidth = 2;
        self.layer.borderColor = [UIColor clearColor].CGColor;
        
        _imageView = [[UIImageView alloc] initWithFrame:self.contentView.bounds];
        _imageView.contentMode = UIViewContentModeCenter;
        _imageView.clipsToBounds = YES;
        [self.contentView addSubview:_imageView];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.imageView.frame = self.contentView.bounds;
}

- (void)setupWithImage:(UIImage *)image {
    self.imageView.image = image;
}

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    if (selected) {
        self.layer.borderColor = [PLVColorUtil colorFromHexString:@"#4399FF"].CGColor;
    } else {
        self.layer.borderColor = [UIColor clearColor].CGColor;
    }
}

@end

@interface PLVStickerTextTemplateView () <UICollectionViewDelegate, UICollectionViewDataSource>

@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIButton *doneButton;
@property (nonatomic, strong) UIButton *cancelButton;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) NSArray<PLVStickerTextModel *> *templates;
@property (nonatomic, strong) NSIndexPath *selectedIndexPath;

// 新增属性
@property (nonatomic, assign) PLVStickerTemplateOperationType operationType;

@end

@implementation PLVStickerTextTemplateView

#pragma mark - Life Cycle

- (instancetype)init {
    if (self = [super init]) {
        [self setupTemplates];
        [self setupUI];
    }
    return self;
}

#pragma mark - Setup

- (void)setupTemplates {
    
    self.templates = [PLVStickerTextModel defaultTextModels];
}

- (void)setupUI {

    // 添加子视图
    [self addSubview:self.contentView];
    [self.contentView addSubview:self.titleLabel];
    [self.contentView addSubview:self.doneButton];
    [self.contentView addSubview:self.cancelButton];
    [self.contentView addSubview:self.collectionView];
}

#pragma mark - Lazy Loading

- (UIView *)contentView {
    if (!_contentView) {
        _contentView = [[UIView alloc] init];
        _contentView.backgroundColor = [PLVColorUtil colorFromHexString:@"#2B2C32"];
    }
    return _contentView;
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.text = PLVLocalizedString(@"选择文字模版");
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
        _titleLabel.textColor = [UIColor whiteColor];
    }
    return _titleLabel;
}

- (UIButton *)cancelButton {
    if (!_cancelButton) {
        _cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
        UIImage *cancelImage = [PLVSAUtils imageForLiveroomResource:@"plvsa_liveroom_stickertext_cancel"];
        [_cancelButton setImage:cancelImage forState:UIControlStateNormal];
        [_cancelButton addTarget:self action:@selector(cancelButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _cancelButton;
}

- (UIButton *)doneButton {
    if (!_doneButton) {
        _doneButton = [UIButton buttonWithType:UIButtonTypeCustom];
        UIImage *doneImage = [PLVSAUtils imageForLiveroomResource:@"plvsa_liveroom_stickertext_done"];
        [_doneButton setImage:doneImage forState:UIControlStateNormal];
        [_doneButton addTarget:self action:@selector(doneButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _doneButton;
}

- (UICollectionView *)collectionView {
    if (!_collectionView) {
        // 创建集合视图布局
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        layout.minimumLineSpacing = 12;
        layout.minimumInteritemSpacing = 15;
        
        // 创建集合视图
        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
        _collectionView.backgroundColor = [UIColor clearColor];
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
        [_collectionView registerClass:[PLVStickerTextTemplateCell class] forCellWithReuseIdentifier:@"PLVStickerTextTemplateCell"];
    }
    return _collectionView;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    BOOL isLandscape = [UIScreen mainScreen].bounds.size.width > [UIScreen mainScreen].bounds.size.height;
    self.contentView.frame = self.bounds;
    CGFloat contentWidth = self.contentView.bounds.size.width;
    
    // 标题和按钮布局
    self.titleLabel.frame = CGRectMake(0, 20, contentWidth, 30);
    self.doneButton.frame = CGRectMake(contentWidth - 16 - 28, 21, 28, 28);
    self.cancelButton.frame = CGRectMake(16 + [PLVSAUtils sharedUtils].areaInsets.left, 21, 28, 28);
    
    // 集合视图布局
    CGFloat collectionViewTop = CGRectGetMaxY(self.titleLabel.frame) + 20;
    CGFloat collectionViewHeight = self.contentView.bounds.size.height - collectionViewTop - 20;
    NSInteger startX = isLandscape ? [PLVSAUtils sharedUtils].areaInsets.left + 20: 20;
    self.collectionView.frame = CGRectMake(startX, collectionViewTop, contentWidth - (20+ startX), collectionViewHeight);
    
    // 更新集合视图布局
    UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout *)self.collectionView.collectionViewLayout;
    CGFloat totalSpacing = layout.minimumInteritemSpacing * 3;
    NSInteger countForRow = isLandscape ? 8: 4;
    CGFloat itemWidth = (self.collectionView.bounds.size.width - totalSpacing) / countForRow;
    CGFloat itemHeight = 56;
    layout.itemSize = CGSizeMake(itemWidth, itemHeight);
}

#pragma mark - Public Methods

- (void)showForAddInView:(UIView *)parentView {
    self.operationType = PLVStickerTemplateOperationTypeAdd;
    self.deleteState = NO;

    [self showInView:parentView];

    // 新增模式：默认选中第一个模版并立即添加贴纸
    self.selectedIndexPath = [NSIndexPath indexPathForItem:0 inSection:0];
    [self.collectionView selectItemAtIndexPath:self.selectedIndexPath animated:NO scrollPosition:UICollectionViewScrollPositionNone];

    // 立即添加一条贴纸数据
    PLVStickerTextModel *firstModel = self.templates[0];
    if (self.delegate && [self.delegate respondsToSelector:@selector(textTemplateView:addTextModel:)]) {
        PLVStickerTextModel *addTextModel = [PLVStickerTextModel defaultTextModelWithText:firstModel.text templateType:firstModel.templateType];
        [self.delegate textTemplateView:self addTextModel:addTextModel];
    }
}

- (void)showForEditInView:(UIView *)parentView textModel:(PLVStickerTextModel *)textModel {
    self.operationType = PLVStickerTemplateOperationTypeEdit;
    self.deleteState = NO;

    [self showInView:parentView];

    // 编辑模式：选中对应的模版类型
    for (NSInteger index = 0; index < self.templates.count; index++) {
        PLVStickerTextModel *model = self.templates[index];
        if (model.templateType == textModel.templateType) {
            self.selectedIndexPath = [NSIndexPath indexPathForItem:index inSection:0];
            [self.collectionView selectItemAtIndexPath:self.selectedIndexPath animated:NO scrollPosition:UICollectionViewScrollPositionNone];
            break;
        }
    }
}

- (void)showInView:(UIView *)parentView {
    if (!parentView) return;
    BOOL isLandscape = [UIScreen mainScreen].bounds.size.width > [UIScreen mainScreen].bounds.size.height;
    self.alpha = 0.0;
    [parentView addSubview:self];

    // 设置frame 高度268 从底部弹出
    NSInteger viewH = isLandscape ? 156: 268;
    self.frame = CGRectMake(0, parentView.bounds.size.height, parentView.bounds.size.width, viewH);

    // 动画显示
    [UIView animateWithDuration:0.3 animations:^{
        self.alpha = 1.0;
        self.frame = CGRectMake(0, parentView.bounds.size.height - viewH, parentView.bounds.size.width, viewH);
    }];
}

- (void)hideWithCompletion:(void(^)(void))completion {
    [UIView animateWithDuration:0.3 animations:^{
        self.alpha = 0.0;
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
        if (completion) {
            completion();
        }
    }];
}

#pragma mark - Actions

- (void)cancelButtonAction {
    // 根据操作类型处理取消逻辑
    if (self.delegate && [self.delegate respondsToSelector:@selector(textTemplateView:didCancelWithOperationType:)]) {
        [self.delegate textTemplateView:self didCancelWithOperationType:self.operationType];
    }

    [self hideWithCompletion:^{

    }];
}

- (void)doneButtonAction {
    if (!self.selectedIndexPath) {
        [self hideWithCompletion:^{
            
        }];
        return;
    }
    
    // 将编辑状态的值付费 正式值
    if (self.operationType == PLVStickerTemplateOperationTypeAdd) {
        // 新增模式：
    } else if (self.operationType == PLVStickerTemplateOperationTypeEdit) {
        // 编辑模式：
    }

    if (self.delegate && [self.delegate respondsToSelector:@selector(textTemplateView:didDoneWithOperationType:)]) {
        [self.delegate textTemplateView:self didDoneWithOperationType:self.operationType];
    }

    [self hideWithCompletion:^{

    }];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.templates.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    PLVStickerTextTemplateCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"PLVStickerTextTemplateCell" forIndexPath:indexPath];
    
    NSString *imageName = [NSString stringWithFormat:@"plvsa_livemroom_stickertext_template_%ld", (long)indexPath.item + 1];
    UIImage *image = [PLVSAUtils imageForLiveroomResource:imageName];
    [cell setupWithImage:image];
    
    return cell;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    // 如果处于删除状态，选择其他模版会恢复贴纸显示并退出删除状态
    if (self.deleteState) {
        // 恢复被隐藏的贴纸
        self.deleteState = NO;
    }
    
    self.selectedIndexPath = indexPath;

    // 实时预览选中的模版效果
    if (self.selectedIndexPath && self.delegate && [self.delegate respondsToSelector:@selector(textTemplateView:didSelectTextModel:)]) {
        PLVStickerTextModel *selectedTemplate = self.templates[self.selectedIndexPath.item];
        [self.delegate textTemplateView:self didSelectTextModel:selectedTemplate];
    }
}

#pragma mark - Execute Done Action
- (void)executeDoneAction {
    [self doneButtonAction];
}

@end
