//
//  PLVLSDocumentNumView.m
//  PLVLiveStreamerDemo
//
//  Created by MissYasiky on 2021/3/24.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVLSDocumentNumView.h"

// 依赖库
#import <PLVFoundationSDK/PLVFoundationSDK.h>

@interface PLVLSDocumentNumView ()

@property (nonatomic, strong) UIView *bgView;
@property (nonatomic, strong) UILabel *numLabel;

@end

@implementation PLVLSDocumentNumView

- (instancetype)init {
    self = [super init];
    if (self) {
        self.hidden = YES;
        [self addSubview:self.bgView];
        [self.bgView addSubview:self.numLabel];
    }
    return self;
}

- (UIView *)bgView {
    if (!_bgView) {
        _bgView = [[UIView alloc] init];
        _bgView.backgroundColor = [UIColor colorWithRed:0x1b/255.0 green:0x20/255.0 blue:0x2d/255.0 alpha:0.2];
        _bgView.layer.cornerRadius = 12.0f;
        _bgView.layer.masksToBounds = YES;
    }
    return _bgView;
}

- (UILabel *)numLabel {
    if (!_numLabel) {
        _numLabel = [[UILabel alloc] init];
        _numLabel.textColor = [UIColor whiteColor];
        _numLabel.font = [UIFont systemFontOfSize:12];
        _numLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _numLabel;
}

- (void)setCurrentPage:(NSUInteger)pageId totalPage:(NSUInteger)totalPage {
    if (totalPage <= 1) {
        self.hidden = YES;
        return;
    }
    
    self.hidden = self.guestFinishClass;
    NSUInteger pageNum = pageId;
    if (pageId > totalPage) {
        pageNum = totalPage;
    } else if (pageId <= 0) {
        pageNum = 1;
    }
    NSString *number = [NSString stringWithFormat:@"%ld/%ld", pageNum, totalPage];
    plv_dispatch_main_async_safe(^{
        self.numLabel.text = number;
        CGSize size = [number boundingRectWithSize:CGSizeMake(self.bounds.size.width - 20, 24) options:0 attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:12]} context:nil].size;
        
        CGRect rect = self.bounds;
        self.bgView.frame = CGRectMake(rect.size.width - (size.width + 20), 0, size.width + 20, rect.size.height);
        self.numLabel.frame = self.bgView.bounds;
    })
    
}

- (void)setGuestFinishClass:(BOOL)guestFinishClass {
    _guestFinishClass = guestFinishClass;
    self.hidden = guestFinishClass;
}

@end
