//
//  PLVECBulletinCardView.h
//  PolyvLiveEcommerceDemo
//
//  Created by ftao on 2020/5/25.
//  Copyright © 2020 polyv. All rights reserved.
//

#import "PLVECCardView.h"

/// 公告卡片视图
@interface PLVECBulletinCardView : PLVECCardView

@property (nonatomic, strong) UITextView *contentTextView;

@property (nonatomic, copy) NSString *content;

@end
