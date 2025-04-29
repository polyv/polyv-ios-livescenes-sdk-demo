//
//  PLVVirtualBackgroudCell.m
//  PolyvLiveScenesDemo
//
//  Created by polyv on 2025/4/10.
//  Copyright © 2025 PLV. All rights reserved.
//

#import "PLVVirtualBackgroudCell.h"
#import "PLVVirtualBackgroundUtil.h"
#import <PLVFoundationSDK/PLVColorUtil.h>

@interface PLVVirtualBackgroudCell ()

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UILabel *titleLable;
@property (nonatomic, strong) UIButton *deleteButton;
@property (nonatomic, strong) UIView *selectedIndicatorView;
@property (nonatomic, assign, readwrite) PLVVirtualBackgroudCellType cellType;

@end

@implementation PLVVirtualBackgroudCell

#pragma mark - [ Life Cycle ]

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.layer.cornerRadius = 4.0;
        self.layer.masksToBounds = YES;
        
        [self.contentView addSubview:self.imageView];
        [self.contentView addSubview:self.titleLable];
        [self.contentView addSubview:self.deleteButton];
        
        [self setupUI];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    [self updateUILayout];
}

#pragma mark - [ Public Method ]

- (void)configCellWithModel:(PLVVirtualBackgroudModel *)model {
    self.cellType = model.type;
    
    if (model.image) {
        self.imageView.image = model.image;
    }
    
    self.titleLable.text = model.title;
    
    // 根据类型决定是否显示删除按钮
    if (model.type == PLVVirtualBackgroudCellCustomPicture) {
        self.deleteButton.hidden = NO;
    } else {
        self.deleteButton.hidden = YES;
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected];
    
    if (selected){
        self.imageView.layer.borderWidth = 2;
        self.imageView.layer.borderColor = [PLVColorUtil colorFromHexString:@"#0382FF"].CGColor;
    }
    else{
        self.imageView.layer.borderWidth = 0;
    }
}

#pragma mark - [ Private Method ]

- (void)setupUI {
    // 初始布局
    [self updateUILayout];
    
    // 初始化选中状态
    self.selectedIndicatorView.alpha = 0.0;
}

- (void)updateUILayout {
    // 获取当前宽高
    CGFloat width = CGRectGetWidth(self.bounds);
    NSInteger start_x = 0;
    NSInteger start_y = 10;
    
    // 标题高度
    CGFloat titleHeight = 18.0;
    
    // 设置图片视图布局
    self.imageView.frame = CGRectMake(start_x, start_y, 48, 48);
    
    // 设置标题标签布局
    self.titleLable.frame = CGRectMake(0, CGRectGetMaxY(self.imageView.frame), 48, titleHeight);
    
    // 设置删除按钮布局
    if (self.cellType == PLVVirtualBackgroudCellCustomPicture){
        CGFloat deleteButtonSize = 20.0;
        self.deleteButton.frame = CGRectMake(width - deleteButtonSize, 0, deleteButtonSize, deleteButtonSize);
    }
    else{
        self.deleteButton.hidden = YES;
    }
}

#pragma mark - [ Event ]

- (void)deleteButtonAction:(UIButton *)button {
    if (self.delegate && [self.delegate respondsToSelector:@selector(virtualBackgroudCellDidClickDeleteButton:)]) {
        [self.delegate virtualBackgroudCellDidClickDeleteButton:self];
    }
}

#pragma mark - [ Getter ]

- (UIImageView *)imageView {
    if (!_imageView) {
        _imageView = [[UIImageView alloc] init];
        _imageView.contentMode = UIViewContentModeScaleAspectFill;
        _imageView.clipsToBounds = YES;
        _imageView.backgroundColor = [UIColor clearColor];
        _imageView.layer.cornerRadius = 4;
    }
    return _imageView;
}

- (UILabel *)titleLable {
    if (!_titleLable) {
        _titleLable = [[UILabel alloc] init];
        _titleLable.textAlignment = NSTextAlignmentCenter;
        _titleLable.font = [UIFont systemFontOfSize:11.0];
        _titleLable.textColor = [UIColor whiteColor];
        _titleLable.backgroundColor = [UIColor clearColor];
        
    }
    return _titleLable;
}

- (UIButton *)deleteButton {
    if (!_deleteButton) {
        _deleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_deleteButton setImage:[PLVVirtualBackgroundUtil imageForResource:@"plv_virtualbg_btn_del"] forState:UIControlStateNormal];
        _deleteButton.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5];
        _deleteButton.layer.cornerRadius = 10.0;
        _deleteButton.layer.masksToBounds = YES;
        _deleteButton.hidden = YES;
        [_deleteButton addTarget:self action:@selector(deleteButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _deleteButton;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    
    self.imageView.image = nil;
    self.titleLable.text = nil;
    self.deleteButton.hidden = YES;
}

@end
