//
//  PLVImagePickerViewController.h
//  PolyvLiveScenesDemo
//
//  Created by Dhan on 2022/4/6.
//  Copyright © 2022 PLV. All rights reserved.
//

#import <PLVImagePickerController/PLVImagePickerController.h>

NS_ASSUME_NONNULL_BEGIN

@interface PLVImagePickerViewController : PLVImagePickerController

/// 创建默认UI的图片选择器
/// @param columnNumber 列数
///
/// @note 本方法默认创建固定UI的PLVImagePickerController，可修改[setupUI]内部方法改变或参考该类使用PLVImagePickerController自行实现
/// 注意：本方法只默认UI配置，仍需要自行实现图片选择的回调
/// @code
/// // 使用演示 (具体参数及调用时机，请根据业务场景所需，进行实际设置)
///  PLVImagePickerViewController *vctrl = [[PLVImagePickerViewController alloc] initWithColumnNumber:4];
/// [vctrl setDidFinishPickingPhotosHandle:^(NSArray<UIImage *> *photos, NSArray *assets, BOOL isSelectOriginalPhoto) {
/// //实现图片选择回调
/// }
/// [vctrl setImagePickerControllerDidCancelHandle:^{
/// //实现图片选择取消回调
/// }
/// @endcode
- (instancetype)initWithColumnNumber:(NSInteger)columnNumber;
@end

NS_ASSUME_NONNULL_END
