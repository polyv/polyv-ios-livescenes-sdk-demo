//
//  PLVHCEmojiCollectionViewCell.m
//  PLVLiveScenesDemo
//
//  Created by lijingtong on 2021/9/6.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVHCEmojiCollectionViewCell.h"

@implementation PLVHCEmojiCollectionViewCell

#pragma mark - [ Life Cycle ]

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self.contentView addSubview:self.imageView];
    }
    return self;
}

- (void)layoutSubviews{
    [super layoutSubviews];
    CGFloat imageViewWH = MIN(35, MIN(self.contentView.bounds.size.width, self.contentView.bounds.size.height)); // 小屏适配
    
    self.imageView.frame = CGRectMake(0, 0, imageViewWH, imageViewWH);
    self.imageView.center = self.contentView.center;
}

#pragma mark - [ Private Method ]
#pragma mark Getter

- (UIImageView *)imageView {
    if (!_imageView) {
        _imageView = [[UIImageView alloc] init];
        _imageView.contentMode = UIViewContentModeScaleAspectFit;
    }
    return _imageView;
}

@end
