//
//  PLVHCCompanyTableViewCell.h
//  PLVLiveScenesDemo
//
//  Created by jiaweihuang on 2021/6/30.
//  Copyright © 2021 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface PLVHCCompanyTableViewCell : UITableViewCell

- (void)setCompanyName:(NSString *)companyName;

+ (CGFloat)cellHeightWithText:(NSString *)text cellWidth:(CGFloat)cellWidth;

@end

