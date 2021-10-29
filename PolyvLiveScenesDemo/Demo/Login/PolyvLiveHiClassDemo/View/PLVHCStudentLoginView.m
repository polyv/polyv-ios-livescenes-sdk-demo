//
//  PLVHCStudentLoginView.m
//  PLVLiveScenesDemo
//
//  Created by Sakya on 2021/8/9.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVHCStudentLoginView.h"

// 工具类
#import "PLVHCDemoUtils.h"

// 依赖库
#import <PLVFoundationSDK/PLVFoundationSDK.h>


@interface PLVHCStudentLoginView ()<UITextFieldDelegate>

//页面样式
@property (nonatomic, assign) PLVHCStudentLoginViewType viewType;
// 标题
@property (nonatomic, strong) UILabel *titleLabel;
// 讲师角色图片
@property (nonatomic, strong) UIImageView *titleImageView;
// 输入框下划线
@property (nonatomic, strong) CALayer *textFieldLine;
// PLVHCStudentLoginViewType_WhiteList 时密码输入框下划线
@property (nonatomic, strong) CALayer *passwordTextFieldLine;
// 使用协议文本
@property (nonatomic, strong) UILabel *agreementLabel;
// 跳转到使用协议页按钮
@property (nonatomic, strong) UIButton *readAgreementButton;

@end

@implementation PLVHCStudentLoginView

#pragma mark - [ Life cycle ]

- (instancetype)initWithType:(PLVHCStudentLoginViewType)type {
    self = [super init];
    if (self) {
        _viewType = type;
        [self setUpUI];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:self.bounds byRoundingCorners:UIRectCornerTopLeft cornerRadii:CGSizeMake(40,40)];
    CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
    maskLayer.frame = self.bounds;
    maskLayer.path = maskPath.CGPath;
    self.layer.mask = maskLayer;
    self.titleLabel.frame = CGRectMake(34, 33, 104, 37);
    self.titleImageView.center = CGPointMake(CGRectGetMaxX(self.titleLabel.frame) + 10 + CGRectGetWidth(self.titleImageView.bounds)/2, CGRectGetMidY(self.titleLabel.frame));
    self.textField.frame = CGRectMake(34, CGRectGetMaxY(self.titleLabel.frame) + 42, CGRectGetWidth(self.bounds) - 34 * 2, 40);
    self.textFieldLine.frame = CGRectMake(CGRectGetMinX(self.textField.frame), CGRectGetMaxY(self.textField.frame) + 5, CGRectGetWidth(self.textField.bounds), 1);
    
    if (_viewType == PLVHCStudentLoginViewType_CourseOrLesson) {
        CGFloat bottomPadding = 0;
        if (@available(iOS 11.0, *)) {
            if (self.superview) {
                bottomPadding = self.superview.safeAreaInsets.bottom;
            }
        }
        self.agreementButton.frame = CGRectMake(105, CGRectGetMaxY(self.bounds) - bottomPadding - 20 - 16, 16, 16);
        self.agreementLabel.frame = CGRectMake(CGRectGetMaxX(self.agreementButton.frame) + 4, CGRectGetMidY(self.agreementButton.frame) - 32 / 2, 75, 32);
        self.readAgreementButton.frame = CGRectMake(CGRectGetMaxX(self.agreementLabel.frame), CGRectGetMinY(self.agreementLabel.frame), 80, 32);        
    } else if (_viewType == PLVHCStudentLoginViewType_Code) {
        self.passwordTextField.frame = self.textField.frame;
        self.passwordTextFieldLine.frame = self.textFieldLine.frame;
        self.textField.frame = CGRectMake(CGRectGetMinX(self.passwordTextField.frame), CGRectGetMaxY(self.passwordTextFieldLine.frame) + 42, CGRectGetWidth(self.passwordTextField.bounds), CGRectGetHeight(self.passwordTextField.bounds));
        self.textFieldLine.frame = CGRectMake(CGRectGetMinX(self.textField.frame), CGRectGetMaxY(self.textField.frame) + 5, CGRectGetWidth(self.textField.bounds), 1);
    }
    self.loginButton.frame = CGRectMake(24, CGRectGetMaxY(self.textFieldLine.frame) + 48, CGRectGetWidth(self.bounds) - 24 * 2, 50);
    [self.loginButton setBackgroundImage:[self createImageWithColorSize:self.loginButton.bounds.size isGradient:YES] forState:UIControlStateNormal];
}

#pragma mark - [ Private Method ]

- (void)setUpUI {
    self.backgroundColor = [PLVColorUtil colorFromHexString:@"#171A38"];
    [self addSubview:self.titleLabel];
    [self addSubview:self.titleImageView];
    [self addSubview:self.textField];
    [self.layer addSublayer:self.textFieldLine];
    [self addSubview:self.loginButton];
    if (_viewType == PLVHCStudentLoginViewType_CourseOrLesson) {
        [self addSubview:self.agreementButton];
        [self addSubview:self.agreementLabel];
        [self addSubview:self.readAgreementButton];
        self.titleLabel.text = @"登录课程";
        _textField.attributedPlaceholder = [self placeholderAttributedStringWithString:@"请输入课程号 / 课节号"];
    } else if (_viewType == PLVHCStudentLoginViewType_Null) {
        self.titleLabel.text = @"设置名称";
        _textField.attributedPlaceholder = [self placeholderAttributedStringWithString:@"请设置你的名称"];
    } else if(_viewType == PLVHCStudentLoginViewType_WhiteList) {
        self.titleLabel.text = @"学生码";
        _textField.attributedPlaceholder = [self placeholderAttributedStringWithString:@"请输入学生码"];
    } else if(_viewType == PLVHCStudentLoginViewType_Code) {
        [self addSubview:self.passwordTextField];
        [self.layer addSublayer:self.passwordTextFieldLine];
        self.titleLabel.text = @"验证信息";
        _passwordTextField.attributedPlaceholder = [self placeholderAttributedStringWithString:@"请输入密码"];
        _textField.attributedPlaceholder = [self placeholderAttributedStringWithString:@"请设置你的名称"];
    }
}
    
//用渐变色或者纯色生成图片 当为渐变色时必须传size
- (UIImage *)createImageWithColorSize:(CGSize)size
                           isGradient:(BOOL)isGradient {
    if (isGradient) {
        CAGradientLayer *gradientLayer = [CAGradientLayer layer];
        gradientLayer.frame = CGRectMake(0, 0, size.width, size.height);
        gradientLayer.colors = @[(__bridge id)PLV_UIColorFromRGB(@"#00B16C").CGColor, (__bridge id)PLV_UIColorFromRGB(@"#00E78D").CGColor];
        gradientLayer.locations = @[@0.5, @1.0];
        gradientLayer.startPoint = CGPointMake(0, 0);
        gradientLayer.endPoint = CGPointMake(1.0, 0);
        UIGraphicsBeginImageContext(size);
        [gradientLayer renderInContext:UIGraphicsGetCurrentContext()];
    } else {
        if (CGSizeEqualToSize(size, CGSizeZero)) {
            size = CGSizeMake(1.0, 1.0);
        }
        UIGraphicsBeginImageContext(size);
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGContextSetFillColorWithColor(context, [PLV_UIColorFromRGB(@"#2D3452") CGColor]);
        CGRect rect = CGRectMake(0.0f, 0.0f, size.width, size.height);
        CGContextFillRect(context, rect);
    }
    UIImage *theImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return theImage;
}

- (NSMutableAttributedString *)placeholderAttributedStringWithString:(NSString *)string {
    if (!PLV_SafeStringForValue(string)) return nil;
    NSMutableAttributedString *placeholder = [[NSMutableAttributedString alloc] initWithString:string];
    [placeholder addAttribute:NSForegroundColorAttributeName
                value:PLV_UIColorFromRGBA(@"#EEEEEE",0.5)
                  range:NSMakeRange(0, string.length)];
    [placeholder addAttribute:NSFontAttributeName
                  value:[UIFont fontWithName:@"PingFangSC-Regular" size:16]
                  range:NSMakeRange(0, string.length)];
    return placeholder;
}

#pragma mark  Getter & Setter

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.text = @"登录课程";
        _titleLabel.font = [UIFont fontWithName:@"PingFangSC-Semibold" size:26];
        _titleLabel.textColor = [UIColor whiteColor];
    }
    return _titleLabel;
}

- (UIImageView *)titleImageView {
    if (!_titleImageView) {
        _titleImageView = [[UIImageView alloc] initWithImage:[PLVHCDemoUtils imageForHiClassResource:@"plvhc_title_student_image"]];
        _titleImageView.frame = CGRectMake(0, 0, 48, 24);
    }
    return _titleImageView;
}

- (UITextField *)textField {
    if (!_textField) {
        _textField = [[UITextField alloc] init];
        _textField.textColor = PLV_UIColorFromRGB(@"#FFFFFF");
        _textField.font = [UIFont fontWithName:@"PingFangSC-Regular" size:16];
        [_textField addTarget:self action:@selector(textFieldTextChange:) forControlEvents:UIControlEventEditingChanged];
        _textField.clearButtonMode = UITextFieldViewModeWhileEditing;
        [_textField setReturnKeyType:UIReturnKeyDone];
        _textField.delegate = self;
        UIButton *clearButton = [_textField valueForKey:@"_clearButton"];
        [clearButton setImage:[PLVHCDemoUtils imageForHiClassResource:@"plvhc_login_clear_btn"] forState:UIControlStateNormal];
    }
    return _textField;
}

- (UITextField *)passwordTextField {
    if (!_passwordTextField) {
        _passwordTextField = [[UITextField alloc] init];
        _passwordTextField.textColor = PLV_UIColorFromRGBA(@"#EEEEEE",0.5);
        _passwordTextField.font = [UIFont fontWithName:@"PingFangSC-Regular" size:16];
        [_passwordTextField addTarget:self action:@selector(textFieldTextChange:) forControlEvents:UIControlEventEditingChanged];
        _passwordTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
        [_passwordTextField setReturnKeyType:UIReturnKeyNext];
        _passwordTextField.delegate = self;
        UIButton *clearButton = [_passwordTextField valueForKey:@"_clearButton"];
        [clearButton setImage:[PLVHCDemoUtils imageForHiClassResource:@"plvhc_login_clear_btn"] forState:UIControlStateNormal];
    }
    return _passwordTextField;
}

- (CALayer *)textFieldLine {
    if (!_textFieldLine) {
        _textFieldLine = [[CALayer alloc] init];
        _textFieldLine.backgroundColor = PLV_UIColorFromRGBA(@"#FFFFFF",0.2).CGColor;
    }
    return _textFieldLine;
}

- (CALayer *)passwordTextFieldLine {
    if (!_passwordTextFieldLine) {
        _passwordTextFieldLine = [[CALayer alloc] init];
        _passwordTextFieldLine.backgroundColor = PLV_UIColorFromRGBA(@"#FFFFFF",0.2).CGColor;
    }
    return _passwordTextFieldLine;
}

- (UIButton *)loginButton {
    if (!_loginButton) {
        _loginButton = [[UIButton alloc] init];
        [_loginButton setTitle:@"登录" forState:UIControlStateNormal];
        _loginButton.titleLabel.font = [UIFont fontWithName:@"PingFangSC-Medium" size:16];
        [_loginButton setTitleColor:PLV_UIColorFromRGBA(@"#FFFFFF",0.5) forState:UIControlStateDisabled];
        [_loginButton setBackgroundImage:[self createImageWithColorSize:CGSizeZero isGradient:NO] forState:UIControlStateDisabled];
        [_loginButton setTitleColor:PLV_UIColorFromRGBA(@"#FFFFFF",1) forState:UIControlStateNormal];
        [_loginButton addTarget:self action:@selector(loginButtonAction) forControlEvents:UIControlEventTouchUpInside];
        _loginButton.layer.masksToBounds = YES;
        _loginButton.layer.cornerRadius = 25;
        _loginButton.enabled = NO;
    }
    return _loginButton;
}

- (PLVHCLoginCustomButton *)agreementButton {
    if (!_agreementButton) {
        _agreementButton = [[PLVHCLoginCustomButton alloc] init];
        [_agreementButton setImage:[PLVHCDemoUtils imageForHiClassResource:@"plvhc_btn_agreement_normal"] forState:UIControlStateNormal];
        [_agreementButton setImage:[PLVHCDemoUtils imageForHiClassResource:@"plvhc_btn_agreement_selected"] forState:UIControlStateSelected];
        [_agreementButton addTarget:self action:@selector(agreementButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _agreementButton;
}

- (UILabel *)agreementLabel {
    if (!_agreementLabel) {
        _agreementLabel = [[UILabel alloc] init];
        _agreementLabel.backgroundColor = [UIColor clearColor];
        _agreementLabel.text = @"已阅读并同意";
        _agreementLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:12];
        _agreementLabel.textColor = PLV_UIColorFromRGBA(@"#F0F1F5",0.6);
    }
    return _agreementLabel;
}

- (UIButton *)readAgreementButton {
    if (!_readAgreementButton) {
        _readAgreementButton = [[UIButton alloc] init];
        [_readAgreementButton setTitle:@"《使用协议》" forState:UIControlStateNormal];
        [_readAgreementButton setTitleColor:PLV_UIColorFromRGB(@"#F0F1F5") forState:UIControlStateNormal];
        _readAgreementButton.titleLabel.font = [UIFont systemFontOfSize:12.0];
        _readAgreementButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        [_readAgreementButton addTarget:self action:@selector(readAgreementButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _readAgreementButton;
}

#pragma mark - [ Event ]

#pragma mark Action

- (void)agreementButtonAction:(UIButton *)sender {
    sender.selected = !sender.selected;
    BOOL enable = self.textField.text.length && sender.selected;
    self.loginButton.enabled = enable;
}

- (void)loginButtonAction {
    if (self.delegate && [self.delegate respondsToSelector:@selector(studentLoginViewLoginSelected:)]) {
        [self.delegate studentLoginViewLoginSelected:self];
    }
}

- (void)readAgreementButtonAction {
    if (self.delegate && [self.delegate respondsToSelector:@selector(studentLoginViewAgreementSelected:)]) {
        [self.delegate studentLoginViewAgreementSelected:self];
    }
}

#pragma mark - [Delegate]

#pragma mark UITextFieldDelegate

- (void)textFieldTextChange:(UITextField *)textField {
    BOOL enabled = NO;
    if (_viewType == PLVHCStudentLoginViewType_CourseOrLesson) {
        enabled = self.textField.text.length && self.agreementButton.selected;
    } else if (_viewType == PLVHCStudentLoginViewType_Null ||
               _viewType == PLVHCStudentLoginViewType_WhiteList) {
        enabled = self.textField.text.length;
    } else if(_viewType == PLVHCStudentLoginViewType_Code) {
        enabled = self.textField.text.length && self.passwordTextField.text.length;
    }
    self.loginButton.enabled = enabled;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if ([textField isEqual:self.passwordTextField]) {
        [self.passwordTextField resignFirstResponder];
        [self.textField becomeFirstResponder];
    } else {
        [self.textField resignFirstResponder];
    }
 
    return YES;
}

@end
