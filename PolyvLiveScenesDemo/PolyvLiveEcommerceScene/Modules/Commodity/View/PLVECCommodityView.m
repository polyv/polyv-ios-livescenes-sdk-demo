//
//  PLVECCommodityView.m
//  PolyvLiveScenesDemo
//
//  Created by ftao on 2020/6/28.
//  Copyright © 2020 polyv. All rights reserved.
//  商品列表View

#import "PLVECCommodityView.h"
#import "PLVECUtils.h"

@interface PLVECCommodityView ()

@property (nonatomic, strong) UIImageView *iconImageView;

@property (nonatomic, strong) UIImageView *notAddedImageView;

@property (nonatomic, strong) UILabel *tipLabel;

@property (nonatomic, strong) UILabel *titleLabel;

@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic, strong) UIActivityIndicatorView *indicatorView;

@end

@implementation PLVECCommodityView

#pragma mark - [ Life Period ]
- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setupUI];
    }
    
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.iconImageView.frame = CGRectMake(16, 21, 12, 12);
    self.titleLabel.frame = CGRectMake(CGRectGetMaxX(self.iconImageView.frame)+4, 18, 100, 17);
    self.indicatorView.center = CGPointMake(CGRectGetWidth(self.bounds)/2, CGRectGetHeight(self.bounds)/2);
    self.tableView.frame = CGRectMake(16, 55, CGRectGetWidth(self.bounds)-32, CGRectGetHeight(self.bounds)-55);
}

#pragma mark - [ Public Methods ]
- (void)setDataSource:(id<UITableViewDataSource>)dataSource {
    self.tableView.dataSource = dataSource;
}

- (void)setDelegate:(id<UITableViewDelegate>)delegate {
    self.tableView.delegate = delegate;
}

- (void)startLoading {
    [self.indicatorView startAnimating];
}

- (void)stopLoading {
    [self.indicatorView stopAnimating];
}

- (void)reloadData:(NSInteger)total {
    if (total < 0) {
        total = 0;
    }
    
    [self setupUIOfNoGoods:total == 0];
    
    UIFont *font = [UIFont systemFontOfSize:12.0];
    NSMutableAttributedString *mAttriStr = [[NSMutableAttributedString alloc] initWithString:@"共件商品" attributes:@{NSFontAttributeName:font, NSForegroundColorAttributeName:UIColor.whiteColor}];
    NSAttributedString *countStr = [[NSAttributedString alloc] initWithString:@(total).stringValue attributes:@{NSFontAttributeName:font, NSForegroundColorAttributeName:[UIColor colorWithRed:1 green:153/255.0 blue:17/255.0 alpha:1]}];
    [mAttriStr insertAttributedString:countStr atIndex:1];
    
    self.titleLabel.attributedText = mAttriStr;
    
    [self.tableView reloadData];
}

#pragma mark - [ Private Methods ]
- (void)setupUI {
    [self addSubview:self.iconImageView];
    [self addSubview:self.titleLabel];
    [self addSubview:self.indicatorView];
    [self addSubview:self.tableView];
}

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

#pragma mark Getter
- (UIImageView *)iconImageView {
    if (! _iconImageView) {
        _iconImageView = [[UIImageView alloc] init];
        _iconImageView.image = [PLVECUtils imageForWatchResource:@"plv_commodity_icon"];
    }
    
    return _iconImageView;
}

- (UILabel *)titleLabel {
    if (! _titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.textAlignment = NSTextAlignmentLeft;
    }
    
    return _titleLabel;
}

- (UIActivityIndicatorView *)indicatorView {
    if (! _indicatorView) {
        if (@available(iOS 13.0, *)) {
    #ifdef __IPHONE_13_0
            _indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
    #else
            _indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    #endif
        } else {
            _indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        }
    }
    
    return _indicatorView;
}

- (UITableView *)tableView {
    if (! _tableView) {
        _tableView = [[UITableView alloc] init];
        _tableView.backgroundColor = UIColor.clearColor;
        _tableView.allowsSelection =  NO;
        _tableView.showsVerticalScrollIndicator = NO;
        _tableView.showsHorizontalScrollIndicator = NO;
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    }
    
    return _tableView;
}

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
