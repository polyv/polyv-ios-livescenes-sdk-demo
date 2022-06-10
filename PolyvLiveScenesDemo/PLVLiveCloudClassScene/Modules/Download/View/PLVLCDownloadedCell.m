//
//  PLVLCDownloadedCell.m
//  PolyvLiveScenesDemo
//
//  Created by junotang on 2022/5/26.
//  Copyright © 2022 PLV. All rights reserved.
//

#import "PLVLCDownloadedCell.h"
#import <PLVFoundationSDK/PLVFoundationSDK.h>
#import "PLVLCUtils.h"

@interface PLVLCDownloadedCell ()

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *sizeLabel;
@property (nonatomic, strong) UIButton *deleteButton;
@property (nonatomic, strong) UIView *separatorView;

@end

@implementation PLVLCDownloadedCell

#pragma mark - [ Life Cycle ]

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        [self.contentView addSubview:self.titleLabel];
        [self.contentView addSubview:self.sizeLabel];
        [self.contentView addSubview:self.deleteButton];
        [self.contentView addSubview:self.separatorView];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    [self resetUI];
}

#pragma mark - [ Public Method ]
- (void)configModel:(PLVDownloadPlaybackTaskInfo *)model {
    self.titleLabel.text = model.title;
    self.sizeLabel.text = model.totalBytesExpectedToWriteString;
    
    [self resetUI];
}

+ (CGFloat)cellHeightWithModel:(NSString *)model cellWidth:(CGFloat)cellWidth {
    
    CGFloat titLabelHeight = [model boundingRectWithSize:CGSizeMake(cellWidth - 80, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:16]} context:nil].size.height;
    
    return titLabelHeight + 60;
}

#pragma mark - [Private Method]

- (void)resetUI {
    CGFloat padding = 16;
    CGFloat cellWidth = CGRectGetWidth(self.frame);
    CGFloat titLabelHeight = [self.titleLabel.text boundingRectWithSize:CGSizeMake(cellWidth - 80, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:16]} context:nil].size.height;
    CGFloat cellHeight = titLabelHeight + 60;
    
    self.titleLabel.frame = CGRectMake(padding, 23 , cellWidth - 80, titLabelHeight);
    self.sizeLabel.frame = CGRectMake(padding, CGRectGetMaxY(self.titleLabel.frame) + 4, cellWidth - 80, 20);
    self.deleteButton.frame = CGRectMake(cellWidth - padding - 32, (cellHeight - 32) * 0.5, 32, 32);
    self.separatorView.frame = CGRectMake(0, cellHeight - 1, cellWidth, 1);
}

#pragma mark - [ Action ]

- (void)clickDeleteAction {
    if (self.clickDeleteButtonBlock) {
        self.clickDeleteButtonBlock();
    }
}

#pragma mark - [ Loadlazy ]
- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc]init];
        _titleLabel.textColor = [UIColor whiteColor];
        _titleLabel.font = [UIFont systemFontOfSize:16];
        _titleLabel.numberOfLines = 0;
    }
    return _titleLabel;
}

- (UILabel *)sizeLabel {
    if (!_sizeLabel) {
        _sizeLabel = [[UILabel alloc]init];
        _sizeLabel.textColor = [PLVColorUtil colorFromHexString:@"#ADADC0"];
        _sizeLabel.font = [UIFont systemFontOfSize:12];
    }
    return _sizeLabel;
}

- (UIButton *)deleteButton {
    if (!_deleteButton) {
        _deleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _deleteButton.backgroundColor = [PLVColorUtil colorFromHexString:@"#D8D8D8" alpha:0.1];
        [_deleteButton setImage:[PLVLCUtils imageForMediaResource:@"plvlc_media_delete_btn"] forState:0];
        _deleteButton.layer.cornerRadius = 16;
        _deleteButton.layer.masksToBounds = YES;
        [_deleteButton addTarget:self action:@selector(clickDeleteAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _deleteButton;
}

- (UIView *)separatorView {
    if (!_separatorView) {
        _separatorView = [[UIView alloc]init];
        _separatorView.backgroundColor = [UIColor blackColor];
    }
    return _separatorView;
}

@end
