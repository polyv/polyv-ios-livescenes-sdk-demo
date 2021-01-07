//
//  PLVECCommodityView.m
//  PolyvLiveScenesDemo
//
//  Created by ftao on 2020/6/28.
//  Copyright © 2020 polyv. All rights reserved.
//

#import "PLVECCommodityView.h"
#import "PLVECUtils.h"

@interface PLVECCommodityView ()

@property (nonatomic, strong) PLVECCommodityPresenter *presenter;

@end

@implementation PLVECCommodityView

#pragma mark - <PLVECCommodityViewProtocol>

@synthesize channelId;
@synthesize titleLabel;
@synthesize tableView;
@synthesize indicatorView;

- (void)setupUIOfNoGoods:(BOOL)noGoods {
    if (noGoods) {
        self.notAddedImageView.hidden = NO;
        self.tipLabel.hidden = NO;
    } else {
        if (_notAddedImageView) {
            _notAddedImageView.hidden = YES;
        }
        if (_tipLabel) {
            _tipLabel.hidden = YES;
        }
    }
}

- (void)jumpToGoodsDetail:(NSURL *)goodsURL {
    self.hidden = YES;
    [self clearCommodityInfo];
    
    if (self.goodsSelectedHandler) {
        self.goodsSelectedHandler(goodsURL);
    }
}

#pragma mark - <PLVECCommodityPresenterProtocol>

- (void)setChannelId:(NSString *)channelId {
    self.presenter.channelId = channelId;
}

- (void)loadCommodityInfo {
    [self.presenter loadCommodityInfo];
}

- (void)clearCommodityInfo {
    [self.presenter clearCommodityInfo];
}

- (void)receiveProductMessage:(NSInteger)status content:(id)content {
    [self.presenter receiveProductMessage:status content:content];
}

#pragma mark - Self methods

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
        
        self.presenter = [[PLVECCommodityPresenter alloc] init];
        self.presenter.view = self;
    }
    return self;
}

- (void)setupUI {
    self.iconImageView = [[UIImageView alloc] init];
    self.iconImageView.image = [PLVECUtils imageForWatchResource:@"plv_commodity_icon"];
    [self addSubview:self.iconImageView];
    
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.textAlignment = NSTextAlignmentLeft;
    [self addSubview:self.titleLabel];
    
    if (@available(iOS 13.0, *)) {
#ifdef __IPHONE_13_0
        self.indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
#else
        self.indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
#endif
    } else {
        self.indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    }
    [self addSubview:self.indicatorView];
    
    self.tableView = [[UITableView alloc] init];
    self.tableView.backgroundColor = UIColor.clearColor;
    self.tableView.allowsSelection =  NO;
    self.tableView.showsVerticalScrollIndicator = NO;
    self.tableView.showsHorizontalScrollIndicator = NO;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self addSubview:self.tableView];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.iconImageView.frame = CGRectMake(16, 21, 12, 12);
    self.titleLabel.frame = CGRectMake(CGRectGetMaxX(self.iconImageView.frame)+4, 18, 100, 17);
    self.indicatorView.center = CGPointMake(CGRectGetWidth(self.bounds)/2, CGRectGetHeight(self.bounds)/2);
    self.tableView.frame = CGRectMake(16, 55, CGRectGetWidth(self.bounds)-32, CGRectGetHeight(self.bounds)-55);
}

#pragma mark - Getter

- (UIImageView *)notAddedImageView {
    if (!_notAddedImageView) {
        _notAddedImageView = [[UIImageView alloc] init];
        _notAddedImageView.frame = CGRectMake(CGRectGetWidth(self.bounds)/2-44, 142, 88, 88);
        _notAddedImageView.image = [PLVECUtils imageForWatchResource:@"plv_commodity_img_notAdded"];
        [self addSubview:_notAddedImageView];
    }
    return _notAddedImageView;
}

- (UILabel *)tipLabel {
    if (!_tipLabel) {
        _tipLabel = [[UILabel alloc] init];
        _tipLabel.frame = CGRectMake(CGRectGetWidth(self.bounds)/2-100, CGRectGetMaxY(self.notAddedImageView.frame)+8, 200, 20);
        _tipLabel.text = @"宝贝还没上架，敬请期待";
        _tipLabel.textAlignment = NSTextAlignmentCenter;
        _tipLabel.textColor = [UIColor colorWithWhite:1 alpha:0.6];
        _tipLabel.font = [UIFont systemFontOfSize:14.0];
        [self addSubview:_tipLabel];
    }
    return _tipLabel;
}

@end
