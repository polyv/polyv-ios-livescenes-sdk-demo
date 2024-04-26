//
//  PLVLSSipIncomingTelegramMemberCell.m
//  PolyvLiveScenesDemo
//
//  Created by jiaweihuang on 2022/3/25.
//  Copyright © 2022 PLV. All rights reserved.
//

#import "PLVLSSipIncomingTelegramMemberCell.h"

@interface PLVLSSipIncomingTelegramMemberCell()

@end

@implementation PLVLSSipIncomingTelegramMemberCell

#pragma mark - [ Life Cycle ]

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self initUI];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
}

#pragma mark - [ Private Method ]

- (void)initUI {
}

#pragma mark Getter & Setter

@end
