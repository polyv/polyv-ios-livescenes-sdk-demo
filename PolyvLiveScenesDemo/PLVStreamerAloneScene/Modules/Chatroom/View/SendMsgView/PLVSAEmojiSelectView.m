//
//  PLVSAEmojiSelectView.m
//  PLVLiveScenesDemo
//
//  Created by lijingtong on 2021/5/26.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVSAEmojiSelectView.h"
#import "PLVSAEmojiPopupView.h"
// Utils
#import "PLVSAUtils.h"

// Manager
#import "PLVEmoticonManager.h"

// SDK
#import <PLVFoundationSDK/PLVFoundationSDK.h>
#import <SDWebImage/UIImageView+WebCache.h>

static CGFloat kDefaultEmojiMaxRow = 3.8;//默认表情
static NSInteger kDefaultEmojiMaxColumn = 6;
static NSInteger kCustomEmojiMaxRow = 2;
static NSInteger kCustomEmojiMaxColumn = 5;
static CGFloat kSAEmojiToolHeight = 40; //切换表情工具栏高度

@interface PLVSAEmojiSelectView ()<UIScrollViewDelegate>

@property (nonatomic, strong) UIButton *deleteButton;

@property (nonatomic, strong) UIButton *sendButton;

@property (nonatomic, assign) BOOL layoutEmoticonButton;

@property (nonatomic, strong) NSTimer *timer;
//表情面板的承载视图
@property (nonatomic, strong) UIScrollView *scrollView;

@property (nonatomic, strong) PLVSADefaultEmojiSelectView *defaultEmojiSelectView;

@property (nonatomic, strong) PLVSACustomEmojiSelectView *customEmojiSelectView;
//表情切换面板的承载视图
@property (nonatomic, strong) UIScrollView *emojiToolScrollView;

@property (nonatomic, strong) NSArray *faces;

//全屏机圆角为0 非全屏机圆角为4
@property (nonatomic, assign) CGFloat buttonCornerRadius;

@end

@implementation PLVSAEmojiSelectView

#pragma mark - [ Life Cycle ]

- (instancetype)init {
    self = [super init];
    if (self) {
        _buttonCornerRadius = P_SafeAreaBottomEdgeInsets() > 0 ? 4 : 0;
        [self setupUI];
        self.faces = [PLVEmoticonManager sharedManager].models;
        self.defaultEmojiSelectView.faces = self.faces;
    }
    return self;
}

#pragma mark - [ Override ]

- (void)layoutSubviews {
    [super layoutSubviews];
    
    UIEdgeInsets areaInsets = [PLVSAUtils sharedUtils].areaInsets;
    CGFloat buttonWidth = 48.0;
    CGFloat areaInsetsBottom = areaInsets.bottom;
    CGFloat areaInsetsLeft = areaInsets.left;
    CGFloat areaInsetsRight = areaInsets.right;
    
    self.scrollView.frame = CGRectMake(0, 0, CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds) - areaInsetsBottom - kSAEmojiToolHeight);
    CGSize contentViewSize = CGSizeMake(CGRectGetWidth(self.scrollView.bounds), CGRectGetHeight(self.scrollView.bounds));
    
    //图片表情需要更新的布局
    self.scrollView.contentSize = CGSizeMake(contentViewSize.width * 2, contentViewSize.height);
    
    //切换表情的ScrollView
    self.emojiToolScrollView.frame = CGRectMake(0, CGRectGetMaxY(self.scrollView.frame), CGRectGetWidth(self.bounds), kSAEmojiToolHeight);
    //自定义表情按钮
    UIButton *defaultEmojiButton = (UIButton *)[self.emojiToolScrollView viewWithTag:10000];
    UIButton *customEmojiButton = (UIButton *)[self.emojiToolScrollView viewWithTag:10001];
    if (defaultEmojiButton) {
        defaultEmojiButton.center = CGPointMake(areaInsetsLeft + 16 + CGRectGetWidth(defaultEmojiButton.bounds)/2, CGRectGetHeight(defaultEmojiButton.bounds)/2);
    }
    if (customEmojiButton) {
        customEmojiButton.center = CGPointMake(CGRectGetMaxX(defaultEmojiButton.frame) + CGRectGetWidth(customEmojiButton.bounds)/2, CGRectGetHeight(customEmojiButton.bounds)/2);
    }
    //自定义表情view
    self.customEmojiSelectView.frame = CGRectMake(CGRectGetWidth(self.scrollView.bounds) + areaInsetsLeft, 0, CGRectGetWidth(self.scrollView.bounds) - areaInsetsLeft - areaInsetsRight, CGRectGetHeight(self.scrollView.bounds));
    
    //大黄脸表情view
    self.deleteButton.frame = CGRectMake(CGRectGetWidth(self.scrollView.bounds) - buttonWidth - areaInsetsRight - 8, 15.0, buttonWidth, buttonWidth);
    self.sendButton.frame = CGRectMake(CGRectGetMinX(self.deleteButton.frame), CGRectGetMaxY(self.deleteButton.frame) + 8.0, buttonWidth, 112.0);
    self.defaultEmojiSelectView.frame = CGRectMake(areaInsetsLeft, 0, CGRectGetWidth(self.bounds) - CGRectGetWidth(self.deleteButton.bounds) - areaInsetsLeft - areaInsetsRight - 8, CGRectGetHeight(self.scrollView.bounds));
}

#pragma mark - Getter && Setter

- (PLVSADefaultEmojiSelectView *)defaultEmojiSelectView {
    if (!_defaultEmojiSelectView) {
        _defaultEmojiSelectView = [[PLVSADefaultEmojiSelectView alloc] init];
        __weak typeof(self) weakSelf = self;
        _defaultEmojiSelectView.selectItemBlock = ^(NSInteger index) {
            if ([weakSelf.delegate respondsToSelector:@selector(emojiSelectView_didSelectEmoticon:)]) {
                [weakSelf.delegate emojiSelectView_didSelectEmoticon:[weakSelf.faces objectAtIndex:index]];
            }
        };
    }
    return _defaultEmojiSelectView;
}
- (PLVSACustomEmojiSelectView *)customEmojiSelectView {
    if (!_customEmojiSelectView) {
        _customEmojiSelectView = [[PLVSACustomEmojiSelectView alloc] init];
        __weak typeof(self) weakSelf = self;
        _customEmojiSelectView.selectItemBlock = ^(NSInteger index) {
            if (weakSelf.delegate&& [weakSelf.delegate respondsToSelector:@selector(emojiSelectView_sendImageEmoticon:)]) {
                PLVImageEmotion *imageEmoticon = [PLVImageEmotion imageEmoticonWithDictionary:[weakSelf.imageEmotions objectAtIndex:index]];
                [weakSelf.delegate emojiSelectView_sendImageEmoticon:imageEmoticon];
            }
        };
    }
    return _customEmojiSelectView;
}
- (UIScrollView *)scrollView {
    if (!_scrollView) {
        _scrollView = [[UIScrollView alloc] init];
        _scrollView.showsHorizontalScrollIndicator = NO;
        _scrollView.pagingEnabled = YES;
        _scrollView.delegate = self;
    }
    return _scrollView;
}
- (UIScrollView *)emojiToolScrollView {
    if (!_emojiToolScrollView) {
        _emojiToolScrollView = [[UIScrollView alloc] init];
        _emojiToolScrollView.pagingEnabled = YES;
        _emojiToolScrollView.alwaysBounceHorizontal = YES;
        for (NSInteger index = 0; index < 2; index ++) {
            UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
            button.bounds = CGRectMake(0, 0, 60, kSAEmojiToolHeight);
            button.tag = 10000 + index;
            UIImage *normalImage = [self createImageWithColor:[PLVColorUtil colorFromHexString:@"#3E3E4E"] imageSize:button.bounds.size cornerRadius:_buttonCornerRadius];
            UIImage *selectedImage = [self createImageWithColor:[PLVColorUtil colorFromHexString:@"#2B2C35"] imageSize:button.bounds.size cornerRadius:_buttonCornerRadius];
            [button setBackgroundImage:normalImage forState:UIControlStateNormal];
            [button setBackgroundImage:selectedImage forState:UIControlStateSelected];
            [button addTarget:self action:@selector(emojiToolSelected:) forControlEvents:UIControlEventTouchUpInside];
            if (index == 0) {
                [button setImage:[PLVSAUtils imageForToolbarResource:@"plvsa_toolbar_emoji_default_icon"] forState:UIControlStateNormal];
                button.selected = YES;
            } else {
                [button setImage:[PLVSAUtils imageForToolbarResource:@"plvsa_toolbar_emoji_custom_icon"] forState:UIControlStateNormal];
            }
            [_emojiToolScrollView addSubview:button];
        }
    }
    return _emojiToolScrollView;
}
- (UIButton *)deleteButton {
    if (!_deleteButton) {
        _deleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _deleteButton.layer.cornerRadius = 4.0;
        _deleteButton.backgroundColor = PLV_UIColorFromRGB(@"#3E3E4E");;
        [_deleteButton setImage:[PLVSAUtils imageForToolbarResource:@"plvsa_toolbar_btn_emoji"] forState:UIControlStateNormal];
        [_deleteButton addTarget:self action:@selector(deleteButtonTouchBegin)forControlEvents:UIControlEventTouchDown];
        [_deleteButton addTarget:self action:@selector(deleteButtonTouchEnd)forControlEvents:UIControlEventTouchUpInside];
        [_deleteButton addTarget:self action:@selector(deleteButtonTouchEnd)forControlEvents:UIControlEventTouchUpOutside];
    }
    return _deleteButton;
}
- (UIButton *)sendButton {
    if (!_sendButton) {
        _sendButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _sendButton.layer.cornerRadius = 4.0;
        _sendButton.layer.masksToBounds = YES;
        _sendButton.enabled = NO;
        [_sendButton setTitle:@"发送" forState:UIControlStateNormal];
        [_sendButton addTarget:self action:@selector(sendButtonButtonAction) forControlEvents:UIControlEventTouchUpInside];
        _sendButton.titleLabel.font = [UIFont systemFontOfSize:14.0f];
        
        UIImage *bgImage = [self createImageWithColor:[PLVColorUtil colorFromHexString:@"#3E3E4E"] imageSize:CGSizeMake(1, 1) cornerRadius:0];
        [_sendButton setBackgroundImage:bgImage forState:UIControlStateNormal];
        [_sendButton setBackgroundImage:bgImage forState:UIControlStateDisabled];
        [_sendButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_sendButton setTitleColor:[UIColor whiteColor] forState:UIControlStateDisabled];
    }
    return _sendButton;
}

- (void)setImageEmotions:(NSArray *)imageEmotions {
    _imageEmotions = imageEmotions;
    self.customEmojiSelectView.imageEmotions = imageEmotions;
}

#pragma mark - [ Public Method ]

- (void)sendButtonEnable:(BOOL)enable {
    self.sendButton.enabled = enable;
}

#pragma mark - [ Private Method ]

#pragma mark Init

- (void)setupUI {
    
    self.backgroundColor = [PLVColorUtil colorFromHexString:@"#3E3E4E"];
    self.scrollView.backgroundColor = [PLVColorUtil colorFromHexString:@"#2B2C35"];
    
    [self addSubview:self.scrollView];
    //小黄脸表情面板
    [self.scrollView addSubview:self.defaultEmojiSelectView];
    [self.scrollView addSubview:self.deleteButton];
    [self.scrollView addSubview:self.sendButton];
    //图片表情需要添加视图
    [self.scrollView addSubview:self.customEmojiSelectView];
    //切换
    [self addSubview:self.emojiToolScrollView];
}

- (UIImage *)createImageWithColor:(UIColor *)color
                        imageSize:(CGSize)imageSize
                     cornerRadius:(CGFloat)cornerRadius {
    
    UIGraphicsBeginImageContext(imageSize);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [color CGColor]);
    
    CGRect rect = CGRectMake(0.0f, 0.0f, imageSize.width, imageSize.height);
    CGContextFillRect(context, rect);
    
    UIImage *theImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    if (cornerRadius == 0) return  theImage;
    
    UIGraphicsBeginImageContext(imageSize);
    
    UIRectCorner corner = UIRectCornerBottomLeft | UIRectCornerBottomRight;
    UIBezierPath * path = [UIBezierPath bezierPathWithRoundedRect:rect byRoundingCorners:corner cornerRadii:CGSizeMake(cornerRadius, cornerRadius)];
    
    CGContextRef cornerRadiusContext = UIGraphicsGetCurrentContext();
    CGContextAddPath(cornerRadiusContext, path.CGPath);
    CGContextClip(cornerRadiusContext);
    
    [theImage drawInRect:rect];
    
    UIImage *cornerRadiusImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return cornerRadiusImage;
}

#pragma mark Action

- (void)emojiToolSelected:(UIButton *)sender {
    NSInteger contentOffset = (sender.tag - 10000) * CGRectGetWidth(self.scrollView.bounds);
    [self.scrollView setContentOffset:CGPointMake(contentOffset, 0) animated:YES];
    for (UIButton *button in self.emojiToolScrollView.subviews) {
        if (button && [button isKindOfClass:[UIButton class]]) {
            button.selected = NO;
        }
    }
    sender.selected = YES;
}
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
    if ([self.delegate respondsToSelector:@selector(emojiSelectView_didReceiveEvent:)]) {
        [self.delegate emojiSelectView_didReceiveEvent:PLVSAEmojiSelectViewEventSend];
    }
}
- (void)emoticonButtonAction:(UIButton *)button {
    if ([self.delegate respondsToSelector:@selector(emojiSelectView_didSelectEmoticon:)]) {
        NSArray *models = [PLVEmoticonManager sharedManager].models;
        [self.delegate emojiSelectView_didSelectEmoticon:models[button.tag]];
    }
}
- (void)deleteAction {
    if ([self.delegate respondsToSelector:@selector(emojiSelectView_didReceiveEvent:)]) {
        [self.delegate emojiSelectView_didReceiveEvent:PLVSAEmojiSelectViewEventDelete];
    }
}

#pragma mark - Scrollview Delegate

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    NSInteger index = scrollView.contentOffset.x/self.scrollView.bounds.size.width;
    for (UIButton *button in self.emojiToolScrollView.subviews) {
        if (button && [button isKindOfClass:[UIButton class]]) {
            button.selected = NO;
        }
    }
    UIButton *selectButton = [self.emojiToolScrollView viewWithTag:index + 10000];
    selectButton.selected = YES;
}

@end


#pragma mark - PLVSADefaultEmojiSelectView
///默认选择表情大黄脸
@interface PLVSADefaultEmojiSelectView ()<UICollectionViewDelegate, UICollectionViewDataSource>

@property (nonatomic, strong) UICollectionView *collectionView;

@end

@implementation PLVSADefaultEmojiSelectView

#pragma mark - Life Cycle

- (instancetype)init {
    self = [super init];
    if (self) {
        [self addSubview:self.collectionView];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self.collectionView setFrame:self.bounds];
}

#pragma mark -- Getter
- (UICollectionView *)collectionView {
    if (!_collectionView) {
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        layout.scrollDirection = UICollectionViewScrollDirectionVertical;
        layout.minimumLineSpacing = 0;
        layout.minimumInteritemSpacing = 0;
        UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
        collectionView.showsVerticalScrollIndicator = NO;
        collectionView.delegate = self;
        collectionView.dataSource = self;
        collectionView.backgroundColor = [UIColor clearColor];
        //注册item类型 这里使用系统的类型
        [collectionView registerClass:[PLVSAEmojiCollectionViewCell class] forCellWithReuseIdentifier:@"DefaultEmojiCellId"];
        _collectionView = collectionView;
    }
    return _collectionView;
}

#pragma mark - CollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.faces.count;
}
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    PLVSAEmojiCollectionViewCell *cell  = [collectionView dequeueReusableCellWithReuseIdentifier:@"DefaultEmojiCellId" forIndexPath:indexPath];
    PLVEmoticon *emojiModel = [self.faces objectAtIndex:indexPath.row];
    //不用异步加载第一次进入界面滑动会卡顿
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        UIImage *emojiImage = [[PLVEmoticonManager sharedManager] imageForEmoticonName:emojiModel.imageName];
        dispatch_async(dispatch_get_main_queue(), ^{
            cell.imageView.image = emojiImage;
        });
    });
    return cell;
}

#pragma mark - CollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    _selectItemBlock ? _selectItemBlock(indexPath.row) : nil;
}
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(self.bounds.size.width/kDefaultEmojiMaxColumn, self.bounds.size.height/kDefaultEmojiMaxRow);
}

@end

#pragma mark - PLVSACustomEmojiSelectView

///个性化表情
@interface PLVSACustomEmojiSelectView ()<UICollectionViewDelegate, UICollectionViewDataSource>

@property (nonatomic, strong) UICollectionView *collectionView;

@end

@implementation PLVSACustomEmojiSelectView

#pragma mark - Life Cycle

- (instancetype)init {
    self = [super init];
    if (self) {
        [self addSubview:self.collectionView];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self.collectionView setFrame:self.bounds];
}

#pragma mark -- Getter && Setter

- (UICollectionView *)collectionView {
    if (!_collectionView) {
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        layout.scrollDirection = UICollectionViewScrollDirectionVertical;
        layout.minimumLineSpacing = 0;
        layout.minimumInteritemSpacing = 0;
        UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
        collectionView.showsVerticalScrollIndicator = NO;
        collectionView.delegate = self;
        collectionView.dataSource = self;
        collectionView.backgroundColor = [UIColor clearColor];
        //注册item类型 这里使用系统的类型
        [collectionView registerClass:[PLVSACustomEmojiCollectionViewCell class] forCellWithReuseIdentifier:@"CustomEmojiCellId"];
        _collectionView = collectionView;
    }
    return _collectionView;
}

- (void)setImageEmotions:(NSArray *)imageEmotions {
    _imageEmotions = imageEmotions;
    [self.collectionView reloadData];
}

#pragma mark - CollectionViewDataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.imageEmotions.count;
}
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    PLVSACustomEmojiCollectionViewCell *cell  = [collectionView dequeueReusableCellWithReuseIdentifier:@"CustomEmojiCellId" forIndexPath:indexPath];
    NSDictionary *emojiDict = [self.imageEmotions objectAtIndex:indexPath.row];
    PLVImageEmotion *imageEmoticon = [PLVImageEmotion imageEmoticonWithDictionary:emojiDict];
    cell.imageEmotion = imageEmoticon;
    return cell;
}

#pragma mark - CollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    _selectItemBlock ? _selectItemBlock(indexPath.row) : nil;
}
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(self.bounds.size.width/kCustomEmojiMaxColumn, self.bounds.size.height/kCustomEmojiMaxRow);
}

@end

#pragma mark - PLVSAEmojiCollectionViewCell

@implementation PLVSAEmojiCollectionViewCell

#pragma mark - Life Cycle

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self.contentView addSubview:self.imageView];
    }
    return self;
}
- (void)layoutSubviews{
    [super layoutSubviews];
    self.imageView.center = self.contentView.center;
}

#pragma mark - Getter & Setter

- (UIImageView *)imageView {
    if (!_imageView) {
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 35, 35)];
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        _imageView = imageView;
    }
    return _imageView;
}

@end

#pragma mark - PLVSACustomEmojiCollectionViewCell

@implementation PLVSACustomEmojiCollectionViewCell

#pragma mark - Life Cycle

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self.contentView addSubview:self.imageView];
        [self.contentView addSubview:self.titleLabel];
    }
    return self;
}
- (void)layoutSubviews{
    [super layoutSubviews];
    self.imageView.center = CGPointMake(self.contentView.bounds.size.width/2, self.imageView.bounds.size.height/2 + 10);
    self.titleLabel.frame = CGRectMake(0, self.imageView.frame.origin.y + self.imageView.bounds.size.height + 4, CGRectGetWidth(self.contentView.bounds), 20);
}

#pragma mark - Getter & Setter

- (UIImageView *)imageView {
    if (!_imageView) {
        UIImageView *imageView = [[UIImageView alloc] initWithFrame: CGRectMake(0, 0, 54, 54)];
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        imageView.userInteractionEnabled = YES;
        imageView.layer.cornerRadius = 4;
        //创建长按手势
        UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressGestureEvent:)];
        longPressGesture.minimumPressDuration = 0.2;
        //添加手势
        [imageView addGestureRecognizer:longPressGesture];
        _imageView = imageView;
    }
    return _imageView;
}
- (UILabel *)titleLabel {
    if (!_titleLabel) {
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        titleLabel.textColor = [UIColor colorWithRed:173/255.0 green:173/255.0 blue:192/255.0 alpha:1.0];
        titleLabel.font = [UIFont systemFontOfSize:13];
        titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel = titleLabel;
    }
    return _titleLabel;
}
- (void)setImageEmotion:(PLVImageEmotion *)imageEmotion {
    _imageEmotion = imageEmotion;
    [self.imageView sd_setImageWithURL:[NSURL URLWithString:imageEmotion.url]
                      placeholderImage:nil
                               options:SDWebImageRetryFailed];
    self.titleLabel.text = imageEmotion.title;
}

#pragma mark - Gesture

- (void)longPressGestureEvent:(UILongPressGestureRecognizer *)gesture {
    //背景颜色修改
    switch (gesture.state) {
        case UIGestureRecognizerStateBegan: {
            [UIView animateWithDuration:0.3 animations:^{
                self.imageView.backgroundColor = [PLVColorUtil colorFromHexString:@"#3E3E4E"];
            }];
            PLVSAEmojiPopupView *popupView = [[PLVSAEmojiPopupView alloc] init];
            popupView.relyView = self.imageView;
            popupView.imageEmotion = self.imageEmotion;
            [popupView showPopupView];
        }
            break;
        case UIGestureRecognizerStateEnded: {
            [UIView animateWithDuration:0.3 animations:^{
                self.imageView.backgroundColor = [UIColor clearColor];
            }];
        }
            break;
        default:
            break;
    }
}

@end
