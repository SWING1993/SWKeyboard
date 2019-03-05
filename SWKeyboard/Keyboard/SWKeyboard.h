//
//  SWKeyboard.h
//  SWKeyboard
//
//  Created by 宋国华 on 2019/3/5.
//  Copyright © 2019 songguohua. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class SWKeyboard;

typedef NS_ENUM(NSUInteger, SWKeyboardButtonStyle) {

    SWKeyboardButtonStyleWhite,
    
    SWKeyboardButtonStyleGray,
    
    SWKeyboardButtonStyleDone
};

@protocol SWKeyboardDelegate <NSObject>

@optional

- (BOOL)numberKeyboard:(SWKeyboard *)keyboard shouldInsertText:(NSString *)text;

- (BOOL)numberKeyboardShouldReturn:(SWKeyboard *)keyboard;

- (BOOL)numberKeyboardShouldDeleteBackward:(SWKeyboard *)keyboard;

@end


@interface SWKeyboard : UIInputView

@property (weak, nonatomic, nullable) id <UIKeyInput> keyInput;

@property (weak, nonatomic, nullable) id <SWKeyboardDelegate> delegate;

@property (assign, nonatomic) BOOL allowsDecimalPoint;

@property (copy, nonatomic, null_resettable) NSString *returnKeyTitle;

@property (assign, nonatomic) SWKeyboardButtonStyle returnKeyButtonStyle;

@property (assign, nonatomic) BOOL enablesReturnKeyAutomatically;

- (void)configureSpecialKeyWithImage:(UIImage *)image actionHandler:(nullable dispatch_block_t)handler;

- (void)configureSpecialKeyWithImage:(UIImage *)image target:(id)target action:(SEL)action;

@end

NS_ASSUME_NONNULL_END
