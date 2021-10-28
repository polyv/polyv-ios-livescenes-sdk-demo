//
//  PLVHCMemberSheetHeaderView.m
//  PolyvLiveScenesDemo
//
//  Created by MissYasiky on 2021/7/29.
//  Copyright © 2021 polyv. All rights reserved.
//

#import "PLVHCMemberSheetHeaderView.h"
#import "PLVHCUtils.h"
#import <PLVFoundationSDK/PLVFoundationSDK.h>

@interface PLVHCMemberSheetHeaderView ()

#pragma mark UI
/// 第一行控件
@property (nonatomic, strong) UILabel *titleLabel; // 弹层标题文本
@property (nonatomic, strong) UIView *titleLine; // 标题文本底部分割线
@property (nonatomic, strong) UIView *buttonLine; // 【全体禁麦】按钮与【全体下台】按钮中间的分割线

/// 第二行控件
@property (nonatomic, strong) UIView *leftView; // 左侧视图：包含【在线/踢出学生】、切换按钮、【举手】
@property (nonatomic, strong) UIView *rightView; // 右侧视图：包含剩余的UILabel
@property (nonatomic, strong) NSArray <UILabel *> *labelArray; // 右侧视图上的UILabel控件数组
@property (nonatomic, strong) UILabel *tableTitleLabel; // 【在线/踢出学生】
@property (nonatomic, strong) UILabel *handUpLabel; // 【举手】

#pragma mark 数据
@property (nonatomic, strong) NSArray *labelTextArray; // 第二行文本内容数组

@end

@implementation PLVHCMemberSheetHeaderView

#pragma mark - [ Life Cycle ]

- (instancetype)init {
    self = [super init];
    if (self) {
        self.backgroundColor = [PLVColorUtil colorFromHexString:@"#2D3452"];
        self.labelTextArray = @[@"上下台", @"画笔", @"麦克风", @"摄像头", @"奖励", @"禁言", @"移出"];
        
        // 第一行控件
        [self addSubview:self.titleLabel];
        [self addSubview:self.titleLine];
        [self addSubview:self.closeMicButton];
        [self addSubview:self.buttonLine];
        [self addSubview:self.leaveLinkMicButton];
        
        // 第二行控件
        [self addSubview:self.leftView];
        [self.leftView addSubview:self.tableTitleLabel];
        [self.leftView addSubview:self.changeListButton];
        [self.leftView addSubview:self.handUpLabel];
        
        [self addSubview:self.rightView];
        NSMutableArray *muArray = [[NSMutableArray alloc] initWithCapacity:[self.labelTextArray count]];
        for (NSString *text in self.labelTextArray) {
            UILabel *label = [self generateWhiteLabelWithText:text];
            [muArray addObject:label];
            [self.rightView addSubview:label];
        }
        self.labelArray = [muArray copy];
    }
    return self;
}

- (void)layoutSubviews {
    // 第一行控件
    self.titleLabel.frame = CGRectMake(24, 7, 54, 17);
    self.titleLine.frame = CGRectMake(16, 31.5, self.bounds.size.width - 16 - 23, 1);
    self.buttonLine.frame = CGRectMake(self.bounds.size.width - 84, 10, 1, 12);
    self.closeMicButton.frame = CGRectMake(CGRectGetMinX(self.buttonLine.frame) - 80 - 11.5, 0, 80, 32);
    self.leaveLinkMicButton.frame = CGRectMake(CGRectGetMinX(self.buttonLine.frame) + 11.5, 0, 50, 32);
    
    // 第二行控件
    // 父视图
    CGFloat leftViewWidth = self.bounds.size.width * 0.36;
    CGFloat rightViewWidth = self.bounds.size.width - leftViewWidth;
    self.leftView.frame = CGRectMake(0, self.bounds.size.height / 2.0, leftViewWidth, self.bounds.size.height / 2.0);
    self.rightView.frame = CGRectMake(leftViewWidth, self.bounds.size.height / 2.0, rightViewWidth, self.bounds.size.height / 2.0);
    
    // 左侧子视图
    self.tableTitleLabel.frame = CGRectMake(12, 0, self.leftView.frame.size.width - 12, self.leftView.frame.size.height);
    self.handUpLabel.frame = CGRectMake(12, 0, self.leftView.frame.size.width - 12 - 8, self.leftView.frame.size.height);
    CGFloat tableTitleWidth = [self.tableTitleLabel.text boundingRectWithSize:self.tableTitleLabel.frame.size
                                                                      options:0
                                                                   attributes:@{ NSFontAttributeName : [UIFont systemFontOfSize:12] }
                                                                      context:nil].size.width;
    self.changeListButton.frame = CGRectMake(12 + tableTitleWidth + 5, 0, 30, 30);
    
    // 右侧子视图
    CGFloat labelX = 0;
    CGFloat labelWidth = (rightViewWidth - 22.0) / 7.0;
    for (UILabel *label in self.labelArray) {
        label.frame = CGRectMake(labelX, 0, labelWidth, self.rightView.frame.size.height);
        labelX += labelWidth;
    }
}

#pragma mark - [ Public Method ]

- (void)setTableTitle:(NSString *)text {
    self.tableTitleLabel.text = text;
}

- (void)setHandupLabelCount:(NSInteger)count {
    self.handUpLabel.text = [NSString stringWithFormat:@"举手(%zd)", MAX(0, count)];
}

#pragma mark - [ Private Method ]

- (UILabel *)generateWhiteLabelWithText:(NSString *)text {
    UILabel *label = [[UILabel alloc] init];
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = [UIColor whiteColor];
    label.font = [UIFont systemFontOfSize:12];
    label.text = text;
    return label;
}

#pragma mark Getter & Setter

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.textColor = [UIColor whiteColor];
        _titleLabel.font = [UIFont systemFontOfSize:12];
        _titleLabel.text = @"学生列表";
    }
    return _titleLabel;
}

- (UIView *)titleLine {
    if (!_titleLine) {
        _titleLine = [[UIView alloc] init];
        _titleLine.backgroundColor = [PLVColorUtil colorFromHexString:@"#F0F1F5" alpha:0.08];
    }
    return _titleLine;
}

- (UIButton *)closeMicButton {
    if (!_closeMicButton) {
        _closeMicButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_closeMicButton setTitle:@"全体禁麦" forState:UIControlStateNormal];
        [_closeMicButton setTitle:@"取消全体禁麦" forState:UIControlStateSelected];
        [_closeMicButton setTitleColor:[PLVColorUtil colorFromHexString:@"#78A7ED"] forState:UIControlStateNormal];
        _closeMicButton.titleLabel.font = [UIFont systemFontOfSize:12];
        _closeMicButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
        _closeMicButton.hidden = YES; //暂时屏蔽掉全员禁麦
    }
    return _closeMicButton;
}

- (UIView *)buttonLine {
    if (!_buttonLine) {
        _buttonLine = [[UIView alloc] init];
        _buttonLine.backgroundColor = [PLVColorUtil colorFromHexString:@"#F0F1F5" alpha:0.08];
    }
    return _buttonLine;
}

- (UIButton *)leaveLinkMicButton {
    if (!_leaveLinkMicButton) {
        _leaveLinkMicButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_leaveLinkMicButton setTitle:@"全体下台" forState:UIControlStateNormal];
        [_leaveLinkMicButton setTitleColor:[PLVColorUtil colorFromHexString:@"#78A7ED"] forState:UIControlStateNormal];
        _leaveLinkMicButton.titleLabel.font = [UIFont systemFontOfSize:12];
    }
    return _leaveLinkMicButton;
}

- (UIView *)leftView {
    if (!_leftView) {
        _leftView = [[UIView alloc] init];
    }
    return _leftView;
}

- (UIView *)rightView {
    if (!_rightView) {
        _rightView = [[UIView alloc] init];
    }
    return _rightView;
}

- (UILabel *)tableTitleLabel {
    if (!_tableTitleLabel) {
        _tableTitleLabel = [[UILabel alloc] init];
        _tableTitleLabel.textColor = [UIColor whiteColor];
        _tableTitleLabel.font = [UIFont systemFontOfSize:12];
    }
    return _tableTitleLabel;
}

- (UIButton *)changeListButton {
    if (!_changeListButton) {
        _changeListButton = [UIButton buttonWithType:UIButtonTypeCustom];
        UIImage *normalImage = [PLVHCUtils imageForMemberResource:@"plvhc_member_unfold_btn"];
        UIImage *selectedImage = [PLVHCUtils imageForMemberResource:@"plvhc_member_fold_btn"];
        [_changeListButton setImage:normalImage forState:UIControlStateNormal];
        [_changeListButton setImage:selectedImage forState:UIControlStateSelected];
    }
    return _changeListButton;
}

- (UILabel *)handUpLabel {
    if (!_handUpLabel) {
        _handUpLabel = [[UILabel alloc] init];
        _handUpLabel.textAlignment = NSTextAlignmentRight;
        _handUpLabel.textColor = [UIColor whiteColor];
        _handUpLabel.font = [UIFont systemFontOfSize:12];
    }
    return _handUpLabel;
}

@end
