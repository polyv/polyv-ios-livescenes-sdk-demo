//
//  PLVLSDocumentDeleteView.m
//  PLVCloudClassStreamerModul
//
//  Created by MissYasiky on 2019/10/17.
//  Copyright © 2019 easefun. All rights reserved.
//

#import "PLVLSDocumentDeleteView.h"
#import "PLVLSUtils.h"

@interface PLVLSDocumentDeleteView ()

@property (nonatomic, strong) UIButton *deleteButton;

@end

@implementation PLVLSDocumentDeleteView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {

        UIImage *image = [PLVLSUtils imageForDocumentResource:@"plvls_doc_pic_delete"];
        UIImageView *bgImageView = [[UIImageView alloc] initWithFrame:self.bounds];
        [bgImageView setImage:image];
        [self addSubview:bgImageView];
        
        _deleteButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [_deleteButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _deleteButton.titleLabel.font = [UIFont systemFontOfSize:14];
        [_deleteButton setTitle:@"删除" forState:UIControlStateNormal];
        [_deleteButton setTitleEdgeInsets:UIEdgeInsetsMake(-7.5, 0, 0, 0)];
        [_deleteButton addTarget:self action:@selector(deleteAction:) forControlEvents:UIControlEventTouchUpInside];
        
        _deleteButton.frame = frame;
        [self addSubview:_deleteButton];
    }
    return self;
}

- (void)showInView:(UIView *)view {
    [view addSubview:self];
}
 
- (void)dismiss {
    [self removeFromSuperview];
}

- (void)deleteAction:(id)sender {
    if (self.delegate) {
        [self.delegate deleteAtIndex:self.index];
    }
}

@end
