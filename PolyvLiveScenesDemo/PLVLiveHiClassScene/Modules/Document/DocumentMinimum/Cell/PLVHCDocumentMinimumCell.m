//
//  PLVHCDocumentMinimumCell.m
//  PLVLiveScenesDemo
//
//  Created by lijingtong on 2021/7/12.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVHCDocumentMinimumCell.h"

// 工具
#import "PLVHCUtils.h"

// 模型
#import "PLVHCDocumentMinimumModel.h"

// 依赖库
#import <PLVFoundationSDK/PLVFoundationSDK.h>

@interface PLVHCDocumentMinimumCell()

#pragma mark UI

@property (nonatomic, strong) UIView *bubbleView; // 背景气泡
@property (nonatomic, strong) UILabel *titleLabel; // 文档标题
@property (nonatomic, strong) UIButton *removeButton; // 移除文档按钮

#pragma mark 数据

@property (nonatomic, strong) PLVHCDocumentMinimumModel *documentModel;
@property (nonatomic, assign) CGFloat cellWidth;

@end

@implementation PLVHCDocumentMinimumCell

#pragma mark - [ Life Cycle ]

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = [UIColor clearColor];
        [self.contentView addSubview:self.bubbleView];
        [self.bubbleView addSubview:self.titleLabel];
        [self.bubbleView addSubview:self.removeButton];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.bubbleView.frame = CGRectMake(0, 14, self.contentView.bounds.size.width, self.contentView.bounds.size.height - 14);
    self.titleLabel.frame = CGRectMake(8, 0, self.bubbleView.frame.size.width - 8 - 18 - 8 - 8, self.bubbleView.frame.size.height);
    self.removeButton.frame = CGRectMake(CGRectGetMaxX(self.titleLabel.frame), (self.bubbleView.frame.size.height - 18) / 2, 18, 18);
}

#pragma mark - [ Public Method ]

+ (CGFloat)cellHeight {
    return 14 + 32;
}

+ (NSString *)cellId {
    return NSStringFromClass([self class]);
}

- (void)updateWithModel:(PLVHCDocumentMinimumModel *)model cellWidth:(CGFloat)cellWidth {
    if (!model ||
        ![model isKindOfClass:[PLVHCDocumentMinimumModel class]] ||
        cellWidth == 0) {
        self.cellWidth = 0;
        return;
    }
    self.cellWidth = cellWidth;
    self.documentModel = model;
}

#pragma mark Setter
- (void)setDocumentModel:(PLVHCDocumentMinimumModel *)documentModel {
    _documentModel = documentModel;
    
    NSString *titleLabelString = [self getName:documentModel.fileName fileType:documentModel.fileExtension cutCount:0];
    self.titleLabel.text = titleLabelString;
}

#pragma mark - [ Private Method ]
#pragma mark Getter

- (UIView *)bubbleView {
    if (!_bubbleView) {
        _bubbleView = [[UIView alloc] init];
        _bubbleView.backgroundColor = [PLVColorUtil colorFromHexString:@"#2D3452"];
        _bubbleView.layer.cornerRadius = 8;
        _bubbleView.layer.masksToBounds = YES;
    }
    return _bubbleView;
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = [UIFont systemFontOfSize:14];
        _titleLabel.textColor = [UIColor whiteColor];
        _titleLabel.textAlignment = NSTextAlignmentLeft;
    }
    return _titleLabel;
}

- (UIButton *)removeButton {
    if (!_removeButton) {
        _removeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _removeButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
        [_removeButton setImage:[PLVHCUtils imageForDocumentResource:@"plvhc_doc_btn_close"] forState:UIControlStateNormal];
        [_removeButton addTarget:self action:@selector(removeButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _removeButton;
}

#pragma mark 文件名省略号处理

// 文件名省略号处理
- (NSString *)getName:(NSString *)fileName fileType:(NSString *)fileType cutCount:(NSInteger)cutCount {
    if (!fileName ||
        ![fileName isKindOfClass:[NSString class]]) {
        fileName = @"";
    }
    if (!fileType ||
        ![fileType isKindOfClass:[NSString class]]) {
        fileType = @"";
    }
    
    NSString *string = [NSString stringWithFormat:@"%@.%@", fileName, fileType];
    if (cutCount > 0) {
        string = [NSString stringWithFormat:@"%@...%@", fileName, fileType];
    }
    
    CGFloat width = [string boundingRectWithSize:CGSizeMake(MAXFLOAT, 20)
                                        options:NSStringDrawingUsesLineFragmentOrigin
                                     attributes:@{NSFontAttributeName:self.titleLabel.font}
                                        context:nil].size.width;
    
    if (width > self.cellWidth - 8 - 18 - 8 - 8 && fileName.length > 1) {
        fileName = [fileName substringToIndex:fileName.length - 1];
        return [self getName:fileName fileType:fileType cutCount:cutCount + 1];;
    }
    
    return string;
}


#pragma mark - [ Event ]
#pragma mark Action

- (void)removeButtonAction {
    if (self.removeHandler) {
        self.removeHandler(self.documentModel);
    }
}

@end
