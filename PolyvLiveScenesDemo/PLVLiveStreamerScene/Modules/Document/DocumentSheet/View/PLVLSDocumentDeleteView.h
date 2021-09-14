//
//  PLVLSDocumentDeleteView.h
//  PLVCloudClassStreamerModul
//  文档列表页 PLVSDocumentListViewController 长按 cell 时出现的红色气泡+删除按钮自定义 UIView
//
//  Created by MissYasiky on 2019/10/17.
//  Copyright © 2019 easefun. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol PLVLSDocumentDeleteViewProtocol <NSObject>

- (void)deleteAtIndex:(NSInteger)index;

@end

@interface PLVLSDocumentDeleteView : UIView

@property (nonatomic, assign) NSInteger index;

@property (nonatomic, weak) id<PLVLSDocumentDeleteViewProtocol> delegate;

- (void)showInView:(UIView *)view;
 
- (void)dismiss;

@end

NS_ASSUME_NONNULL_END
