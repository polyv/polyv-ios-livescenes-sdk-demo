//
//  PLVLCNewMessageView.m
//  PolyvLiveScenesDemo
//
//  Created by MissYasiky on 2020/11/6.
//  Copyright © 2020 polyv. All rights reserved.
//

#import "PLVLCNewMessageView.h"
#import <PolyvFoundationSDK/PLVColorUtil.h>

@interface PLVLCNewMessageView ()

@property (nonatomic, assign) NSUInteger messageCount;

@property (nonatomic, strong) UILabel *label;

@end

@implementation PLVLCNewMessageView

#pragma mark - Life Cycle

- (instancetype)init {
    self = [super init];
    if (self) {
        self.backgroundColor = [PLVColorUtil colorFromHexString:@"#427bbf"];
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
        _label.textColor = [UIColor whiteColor];
        _label.font = [UIFont systemFontOfSize:12];
        _label.textAlignment = NSTextAlignmentCenter;
        _label.text = [self labelText];
    }
    return _label;
}

#pragma mark - Public

- (void)updateMeesageCount:(NSUInteger)count {
    self.messageCount = count;
    self.label.text = [self labelText];
}

- (void)show {
    if (self.hidden == NO) {
        return;
    }
    self.hidden = NO;
    self.alpha = 0;
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:0.3 animations:^{
        weakSelf.alpha = 1;
    } completion:nil];
}

- (void)hidden {
    if (self.hidden) {
        return;
    }
    self.alpha = 1;
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:0.3 animations:^{
        weakSelf.alpha = 0;
    } completion:^(BOOL finished) {
        weakSelf.hidden = YES;
        [weakSelf updateMeesageCount:0];
    }];
}

#pragma mark - Private

- (NSString *)labelText {
    NSString *string = [NSString stringWithFormat:@"有%zd条新消息，点击查看", self.messageCount];
    return string;
}

@end
