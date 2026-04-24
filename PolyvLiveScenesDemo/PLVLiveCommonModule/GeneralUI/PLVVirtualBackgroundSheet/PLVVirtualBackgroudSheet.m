//
//  PLVVirtualBackgroudSheet.m
//  PolyvLiveScenesDemo
//
//  Created by polyv on 2025/4/10.
//  Copyright © 2025 PLV. All rights reserved.
//

#import "PLVVirtualBackgroudSheet.h"
#import "PLVVirtualBackgroudCollectionView.h"
#import "PLVImagePickerViewController.h"
#import "PLVVirtualBackgroundUtil.h"
#import "PLVVirtualBackgroundColorSampler.h"
#import "PLVMultiLanguageManager.h"
#import <PLVFoundationSDK/PLVFoundationSDK.h>
#import <QuartzCore/QuartzCore.h>

const NSInteger kMaxCustomImageItem = 3;

static const float kPLVDefaultSimilarity = 0.40f;
static const float kPLVDefaultSmoothness = 0.10f;
static const float kPLVDefaultSpill = 0.35f;
static const NSTimeInterval kPLVSliderEmitInterval = 0.03;
static const CGFloat kPLVEyedropperFeedbackCircleSize = 56.0;
static const CGFloat kPLVEyedropperFeedbackSpacing = 10.0;
static const CGFloat kPLVEyedropperSamplingSquareSize = 24.0;
static const CGFloat kPLVEyedropperCrosshairLineThickness = 1.5;
static const CGFloat kPLVEyedropperCrosshairCenterGap = 6.0;
static const CGFloat kPLVEyedropperFingerGap = 47.0;
static const NSTimeInterval kPLVSamplingContextRefreshInterval = 0.5;
static const CGFloat kPLVEyedropperDefaultY = 300.0;
static const CGFloat kPLVEyedropperEdgeMargin = 8.0;

typedef NS_ENUM(NSInteger, PLVVirtualBackgroundKeyColorType) {
    PLVVirtualBackgroundKeyColorTypeGreen = 0,
    PLVVirtualBackgroundKeyColorTypeBlue,
    PLVVirtualBackgroundKeyColorTypeCustom
};

typedef NS_ENUM(NSInteger, PLVVirtualBackgroundSliderType) {
    PLVVirtualBackgroundSliderTypeSimilarity = 0,
    PLVVirtualBackgroundSliderTypeSmoothness,
    PLVVirtualBackgroundSliderTypeSpill
};

@interface PLVVirtualBackgroudSheet () <PLVVirtualBackgroudCollectionViewDelegate>

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *scrollContentView;
@property (nonatomic, strong) PLVVirtualBackgroudCollectionView *collectionView;
@property (nonatomic, strong) UILabel *titleLable;
@property (nonatomic, strong) UILabel *greenScreenTitleLabel;
@property (nonatomic, strong) UISwitch *greenScreenSwitch;
@property (nonatomic, strong) UIView *greenScreenContainerView;
@property (nonatomic, strong) UILabel *keyColorTitleLabel;
@property (nonatomic, strong) UIButton *greenColorButton;
@property (nonatomic, strong) UIButton *blueColorButton;
@property (nonatomic, strong) UIButton *customColorButton;
@property (nonatomic, strong) UIButton *advancedToggleButton;
@property (nonatomic, strong) UILabel *advancedTitleLabel;
@property (nonatomic, strong) UIButton *restoreRecommendButton;
@property (nonatomic, strong) UIImageView *advancedArrowView;
@property (nonatomic, strong) UIView *advancedDetailView;
@property (nonatomic, strong) UILabel *similarityLabel;
@property (nonatomic, strong) UISlider *similaritySlider;
@property (nonatomic, strong) UILabel *smoothnessLabel;
@property (nonatomic, strong) UISlider *smoothnessSlider;
@property (nonatomic, strong) UILabel *spillLabel;
@property (nonatomic, strong) UISlider *spillSlider;
@property (nonatomic, strong) UIView *samplingInteractionView;
@property (nonatomic, strong) UIView *eyedropperContainerView;
@property (nonatomic, strong) UIView *eyedropperFeedbackCircleView;
@property (nonatomic, strong) UIView *eyedropperSamplingSquareView;

@property (nonatomic, assign) BOOL greenScreenEnabled;
@property (nonatomic, assign) BOOL advancedExpanded;
@property (nonatomic, assign) BOOL colorPickingActive;
@property (nonatomic, assign) float keyColorR;
@property (nonatomic, assign) float keyColorG;
@property (nonatomic, assign) float keyColorB;
@property (nonatomic, assign) PLVVirtualBackgroundKeyColorType selectedKeyColorType;
@property (nonatomic, assign) NSTimeInterval lastSimilarityEmitTime;
@property (nonatomic, assign) NSTimeInterval lastSmoothnessEmitTime;
@property (nonatomic, assign) NSTimeInterval lastSpillEmitTime;
@property (nonatomic, strong) UIImage *samplingSnapshot;
@property (nonatomic, assign) CGRect samplingFrameInHostView;
@property (nonatomic, weak) UIView *samplingHostView;
@property (nonatomic, assign) NSTimeInterval lastSamplingContextRefreshTime;

@end

@implementation PLVVirtualBackgroudSheet

- (instancetype)initWithSheetHeight:(CGFloat)sheetHeight sheetLandscapeWidth:(CGFloat)sheetLandscapeWidth {
    self = [super initWithSheetHeight:sheetHeight sheetLandscapeWidth:sheetLandscapeWidth];
    if (self) {
        self.greenScreenEnabled = NO;
        self.advancedExpanded = NO;
        self.colorPickingActive = NO;
        self.keyColorR = 0.0f;
        self.keyColorG = 1.0f;
        self.keyColorB = 0.0f;
        self.selectedKeyColorType = PLVVirtualBackgroundKeyColorTypeGreen;
        self.samplingFrameInHostView = CGRectZero;
        self.lastSamplingContextRefreshTime = 0;
        [self initUI];
    }
    return self;
}

- (void)dealloc {
    [self.samplingInteractionView removeFromSuperview];
}

- (void)initUI {
    [self.contentView addSubview:self.scrollView];
    [self.scrollView addSubview:self.scrollContentView];
    [self.scrollContentView addSubview:self.titleLable];
    [self.scrollContentView addSubview:self.greenScreenTitleLabel];
    [self.scrollContentView addSubview:self.greenScreenSwitch];
    [self.scrollContentView addSubview:self.greenScreenContainerView];
    [self.greenScreenContainerView addSubview:self.keyColorTitleLabel];
    [self.greenScreenContainerView addSubview:self.greenColorButton];
    [self.greenScreenContainerView addSubview:self.blueColorButton];
    [self.greenScreenContainerView addSubview:self.customColorButton];
    [self.greenScreenContainerView addSubview:self.advancedToggleButton];
    [self.greenScreenContainerView addSubview:self.advancedTitleLabel];
    [self.greenScreenContainerView addSubview:self.restoreRecommendButton];
    [self.greenScreenContainerView addSubview:self.advancedArrowView];
    [self.greenScreenContainerView addSubview:self.advancedDetailView];
    [self.advancedDetailView addSubview:self.similarityLabel];
    [self.advancedDetailView addSubview:self.similaritySlider];
    [self.advancedDetailView addSubview:self.smoothnessLabel];
    [self.advancedDetailView addSubview:self.smoothnessSlider];
    [self.advancedDetailView addSubview:self.spillLabel];
    [self.advancedDetailView addSubview:self.spillSlider];
    [self.scrollContentView addSubview:self.collectionView];
    [self.samplingInteractionView addSubview:self.eyedropperContainerView];
    [self.eyedropperContainerView addSubview:self.eyedropperFeedbackCircleView];
    [self.eyedropperContainerView addSubview:self.eyedropperSamplingSquareView];

    [self updateKeyColorButtonStates];
    [self updateGreenScreenViews];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.scrollView.frame = self.contentView.bounds;
    self.scrollContentView.frame = CGRectMake(0, 0, self.scrollView.bounds.size.width, self.scrollContentView.bounds.size.height);

    self.titleLable.frame = CGRectMake(32, 32, 200, 18);
    CGFloat sideInset = 32;
    CGFloat contentWidth = self.scrollView.bounds.size.width - sideInset * 2;

    self.greenScreenTitleLabel.frame = CGRectMake(32, CGRectGetMaxY(self.titleLable.frame) + 20, 180, 20);
    self.greenScreenSwitch.frame = CGRectMake(self.scrollView.bounds.size.width - sideInset - 51, CGRectGetMinY(self.greenScreenTitleLabel.frame) - 4, 51, 31);

    CGFloat startX = 32;
    CGFloat startY = CGRectGetMaxY(self.greenScreenTitleLabel.frame) + 12;
    CGFloat containerHeight = 0;
    if (self.greenScreenEnabled) {
        containerHeight = self.advancedExpanded ? 208 : 110;
    }
    self.greenScreenContainerView.frame = CGRectMake(startX, startY, contentWidth, containerHeight);

    self.keyColorTitleLabel.frame = CGRectMake(0, 2, 120, 18);
    CGFloat colorButtonY = CGRectGetMaxY(self.keyColorTitleLabel.frame) + 10;
    CGFloat colorButtonWidth = 48;
    CGFloat colorButtonHeight = 36;
    self.greenColorButton.frame = CGRectMake(0, colorButtonY, colorButtonWidth, colorButtonHeight);
    self.blueColorButton.frame = CGRectMake(CGRectGetMaxX(self.greenColorButton.frame) + 12, colorButtonY, colorButtonWidth, colorButtonHeight);
    self.customColorButton.frame = CGRectMake(CGRectGetMaxX(self.blueColorButton.frame) + 12, colorButtonY, colorButtonWidth, colorButtonHeight);

    CGFloat advancedY = CGRectGetMaxY(self.greenColorButton.frame) + 14;
    self.advancedTitleLabel.frame = CGRectMake(0, advancedY, 180, 18);
    self.advancedArrowView.frame = CGRectMake(self.greenScreenContainerView.bounds.size.width - 14, advancedY + 2, 12, 12);
    self.restoreRecommendButton.frame = CGRectMake(CGRectGetMaxX(self.advancedTitleLabel.frame) + 12, advancedY - 4, 88, 28);
    self.advancedToggleButton.frame = CGRectMake(0, advancedY - 6, self.greenScreenContainerView.bounds.size.width, 30);

    CGFloat advancedDetailHeight = self.advancedExpanded ? 92 : 0;
    self.advancedDetailView.frame = CGRectMake(0, CGRectGetMaxY(self.advancedToggleButton.frame) + 6, self.greenScreenContainerView.bounds.size.width, advancedDetailHeight);
    CGFloat sliderWidth = self.advancedDetailView.bounds.size.width - 66;
    self.similarityLabel.frame = CGRectMake(0, 0, 56, 18);
    self.similaritySlider.frame = CGRectMake(62, -2, sliderWidth, 22);
    self.smoothnessLabel.frame = CGRectMake(0, 34, 56, 18);
    self.smoothnessSlider.frame = CGRectMake(62, 32, sliderWidth, 22);
    self.spillLabel.frame = CGRectMake(0, 68, 56, 18);
    self.spillSlider.frame = CGRectMake(62, 66, sliderWidth, 22);

    CGFloat collectionStartY = CGRectGetMaxY(self.greenScreenContainerView.frame) + 16;
    CGFloat collectionHeight = [self.collectionView preferredContentHeightForWidth:contentWidth];
    self.collectionView.frame = CGRectMake(startX, collectionStartY, contentWidth, MAX(collectionHeight, 120));
    
    CGFloat contentHeight = CGRectGetMaxY(self.collectionView.frame) + 24;
    self.scrollContentView.frame = CGRectMake(0, 0, self.scrollView.bounds.size.width, contentHeight);
    self.scrollView.contentSize = CGSizeMake(self.scrollView.bounds.size.width, MAX(contentHeight, self.scrollView.bounds.size.height));

    [self updateSamplingInteractionViewFrame];
}

#pragma mark -- Private

- (UIViewController *)viewController {
    UIViewController *vc = nil;

    UIResponder *responder = self;
    while (responder) {
        if ([responder isKindOfClass:[UIViewController class]]) {
            vc = (UIViewController *)responder;
            break;
        }
        responder = [responder nextResponder];
    }

    return vc;
}

- (void)showImagePicker {
    if (self.collectionView.customImgCoutn >= kMaxCustomImageItem) {
        return;
    }
    PLVImagePickerViewController *imagePickerVC = [[PLVImagePickerViewController alloc] initWithColumnNumber:4];
    imagePickerVC.allowPickingOriginalPhoto = YES;
    imagePickerVC.allowPickingVideo = NO;
    imagePickerVC.allowTakePicture = NO;
    imagePickerVC.allowTakeVideo = NO;
    imagePickerVC.maxImagesCount = 1;
    __weak typeof(self) weakSelf = self;

    [imagePickerVC setDidFinishPickingPhotosHandle:^(NSArray<UIImage *> *photos, NSArray *assets, BOOL isSelectOriginalPhoto) {
        if (photos.count > 0) {
            [weakSelf.collectionView addUploadedImage:photos.firstObject];
        }
    }];

    [imagePickerVC setImagePickerControllerDidCancelHandle:^{}];
    [[self viewController] presentViewController:imagePickerVC animated:YES completion:nil];
}

- (void)updateGreenScreenViews {
    self.greenScreenContainerView.hidden = !self.greenScreenEnabled;
    self.advancedDetailView.hidden = !self.advancedExpanded;
    self.restoreRecommendButton.hidden = !self.greenScreenEnabled;
    if (!self.greenScreenEnabled && self.colorPickingActive) {
        [self exitColorPickingModeCommit:NO sampledColor:nil];
    }
    [UIView animateWithDuration:0.2 animations:^{
        self.advancedArrowView.transform = self.advancedExpanded ? CGAffineTransformMakeRotation((CGFloat)M_PI_2) : CGAffineTransformIdentity;
        [self setNeedsLayout];
        [self layoutIfNeeded];
    }];
}

- (void)attachSamplingInteractionViewIfNeeded {
    UIViewController *vc = [self viewController];
    UIView *hostView = vc.view ?: self.superview;
    if (!hostView) {
        return;
    }
    self.samplingHostView = hostView;
    if (self.samplingInteractionView.superview != hostView) {
        [self.samplingInteractionView removeFromSuperview];
        [hostView addSubview:self.samplingInteractionView];
    }
    [hostView bringSubviewToFront:self.samplingInteractionView];
    [self updateSamplingInteractionViewFrame];
}

- (void)updateSamplingInteractionViewFrame {
    UIView *hostView = self.samplingInteractionView.superview ?: self.samplingHostView;
    if (!hostView) {
        return;
    }
    self.samplingInteractionView.frame = hostView.bounds;
}

- (void)applyKeyColorWithR:(float)r g:(float)g b:(float)b type:(PLVVirtualBackgroundKeyColorType)type notify:(BOOL)notify {
    self.keyColorR = r;
    self.keyColorG = g;
    self.keyColorB = b;
    self.selectedKeyColorType = type;
    [self updateKeyColorButtonStates];

    if (notify && self.delegate && [self.delegate respondsToSelector:@selector(virtualBackgroudSheet:didChangeKeyColorWithR:g:b:)]) {
        [self.delegate virtualBackgroudSheet:self didChangeKeyColorWithR:r g:g b:b];
    }
}

- (void)updateKeyColorButtonStates {
    UIColor *selectedBorderColor = [UIColor colorWithRed:0.50 green:0.74 blue:1.00 alpha:1.0];
    [self applyKeyColorButtonStyle:self.greenColorButton
                          selected:(self.selectedKeyColorType == PLVVirtualBackgroundKeyColorTypeGreen)
                   selectedBorder:selectedBorderColor];
    [self applyKeyColorButtonStyle:self.blueColorButton
                          selected:(self.selectedKeyColorType == PLVVirtualBackgroundKeyColorTypeBlue)
                   selectedBorder:selectedBorderColor];

    BOOL customSelected = (self.selectedKeyColorType == PLVVirtualBackgroundKeyColorTypeCustom);
    [self applyKeyColorButtonStyle:self.customColorButton selected:customSelected selectedBorder:selectedBorderColor];
    if (customSelected) {
        self.customColorButton.backgroundColor = [UIColor colorWithRed:self.keyColorR green:self.keyColorG blue:self.keyColorB alpha:1.0];
        [self.customColorButton setTitle:nil forState:UIControlStateNormal];
    } else {
        self.customColorButton.backgroundColor = [UIColor colorWithWhite:1 alpha:0.08];
        if (self.customColorButton.currentImage == nil) {
            [self.customColorButton setTitle:PLVLocalizedString(@"取色") forState:UIControlStateNormal];
        }
    }

    if (self.colorPickingActive) {
        self.customColorButton.layer.borderColor = [UIColor colorWithRed:0.37 green:0.63 blue:1.0 alpha:1.0].CGColor;
    }
}

- (void)applyKeyColorButtonStyle:(UIButton *)button selected:(BOOL)selected selectedBorder:(UIColor *)selectedBorder {
    button.layer.borderWidth = selected ? 2.0 : 1.0;
    button.layer.borderColor = (selected ? selectedBorder : [UIColor colorWithWhite:1 alpha:0.25]).CGColor;
    button.layer.shadowColor = selected ? [UIColor colorWithRed:0.51 green:0.74 blue:1 alpha:1].CGColor : UIColor.clearColor.CGColor;
    button.layer.shadowOpacity = selected ? 0.55 : 0;
    button.layer.shadowRadius = selected ? 8 : 0;
    button.layer.shadowOffset = CGSizeZero;
}

- (void)enterColorPickingMode {
    if (!self.greenScreenEnabled || self.colorPickingActive) {
        return;
    }
    [self attachSamplingInteractionViewIfNeeded];
    self.colorPickingActive = YES;
    self.samplingInteractionView.hidden = NO;
    self.samplingInteractionView.userInteractionEnabled = YES;
    self.eyedropperContainerView.hidden = NO;
    self.hidden = YES;
    CGSize containerSize = [self eyedropperContainerSize];
    CGFloat defaultX = (self.samplingInteractionView.bounds.size.width - containerSize.width) * 0.5;
    CGRect defaultFrame = [self adjustedEyedropperContainerFrameForRawFrame:CGRectMake(defaultX, kPLVEyedropperDefaultY, containerSize.width, containerSize.height)];
    self.eyedropperContainerView.frame = defaultFrame;
    [self updateEyedropperSubviewsLayout];
    self.eyedropperFeedbackCircleView.backgroundColor = [UIColor colorWithRed:self.keyColorR green:self.keyColorG blue:self.keyColorB alpha:1.0];
    [self refreshSamplingContext];
    [self updateKeyColorButtonStates];
}

- (void)exitColorPickingModeCommit:(BOOL)commit sampledColor:(UIColor *)sampledColor {
    if (!self.colorPickingActive) {
        return;
    }
    self.colorPickingActive = NO;
    self.samplingInteractionView.hidden = YES;
    self.samplingInteractionView.userInteractionEnabled = NO;
    self.eyedropperContainerView.hidden = YES;
    self.hidden = NO;

    if (commit && sampledColor) {
        CGFloat r = 0, g = 0, b = 0, a = 0;
        if ([sampledColor getRed:&r green:&g blue:&b alpha:&a]) {
            [self applyKeyColorWithR:r g:g b:b type:PLVVirtualBackgroundKeyColorTypeCustom notify:YES];
        }
    }

    self.samplingSnapshot = nil;
    self.samplingFrameInHostView = CGRectZero;
    self.lastSamplingContextRefreshTime = 0;
    [self updateKeyColorButtonStates];
}

- (void)refreshSamplingContext {
    if (!self.delegate) {
        self.samplingSnapshot = nil;
        self.samplingFrameInHostView = CGRectZero;
        return;
    }

    if ([self.delegate respondsToSelector:@selector(previewSamplingSnapshotInVirtualBackgroudSheet:)]) {
        self.samplingSnapshot = [self.delegate previewSamplingSnapshotInVirtualBackgroudSheet:self];
    } else {
        self.samplingSnapshot = nil;
    }

    if ([self.delegate respondsToSelector:@selector(previewSamplingFrameInVirtualBackgroudSheet:)]) {
        self.samplingFrameInHostView = [self.delegate previewSamplingFrameInVirtualBackgroudSheet:self];
    } else if (self.samplingHostView) {
        self.samplingFrameInHostView = self.samplingHostView.bounds;
    } else if (self.superview) {
        self.samplingFrameInHostView = self.superview.bounds;
    } else {
        self.samplingFrameInHostView = CGRectZero;
    }
}

- (CGSize)eyedropperContainerSize {
    CGFloat width = MAX(kPLVEyedropperFeedbackCircleSize, kPLVEyedropperSamplingSquareSize);
    CGFloat height = kPLVEyedropperFeedbackCircleSize + kPLVEyedropperFeedbackSpacing + kPLVEyedropperSamplingSquareSize;
    return CGSizeMake(width, height);
}

- (CGPoint)samplingAnchorCenterInContainer {
    CGSize containerSize = [self eyedropperContainerSize];
    CGFloat centerX = containerSize.width * 0.5;
    CGFloat originY = containerSize.height - kPLVEyedropperSamplingSquareSize;
    return CGPointMake(centerX, originY + kPLVEyedropperSamplingSquareSize * 0.5);
}

- (void)updateEyedropperSubviewsLayout {
    CGSize containerSize = [self eyedropperContainerSize];
    CGFloat circleX = (containerSize.width - kPLVEyedropperFeedbackCircleSize) * 0.5;
    self.eyedropperFeedbackCircleView.frame = CGRectMake(circleX, 0, kPLVEyedropperFeedbackCircleSize, kPLVEyedropperFeedbackCircleSize);

    CGFloat crosshairX = (containerSize.width - kPLVEyedropperSamplingSquareSize) * 0.5;
    CGFloat crosshairY = containerSize.height - kPLVEyedropperSamplingSquareSize;
    self.eyedropperSamplingSquareView.frame = CGRectMake(crosshairX, crosshairY, kPLVEyedropperSamplingSquareSize, kPLVEyedropperSamplingSquareSize);
}

- (CGRect)adjustedEyedropperContainerFrameForRawFrame:(CGRect)rawFrame {
    CGRect frame = rawFrame;
    CGFloat maxX = self.samplingInteractionView.bounds.size.width - frame.size.width - kPLVEyedropperEdgeMargin;
    CGFloat maxY = self.samplingInteractionView.bounds.size.height - frame.size.height - kPLVEyedropperEdgeMargin;
    frame.origin.x = MIN(MAX(frame.origin.x, kPLVEyedropperEdgeMargin), MAX(maxX, kPLVEyedropperEdgeMargin));
    frame.origin.y = MIN(MAX(frame.origin.y, kPLVEyedropperEdgeMargin), MAX(maxY, kPLVEyedropperEdgeMargin));
    return frame;
}

- (void)handleColorSamplingAtPoint:(CGPoint)point commit:(BOOL)commit {
    if (!self.colorPickingActive) {
        return;
    }

    NSTimeInterval now = CACurrentMediaTime();
    BOOL needsRefreshSamplingContext = (commit ||
                                        !self.samplingSnapshot ||
                                        now - self.lastSamplingContextRefreshTime >= kPLVSamplingContextRefreshInterval);
    if (needsRefreshSamplingContext) {
        [self refreshSamplingContext];
        self.lastSamplingContextRefreshTime = now;
    }
    if (!self.samplingSnapshot) {
        [self exitColorPickingModeCommit:NO sampledColor:nil];
        return;
    }

    UIView *hostView = self.samplingInteractionView.superview ?: self.samplingHostView ?: self.superview;
    if (!hostView) {
        [self exitColorPickingModeCommit:NO sampledColor:nil];
        return;
    }
    CGSize containerSize = [self eyedropperContainerSize];
    CGPoint anchorCenterInContainer = [self samplingAnchorCenterInContainer];
    CGPoint targetAnchorInInteraction = CGPointMake(point.x, point.y - kPLVEyedropperFingerGap);
    CGFloat containerX = targetAnchorInInteraction.x - anchorCenterInContainer.x;
    CGFloat containerY = targetAnchorInInteraction.y - anchorCenterInContainer.y;
    CGRect rawContainerFrame = CGRectMake(containerX, containerY, containerSize.width, containerSize.height);
    self.eyedropperContainerView.frame = [self adjustedEyedropperContainerFrameForRawFrame:rawContainerFrame];
    [self updateEyedropperSubviewsLayout];

    CGPoint anchorCenterInContainerByFrame = CGPointMake(CGRectGetMidX(self.eyedropperSamplingSquareView.frame), CGRectGetMidY(self.eyedropperSamplingSquareView.frame));
    CGPoint anchorPointInInteraction = [self.eyedropperContainerView convertPoint:anchorCenterInContainerByFrame
                                                                            toView:self.samplingInteractionView];
    CGPoint hostPoint = [self.samplingInteractionView convertPoint:anchorPointInInteraction toView:hostView];
    CGRect samplingFrame = self.samplingFrameInHostView;
    if (CGRectIsEmpty(samplingFrame)) {
        samplingFrame = hostView.bounds;
    }
    if (CGRectIsEmpty(samplingFrame)) {
        [self exitColorPickingModeCommit:NO sampledColor:nil];
        return;
    }

    CGFloat clampedX = MIN(MAX(hostPoint.x, CGRectGetMinX(samplingFrame)), CGRectGetMaxX(samplingFrame));
    CGFloat clampedY = MIN(MAX(hostPoint.y, CGRectGetMinY(samplingFrame)), CGRectGetMaxY(samplingFrame));

    CGFloat normalizedX = (clampedX - CGRectGetMinX(samplingFrame)) / MAX(CGRectGetWidth(samplingFrame), 1.0);
    CGFloat normalizedY = (clampedY - CGRectGetMinY(samplingFrame)) / MAX(CGRectGetHeight(samplingFrame), 1.0);
    normalizedX = MIN(MAX(normalizedX, 0.0), 1.0);
    normalizedY = MIN(MAX(normalizedY, 0.0), 1.0);

    UIColor *sampledColor = PLVVirtualBackgroundSampleColor(self.samplingSnapshot, CGPointMake(normalizedX, normalizedY));
    if (!sampledColor) {
        if (commit) {
            [self exitColorPickingModeCommit:NO sampledColor:nil];
        }
        return;
    }

    self.eyedropperFeedbackCircleView.backgroundColor = sampledColor;

    if (commit) {
        [self exitColorPickingModeCommit:YES sampledColor:sampledColor];
    }
}

- (void)emitSliderValueWithType:(PLVVirtualBackgroundSliderType)type force:(BOOL)force {
    NSTimeInterval now = CACurrentMediaTime();
    switch (type) {
        case PLVVirtualBackgroundSliderTypeSimilarity: {
            if (!force && now - self.lastSimilarityEmitTime < kPLVSliderEmitInterval) {
                return;
            }
            self.lastSimilarityEmitTime = now;
            if (self.delegate && [self.delegate respondsToSelector:@selector(virtualBackgroudSheet:didChangeSimilarity:)]) {
                [self.delegate virtualBackgroudSheet:self didChangeSimilarity:self.similaritySlider.value];
            }
        } break;
        case PLVVirtualBackgroundSliderTypeSmoothness: {
            if (!force && now - self.lastSmoothnessEmitTime < kPLVSliderEmitInterval) {
                return;
            }
            self.lastSmoothnessEmitTime = now;
            if (self.delegate && [self.delegate respondsToSelector:@selector(virtualBackgroudSheet:didChangeSmoothness:)]) {
                [self.delegate virtualBackgroudSheet:self didChangeSmoothness:self.smoothnessSlider.value];
            }
        } break;
        case PLVVirtualBackgroundSliderTypeSpill: {
            if (!force && now - self.lastSpillEmitTime < kPLVSliderEmitInterval) {
                return;
            }
            self.lastSpillEmitTime = now;
            if (self.delegate && [self.delegate respondsToSelector:@selector(virtualBackgroudSheet:didChangeSpill:)]) {
                [self.delegate virtualBackgroudSheet:self didChangeSpill:self.spillSlider.value];
            }
        } break;
    }
}

#pragma mark - Green Screen Events

- (void)greenScreenSwitchValueChanged:(UISwitch *)sender {
    self.greenScreenEnabled = sender.isOn;
    [self updateGreenScreenViews];
    if (self.delegate && [self.delegate respondsToSelector:@selector(virtualBackgroudSheet:didChangeGreenScreenEnabled:)]) {
        [self.delegate virtualBackgroudSheet:self didChangeGreenScreenEnabled:self.greenScreenEnabled];
    }
    if (self.greenScreenEnabled) {
        [self applyKeyColorWithR:self.keyColorR g:self.keyColorG b:self.keyColorB type:self.selectedKeyColorType notify:YES];
        [self emitSliderValueWithType:PLVVirtualBackgroundSliderTypeSimilarity force:YES];
        [self emitSliderValueWithType:PLVVirtualBackgroundSliderTypeSmoothness force:YES];
        [self emitSliderValueWithType:PLVVirtualBackgroundSliderTypeSpill force:YES];
    }
}

- (void)advancedToggleButtonAction:(UIButton *)sender {
    self.advancedExpanded = !self.advancedExpanded;
    [self updateGreenScreenViews];
}

- (void)restoreRecommendButtonAction:(UIButton *)sender {
    self.similaritySlider.value = kPLVDefaultSimilarity;
    self.smoothnessSlider.value = kPLVDefaultSmoothness;
    self.spillSlider.value = kPLVDefaultSpill;
    [self emitSliderValueWithType:PLVVirtualBackgroundSliderTypeSimilarity force:YES];
    [self emitSliderValueWithType:PLVVirtualBackgroundSliderTypeSmoothness force:YES];
    [self emitSliderValueWithType:PLVVirtualBackgroundSliderTypeSpill force:YES];
}

- (void)keyColorButtonAction:(UIButton *)sender {
    if (sender == self.greenColorButton) {
        [self exitColorPickingModeCommit:NO sampledColor:nil];
        [self applyKeyColorWithR:0.0f g:1.0f b:0.0f type:PLVVirtualBackgroundKeyColorTypeGreen notify:YES];
    } else if (sender == self.blueColorButton) {
        [self exitColorPickingModeCommit:NO sampledColor:nil];
        [self applyKeyColorWithR:0.0f g:0.0f b:1.0f type:PLVVirtualBackgroundKeyColorTypeBlue notify:YES];
    } else {
        [self enterColorPickingMode];
    }
}

- (void)similaritySliderValueChanged:(UISlider *)sender {
    [self emitSliderValueWithType:PLVVirtualBackgroundSliderTypeSimilarity force:NO];
}

- (void)smoothnessSliderValueChanged:(UISlider *)sender {
    [self emitSliderValueWithType:PLVVirtualBackgroundSliderTypeSmoothness force:NO];
}

- (void)spillSliderValueChanged:(UISlider *)sender {
    [self emitSliderValueWithType:PLVVirtualBackgroundSliderTypeSpill force:NO];
}

- (void)sliderTouchUp:(UISlider *)sender {
    if (sender == self.similaritySlider) {
        [self emitSliderValueWithType:PLVVirtualBackgroundSliderTypeSimilarity force:YES];
    } else if (sender == self.smoothnessSlider) {
        [self emitSliderValueWithType:PLVVirtualBackgroundSliderTypeSmoothness force:YES];
    } else if (sender == self.spillSlider) {
        [self emitSliderValueWithType:PLVVirtualBackgroundSliderTypeSpill force:YES];
    }
}

- (void)samplingPanGestureAction:(UIPanGestureRecognizer *)gesture {
    CGPoint point = [gesture locationInView:self.samplingInteractionView];
    if (gesture.state == UIGestureRecognizerStateBegan || gesture.state == UIGestureRecognizerStateChanged) {
        [self handleColorSamplingAtPoint:point commit:NO];
    } else if (gesture.state == UIGestureRecognizerStateEnded || gesture.state == UIGestureRecognizerStateCancelled || gesture.state == UIGestureRecognizerStateFailed) {
        [self handleColorSamplingAtPoint:point commit:YES];
    }
}

- (void)samplingTapGestureAction:(UITapGestureRecognizer *)gesture {
    CGPoint point = [gesture locationInView:self.samplingInteractionView];
    [self handleColorSamplingAtPoint:point commit:YES];
}

#pragma mark - PLVVirtualBackgroudCollectionViewDelegate

- (void)virtualBackgroudCollectionView:(PLVVirtualBackgroudCollectionView *)collectionView data:(nonnull PLVVirtualBackgroudModel *)model {
    if (model.type == PLVVirtualBackgroudCellDefault) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(virtualBackgroudSheet:matType:image:)]) {
            [self.delegate virtualBackgroudSheet:self matType:PLVVirtualBackgroudMatTypeNone image:nil];
        }
    } else if (model.type == PLVVirtualBackgroudCellBlur) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(virtualBackgroudSheet:matType:image:)]) {
            [self.delegate virtualBackgroudSheet:self matType:PLVVirtualBackgroudMatTypeBlur image:nil];
        }
    } else {
        if (self.delegate && [self.delegate respondsToSelector:@selector(virtualBackgroudSheet:matType:image:)]) {
            UIImage *image = nil;
            if (model.type == PLVVirtualBackgroudCellCustomPicture) {
                image = model.image;
            } else if (model.type == PLVVirtualBackgroudCellInnerPicture) {
                NSString *imageSource = model.imageSourceName;
                BOOL isFullscreen = [UIScreen mainScreen].bounds.size.width > [UIScreen mainScreen].bounds.size.height;
                if (isFullscreen) {
                    imageSource = model.landscapeImageSourceName;
                }
                image = [PLVVirtualBackgroundUtil imageForResource:imageSource];
            }

            [self.delegate virtualBackgroudSheet:self matType:PLVVirtualBackgroudMatTypeCustomImage image:image];
        }
    }
}

- (void)virtualBackgroudCollectionViewDidClickUploadButton:(PLVVirtualBackgroudCollectionView *)collectionView {
    [self showImagePicker];
}

- (void)virtualBackgroudCollectionViewDidUpdateContent:(PLVVirtualBackgroudCollectionView *)collectionView {
    [self setNeedsLayout];
}

#pragma mark -- getter

- (PLVVirtualBackgroudCollectionView *)collectionView {
    if (!_collectionView) {
        _collectionView = [[PLVVirtualBackgroudCollectionView alloc] init];
        _collectionView.delegate = self;
    }
    return _collectionView;
}

- (UIScrollView *)scrollView {
    if (!_scrollView) {
        _scrollView = [[UIScrollView alloc] init];
        _scrollView.showsVerticalScrollIndicator = NO;
        _scrollView.alwaysBounceVertical = YES;
        _scrollView.clipsToBounds = YES;
    }
    return _scrollView;
}

- (UIView *)scrollContentView {
    if (!_scrollContentView) {
        _scrollContentView = [[UIView alloc] init];
    }
    return _scrollContentView;
}

- (UILabel *)titleLable {
    if (!_titleLable) {
        _titleLable = [[UILabel alloc] init];
        _titleLable.text = PLVLocalizedString(@"虚拟背景");
        _titleLable.font = [UIFont systemFontOfSize:18];
        _titleLable.textColor = [UIColor whiteColor];
    }
    return _titleLable;
}

- (UILabel *)greenScreenTitleLabel {
    if (!_greenScreenTitleLabel) {
        _greenScreenTitleLabel = [[UILabel alloc] init];
        _greenScreenTitleLabel.text = PLVLocalizedString(@"专业绿幕");
        _greenScreenTitleLabel.font = [UIFont systemFontOfSize:15];
        _greenScreenTitleLabel.textColor = [UIColor whiteColor];
    }
    return _greenScreenTitleLabel;
}

- (UISwitch *)greenScreenSwitch {
    if (!_greenScreenSwitch) {
        _greenScreenSwitch = [[UISwitch alloc] init];
        _greenScreenSwitch.on = NO;
        [_greenScreenSwitch addTarget:self action:@selector(greenScreenSwitchValueChanged:) forControlEvents:UIControlEventValueChanged];
    }
    return _greenScreenSwitch;
}

- (UIView *)greenScreenContainerView {
    if (!_greenScreenContainerView) {
        _greenScreenContainerView = [[UIView alloc] init];
        _greenScreenContainerView.hidden = YES;
        _greenScreenContainerView.clipsToBounds = YES;
    }
    return _greenScreenContainerView;
}

- (UILabel *)keyColorTitleLabel {
    if (!_keyColorTitleLabel) {
        _keyColorTitleLabel = [[UILabel alloc] init];
        _keyColorTitleLabel.text = PLVLocalizedString(@"幕布颜色");
        _keyColorTitleLabel.font = [UIFont systemFontOfSize:14];
        _keyColorTitleLabel.textColor = [UIColor colorWithWhite:1 alpha:0.85];
    }
    return _keyColorTitleLabel;
}

- (UIButton *)greenColorButton {
    if (!_greenColorButton) {
        _greenColorButton = [self createKeyColorButtonWithColor:PLV_UIColorFromRGB(@"#0BFF00")];
        [_greenColorButton addTarget:self action:@selector(keyColorButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _greenColorButton;
}

- (UIButton *)blueColorButton {
    if (!_blueColorButton) {
        _blueColorButton = [self createKeyColorButtonWithColor:PLV_UIColorFromRGB(@"#1218FF")];
        [_blueColorButton addTarget:self action:@selector(keyColorButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _blueColorButton;
}

- (UIButton *)customColorButton {
    if (!_customColorButton) {
        _customColorButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _customColorButton.layer.cornerRadius = 8;
        _customColorButton.layer.borderWidth = 1;
        _customColorButton.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.2].CGColor;
        _customColorButton.backgroundColor = [UIColor colorWithWhite:1 alpha:0.08];
        if (@available(iOS 13.0, *)) {
            UIImage *icon = [UIImage systemImageNamed:@"eyedropper"];
            [_customColorButton setImage:icon forState:UIControlStateNormal];
            _customColorButton.tintColor = [UIColor colorWithWhite:1 alpha:0.85];
        } else {
            [_customColorButton setTitle:PLVLocalizedString(@"取色") forState:UIControlStateNormal];
            _customColorButton.titleLabel.font = [UIFont systemFontOfSize:12];
            [_customColorButton setTitleColor:[UIColor colorWithWhite:1 alpha:0.8] forState:UIControlStateNormal];
        }
        [_customColorButton addTarget:self action:@selector(keyColorButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _customColorButton;
}

- (UIButton *)advancedToggleButton {
    if (!_advancedToggleButton) {
        _advancedToggleButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_advancedToggleButton addTarget:self action:@selector(advancedToggleButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _advancedToggleButton;
}

- (UILabel *)advancedTitleLabel {
    if (!_advancedTitleLabel) {
        _advancedTitleLabel = [[UILabel alloc] init];
        _advancedTitleLabel.text = PLVLocalizedString(@"高级调节（非专业请勿修改）");
        _advancedTitleLabel.font = [UIFont systemFontOfSize:14];
        _advancedTitleLabel.textColor = [UIColor colorWithWhite:1 alpha:0.85];
    }
    return _advancedTitleLabel;
}

- (UIButton *)restoreRecommendButton {
    if (!_restoreRecommendButton) {
        _restoreRecommendButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _restoreRecommendButton.layer.cornerRadius = 8;
        _restoreRecommendButton.backgroundColor = [UIColor colorWithRed:0.17 green:0.40 blue:0.81 alpha:0.22];
        [_restoreRecommendButton setTitle:PLVLocalizedString(@"恢复推荐") forState:UIControlStateNormal];
        _restoreRecommendButton.titleLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
        [_restoreRecommendButton setTitleColor:[UIColor colorWithRed:0.31 green:0.70 blue:1 alpha:1] forState:UIControlStateNormal];
        [_restoreRecommendButton addTarget:self action:@selector(restoreRecommendButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _restoreRecommendButton;
}

- (UIImageView *)advancedArrowView {
    if (!_advancedArrowView) {
        _advancedArrowView = [[UIImageView alloc] init];
        _advancedArrowView.contentMode = UIViewContentModeScaleAspectFit;
        _advancedArrowView.image = [PLVVirtualBackgroundUtil imageForResource:@"plv_virtualbg_arrow"];
        if (!_advancedArrowView.image) {
            _advancedArrowView.image = [self arrowFallbackImage];
        }
    }
    return _advancedArrowView;
}

- (UIView *)advancedDetailView {
    if (!_advancedDetailView) {
        _advancedDetailView = [[UIView alloc] init];
        _advancedDetailView.hidden = YES;
    }
    return _advancedDetailView;
}

- (UILabel *)similarityLabel {
    if (!_similarityLabel) {
        _similarityLabel = [[UILabel alloc] init];
        _similarityLabel.text = PLVLocalizedString(@"抠像范围");
        _similarityLabel.font = [UIFont systemFontOfSize:12];
        _similarityLabel.textColor = [UIColor colorWithWhite:1 alpha:0.75];
    }
    return _similarityLabel;
}

- (UISlider *)similaritySlider {
    if (!_similaritySlider) {
        _similaritySlider = [[UISlider alloc] init];
        _similaritySlider.minimumValue = 0.0f;
        _similaritySlider.maximumValue = 1.0f;
        _similaritySlider.value = kPLVDefaultSimilarity;
        [_similaritySlider addTarget:self action:@selector(similaritySliderValueChanged:) forControlEvents:UIControlEventValueChanged];
        [_similaritySlider addTarget:self action:@selector(sliderTouchUp:) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside | UIControlEventTouchCancel];
    }
    return _similaritySlider;
}

- (UILabel *)smoothnessLabel {
    if (!_smoothnessLabel) {
        _smoothnessLabel = [[UILabel alloc] init];
        _smoothnessLabel.text = PLVLocalizedString(@"边缘柔化");
        _smoothnessLabel.font = [UIFont systemFontOfSize:12];
        _smoothnessLabel.textColor = [UIColor colorWithWhite:1 alpha:0.75];
    }
    return _smoothnessLabel;
}

- (UISlider *)smoothnessSlider {
    if (!_smoothnessSlider) {
        _smoothnessSlider = [[UISlider alloc] init];
        _smoothnessSlider.minimumValue = 0.0f;
        _smoothnessSlider.maximumValue = 1.0f;
        _smoothnessSlider.value = kPLVDefaultSmoothness;
        [_smoothnessSlider addTarget:self action:@selector(smoothnessSliderValueChanged:) forControlEvents:UIControlEventValueChanged];
        [_smoothnessSlider addTarget:self action:@selector(sliderTouchUp:) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside | UIControlEventTouchCancel];
    }
    return _smoothnessSlider;
}

- (UILabel *)spillLabel {
    if (!_spillLabel) {
        _spillLabel = [[UILabel alloc] init];
        _spillLabel.text = PLVLocalizedString(@"去环境光");
        _spillLabel.font = [UIFont systemFontOfSize:12];
        _spillLabel.textColor = [UIColor colorWithWhite:1 alpha:0.75];
    }
    return _spillLabel;
}

- (UISlider *)spillSlider {
    if (!_spillSlider) {
        _spillSlider = [[UISlider alloc] init];
        _spillSlider.minimumValue = 0.0f;
        _spillSlider.maximumValue = 1.0f;
        _spillSlider.value = kPLVDefaultSpill;
        [_spillSlider addTarget:self action:@selector(spillSliderValueChanged:) forControlEvents:UIControlEventValueChanged];
        [_spillSlider addTarget:self action:@selector(sliderTouchUp:) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside | UIControlEventTouchCancel];
    }
    return _spillSlider;
}

- (UIView *)samplingInteractionView {
    if (!_samplingInteractionView) {
        _samplingInteractionView = [[UIView alloc] init];
        _samplingInteractionView.hidden = YES;
        _samplingInteractionView.userInteractionEnabled = NO;
        _samplingInteractionView.backgroundColor = [UIColor clearColor];

        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(samplingPanGestureAction:)];
        [_samplingInteractionView addGestureRecognizer:pan];

        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(samplingTapGestureAction:)];
        [_samplingInteractionView addGestureRecognizer:tap];
    }
    return _samplingInteractionView;
}

- (UIView *)eyedropperContainerView {
    if (!_eyedropperContainerView) {
        CGSize containerSize = [self eyedropperContainerSize];
        _eyedropperContainerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, containerSize.width, containerSize.height)];
        _eyedropperContainerView.hidden = YES;
        _eyedropperContainerView.userInteractionEnabled = NO;
        _eyedropperContainerView.backgroundColor = [UIColor clearColor];
    }
    return _eyedropperContainerView;
}

- (UIView *)eyedropperFeedbackCircleView {
    if (!_eyedropperFeedbackCircleView) {
        _eyedropperFeedbackCircleView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kPLVEyedropperFeedbackCircleSize, kPLVEyedropperFeedbackCircleSize)];
        _eyedropperFeedbackCircleView.layer.cornerRadius = kPLVEyedropperFeedbackCircleSize * 0.5;
        _eyedropperFeedbackCircleView.backgroundColor = [UIColor colorWithRed:self.keyColorR green:self.keyColorG blue:self.keyColorB alpha:1.0];
    }
    return _eyedropperFeedbackCircleView;
}

- (UIView *)eyedropperSamplingSquareView {
    if (!_eyedropperSamplingSquareView) {
        _eyedropperSamplingSquareView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kPLVEyedropperSamplingSquareSize, kPLVEyedropperSamplingSquareSize)];
        _eyedropperSamplingSquareView.backgroundColor = [UIColor clearColor];

        CGFloat centerX = kPLVEyedropperSamplingSquareSize * 0.5;
        CGFloat centerY = kPLVEyedropperSamplingSquareSize * 0.5;
        CGFloat halfGap = kPLVEyedropperCrosshairCenterGap * 0.5;

        UIView *verticalTopLine = [[UIView alloc] initWithFrame:CGRectMake(centerX - kPLVEyedropperCrosshairLineThickness * 0.5, 0, kPLVEyedropperCrosshairLineThickness, centerY - halfGap)];
        verticalTopLine.backgroundColor = [UIColor colorWithWhite:1 alpha:0.95];
        verticalTopLine.layer.cornerRadius = kPLVEyedropperCrosshairLineThickness * 0.5;
        [_eyedropperSamplingSquareView addSubview:verticalTopLine];

        UIView *verticalBottomLine = [[UIView alloc] initWithFrame:CGRectMake(centerX - kPLVEyedropperCrosshairLineThickness * 0.5, centerY + halfGap, kPLVEyedropperCrosshairLineThickness, centerY - halfGap)];
        verticalBottomLine.backgroundColor = [UIColor colorWithWhite:1 alpha:0.95];
        verticalBottomLine.layer.cornerRadius = kPLVEyedropperCrosshairLineThickness * 0.5;
        [_eyedropperSamplingSquareView addSubview:verticalBottomLine];

        UIView *horizontalLeftLine = [[UIView alloc] initWithFrame:CGRectMake(0, centerY - kPLVEyedropperCrosshairLineThickness * 0.5, centerX - halfGap, kPLVEyedropperCrosshairLineThickness)];
        horizontalLeftLine.backgroundColor = [UIColor colorWithWhite:1 alpha:0.95];
        horizontalLeftLine.layer.cornerRadius = kPLVEyedropperCrosshairLineThickness * 0.5;
        [_eyedropperSamplingSquareView addSubview:horizontalLeftLine];

        UIView *horizontalRightLine = [[UIView alloc] initWithFrame:CGRectMake(centerX + halfGap, centerY - kPLVEyedropperCrosshairLineThickness * 0.5, centerX - halfGap, kPLVEyedropperCrosshairLineThickness)];
        horizontalRightLine.backgroundColor = [UIColor colorWithWhite:1 alpha:0.95];
        horizontalRightLine.layer.cornerRadius = kPLVEyedropperCrosshairLineThickness * 0.5;
        [_eyedropperSamplingSquareView addSubview:horizontalRightLine];
    }
    return _eyedropperSamplingSquareView;
}

- (UIButton *)createKeyColorButtonWithColor:(UIColor *)color {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.layer.cornerRadius = 8;
    button.layer.borderWidth = 1;
    button.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.25].CGColor;
    button.backgroundColor = color;
    return button;
}

- (UIImage *)arrowFallbackImage {
    CGSize imageSize = CGSizeMake(12, 12);
    UIGraphicsBeginImageContextWithOptions(imageSize, NO, 0);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    [[UIColor colorWithWhite:1 alpha:0.85] setStroke];
    CGContextSetLineWidth(ctx, 1.5);
    CGContextMoveToPoint(ctx, 3, 2);
    CGContextAddLineToPoint(ctx, 9, 6);
    CGContextAddLineToPoint(ctx, 3, 10);
    CGContextStrokePath(ctx);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

@end
