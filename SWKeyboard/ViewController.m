//
//  ViewController.m
//  SWKeyboard
//
//  Created by 宋国华 on 2019/3/5.
//  Copyright © 2019 songguohua. All rights reserved.
//

#import "ViewController.h"
#import "SWKeyboard.h"

@interface ViewController ()<SWKeyboardDelegate>

@property (strong, nonatomic) UITextField *textField;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    // Create and configure the keyboard.
    SWKeyboard *keyboard = [[SWKeyboard alloc] initWithFrame:CGRectZero];
    keyboard.allowsDecimalPoint = YES;
    keyboard.delegate = self;
    
    // Configure an example UITextField.
    UITextField *textField = [[UITextField alloc] initWithFrame:CGRectZero];
    textField.inputView = keyboard;
    textField.text = @(123456789).stringValue;
    textField.placeholder = @"Type something…";
    textField.font = [UIFont systemFontOfSize:24.0f];
    textField.contentVerticalAlignment = UIControlContentVerticalAlignmentTop;
    
    self.textField = textField;
    [self.view addSubview:textField];
}

#pragma mark - SWKeyboardDelegate.

- (BOOL)numberKeyboardShouldReturn:(SWKeyboard *)Keyboard {
    // Do something with the done key if neeed. Return YES to dismiss the keyboard.
    return YES;
}

#pragma mark - Layout.

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGRect bounds = (CGRect){
        .size = self.view.bounds.size
    };
    CGRect contentRect = UIEdgeInsetsInsetRect(bounds, (UIEdgeInsets){
        .top = self.topLayoutGuide.length,
        .bottom = self.bottomLayoutGuide.length,
    });
    const CGFloat pad = 20.0f;
    self.textField.frame = CGRectInset(contentRect, pad, pad);
}

#pragma mark - View events.

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.textField becomeFirstResponder];
}



@end
