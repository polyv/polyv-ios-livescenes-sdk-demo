//
//  PLVHCAreaCodeChooseTableViewCell.m
//  PolyvLiveScenesDemo
//
//  Created by lijingtong on 2021/9/15.
//  Copyright © 2021 polyv. All rights reserved.
//

#import "PLVHCAreaCodeChooseTableViewCell.h"

// 依赖库
#import <PLVFoundationSDK/PLVFoundationSDK.h>

@interface PLVHCAreaCodeChooseTableViewCell()

@end

@implementation PLVHCAreaCodeChooseTableViewCell

#pragma mark - [ Life Cycle ]

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.contentView.backgroundColor = [UIColor whiteColor];
        
        [self.contentView addSubview:self.areaLabel];
        [self.contentView addSubview:self.codeLable];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat selfWidth = self.contentView.bounds.size.width;
    CGFloat selfHeight = self.contentView.bounds.size.height;
    
    CGFloat areaWidth = [self.areaLabel sizeThatFits:CGSizeMake(selfWidth, selfHeight)].width;
    CGFloat codeWidth = [self.codeLable sizeThatFits:CGSizeMake(selfWidth, selfHeight)].width;
    if (areaWidth + codeWidth > self.contentView.bounds.size.width) {
        codeWidth = selfWidth - areaWidth;
    }
    
    self.areaLabel.frame = CGRectMake(20, 0, areaWidth, selfHeight);
    self.codeLable.frame = CGRectMake(selfWidth - codeWidth - 40, 0, codeWidth, selfHeight);
}

#pragma mark - [ Private Method ]
#pragma mark Getter

- (UILabel *)areaLabel {
    if (!_areaLabel) {
        _areaLabel = [[UILabel alloc] init];
        _areaLabel.font = [UIFont systemFontOfSize:16];
        _areaLabel.textColor = [PLVColorUtil colorFromHexString:@"#333333"];
        _areaLabel.textAlignment = NSTextAlignmentLeft;
    }
    return _areaLabel;
}

- (UILabel *)codeLable {
    if (!_codeLable) {
        _codeLable = [[UILabel alloc] init];
        _codeLable.font = [UIFont systemFontOfSize:16];
        _codeLable.textColor = [PLVColorUtil colorFromHexString:@"#999999"];
        _codeLable.textAlignment = NSTextAlignmentRight;
    }
    return _codeLable;
}

@end
