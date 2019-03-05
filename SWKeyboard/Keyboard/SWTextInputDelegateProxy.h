//
//  SWTextInputDelegateProxy.h
//  SWKeyboard
//
//  Created by 宋国华 on 2019/3/5.
//  Copyright © 2019 songguohua. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SWTextInputDelegateProxy : NSObject

@property (readonly, nonatomic, weak, nullable) id <UITextInputDelegate> delegate;

@property (readonly, nonatomic, weak, nullable) id <UITextInputDelegate> previousTextInputDelegate;

+ (instancetype)proxyForTextInput:(nullable id <UITextInput>)textInput delegate:(nullable id <UITextInputDelegate>)delegate;

@end

NS_ASSUME_NONNULL_END
