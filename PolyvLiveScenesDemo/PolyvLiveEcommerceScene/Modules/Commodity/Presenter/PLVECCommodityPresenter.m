//
//  PLVECCommodityPresenter.m
//  PolyvLiveScenesDemo
//
//  Created by ftao on 2020/6/29.
//  Copyright © 2020 polyv. All rights reserved.
//

#import "PLVECCommodityPresenter.h"
#import <PLVLiveScenesSDK/PLVLiveVideoConfig.h>
#import <PolyvFoundationSDK/PLVFdUtil.h>
#import <PolyvFoundationSDK/PLVDataUtil.h>
#import "PLVECCommodityViewModel.h"
#import "PLVECCommodityCell.h"

@interface PLVECCommodityPresenter () <UITableViewDelegate, UITableViewDataSource, PLVECCommodityDelegate>

@property (nonatomic, strong) PLVECCommodityViewModel *viewModel;

@property (nonatomic, assign) BOOL loading; // 请求中

@end

// 每次获取列表数据大小，默认10条，最大20
static const NSUInteger listCount = 20;

@implementation PLVECCommodityPresenter
@synthesize channelId;

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.viewModel = [[PLVECCommodityViewModel alloc] init];
    }
    return self;
}

#pragma mark - Setter

- (void)setView:(id<PLVECCommodityViewProtocol>)view {
    _view = view;
    if ([view respondsToSelector:@selector(tableView)]) {
        view.tableView.delegate = self;
        view.tableView.dataSource = self;
    }
}

#pragma mark - <PLVECCommodityControllerProtocol>

// 首次加载
- (void)loadCommodityInfo {
    [self clearCommodityInfo];
    [self.view.indicatorView startAnimating];
    
    self.viewModel.moreData = YES;
    [self requestCommodityInfo];
}

- (void)clearCommodityInfo {
    [self.viewModel.cellModels removeAllObjects];
    self.viewModel.totalItems = -1;
    [self reloadViewData];
}

- (void)receiveProductMessage:(NSInteger)status content:(id)content {
    if (![content isKindOfClass:NSDictionary.class] && ![content isKindOfClass:NSArray.class]) {
        return;
    }
    
//    if (!self.viewModel.cellModels.count) { // 无数据时或未打开商品列表不处理
//        return;
//    }
    
    NSInteger productId = PLV_SafeIntegerForDictKey(content, @"productId");
    NSInteger rank = PLV_SafeIntegerForDictKey(content, @"rank");
    switch (status) {
        case 1: { // 上架商品
            PLVECCommodityModel *model = [PLVECCommodityModel modelWithDict:content];
            NSInteger index = [self.viewModel addModel:model atFirst:NO];
            NSLog(@"新增商品 %ld",index);
            if (index >= 0) {
                [self reloadViewData];
            }
        } break;
        case 2:   // 下架商品
        case 3: { // 删除商品
            NSInteger index = [self.viewModel removeModelWithProductId:productId rank:rank];
            NSLog(@"删除商品 %ld",index);
            if (index >= 0) {
                [self reloadViewData];
            }
        } break;
        case 4: { // 新增商品
            PLVECCommodityModel *model = [PLVECCommodityModel modelWithDict:content];
            NSInteger index = [self.viewModel addModel:model atFirst:YES];
            NSLog(@"新增商品 %ld",index);
            if (index >= 0) {
                [self reloadViewData];
            }
        } break;
        case 5: { // 更新商品
            int type;
            PLVECCommodityModel *model = [PLVECCommodityModel modelWithDict:content];
            NSInteger index = [self.viewModel updateModel:model type:&type];
            NSLog(@"更新商品 type(1:更新；2:增加；3:删除):%d %ld",type,index);
            if (index >= 0) {
                [self reloadViewData];
            }
        } break;
        case 6:   // 上移商品
        case 7: { // 下移商品
            if ([content isKindOfClass:NSArray.class]) {
                if ([(NSArray *)content count] == 2) {
                    PLVECCommodityModel *model1 = [PLVECCommodityModel modelWithDict:content[0]];
                    PLVECCommodityModel *model2 = [PLVECCommodityModel modelWithDict:content[1]];
                    __weak typeof(self)weakSelf = self;
                    [self.viewModel switchModel:model1 with:model2 completion:^(NSInteger idx1, NSInteger idx2, int code) {
                        NSLog(@"交换商品 code(0 参数错误/无需处理；1 更新商品rank值；2 更新一条商品数据（删除&新增）；3 交换数据):%d %ld %ld", code,idx1,idx2);
                        if (code > 1) {
                            [weakSelf reloadViewData];
                        }
                    }];
                }
            }
        } break;
        case 8: { // 置顶商品
        } break;
        case 9: { // 推送商品
        } break;
        default:
            break;
    }
}

#pragma mark - Priveta

- (void)reloadViewData {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.viewModel.totalItems == 0) {
            [self.view setupUIOfNoGoods:YES];
        } else {
            [self.view setupUIOfNoGoods:NO];
        }
        self.view.titleLabel.attributedText = self.viewModel.titleAttrStr;
        [self.view.tableView reloadData];
    });
}

- (void)loadFailur:(NSError *)error message:(NSString *)message {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (error) {
            NSLog(@"loadCommodityInfo error description: %@",error.localizedDescription);
        } else {
            NSLog(@"loadCommodityInfo error message: %@",message);
        }
    });
}

#pragma mark netwrork

- (void)requestCommodityInfo {
    if (self.loading || !self.viewModel.moreData) {
        return;
    }
    self.loading = YES;
    
    NSUInteger minRank = self.viewModel.cellModels.count ? [self.viewModel.cellModels.lastObject.model rank] : 0;
    __weak typeof(self)weakSelf = self;
    [[[NSURLSession sharedSession] dataTaskWithRequest:[self urlRequestForCommodity:minRank] completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.view.indicatorView stopAnimating];
        });
        
        if (error) {
            [weakSelf loadFailur:error message:nil];
        } else {
            NSError *parseErr = nil;
            NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&parseErr];
            if (parseErr) {
                NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                NSLog(@"httpResponse statusCode %ld",(long)httpResponse.statusCode);
                [weakSelf loadFailur:parseErr message:nil];
            } else if ([jsonDict isKindOfClass:NSDictionary.class]) {
                if ([PLV_SafeStringForDictKey(jsonDict, @"status") isEqualToString:@"success"]) {
                    NSDictionary *data = PLV_SafeDictionaryForDictKey(jsonDict, @"data");
                    NSArray *content = PLV_SafeArraryForDictKey(data, @"content");
                    weakSelf.viewModel.moreData = listCount == content.count;
                    if (content.count) {
                        for (NSDictionary *dict in content) {
                            PLVECCommodityModel *model = [PLVECCommodityModel modelWithDict:dict];
                            PLVECCommodityCellModel *cellModel = [[PLVECCommodityCellModel alloc] initWithModel:model];
                            if (cellModel) {
                                [weakSelf.viewModel.cellModels addObject:cellModel];
                            }
                        }
                    } else {
                        weakSelf.viewModel.moreData = NO;
                    }
                    weakSelf.viewModel.totalItems = PLV_SafeIntegerForDictKey(data, @"total");
                    [weakSelf reloadViewData];
                } else {
                    [weakSelf loadFailur:nil message:PLV_SafeStringForDictKey(jsonDict, @"message")];
                }
            } else {
                [weakSelf loadFailur:nil message:@"parseErr: not dict"];
            }
        }
        weakSelf.loading = NO;
    }] resume];
}

// 不传排序号会返回列表最前面的数据，传rank后返回rank之后的商品列表
- (NSURLRequest *)urlRequestForCommodity:(NSUInteger)rank {
    NSString *appId = [PLVLiveVideoConfig sharedInstance].appId;
    NSString *appSecret = [PLVLiveVideoConfig sharedInstance].appSecret;
    
    NSTimeInterval timeStamp = [NSDate.date timeIntervalSince1970] * 1000;
    NSString *timeStampStr = [NSString stringWithFormat:@"%lld", (long long)timeStamp];
    NSString *rankStr = rank > 0 ? [NSString stringWithFormat:@"rank%ld",rank] : @"";
    NSString *signRaw = [NSString stringWithFormat:@"%@appId%@channelId%@count%ld%@timestamp%@%@",appSecret,appId,self.channelId,(long)listCount,rankStr,timeStampStr,appSecret];
    NSString *sign = [[PLVDataUtil md5HexDigest:signRaw] uppercaseString];
    
    NSMutableString *urlStr = [NSMutableString stringWithString:@"https://api.polyv.net/live/v3/channel/product/getListByRank"];
    [urlStr appendFormat:@"?channelId=%@",self.channelId];
    if (rank > 0) {
        [urlStr appendFormat:@"&rank=%ld",(long)rank];
    }
    [urlStr appendFormat:@"&count=%ld",(long)listCount];
    [urlStr appendFormat:@"&sign=%@",sign];
    [urlStr appendFormat:@"&appId=%@",appId];
    [urlStr appendFormat:@"&timestamp=%@",timeStampStr];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlStr] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:15.0];
    
    return request;
}

#pragma mark - <PLVECCommodityDelegate>

- (void)commodity:(id)commodity didSelect:(PLVECCommodityCellModel *)cellModel {
    if (!cellModel.jumpLinkUrl) {
        return;
    }
    
    if (self.view && [self.view respondsToSelector:@selector(jumpToGoodsDetail:)]) {
        [self.view jumpToGoodsDetail:cellModel.jumpLinkUrl];
    } else {
        if (![UIApplication.sharedApplication openURL:cellModel.jumpLinkUrl]) {
            NSLog(@"url: %@",cellModel.jumpLinkUrl);
        }
    }
}

#pragma mark - <UITableViewDataSource>

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.viewModel.cellModels.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *reuseIdentifier = @"reuseIdentifier";
    PLVECCommodityCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
    if (!cell) {
        cell = [[PLVECCommodityCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
    }
    cell.cellModel = self.viewModel.cellModels[indexPath.section];
    cell.delegate = self;
    
    return cell;
}

#pragma mark - <UITableViewDelegate>

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 88.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 20.0;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    UIView *view = [[UIView alloc] init];
    view.backgroundColor = [UIColor clearColor];
    return view;
}

#pragma mark - <>

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat bottomOffset = scrollView.contentSize.height - scrollView.contentOffset.y;
    if (bottomOffset < CGRectGetHeight(scrollView.bounds) + 1) { // tolerance
        [self requestCommodityInfo];
    }
}

@end
