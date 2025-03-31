//
//  PLVSADesktopChatSettingGuideViewController.m
//  PolyvLiveScenesDemo
//
//  Created by Dhan on 2025/3/20.
//  Copyright © 2025 PLV. All rights reserved.
//

#import "PLVSADesktopChatSettingGuideViewController.h"
#import "PLVMultiLanguageManager.h"
#import "PLVSAUtils.h"

@interface PLVSADesktopChatSettingGuideViewController ()

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) NSArray *guideTexts;
@property (nonatomic, strong) NSArray *guideImages;
@property (nonatomic, strong) NSMutableArray *textLabels;
@property (nonatomic, strong) NSMutableArray *imageViews;

@end

@implementation PLVSADesktopChatSettingGuideViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initNavigationBar];
    [self setupData];
    [self setupUI];
}

- (void)setupData {
    self.guideTexts = @[
        PLVLocalizedString(@"1. 在设置中找到'通用'"),
        PLVLocalizedString(@"2. 选择'画中画'功能"),
        PLVLocalizedString(@"3. 允许'自动开启画中画'"),
    ];
    
    self.guideImages = @[
        @"plvsa_liveroom_desktop_chat_setting_guide_step1",
        @"plvsa_liveroom_desktop_chat_setting_guide_step2",
        @"plvsa_liveroom_desktop_chat_setting_guide_step3"
    ];
    
    self.textLabels = [NSMutableArray array];
    self.imageViews = [NSMutableArray array];
}

- (void)setupUI {
    self.view.backgroundColor = [UIColor whiteColor];
    
    // 创建滚动视图
    self.scrollView = [[UIScrollView alloc] init];
    CGFloat navigationBarHeight = self.navigationController.navigationBar.frame.size.height;
    CGFloat statusBarHeight = [UIApplication sharedApplication].statusBarFrame.size.height;
    CGFloat topOffset = navigationBarHeight + statusBarHeight;
    
    self.scrollView.frame = CGRectMake(0, topOffset, CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame) - topOffset);
    [self.view addSubview:self.scrollView];
    
    CGFloat padding = 20.0;
    CGFloat imageWidth = CGRectGetWidth(self.view.frame) - 2 * padding;
    CGFloat imageHeight = imageWidth * 0.626;
    CGFloat labelHeight = 44.0;
    CGFloat totalSpacing = 15.0;
    
    CGFloat currentY = padding;
    
    // 创建文本标签和图片视图
    for (NSInteger i = 0; i < self.guideTexts.count; i++) {
        // 添加文本标签
        UILabel *label = [[UILabel alloc] init];
        label.text = self.guideTexts[i];
        label.font = [UIFont systemFontOfSize:16];
        label.textColor = [UIColor colorWithRed:0x33/255.0 green:0x33/255.0 blue:0x33/255.0 alpha:1];
        label.frame = CGRectMake(padding, currentY, imageWidth, labelHeight);
        [self.scrollView addSubview:label];
        [self.textLabels addObject:label];
        
        currentY += labelHeight + totalSpacing;
        
        // 添加图片视图
        UIImageView *imageView = [[UIImageView alloc] init];
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        imageView.image = [PLVSAUtils imageForLiveroomResource:self.guideImages[i]];
        imageView.frame = CGRectMake(padding, currentY, imageWidth, imageHeight);
        imageView.layer.cornerRadius = 8.0;
        imageView.layer.masksToBounds = YES;
        [self.scrollView addSubview:imageView];
        [self.imageViews addObject:imageView];
        
        currentY += imageHeight + totalSpacing;
    }
    
    // 设置滚动视图的内容大小
    self.scrollView.contentSize = CGSizeMake(CGRectGetWidth(self.view.frame), currentY);
}

- (void)initNavigationBar {
    [self.navigationController.navigationBar setBackgroundColor:[UIColor whiteColor]];
    [self.navigationController.navigationBar setBackgroundImage:[[UIImage alloc] init] forBarMetrics:UIBarMetricsDefault];
    [self.navigationController.navigationBar setShadowImage:[[UIImage alloc] init]];
    
    NSDictionary *titleAttributes = @{NSFontAttributeName:[UIFont fontWithName:@"PingFangSC-Medium" size:20],
                                      NSForegroundColorAttributeName:[UIColor colorWithRed:0x33/255.0 green:0x33/255.0 blue:0x33/255.0 alpha:1]};
    [self.navigationController.navigationBar setTitleTextAttributes:titleAttributes];
    UIButton *leftButton = [UIButton buttonWithType:UIButtonTypeCustom];
    leftButton.frame = CGRectMake(0, 0, 44, 44);
    [leftButton setImage:[PLVSAUtils imageForLiveroomResource:@"plvsa_liveroom_btn_leftBack"] forState:UIControlStateNormal];
    [leftButton addTarget:self action:@selector(backButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    leftButton.imageEdgeInsets = UIEdgeInsetsMake(0, -40, 0, 0);
    UIBarButtonItem *backItem =[[UIBarButtonItem alloc] initWithCustomView:leftButton];
    self.navigationItem.leftBarButtonItem = backItem;
    self.title = PLVLocalizedString(@"系统设置引导");
}

#pragma mark - Action

- (void)backButtonAction:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
