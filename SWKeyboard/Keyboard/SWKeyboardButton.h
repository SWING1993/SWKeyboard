//
//  SWKeyboardButton.h
//  SWKeyboard
//
//  Created by 宋国华 on 2019/3/5.
//  Copyright © 2019 songguohua. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SWKeyboard.h"

NS_ASSUME_NONNULL_BEGIN

@interface SWKeyboardButton : UIButton

@property (assign, nonatomic) SWKeyboardButtonStyle style;

@property (assign, nonatomic) BOOL usesRoundedCorners;

+ (instancetype)keyboardButtonWithStyle:(SWKeyboardButtonStyle)style;

- (void)addTarget:(id)target action:(SEL)action forContinuousPressWithTimeInterval:(NSTimeInterval)timeInterval;

@end

NS_ASSUME_NONNULL_END
