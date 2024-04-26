//
//  PLVLivePictureInPicturePlaceholderView.m
//  PolyvLiveScenesDemo
//
//  Created by junotang on 2022/2/14.
//  Copyright © 2022 PLV. All rights reserved.
//

#import "PLVLivePictureInPicturePlaceholderView.h"
#import "PLVMultiLanguageManager.h"

// 依赖库
#import <PLVFoundationSDK/PLVFoundationSDK.h>

@interface PLVLivePictureInPicturePlaceholderView ()

@property (nonatomic, strong) UILabel *placeholderLabel;

@end

@implementation PLVLivePictureInPicturePlaceholderView

#pragma mark - Life Cycle
- (instancetype)init {
    self = [super init];
    if (self) {
        self.backgroundColor = [PLVColorUtil colorFromHexString:@"#2B3045"];
        [self addSubview:self.placeholderLabel];
    }
    return self;
}

- (void)layoutSubviews {
    self.placeholderLabel.frame = CGRectMake(0, (self.bounds.size.height - 16) * 0.5, self.bounds.size.width, 16);
}

#pragma mark - Getter
- (UILabel *)placeholderLabel {
    if (!_placeholderLabel) {
        _placeholderLabel = [[UILabel alloc]init];
        _placeholderLabel.text = PLVLocalizedString(@"小窗播放中...");
        _placeholderLabel.textColor = [PLVColorUtil colorFromHexString:@"#E4E4E4"];
        _placeholderLabel.textAlignment = NSTextAlignmentCenter;
        _placeholderLabel.font = [UIFont systemFontOfSize:14.0];
    }
    return _placeholderLabel;
}

@end
