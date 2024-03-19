//
//  PLVSACameraSettingSheet.m
//  PolyvLiveScenesDemo
//
//  Created by Dhan on 2023/10/19.
//  Copyright © 2023 PLV. All rights reserved.
//

#import "PLVSACameraSettingSheet.h"
#import <PLVFoundationSDK/PLVFoundationSDK.h>
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>
#import "PLVSAUtils.h"
#import "PLVMultiLanguageManager.h"
#import "PLVRoomDataManager.h"
#import "PLVImagePickerViewController.h"
#import <CropViewController/CropViewController.h>

@interface PLVSACameraSettingSheet()
<TOCropViewControllerDelegate>

// UI
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *cameraSwitchLabel;
@property (nonatomic, strong) UISwitch *cameraSwitch;
@property (nonatomic, strong) UILabel *sourceLabel;
@property (nonatomic, strong) UIButton *cameraSourceButton;
@property (nonatomic, strong) UIButton *imageSourceButton;
@property (nonatomic, strong) UILabel *uploadLabel;
@property (nonatomic, strong) UILabel *uploadTipLabel;
@property (nonatomic, strong) UIView *uploadImageGestureView;
@property (nonatomic, strong) UIView *uploadImagePlaceholderView;
@property (nonatomic, strong) UIImageView *uploadImageView;
@property (nonatomic, strong) UILabel *imageChangeLabel;

// 数据
@property (nonatomic, strong) UIImage *placeholderImage;
@property (nonatomic, copy) NSString *placeholderImageUrl;
@property (nonatomic, assign) CGSize placeholderImageSize;

// 工具
@property (nonatomic, strong) PLVImagePickerViewController *imagePicker;


@end

@implementation PLVSACameraSettingSheet

#pragma mark - [ Life Cycle ]
- (instancetype)initWithSheetHeight:(CGFloat)sheetHeight sheetLandscapeWidth:(CGFloat)sheetLandscapeWidth {
    self = [super initWithSheetHeight:sheetHeight sheetLandscapeWidth:sheetLandscapeWidth];
    if (self) {
        self.placeholderImageSize = CGSizeMake(80, 80);
        [self initUI];
    }
    return self;
}

- (void)initUI {
    [self.contentView addSubview:self.titleLabel];
    [self.contentView addSubview:self.cameraSwitchLabel];
    [self.contentView addSubview:self.cameraSwitch];
    [self.contentView addSubview:self.sourceLabel];
    [self.contentView addSubview:self.cameraSourceButton];
    [self.contentView addSubview:self.imageSourceButton];
    [self.contentView addSubview:self.uploadLabel];
    [self.contentView addSubview:self.uploadTipLabel];
//    [self.contentView addSubview:self.uploadImageView];
    [self.contentView addSubview:self.uploadImagePlaceholderView];
    [self.uploadImagePlaceholderView addSubview:self.uploadImageView];
    [self.uploadImagePlaceholderView addSubview:self.imageChangeLabel];
    [self.uploadImagePlaceholderView addSubview:self.uploadImageGestureView];
}

#pragma mark - [ Override ]

- (void)layoutSubviews {
    [super layoutSubviews];
    BOOL isPad = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
    CGFloat titleLabelLeft = isPad ? 56 : 32;
    self.titleLabel.frame = CGRectMake(titleLabelLeft, 32, 90, 18);
    self.cameraSwitchLabel.frame = CGRectMake(titleLabelLeft, CGRectGetMaxY(self.titleLabel.frame) + 22, 70, 20);
    if (isPad) {
        self.titleLabel.frame = CGRectMake(titleLabelLeft, 32, 90, 25);
        self.cameraSwitchLabel.frame = CGRectMake(titleLabelLeft, CGRectGetMaxY(self.titleLabel.frame) + 34, 70, 20);
    }
    [self.cameraSwitchLabel sizeToFit];
    
    CGFloat maxLabelWidth = [PLVSAUtils sharedUtils].landscape ? self.sheetLandscapeWidth - titleLabelLeft : self.bounds.size.width - 2 * titleLabelLeft;
    self.cameraSwitch.frame = CGRectMake(CGRectGetMaxX(self.cameraSwitchLabel.frame) + 8, CGRectGetMinY(self.cameraSwitchLabel.frame), 32, 18);
    self.sourceLabel.frame = CGRectMake(titleLabelLeft, CGRectGetMaxY(self.cameraSwitchLabel.frame) + 30, maxLabelWidth, 20);
    self.cameraSourceButton.frame = CGRectMake(titleLabelLeft, CGRectGetMaxY(self.sourceLabel.frame) + 8, 60, 30);
    self.imageSourceButton.frame = CGRectMake(CGRectGetMaxX(self.cameraSourceButton.frame) +12, CGRectGetMaxY(self.sourceLabel.frame) + 8, 60, 30);
    self.uploadLabel.frame = CGRectMake(titleLabelLeft, CGRectGetMaxY(self.cameraSourceButton.frame) + 24, maxLabelWidth, 20);
    self.uploadTipLabel.frame = CGRectMake(titleLabelLeft, CGRectGetMaxY(self.uploadLabel.frame) + 2, maxLabelWidth, 20);
    [self.uploadTipLabel sizeToFit];
    
    self.uploadImagePlaceholderView.frame = CGRectMake(titleLabelLeft, CGRectGetMaxY(self.uploadTipLabel.frame) + 8, self.placeholderImageSize.width, self.placeholderImageSize.height);
    self.imageChangeLabel.frame = CGRectMake(0, self.uploadImagePlaceholderView.frame.size.height - 20 , self.uploadImagePlaceholderView.frame.size.width, 20);
    self.uploadImageView.frame = self.uploadImagePlaceholderView.bounds;
    self.uploadImageGestureView.frame = self.uploadImagePlaceholderView.bounds;
}

- (void)dismiss {
    if (self.cameraSwitch.on) {
        if (self.imageSourceButton.selected && (!self.placeholderImage || ![PLVFdUtil checkStringUseable:self.placeholderImageUrl])) {
            [self cameraSourceButtonAction];
        }
    }
    [super dismiss];
}

#pragma mark - [ Public Method ]

- (void)updateCameraSetting:(BOOL)isPicture placeholderImage:(UIImage * _Nullable)image placeholderImageUrl:(NSString * _Nullable)url {
    if ([PLVFdUtil checkStringUseable:url] && image) {
        self.placeholderImage = image;
        self.placeholderImageUrl = url;
        self.uploadImageView.image = image;
        self.imageChangeLabel.hidden = image && ![self allowChangeDefaultImageSource];
        [self updatePlaceHolderImageSizeWithSize:image.size];
        [self changeButton:self.cameraSourceButton selected:!isPicture];
        [self changeButton:self.imageSourceButton selected:isPicture];
        [self showUploadImage:isPicture];
    } else {
        [self changeButton:self.cameraSourceButton selected:YES];
        [self changeButton:self.imageSourceButton selected:NO];
        [self showUploadImage:NO];
    }
    
    [self showCameraSource:self.currentCameraOpen];
}

#pragma mark Getter

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:18];
        _titleLabel.textColor = PLV_UIColorFromRGB(@"#F0F1F5");
        _titleLabel.text = PLVLocalizedString(@"摄像头设置");
    }
    return _titleLabel;
}

- (UILabel *)cameraSwitchLabel {
    if (!_cameraSwitchLabel) {
        _cameraSwitchLabel = [[UILabel alloc] init];
        _cameraSwitchLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:14];
        _cameraSwitchLabel.textColor = PLV_UIColorFromRGB(@"#F0F1F5");
        _cameraSwitchLabel.text = PLVLocalizedString(@"本地摄像头");

    }
    return _cameraSwitchLabel;
}

- (UISwitch *)cameraSwitch {
    if (!_cameraSwitch) {
        _cameraSwitch = [[UISwitch alloc] init];
        _cameraSwitch.on = YES;
        _cameraSwitch.onTintColor = [PLVColorUtil colorFromHexString:@"#0080FF"];
        _cameraSwitch.transform = CGAffineTransformMakeScale(0.627, 0.58);
        [_cameraSwitch addTarget:self action:@selector(cameraSwitchChanged:) forControlEvents:UIControlEventValueChanged];
    }
    return _cameraSwitch;
}

- (UILabel *)sourceLabel {
    if (!_sourceLabel) {
        _sourceLabel = [[UILabel alloc] init];
        _sourceLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:14];
        _sourceLabel.textColor = PLV_UIColorFromRGB(@"#F0F1F5");
        _sourceLabel.text = PLVLocalizedString(@"画面来源");
    }
    return _sourceLabel;
}

- (UIButton *)cameraSourceButton {
    if (!_cameraSourceButton) {
        _cameraSourceButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_cameraSourceButton setTitle:PLVLocalizedString(@"摄像头") forState:UIControlStateNormal];
        [_cameraSourceButton setTitle:PLVLocalizedString(@"摄像头") forState:UIControlStateSelected];
        _cameraSourceButton.titleLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:14];;
        [_cameraSourceButton setTitleColor:PLV_UIColorFromRGB(@"#F0F1F5") forState:UIControlStateNormal];
        [_cameraSourceButton setTitleColor:PLV_UIColorFromRGB(@"#3E95FF") forState:UIControlStateSelected];
        _cameraSourceButton.layer.cornerRadius = 4;
        [self changeButton:_cameraSourceButton selected:YES];
        [_cameraSourceButton addTarget:self action:@selector(cameraSourceButtonAction) forControlEvents:UIControlEventTouchUpInside];
        
    }
    return _cameraSourceButton;
}

- (UIButton *)imageSourceButton {
    if (!_imageSourceButton) {
        _imageSourceButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_imageSourceButton setTitle:PLVLocalizedString(@"画面") forState:UIControlStateNormal];
        [_imageSourceButton setTitle:PLVLocalizedString(@"画面") forState:UIControlStateSelected];
        _imageSourceButton.titleLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:14];;
        [_imageSourceButton setTitleColor:PLV_UIColorFromRGB(@"#F0F1F5") forState:UIControlStateNormal];
        [_imageSourceButton setTitleColor:PLV_UIColorFromRGB(@"#3E95FF") forState:UIControlStateSelected];
        _imageSourceButton.layer.cornerRadius = 4;
        [self changeButton:_imageSourceButton selected:NO];
        [_imageSourceButton addTarget:self action:@selector(imageSourceButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _imageSourceButton;
}

- (UILabel *)uploadLabel {
    if (!_uploadLabel) {
        _uploadLabel = [[UILabel alloc] init];
        _uploadLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:14];
        _uploadLabel.textColor = PLV_UIColorFromRGB(@"#F0F1F5");
        _uploadLabel.text = PLVLocalizedString(@"上传图片");
        _uploadLabel.hidden = YES;
    }
    return _uploadLabel;
}

- (UILabel *)uploadTipLabel {
    if (!_uploadTipLabel) {
        _uploadTipLabel = [[UILabel alloc] init];
        _uploadTipLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:12];
        _uploadTipLabel.numberOfLines = 0;
        _uploadTipLabel.lineBreakMode = NSLineBreakByWordWrapping;
        _uploadTipLabel.textColor = PLV_UIColorFromRGBA(@"#F0F1F5", 0.6);
        _uploadTipLabel.text = PLVLocalizedString(@"支持不超过2M的png、jpg格式，建议尺寸200*200px");
        _uploadTipLabel.hidden = YES;
    }
    return _uploadTipLabel;
}

- (UIView *)uploadImagePlaceholderView {
    if (!_uploadImagePlaceholderView) {
        _uploadImagePlaceholderView = [[UIView alloc] init];
        _uploadImagePlaceholderView.clipsToBounds = YES;
        _uploadImagePlaceholderView.hidden = YES;
        _uploadImagePlaceholderView.layer.cornerRadius = 4;
    }
    return _uploadImagePlaceholderView;
}

- (UIImageView *)uploadImageView {
    if (!_uploadImageView) {
        _uploadImageView = [[UIImageView alloc] init];
        _uploadImageView.image = [PLVSAUtils imageForLiveroomResource:@"plvsa_liveroom_upload_image_placeholder"];
        _uploadImageView.contentMode = UIViewContentModeScaleAspectFit;
    }
    return _uploadImageView;
}

- (UILabel *)imageChangeLabel {
    if (!_imageChangeLabel) {
        _imageChangeLabel = [[UILabel alloc] init];
        _imageChangeLabel.font = [UIFont fontWithName:@"SourceHanSansCN-Regular" size:12];
        _imageChangeLabel.text = PLVLocalizedString(@"更换");
        _imageChangeLabel.textColor = PLV_UIColorFromRGB(@"#FFFFFF");
        _imageChangeLabel.textAlignment = NSTextAlignmentCenter;
        _imageChangeLabel.backgroundColor = PLV_UIColorFromRGBA(@"#000000", 0.6);
        _imageChangeLabel.hidden = YES;
    }
    return _imageChangeLabel;
}

- (PLVImagePickerViewController *)imagePicker {
    if (!_imagePicker) {
        NSInteger columnNumber = 4;
        _imagePicker = [[PLVImagePickerViewController alloc] initWithColumnNumber:columnNumber];
        _imagePicker.maxImagesCount = 1;
        _imagePicker.modalPresentationStyle = UIModalPresentationFullScreen;
        __weak typeof(self)weakSelf = self;
        [_imagePicker setDidFinishPickingPhotosHandle:^(NSArray<UIImage *> *photos, NSArray *assets, BOOL isSelectOriginalPhoto) {
            if ([photos isKindOfClass:NSArray.class]) {
                
                TOCropViewController *cropViewController = [[TOCropViewController alloc] initWithImage:photos.firstObject];
                cropViewController.delegate = weakSelf;
                [[PLVSAUtils sharedUtils].homeVC presentViewController:cropViewController animated:YES completion:nil];
                
                //clean选中缓存
                weakSelf.imagePicker.selectedAssets = [NSMutableArray array];
                [weakSelf.imagePicker popViewControllerAnimated:NO];
            }
        }];
        
        [_imagePicker setImagePickerControllerDidCancelHandle:^{
            //clean选中缓存
            weakSelf.imagePicker.selectedAssets = [NSMutableArray array];
            [weakSelf.imagePicker popViewControllerAnimated:NO];
        }];
    }
    return _imagePicker;
}

- (UIView *)uploadImageGestureView {
    if (!_uploadImageGestureView) {
        _uploadImageGestureView = [[UIView alloc] init];
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(uploadImageViewTapAction)];
        [_uploadImageGestureView addGestureRecognizer:tap];
    }
    return _uploadImageGestureView;
}

- (BOOL)allowChangeDefaultImageSource {
    PLVRoomData *roomData = [PLVRoomDataManager sharedManager].roomData;
    return ![PLVFdUtil checkStringUseable:roomData.userDefaultImageSourceUrl] || roomData.userDefaultAllowChangeDefaultImageSource;
}

#pragma mark Setter

- (void)setCurrentCameraOpen:(BOOL)currentCameraOpen {
    _currentCameraOpen = currentCameraOpen;
    self.cameraSwitch.on = currentCameraOpen;
    [self showCameraSource:currentCameraOpen];
}

#pragma mark - [ Private ]

- (void)changeButton:(UIButton *)button selected:(BOOL)selected {
    button.selected = selected;
    button.layer.borderColor = selected ? PLV_UIColorFromRGB(@"#3E95FF").CGColor :[UIColor clearColor].CGColor;
    button.layer.borderWidth = selected ? 0.5 : 0;
    [button setBackgroundColor:selected ? PLV_UIColorFromRGBA(@"#3E95FF", 0.12) : PLV_UIColorFromRGBA(@"#FFFFFF", 0.12)];
}

- (void)callbackCameraSetting {
    if (self.delegate && [self.delegate respondsToSelector:@selector(plvsaCameraSettingSheet:didTapCameraOpen:cameraSetting:placeholderImage:placeholderImageUrl:)]) {
        [self.delegate plvsaCameraSettingSheet:self didTapCameraOpen:self.cameraSwitch.on cameraSetting:self.imageSourceButton.selected && [PLVFdUtil checkStringUseable:self.placeholderImageUrl] placeholderImage:self.placeholderImage placeholderImageUrl:self.placeholderImageUrl];
    }
}

- (void)updatePlaceHolderImageSizeWithSize:(CGSize)size {
    BOOL isPad = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
    CGFloat sideLength = isPad ? 100 : 80;
    CGSize originSize = CGSizeMake(sideLength, sideLength);
    if (!CGSizeEqualToSize(size, CGSizeZero) && size.width > 0 && size.height > 0) {
        CGFloat scale = size.height / size.width;
        if (scale > 1) {
            originSize.width = sideLength / scale;
        } else if (scale < 1) {
            originSize.height = sideLength * scale;
        }
    }
    self.placeholderImageSize = originSize;
    plv_dispatch_main_async_safe(^{
        [self setNeedsLayout];
        [self layoutIfNeeded];
    })
}

- (void)showCameraSource:(BOOL)show {
    self.sourceLabel.hidden = !show;
    self.cameraSourceButton.hidden = !show;
    self.imageSourceButton.hidden = !show;
    [self showUploadImage:show && !self.cameraSourceButton.selected];
}

- (void)showUploadImage:(BOOL)show {
    self.uploadLabel.hidden = !show;
    self.uploadTipLabel.hidden = !show;
    self.uploadImagePlaceholderView.hidden = !show;
}

#pragma mark - [ Action ]

- (void)cameraSwitchChanged:(UISwitch *)sender {
    [self showCameraSource:sender.on];
    [self callbackCameraSetting];
}

- (void)cameraSourceButtonAction {
    if (self.cameraSourceButton.selected) {
        return;
    }
    [self changeButton:self.cameraSourceButton selected:YES];
    [self changeButton:self.imageSourceButton selected:NO];
    [self showUploadImage:NO];
    [self callbackCameraSetting];
}

- (void)imageSourceButtonAction {
    if (self.imageSourceButton.selected) {
        return;
    }
    [self changeButton:self.cameraSourceButton selected:NO];
    [self changeButton:self.imageSourceButton selected:YES];
    [self showUploadImage:YES];
    [self callbackCameraSetting];
}

- (void)uploadImageViewTapAction {
    if (![self allowChangeDefaultImageSource]) {
        return;
    }
    __weak typeof(self)weakSelf = self;
    [PLVAuthorizationManager requestAuthorizationWithType:PLVAuthorizationTypePhotoLibrary completion:^(BOOL granted) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (granted) {
                [[PLVSAUtils sharedUtils].homeVC presentViewController:weakSelf.imagePicker animated:YES completion:nil];
            } else {
                [PLVSAUtils showAlertWithMessage:PLVLocalizedString(@"应用需要获取您的相册权限，请前往设置") cancelActionTitle:PLVLocalizedString(@"取消") cancelActionBlock:nil confirmActionTitle:PLVLocalizedString(@"设置") confirmActionBlock:^{
                    NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
                    if ([[UIApplication sharedApplication] canOpenURL:url]) {
                        [[UIApplication sharedApplication] openURL:url];
                    }
                }];
            }
        });
    }];
}

#pragma mark - [ Delegate ]

#pragma mark TOCropViewControllerDelegate

- (void)cropViewController:(nonnull TOCropViewController *)cropViewController
            didCropToImage:(nonnull UIImage *)image withRect:(CGRect)cropRect
                     angle:(NSInteger)angle {
    NSString *imageName = [NSString stringWithFormat:@"chat_img_iOS_%@.png", [PLVFdUtil curTimeStamp]];
    
    __weak typeof(self) weakSelf = self;
    [PLVLiveVideoAPI uploadImage:image imageName:imageName progress:^(float fractionCompleted) {
        
    } success:^(NSDictionary * _Nonnull tokenDict, NSString * _Nonnull key, NSString * _Nonnull imageName) {
        NSString *host = PLV_SafeStringForDictKey(tokenDict, @"host") ?: @"";
        NSString *imageUrl = [NSString stringWithFormat:@"https://%@/%@", host, (key ?: @"")];
        weakSelf.placeholderImage = image;
        weakSelf.placeholderImageUrl = imageUrl;
        weakSelf.uploadImageView.image = image;
        weakSelf.imageChangeLabel.hidden = NO;
        [weakSelf updatePlaceHolderImageSizeWithSize:cropRect.size];
        [weakSelf callbackCameraSetting];
    } fail:^(NSError * _Nonnull error) {
        [PLVSAUtils showToastWithMessage:@"图片上传失败" inView:weakSelf];
    }];

    [cropViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)cropViewController:(nonnull TOCropViewController *)cropViewController
        didFinishCancelled:(BOOL)cancelled {
    //clean选中缓存
    self.imagePicker.selectedAssets = [NSMutableArray array];
    [cropViewController dismissViewControllerAnimated:YES completion:nil];
}

@end
