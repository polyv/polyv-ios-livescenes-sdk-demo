//
//  PLVLSEmojiSelectView.h
//  PLVLiveStreamerDemo
//
//  Created by ftao on 2019/11/13.
//  Copyright © 2019 easefun. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PLVEmoticon, PLVImageEmotion;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, PLVLSEmojiSelectViewEvent) {
    PLVLSEmojiSelectViewEventSend,
    PLVLSEmojiSelectViewEventDelete
};

typedef void (^PLVLSCollectionViewDidSelectBlock)(NSInteger index);

@protocol PLVLSEmojiSelectViewProtocol <NSObject>

- (void)emojiSelectView_didSelectEmoticon:(PLVEmoticon *)emoticon;

- (void)emojiSelectView_didReceiveEvent:(PLVLSEmojiSelectViewEvent)event;

- (void)emojiSelectView_sendImageEmoticon:(PLVImageEmotion *)emoticon;

@end

@interface PLVLSEmojiSelectView : UIView

@property (nonatomic, weak) id<PLVLSEmojiSelectViewProtocol> delegate;
///键盘的图片表情
@property (nonatomic, strong) NSArray *imageEmotions;

- (void)sendButtonEnable:(BOOL)enable;

@end

@interface PLVLSDefaultEmojiSelectView : UIView

@property (nonatomic, strong) NSArray *faces;

@property (nonatomic, copy) PLVLSCollectionViewDidSelectBlock selectItemBlock;

@end

@interface PLVLSCustomEmojiSelectView : UIView

@property (nonatomic, strong) NSArray *imageEmotions;

@property (nonatomic, copy) PLVLSCollectionViewDidSelectBlock selectItemBlock;

@end

@interface PLVLSEmojiCollectionViewCell : UICollectionViewCell

@property (nonatomic, strong) UIImageView *imageView;

@end

@interface PLVLSCustomEmojiCollectionViewCell : UICollectionViewCell

@property (nonatomic, strong) UIImageView *imageView;

@property (nonatomic, strong) UILabel *titleLabel;

@property (nonatomic, strong) PLVImageEmotion *imageEmotion;

@end

NS_ASSUME_NONNULL_END
