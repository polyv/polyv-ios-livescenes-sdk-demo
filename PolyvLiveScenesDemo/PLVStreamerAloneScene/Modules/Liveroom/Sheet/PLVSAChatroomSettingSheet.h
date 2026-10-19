//
//  PLVSAChatroomSettingSheet.h
//  PLVLiveScenesDemo
//

#import "PLVSABottomSheet.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, PLVSAChatroomHeightLevel) {
    PLVSAChatroomHeightLevelLow = 0,
    PLVSAChatroomHeightLevelMedium,
    PLVSAChatroomHeightLevelHigh
};

typedef NS_ENUM(NSInteger, PLVSAChatroomFontLevel) {
    PLVSAChatroomFontLevelSmall = 0,
    PLVSAChatroomFontLevelMedium,
    PLVSAChatroomFontLevelLarge
};

/// 本机全局公屏配置，跨账号、频道和横竖屏共用，开播前和开播中统一读写。
@interface PLVSAChatroomSetting : NSObject

@property (nonatomic, assign) PLVSAChatroomHeightLevel heightLevel;
@property (nonatomic, assign) PLVSAChatroomFontLevel fontLevel;

/// 初始化时读取全局本地配置，无记录时默认高度中、字号小。
- (instancetype)init;
/// 保存为全局本地配置。
- (void)save;
+ (CGFloat)heightForLevel:(PLVSAChatroomHeightLevel)level maximumHeight:(CGFloat)maximumHeight landscape:(BOOL)landscape;
+ (CGFloat)fontSizeForLevel:(PLVSAChatroomFontLevel)level;

@end

/// 开播前和开播中共用的竖屏公屏设置控件。
@interface PLVSAChatroomSettingView : UIView

@property (nonatomic, copy) void (^heightLevelChanged)(NSInteger level);
@property (nonatomic, copy) void (^fontLevelChanged)(NSInteger level);
@property (nonatomic, copy) void (^doneHandler)(void);
@property (nonatomic, assign) CGFloat controlsBottom;
@property (nonatomic, assign) CGFloat bottomInset;
@property (nonatomic, assign) CGFloat rightInset;

- (void)updateHeightLevel:(NSInteger)heightLevel fontLevel:(NSInteger)fontLevel;

@end

/// 纯视频开播端公屏高度、字号设置弹层。
/// 横屏时复用 PLVSABottomSheet 的右侧面板、圆角和收起交互，不展示全屏暗色遮罩。
@interface PLVSAChatroomSettingSheet : PLVSABottomSheet

@property (nonatomic, copy) void (^heightLevelChanged)(PLVSAChatroomHeightLevel level);
@property (nonatomic, copy) void (^fontLevelChanged)(PLVSAChatroomFontLevel level);
@property (nonatomic, copy) void (^completeHandler)(void);

- (void)updateHeightLevel:(PLVSAChatroomHeightLevel)heightLevel
                fontLevel:(PLVSAChatroomFontLevel)fontLevel;

@end

NS_ASSUME_NONNULL_END
