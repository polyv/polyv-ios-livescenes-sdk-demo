//
//  PLVHCDocumentMinimumBar.m
//  PLVLiveScenesDemo
//
//  Created by lijingtong on 2021/7/9.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVHCDocumentMinimumBar.h"
// 工具
#import "PLVHCUtils.h"

// 依赖库
#import <PLVFoundationSDK/PLVFoundationSDK.h>


@interface PLVHCDocumentMinimumBar()

// UI
@property (nonatomic, strong) UIImageView *bgImageView;
@property (nonatomic, strong) UILabel *numLabel;

// 数据
@property (nonatomic, weak) UIView *weakSuperView; // 父视图，弱引用
@property (nonatomic, assign) NSInteger minimumNum; // 最小化数量

@end

@implementation PLVHCDocumentMinimumBar

#pragma mark - [ Life Cycle ]

- (instancetype)init {
    self = [super init];
    if (self) {
        [self addSubview:self.bgImageView];
        [self.bgImageView addSubview:self.numLabel];
    
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGesture)];
        [self addGestureRecognizer:tap];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.bgImageView.frame = self.bounds;
    self.numLabel.frame = CGRectMake(self.bgImageView.frame.size.width - 14 - 4, self.bgImageView.frame.size.height - 14 - 4, 14, 14);
}

#pragma mark - [ Public Method ]

- (void)refreshPptContainerTotal:(NSInteger)total {
    if (total < 0) {
        return;
    }
    
    if (total == 0) { // 隐藏视图
        if (self.superview) {
            [self removeFromSuperview];
        }
    } else { // 展示视图 并 刷新数量视图
        if (!self.superview) {
            [self.weakSuperView addSubview:self];
        }
        self.numLabel.text = [NSString stringWithFormat:@"%zd", total];
    }
    self.minimumNum = total;
}


#pragma mark - [ Private Method ]

#pragma mark Getter

- (UIImageView *)bgImageView {
    if (!_bgImageView) {
        _bgImageView = [[UIImageView alloc] init];
        _bgImageView.image = [PLVHCUtils imageForDocumentResource:@"plvhc_doc_btn_bar"];
    }
    return _bgImageView;
}

- (UILabel *)numLabel {
    if (!_numLabel) {
        _numLabel = [[UILabel alloc] init];
        _numLabel.text = @"";
        _numLabel.textColor = [PLVColorUtil colorFromHexString:@"#23273D"];
        _numLabel.textAlignment = NSTextAlignmentCenter;
        
        if (@available(iOS 8.2, *)) {
            _numLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightSemibold];
        } else {
            _numLabel.font = [UIFont systemFontOfSize:12];
        }
    }
    return _numLabel;
}

#pragma mark Setter

- (void)setDocumentNum:(NSInteger)documentNum {
    self.numLabel.text = [NSString stringWithFormat:@"%zd", documentNum];
}

#pragma mark - Event

#pragma mark Gesture

- (void)tapGesture {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(documentMinimumBarDidTap:)]) {
        [self.delegate documentMinimumBarDidTap:self];
    }
}

@end
