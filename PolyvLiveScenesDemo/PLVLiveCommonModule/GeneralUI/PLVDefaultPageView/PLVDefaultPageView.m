//
//  PLVDefaultPageView.m
//  PolyvLiveScenesDemo
//
//  Created by Dhan on 2022/8/19.
//  Copyright © 2022 PLV. All rights reserved.
//

#import "PLVDefaultPageView.h"
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>

static NSString * const defaultPageViewTypeErrorCodeString = @"视频加载失败，请退出重进";
static NSString * const defaultPageViewTypeRefreshString = @"视频加载失败，请检查网络或退出重进";
static NSString * const defaultPageViewTypeRefreshAndSwitchLineString = @"视频加载缓慢，请切换线路或退出重进";

@interface PLVDefaultPageView ()

@property (nonatomic, strong) UIImageView *defaultImageView;

@property (nonatomic, strong) UILabel *messageLabel;

@property (nonatomic, strong) UIButton *refreshButton;

@property (nonatomic, strong) UIButton *switchLineButton;

@property (nonatomic, assign) PLVDefaultPageViewType type;

@end

@implementation PLVDefaultPageView

#pragma mark - Life Cycle

- (instancetype)init {
    self = [super init];
    if (self) {
        self.type = PLVDefaultPageViewTypeErrorCode;
        self.userInteractionEnabled = YES;
        self.backgroundColor = [PLVColorUtil colorFromHexString:@"#2B3045"];
        [self addSubview:self.defaultImageView];
        [self addSubview:self.messageLabel];
        [self addSubview:self.refreshButton];
        [self addSubview:self.switchLineButton];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self updateUI];
}

#pragma mark - Public

- (void)showWithErrorMessage:(NSString * _Nullable)message type:(PLVDefaultPageViewType)type {
    [self showWithErrorCode:0 message:message type:type];
}

- (void)showWithErrorCode:(NSInteger)errorCode message:(NSString * _Nullable)message type:(PLVDefaultPageViewType)type {
    if (!self.hidden && type < self.type) {
        return;
    }
    self.type = type;
    NSString *messageLabelString;
    if (type == PLVDefaultPageViewTypeErrorCode) {
        messageLabelString = [PLVFdUtil checkStringUseable:message] ? message : defaultPageViewTypeErrorCodeString;
    } else if (type == PLVDefaultPageViewTypeRefresh) {
        messageLabelString = [PLVFdUtil checkStringUseable:message] ? message : defaultPageViewTypeRefreshString;
    } else if (type == PLVDefaultPageViewTypeRefreshAndSwitchLine) {
        messageLabelString = [PLVFdUtil checkStringUseable:message] ? message : defaultPageViewTypeRefreshAndSwitchLineString;
    }
    
    if (errorCode) {
        messageLabelString = [NSString stringWithFormat:@"%@(错误码:%ld)",messageLabelString,errorCode];
    }
    self.messageLabel.text = messageLabelString;
    [self updateUI];
    self.hidden = NO;
}

#pragma mark - Private

- (void)updateUI {
    BOOL fullScreen = [UIScreen mainScreen].bounds.size.width > [UIScreen mainScreen].bounds.size.height;
    BOOL isPad = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
    BOOL showOnFloatView = isPad ? (self.frame.size.width <= 150) : (self.frame.size.width <= 224);
    CGFloat height = 0;
    self.refreshButton.hidden = showOnFloatView ? : (self.type == PLVDefaultPageViewTypeErrorCode);
    self.refreshButton.titleLabel.font = fullScreen ? [UIFont fontWithName:@"PingFangSC-Regular" size:14] : [UIFont fontWithName:@"PingFangSC-Regular" size:12];
    self.refreshButton.layer.cornerRadius = fullScreen ? 16 : 12;
    self.switchLineButton.hidden = showOnFloatView? : !(self.type == PLVDefaultPageViewTypeRefreshAndSwitchLine);
    self.switchLineButton.titleLabel.font = fullScreen ? [UIFont fontWithName:@"PingFangSC-Regular" size:14] : [UIFont fontWithName:@"PingFangSC-Regular" size:12];
    self.switchLineButton.layer.cornerRadius = fullScreen ? 16 : 12;
    self.messageLabel.font = fullScreen ? [UIFont fontWithName:@"PingFangSC-Regular" size:14] : [UIFont fontWithName:@"PingFangSC-Regular" size:12];
    
    if (showOnFloatView) {
        if (isPad) {
            height = 40;
        }
        self.defaultImageView.frame = CGRectMake((self.frame.size.width - 82) / 2, 2 + height, 82, 70);
    } else if (fullScreen) {
        if (isPad) {
            height = 180;
        }
        if (self.type == PLVDefaultPageViewTypeErrorCode) {
            self.defaultImageView.frame = CGRectMake((self.frame.size.width - 216) / 2, 90 + height, 216, 184);
        } else {
            self.defaultImageView.frame = CGRectMake((self.frame.size.width - 216) / 2, 68 + height, 216, 184);
            if (self.type == PLVDefaultPageViewTypeRefresh) {
                self.refreshButton.frame = CGRectMake((self.frame.size.width - 97) / 2, CGRectGetMaxY(self.defaultImageView.frame) + 8, 97, 32);
            } else {
                self.switchLineButton.frame = CGRectMake((self.frame.size.width - 24) / 2 - 97, CGRectGetMaxY(self.defaultImageView.frame) + 8, 97, 32);
                self.refreshButton.frame = CGRectMake(CGRectGetMaxX(self.switchLineButton.frame) + 24, CGRectGetMinY(self.switchLineButton.frame), 97, 32);
            }
        }
        self.messageLabel.frame = CGRectMake(40, CGRectGetMinY(self.defaultImageView.frame) + 148, self.frame.size.width - 80, 20);
    } else {
        if (isPad) {
            height = 120;
        }
        if (self.type == PLVDefaultPageViewTypeErrorCode) {
            self.defaultImageView.frame = CGRectMake((self.frame.size.width - 180) / 2, 29 + height, 180, 154);
        } else {
            self.defaultImageView.frame = CGRectMake((self.frame.size.width - 180) / 2, 8 + height, 180, 154);
            if (self.type == PLVDefaultPageViewTypeRefresh) {
                self.refreshButton.frame = CGRectMake((self.frame.size.width - 80) / 2, CGRectGetMaxY(self.defaultImageView.frame), 80, 24);
            } else {
                self.switchLineButton.frame = CGRectMake((self.frame.size.width - 16) / 2 - 80, CGRectGetMaxY(self.defaultImageView.frame), 80, 24);
                self.refreshButton.frame = CGRectMake(CGRectGetMaxX(self.switchLineButton.frame) + 16, CGRectGetMinY(self.switchLineButton.frame), 80, 24);
            }
        }
        self.messageLabel.frame = CGRectMake(30, CGRectGetMinY(self.defaultImageView.frame) + 120, self.frame.size.width - 60, 17);
    }
}

#pragma mark Getter
- (UIImageView *)defaultImageView {
    if (!_defaultImageView) {
        _defaultImageView = [[UIImageView alloc] init];
        _defaultImageView.image = [self imageForPLVDefaultPageViewResource:@"plv_default_page_view_icon"];
        _defaultImageView.contentMode = UIViewContentModeScaleAspectFill;
    }
    return _defaultImageView;
}

- (UILabel *)messageLabel {
    if (!_messageLabel) {
        _messageLabel = [[UILabel alloc] init];
        _messageLabel.text = @"视频加载失败，请检查网络或退出重进";
        _messageLabel.textAlignment = NSTextAlignmentCenter;
        _messageLabel.textColor = [PLVColorUtil colorFromHexString:@"#E4E4E4"];
        _messageLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:14];
    }
    return _messageLabel;
}

- (UIButton *)refreshButton {
    if (!_refreshButton) {
        _refreshButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _refreshButton.titleLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:14];
        [_refreshButton setTitle:@"刷新" forState:UIControlStateNormal];
        [_refreshButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_refreshButton setBackgroundColor:[PLVColorUtil colorFromHexString:@"#3082FE"]];
        [_refreshButton addTarget:self action:@selector(refreshButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        _refreshButton.layer.masksToBounds = YES;
        _refreshButton.layer.cornerRadius = 12;
    }
    return _refreshButton;
}

- (UIButton *)switchLineButton {
    if (!_switchLineButton) {
        _switchLineButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _switchLineButton.titleLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:14];
        [_switchLineButton setTitle:@"切换线路" forState:UIControlStateNormal];
        [_switchLineButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_switchLineButton addTarget:self action:@selector(switchLineButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        _switchLineButton.layer.masksToBounds = YES;
        _switchLineButton.layer.cornerRadius = 12;
        _switchLineButton.layer.borderWidth = 0.5f;
        _switchLineButton.layer.borderColor = [PLVColorUtil colorFromHexString:@"#FFFFFF" alpha:0.4f].CGColor;
    }
    return _switchLineButton;
}

#pragma mark - Event

- (void)refreshButtonAction:(UIButton *)button {
    if (self.delegate && [self.delegate respondsToSelector:@selector(plvDefaultPageViewWannaRefresh:)]) {
        [self.delegate plvDefaultPageViewWannaRefresh:self];
    }
}

- (void)switchLineButtonAction:(UIButton *)button {
    if (self.delegate && [self.delegate respondsToSelector:@selector(plvDefaultPageViewWannaSwitchLine:)]) {
        [self.delegate plvDefaultPageViewWannaSwitchLine:self];
    }
}

#pragma mark - Utils

- (UIImage *)imageForPLVDefaultPageViewResource:(NSString *)imageName {
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSBundle *resourceBundle = [NSBundle bundleWithPath:[bundle pathForResource:@"PLVDefaultPageView" ofType:@"bundle"]];
    return [UIImage imageNamed:imageName inBundle:resourceBundle compatibleWithTraitCollection:nil];
}

@end
