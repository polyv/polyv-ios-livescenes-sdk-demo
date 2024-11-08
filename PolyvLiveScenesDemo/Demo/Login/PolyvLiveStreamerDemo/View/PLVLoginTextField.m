//
//  PLVLoginTextField.m
//  PLVLiveStreamerDemo
//
//  Created by jiaweihuang on 2021/6/15.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVLoginTextField.h"

@interface PLVLoginTextField ()

@property (nonatomic, strong) UIButton *togglePasswordButton;
@property (nonatomic, assign) BOOL showPasswordToggle;

@end

@implementation PLVLoginTextField

#pragma mark - [ Life Period ]

- (instancetype)initPasswordTextField {
    self = [super init];
    if (self) {
        self.showPasswordToggle = YES;
        self.secureTextEntry = YES;
        [self addSubview:self.togglePasswordButton];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    if (self.showPasswordToggle) {
        self.togglePasswordButton.frame = [self toggleButtonRectForBounds:self.bounds];
    }
}

#pragma mark - [ Override ]

- (CGRect)editingRectForBounds:(CGRect)bounds {
    return self.showPasswordToggle ? CGRectMake(12, 0, CGRectGetWidth(bounds) - 12 - 12 - 30, CGRectGetHeight(bounds)) : CGRectMake(12, 0, CGRectGetWidth(bounds) - 12 - 18, CGRectGetHeight(bounds));
}

- (CGRect)textRectForBounds:(CGRect)bounds {
    return self.showPasswordToggle ? CGRectMake(12, 0, CGRectGetWidth(bounds) - 12 - 12 - 30, CGRectGetHeight(bounds)) : CGRectMake(12, 0, CGRectGetWidth(bounds) - 12 - 18, CGRectGetHeight(bounds));
}

- (CGRect)clearButtonRectForBounds:(CGRect)bounds {
    return self.showPasswordToggle ? CGRectMake(CGRectGetWidth(bounds) - 12 - 18 - 30 - 12, (CGRectGetHeight(bounds) - 18) / 2, 18, 18) : CGRectMake(CGRectGetWidth(bounds) - 12 - 18, (CGRectGetHeight(bounds) - 18) / 2, 18, 18);
}

#pragma mark - [ Private Methods ]

- (UIButton *)togglePasswordButton {
    if (!_togglePasswordButton) {
        _togglePasswordButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_togglePasswordButton setImage:[[self class] imageWithImageName:@"plvls_password_hide"] forState:UIControlStateNormal];
        [_togglePasswordButton setImage:[[self class] imageWithImageName:@"plvls_password_show"] forState:UIControlStateSelected];
        [_togglePasswordButton addTarget:self action:@selector(togglePasswordVisibility:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _togglePasswordButton;
}

- (CGRect)toggleButtonRectForBounds:(CGRect)bounds {
    return CGRectMake(CGRectGetWidth(bounds) - 12 - 30, (CGRectGetHeight(bounds) - 30) / 2, 30, 30);
}

- (void)togglePasswordVisibility:(UIButton *)sender {
    sender.selected = !sender.selected;
    self.secureTextEntry = !sender.selected;
}

+ (UIImage *)imageWithImageName:(NSString *)imageName {
    NSString *bundleName = @"LiveStreamer";
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSString *bundlePath = [bundle pathForResource:bundleName ofType:@"bundle"];
    NSBundle *resourceBundle = [NSBundle bundleWithPath:bundlePath];
    UIImage *image = [UIImage imageNamed:imageName inBundle:resourceBundle compatibleWithTraitCollection:nil];
    return image;
}

@end
