//
//  PLVECNewMessageView.m
//  PolyvLiveScenesDemo
//
//  Created by MissYasiky on 2020/11/6，update by Hank on 2020/11/12.
//  Copyright © 2020 polyv. All rights reserved.
//

#import "PLVECNewMessageView.h"
#import "PLVLCUtils.h"
#import <PolyvFoundationSDK/PLVColorUtil.h>

@interface PLVECNewMessageView ()

@property (nonatomic, strong) UILabel *label;

@end

@implementation PLVECNewMessageView

#pragma mark - Life Cycle

- (instancetype)init {
    self = [super init];
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
        self.layer.cornerRadius = 12.5;
        self.layer.masksToBounds = YES;
        
        [self addSubview:self.label];
    }
    return self;
}

- (void)layoutSubviews {
    self.label.frame = self.bounds;
}

#pragma mark - Getter & Setter

- (UILabel *)label {
    if (!_label) {
        _label = [[UILabel alloc] init];
        _label.textColor = [PLVColorUtil colorFromHexString:@"#FFA611"];
        _label.font = [UIFont systemFontOfSize:12];
        _label.textAlignment = NSTextAlignmentCenter;
        _label.text = @"查看新消息";
    }
    return _label;
}

#pragma mark - Public

- (void)show {
    if (self.hidden == NO) {
        return;
    }
    self.hidden = NO;
}

- (void)hidden {
    if (self.hidden) {
        return;
    }
    self.hidden = YES;
}

#pragma mark - Private


@end
