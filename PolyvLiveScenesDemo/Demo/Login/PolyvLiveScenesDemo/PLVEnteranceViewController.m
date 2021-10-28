//
//  PLVEnteranceViewController.m
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2021/5/12.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVEnteranceViewController.h"
#import "PLVLiveWatchLoginController.h"
#import "PLVLiveStreamerLoginViewController.h"

// 模块
#import "PLVHCTeacherLoginManager.h"

@interface PLVEnteranceViewController ()

@property (nonatomic, strong) UIImageView *bgImageView;
@property (nonatomic, strong) UIButton *streamerButton;
@property (nonatomic, strong) UIButton *watchButton;
@property (nonatomic, strong) UIButton *hiClassButton;
@property (nonatomic, strong) UIButton *seminarButton;
@property (nonatomic, strong) NSArray *buttonArray;

@end

@implementation PLVEnteranceViewController

#pragma mark - [ Life Cycle ]

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.view addSubview:self.bgImageView];
    
    self.buttonArray = @[ self.streamerButton, self.watchButton, self.hiClassButton ];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    self.bgImageView.frame = self.view.bounds;
    
    NSInteger buttonCount = self.buttonArray.count;
    CGFloat buttonWidth = 244.0;
    CGFloat buttonHeight = 140.0;
    CGFloat viewWidth = self.view.bounds.size.width;
    CGFloat viewHeight = self.view.bounds.size.height;
    CGFloat originX = (viewWidth - buttonWidth) / 2.0;
    CGFloat originY = (viewHeight - (buttonHeight - 16) * buttonCount) / 2.0;
    for (int i = 0; i < buttonCount; i++) {
        CGRect buttonRect = CGRectMake(originX, originY, buttonWidth, buttonHeight);
        originY += (buttonHeight - 16);
        
        UIButton *button = self.buttonArray[i];
        button.frame = buttonRect;
    }
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    //只支持竖屏方向
    return UIInterfaceOrientationMaskPortrait;
}

#pragma mark - [ Public Method ]
#pragma mark Getter & Setter

- (UIImageView *)bgImageView {
    if (!_bgImageView) {
        _bgImageView = [[UIImageView alloc] init];
        UIImage *image = [[self class] imageWithImageName:@"plv_enterance_bg"];
        _bgImageView.image = image;
        _bgImageView.contentMode = UIViewContentModeScaleAspectFill;
    }
    return _bgImageView;
}

- (UIButton *)streamerButton {
    if (!_streamerButton) {
        _streamerButton = [UIButton buttonWithType:UIButtonTypeCustom];
        UIImage *image = [[self class] imageWithImageName:@"plv_enterance_streamer_btn"];
        [_streamerButton setImage:image forState:UIControlStateNormal];
        [_streamerButton setTitle:@"手机开播" forState:UIControlStateNormal];
        [_streamerButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_streamerButton setTitleEdgeInsets:UIEdgeInsetsMake(-40, -310, 0, 0)];
        _streamerButton.titleLabel.font = [UIFont systemFontOfSize:24];
        _streamerButton.titleLabel.textAlignment = NSTextAlignmentLeft;
        [_streamerButton addTarget:self action:@selector(streamerButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:_streamerButton];
    }
    return _streamerButton;
}

- (UIButton *)watchButton {
    if (!_watchButton) {
        _watchButton = [UIButton buttonWithType:UIButtonTypeCustom];
        UIImage *image = [[self class] imageWithImageName:@"plv_enterance_watch_btn"];
        [_watchButton setImage:image forState:UIControlStateNormal];
        [_watchButton setTitle:@"云直播观看" forState:UIControlStateNormal];
        [_watchButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_watchButton setTitleEdgeInsets:UIEdgeInsetsMake(-40, -290, 0, 0)];
        _watchButton.titleLabel.font = [UIFont systemFontOfSize:24];
        _watchButton.titleLabel.textAlignment = NSTextAlignmentLeft;
        [_watchButton addTarget:self action:@selector(watchButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:_watchButton];
    }
    return _watchButton;
}

- (UIButton *)hiClassButton {
    if (!_hiClassButton) {
        _hiClassButton = [UIButton buttonWithType:UIButtonTypeCustom];
        UIImage *image = [[self class] imageWithImageName:@"plv_enterance_hiclass_btn"];
        [_hiClassButton setImage:image forState:UIControlStateNormal];
        [_hiClassButton setTitle:@"互动学堂" forState:UIControlStateNormal];
        [_hiClassButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_hiClassButton setTitleEdgeInsets:UIEdgeInsetsMake(-40, -290, 0, 0)];
        _hiClassButton.titleLabel.font = [UIFont systemFontOfSize:24];
        _hiClassButton.titleLabel.textAlignment = NSTextAlignmentLeft;
        [_hiClassButton addTarget:self action:@selector(hiClassButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:_hiClassButton];
    }
    return _hiClassButton;
}

#pragma mark - [ Private Method ]
#pragma mark Utils

+ (UIImage *)imageWithImageName:(NSString *)imageName {
    NSString *bundleName = @"LiveScenes";
    NSBundle *bundle = [NSBundle bundleForClass:[self class]]; // 本代码应该与资源文件存放在同个Bundle下
    NSString *bundlePath = [bundle pathForResource:bundleName ofType:@"bundle"]; // 获取到 LiveScenes.bundle 所在 Bundle
    NSBundle *resourceBundle = [NSBundle bundleWithPath:bundlePath];
    UIImage *image = [UIImage imageNamed:imageName inBundle:resourceBundle compatibleWithTraitCollection:nil];
    return image;
}

#pragma mark - [ Event ]
#pragma mark Action

- (void)streamerButtonAction:(id)sender {
    PLVLiveStreamerLoginViewController *vctrl = [[PLVLiveStreamerLoginViewController alloc] init];
    vctrl.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:vctrl animated:YES completion:nil];
}

- (void)watchButtonAction:(id)sender {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    PLVLiveWatchLoginController *vctrl = (PLVLiveWatchLoginController *)[storyboard instantiateInitialViewController];
    vctrl.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:vctrl animated:YES completion:nil];
}

- (void)hiClassButtonAction:(id)sender {
    [PLVHCTeacherLoginManager loadMainViewController];
}

@end
