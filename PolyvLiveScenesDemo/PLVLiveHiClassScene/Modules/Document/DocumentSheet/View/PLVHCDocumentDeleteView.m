//
//  PLVHCDocumentDeleteView.m
//  PLVLiveScenesDemo
//
//  Created by lijingtong on 2021/6/30.
//  Copyright © 2021 PLV. All rights reserved.
// 文档列表页  长按 cell 时出现的气泡+删除按钮自定义 UIView

#import "PLVHCDocumentDeleteView.h"

// 工具
#import "PLVHCUtils.h"

@interface PLVHCDocumentDeleteView ()

@property (nonatomic, strong) UIButton *deleteButton; // 删除按钮

@end

@implementation PLVHCDocumentDeleteView

#pragma mark - [ Life Cycle ]

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        UIImage *image = [PLVHCUtils imageForDocumentResource:@"plvhc_doc_pic_delete"];
        UIImageView *bgImageView = [[UIImageView alloc] initWithFrame:self.bounds];
        [bgImageView setImage:image];
        [self addSubview:bgImageView];
        
        _deleteButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [_deleteButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _deleteButton.titleLabel.font = [UIFont systemFontOfSize:14];
        [_deleteButton setTitleEdgeInsets:UIEdgeInsetsMake(-7.5, 0, 0, 0)];
        [_deleteButton addTarget:self action:@selector(deleteAction:) forControlEvents:UIControlEventTouchUpInside];
        
        _deleteButton.frame = frame;
        [self addSubview:_deleteButton];
    }
    return self;
}

#pragma mark - [ Public Method ]

- (void)showInView:(UIView *)view {
    [view addSubview:self];
}
 
- (void)dismiss {
    [self removeFromSuperview];
}

#pragma mark - [ Event ]
#pragma mark Action

- (void)deleteAction:(id)sender {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(documentDeleteView:didTapDeleteAtIndex:)]) {
        [self.delegate documentDeleteView:self didTapDeleteAtIndex:self.index];
    }
}
@end
