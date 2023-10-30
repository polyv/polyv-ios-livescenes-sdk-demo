//
//  PLVHCChooseCompanyViewController.h
//  PLVLiveScenesDemo
//
//  Created by jiaweihuang on 2021/6/30.
//  Copyright © 2021 PLV. All rights reserved.
//  公司选择页

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PLVHCChooseCompanyViewController : UIViewController

/// 初始化方法
/// @param mobile 上一个登录页输入的手机号
/// @param password 上一个登录页输入的密码
/// @param companyArray 公司数组
- (instancetype)initWithMobile:(NSString *)mobile
                      password:(NSString *)password
                  companyArray:(NSArray <NSDictionary *> *)companyArray;

@end

NS_ASSUME_NONNULL_END
