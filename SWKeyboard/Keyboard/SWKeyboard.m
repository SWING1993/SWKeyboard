//
//  SWKeyboard.m
//  SWKeyboard
//
//  Created by 宋国华 on 2019/3/5.
//  Copyright © 2019 songguohua. All rights reserved.
//

#import "SWKeyboard.h"
#import "SWTextInputDelegateProxy.h"
#import "SWKeyboardButton.h"

typedef NS_ENUM(NSUInteger, SWKeyboardButtonKey) {
    SWKeyboardButtonNumberMin,
    SWKeyboardButtonNumberMax = SWKeyboardButtonNumberMin + 10, // Ten digits.
    SWKeyboardButtonBackspace,
    SWKeyboardButtonDone,
    SWKeyboardButtonSpecial,
    SWKeyboardButtonDecimalPoint,
    SWKeyboardButtonUnderline,
    SWKeyboardButtonCapsLock,
    SWKeyboardButtonNone = NSNotFound,
};

@interface SWKeyboard () <UIInputViewAudioFeedback, UITextInputDelegate>

@property (strong, nonatomic) NSDictionary *buttonDictionary;
@property (strong, nonatomic) SWTextInputDelegateProxy *keyInputProxy;
@property (copy, nonatomic) dispatch_block_t specialKeyHandler;
@property (copy, nonatomic) NSArray *letters;
@property (copy, nonatomic) NSArray *firstLineLetters;
@property (copy, nonatomic) NSArray *secondLineLetters;
@property (copy, nonatomic) NSArray *thirdLineLetters;

@end

static __weak id currentFirstResponder;

@implementation UIResponder (FirstResponder)

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-repeated-use-of-weak"
+ (id)MM_currentFirstResponder {
    currentFirstResponder = nil;
    [[UIApplication sharedApplication] sendAction:@selector(MM_findFirstResponder:) to:nil from:nil forEvent:nil];
    return currentFirstResponder;
}
#pragma clang diagnostic pop

- (void)MM_findFirstResponder:(id)sender {
    currentFirstResponder = self;
}

@end

@implementation SWKeyboard

static const NSInteger SWKeyboardRows = 4;
static const CGFloat SWKeyboardRowHeight = 55.0f;
static const CGFloat SWKeyboardPadBorder = 7.0f;
static const CGFloat SWKeyboardPadSpacing = 8.0f;

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame inputViewStyle:UIInputViewStyleKeyboard];
    if (self) {
        [self _commonInit];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame inputViewStyle:(UIInputViewStyle)inputViewStyle {
    self = [super initWithFrame:frame inputViewStyle:inputViewStyle];
    if (self) {
        [self _commonInit];
    }
    return self;
}

- (void)_commonInit {

    self.firstLineLetters = @[@"Q", @"W", @"E", @"R", @"T", @"Y", @"U", @"I", @"O", @"P"];
    self.secondLineLetters = @[@"A", @"S", @"D", @"F", @"G", @"H", @"J", @"K", @"L"];
    self.thirdLineLetters = @[@"Z", @"X", @"C", @"V", @"B", @"N", @"M"];
    self.letters = @[@"Q", @"W", @"E", @"R", @"T", @"Y", @"U", @"I", @"O", @"P", @"A", @"S", @"D", @"F", @"G", @"H", @"J", @"K", @"L", @"Z", @"X", @"C", @"V", @"B", @"N", @"M"];
    
    [self _configureButtonsForCurrentStyle];
    UIImage *dismissImage = [self.class _keyboardImageNamed:@"SWKeyboardDismissKey.png"];
    [self configureSpecialKeyWithImage:dismissImage target:self action:@selector(_dismissKeyboard:)];
    [self setReturnKeyTitle:nil];
    [self setReturnKeyButtonStyle:SWKeyboardButtonStyleDone];
    [self sizeToFit];
}

- (void)_configureButtonsForCurrentStyle {
    
    NSMutableDictionary *buttonDictionary = [NSMutableDictionary dictionary];
    
    const NSInteger numberMin = SWKeyboardButtonNumberMin;
    const NSInteger numberMax = SWKeyboardButtonNumberMax;
    
    const CGFloat buttonFontPointSize = 28.0f;
    UIFont *buttonFont = ({
        UIFont *font = nil;
#if defined(__has_attribute) && __has_attribute(availability)
        if (@available(iOS 8.2, *)) {
            font = [UIFont systemFontOfSize:buttonFontPointSize weight:UIFontWeightLight];
        }
#else
        if ([UIFont respondsToSelector:@selector(systemFontOfSize:weight:)]) {
            font = [UIFont systemFontOfSize:buttonFontPointSize weight:UIFontWeightLight];
        }
#endif
        font ?: [UIFont fontWithName:@"HelveticaNeue-Light" size:buttonFontPointSize];
    });
    
    UIFont *doneButtonFont = [UIFont systemFontOfSize:17.0f];
    
    for (SWKeyboardButtonKey key = numberMin; key < numberMax; key++) {
        UIButton *button = [SWKeyboardButton keyboardButtonWithStyle:SWKeyboardButtonStyleWhite];
        NSString *title = @(key - numberMin).stringValue;
        [button setTitle:title forState:UIControlStateNormal];
        [button.titleLabel setFont:buttonFont];
        [buttonDictionary setObject:button forKey:@(key)];
    }
    
    UIImage *backspaceImage = [self.class _keyboardImageNamed:@"SWKeyboardDeleteKey.png"];
    UIButton *backspaceButton = [SWKeyboardButton keyboardButtonWithStyle:SWKeyboardButtonStyleGray];
    [backspaceButton setImage:[backspaceImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    [(SWKeyboardButton *)backspaceButton addTarget:self action:@selector(_backspaceRepeat:) forContinuousPressWithTimeInterval:0.15f];
    [buttonDictionary setObject:backspaceButton forKey:@(SWKeyboardButtonBackspace)];
    
    UIButton *specialButton = [SWKeyboardButton keyboardButtonWithStyle:SWKeyboardButtonStyleGray];
    [buttonDictionary setObject:specialButton forKey:@(SWKeyboardButtonSpecial)];
    
    UIButton *doneButton = [SWKeyboardButton keyboardButtonWithStyle:SWKeyboardButtonStyleDone];
    [doneButton.titleLabel setFont:doneButtonFont];
    [doneButton setTitle:@"完成" forState:UIControlStateNormal];
    [buttonDictionary setObject:doneButton forKey:@(SWKeyboardButtonDone)];
    
    UIButton *decimalPointButton = [SWKeyboardButton keyboardButtonWithStyle:SWKeyboardButtonStyleWhite];
    [decimalPointButton setTitle:@"." forState:UIControlStateNormal];
    [buttonDictionary setObject:decimalPointButton forKey:@(SWKeyboardButtonDecimalPoint)];
    
    UIButton *underlineButton = [SWKeyboardButton keyboardButtonWithStyle:SWKeyboardButtonStyleWhite];
    [underlineButton setTitle:@"-" forState:UIControlStateNormal];
    [buttonDictionary setObject:underlineButton forKey:@(SWKeyboardButtonUnderline)];
    
    for (NSString *key in self.letters) {
        UIButton *button = [SWKeyboardButton keyboardButtonWithStyle:SWKeyboardButtonStyleWhite];
        NSString *title = key;
        [button setTitle:title forState:UIControlStateNormal];
        [button.titleLabel setFont:buttonFont];
        [buttonDictionary setObject:button forKey:key];
    }
    
    UIButton *capsLockButton = [SWKeyboardButton keyboardButtonWithStyle:SWKeyboardButtonStyleWhite];
    capsLockButton.selected = YES;
    [capsLockButton setTitle:@"小写" forState:UIControlStateNormal];
    [capsLockButton setTitle:@"大写" forState:UIControlStateSelected];
    [buttonDictionary setObject:capsLockButton forKey:@(SWKeyboardButtonCapsLock)];
    
    for (UIButton *button in buttonDictionary.objectEnumerator) {
        [button setExclusiveTouch:YES];
        [button addTarget:self action:@selector(_buttonInput:) forControlEvents:UIControlEventTouchUpInside];
        [button addTarget:self action:@selector(_buttonPlayClick:) forControlEvents:UIControlEventTouchDown];
        [self addSubview:button];
    }
    
    UIPanGestureRecognizer *highlightGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(_handleHighlightGestureRecognizer:)];
    [self addGestureRecognizer:highlightGestureRecognizer];
    if (self.buttonDictionary) {
        [self.buttonDictionary.allValues makeObjectsPerformSelector:@selector(removeFromSuperview)];
    }
    self.buttonDictionary = buttonDictionary;
}

- (void)_configureButtonsForKeyInputState {
    const BOOL hasText = self.keyInput.hasText;
    const BOOL enablesReturnKeyAutomatically = self.enablesReturnKeyAutomatically;
    SWKeyboardButton *button = self.buttonDictionary[@(SWKeyboardButtonDone)];
    if (button) {
        button.enabled = (!enablesReturnKeyAutomatically) || (enablesReturnKeyAutomatically && hasText);
    }
}

#pragma mark - Input.

- (void)_handleHighlightGestureRecognizer:(UIPanGestureRecognizer *)gestureRecognizer {
    CGPoint point = [gestureRecognizer locationInView:self];
    if (gestureRecognizer.state == UIGestureRecognizerStateChanged || gestureRecognizer.state == UIGestureRecognizerStateEnded) {
        for (UIButton *button in self.buttonDictionary.objectEnumerator) {
            BOOL points = CGRectContainsPoint(button.frame, point) && !button.isHidden;
            
            if (gestureRecognizer.state == UIGestureRecognizerStateChanged) {
                [button setHighlighted:points];
            } else {
                [button setHighlighted:NO];
            }
            
            if (gestureRecognizer.state == UIGestureRecognizerStateEnded && points) {
                [button sendActionsForControlEvents:UIControlEventTouchUpInside];
            }
        }
    }
}

- (void)_buttonPlayClick:(UIButton *)button {
    [[UIDevice currentDevice] playInputClick];
}

- (void)_buttonInput:(UIButton *)button {
    // Get first responder.
    id <UIKeyInput> keyInput = self.keyInput;
    id <SWKeyboardDelegate> delegate = self.delegate;
    
    if (!keyInput) {
        return;
    }
    
    if (button.titleLabel.text.length > 0) {
        NSString *buttonTitleText = [button titleForState:UIControlStateNormal];
        if (button == self.buttonDictionary[[buttonTitleText uppercaseString]] || button == self.buttonDictionary[[buttonTitleText lowercaseString]]) {
            if ([delegate respondsToSelector:@selector(keyboard:shouldInsertText:)]) {
                BOOL shouldInsert = [delegate keyboard:self shouldInsertText:buttonTitleText];
                if (!shouldInsert) {
                    return;
                }
            }
            [keyInput insertText:buttonTitleText];
            return;
        }
    }
    
    __block SWKeyboardButtonKey keyboardButtonKey = SWKeyboardButtonNone;
    
    [self.buttonDictionary enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if (button == obj) {
            keyboardButtonKey = [key unsignedIntegerValue];
            *stop = YES;
        }
    }];
    
    // Handle number.
    const NSInteger numberMin = SWKeyboardButtonNumberMin;
    const NSInteger numberMax = SWKeyboardButtonNumberMax;
    
    if (keyboardButtonKey >= numberMin && keyboardButtonKey < numberMax) {
        NSNumber *number = @(keyboardButtonKey - numberMin);
        NSString *string = number.stringValue;
        
        if ([delegate respondsToSelector:@selector(keyboard:shouldInsertText:)]) {
            BOOL shouldInsert = [delegate keyboard:self shouldInsertText:string];
            if (!shouldInsert) {
                return;
            }
        }
        
        [keyInput insertText:string];
    }
    
    // Handle backspace.
    else if (keyboardButtonKey == SWKeyboardButtonBackspace) {
        BOOL shouldDeleteBackward = YES;
        
        if ([delegate respondsToSelector:@selector(keyboardShouldDeleteBackward:)]) {
            shouldDeleteBackward = [delegate keyboardShouldDeleteBackward:self];
        }
        
        if (shouldDeleteBackward) {
            [keyInput deleteBackward];
        }
    }
    
    // Handle done.
    else if (keyboardButtonKey == SWKeyboardButtonDone) {
        BOOL shouldReturn = YES;
        
        if ([delegate respondsToSelector:@selector(keyboardShouldReturn:)]) {
            shouldReturn = [delegate keyboardShouldReturn:self];
        }
        
        if (shouldReturn) {
            [self _dismissKeyboard:button];
        }
    }
    
    // Handle special key.
    else if (keyboardButtonKey == SWKeyboardButtonSpecial) {
        dispatch_block_t handler = self.specialKeyHandler;
        if (handler) {
            handler();
        }
    }
    
    // Handle .
    else if (keyboardButtonKey == SWKeyboardButtonDecimalPoint) {
        NSString *decimalText = [button titleForState:UIControlStateNormal];
        if ([delegate respondsToSelector:@selector(keyboard:shouldInsertText:)]) {
            BOOL shouldInsert = [delegate keyboard:self shouldInsertText:decimalText];
            if (!shouldInsert) {
                return;
            }
        }
        
        [keyInput insertText:decimalText];
    }
    
    // Handle Underline
    else if (keyboardButtonKey == SWKeyboardButtonUnderline) {
        NSString *underlineText = [button titleForState:UIControlStateNormal];
        if ([delegate respondsToSelector:@selector(keyboard:shouldInsertText:)]) {
            BOOL shouldInsert = [delegate keyboard:self shouldInsertText:underlineText];
            if (!shouldInsert) {
                return;
            }
        }
        [keyInput insertText:underlineText];
    }
    
    // Handle CapsLock
    else if (keyboardButtonKey == SWKeyboardButtonCapsLock) {
        button.selected = !button.selected;
        for (NSString *key in self.letters) {
            UIButton *letterButton = self.buttonDictionary[key];
            NSString *letterTitle = button.selected ? [letterButton.titleLabel.text uppercaseString] : [letterButton.titleLabel.text lowercaseString];
            [letterButton setTitle:letterTitle forState:UIControlStateNormal];
        }
    }
    
    [self _configureButtonsForKeyInputState];
}

- (void)_backspaceRepeat:(UIButton *)button {
    id <UIKeyInput> keyInput = self.keyInput;
    
    if (![keyInput hasText]) {
        return;
    }
    
    [self _buttonPlayClick:button];
    [self _buttonInput:button];
}

- (id<UIKeyInput>)keyInput {
    id <UIKeyInput> keyInput = _keyInput;
    
    if (!keyInput) {
        keyInput = [UIResponder MM_currentFirstResponder];
        if (![keyInput conformsToProtocol:@protocol(UIKeyInput)]) {
            NSLog(@"Warning: First responder %@ does not conform to the UIKeyInput protocol.", keyInput);
            keyInput = nil;
        }
    }
    
    SWTextInputDelegateProxy *keyInputProxy = _keyInputProxy;
    if (keyInput != _keyInput) {
        if ([_keyInput conformsToProtocol:@protocol(UITextInput)]) {
            [(id <UITextInput>)_keyInput setInputDelegate:keyInputProxy.previousTextInputDelegate];
        }
        
        if ([keyInput conformsToProtocol:@protocol(UITextInput)]) {
            keyInputProxy = [SWTextInputDelegateProxy proxyForTextInput:(id <UITextInput>)keyInput delegate:self];
            [(id <UITextInput>)keyInput setInputDelegate:(id)keyInputProxy];
        } else {
            keyInputProxy = nil;
        }
    }
    
    _keyInput = keyInput;
    _keyInputProxy = keyInputProxy;
    
    return keyInput;
}

#pragma mark - <UITextInputDelegate>

- (void)selectionWillChange:(id <UITextInput>)textInput {
    // Intentionally left unimplemented in conformance with <UITextInputDelegate>.
}

- (void)selectionDidChange:(id <UITextInput>)textInput {
    // Intentionally left unimplemented in conformance with <UITextInputDelegate>.
}

- (void)textWillChange:(id <UITextInput>)textInput {
    // Intentionally left unimplemented in conformance with <UITextInputDelegate>.
}

- (void)textDidChange:(id <UITextInput>)textInput {
    [self _configureButtonsForKeyInputState];
}

#pragma mark - Key input lookup.

- (void)didMoveToWindow {
    [super didMoveToWindow];
    [self _configureButtonsForKeyInputState];
}

#pragma mark - Default special action.

- (void)_dismissKeyboard:(id)sender {
    id <UIKeyInput> keyInput = self.keyInput;
    
    if ([keyInput isKindOfClass:[UIResponder class]]) {
        [(UIResponder *)keyInput resignFirstResponder];
    }
}

#pragma mark - Public.

- (void)configureSpecialKeyWithImage:(UIImage *)image actionHandler:(dispatch_block_t)handler {
    if (image) {
        self.specialKeyHandler = handler;
    } else {
        self.specialKeyHandler = NULL;
    }
    
    UIButton *button = self.buttonDictionary[@(SWKeyboardButtonSpecial)];
    [button setImage:image forState:UIControlStateNormal];
}

- (void)configureSpecialKeyWithImage:(UIImage *)image target:(id)target action:(SEL)action {
    __weak typeof(self)weakTarget = target;
    __weak typeof(self)weakSelf = self;
    [self configureSpecialKeyWithImage:image actionHandler:^{
        __strong __typeof(&*weakTarget)strongTarget = weakTarget;
        __strong __typeof(&*weakSelf)strongSelf = weakSelf;
        if (strongTarget) {
            NSMethodSignature *methodSignature = [strongTarget methodSignatureForSelector:action];
            NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:methodSignature];
            [invocation setSelector:action];
            if (methodSignature.numberOfArguments > 2) {
                [invocation setArgument:&strongSelf atIndex:2];
            }
            [invocation invokeWithTarget:strongTarget];
        }
    }];
}

- (void)setReturnKeyTitle:(NSString *)title {
    if (!title) {
        title = [self defaultReturnKeyTitle];
    }
    
    if (![title isEqualToString:self.returnKeyTitle]) {
        UIButton *button = self.buttonDictionary[@(SWKeyboardButtonDone)];
        if (button) {
            NSString *returnKeyTitle = (title != nil && title.length > 0) ? title : [self defaultReturnKeyTitle];
            [button setTitle:returnKeyTitle forState:UIControlStateNormal];
        }
    }
}

- (NSString *)returnKeyTitle {
    UIButton *button = self.buttonDictionary[@(SWKeyboardButtonDone)];
    if (button) {
        NSString *title = [button titleForState:UIControlStateNormal];
        if (title != nil && title.length > 0) {
            return title;
        }
    }
    return [self defaultReturnKeyTitle];
}

- (NSString *)defaultReturnKeyTitle {
    return @"确认";
}

- (void)setReturnKeyButtonStyle:(SWKeyboardButtonStyle)style {
    if (style != _returnKeyButtonStyle) {
        _returnKeyButtonStyle = style;
        SWKeyboardButton *button = self.buttonDictionary[@(SWKeyboardButtonDone)];
        if (button) {
            button.style = style;
        }
    }
}

- (void)setEnablesReturnKeyAutomatically:(BOOL)enablesReturnKeyAutomatically {
    if (enablesReturnKeyAutomatically != _enablesReturnKeyAutomatically) {
        _enablesReturnKeyAutomatically = enablesReturnKeyAutomatically;
        [self _configureButtonsForKeyInputState];
    }
}

#pragma mark - Layout.

NS_INLINE CGRect MMButtonRectMake(CGRect rect, CGRect contentRect) {
    rect = CGRectOffset(rect, contentRect.origin.x, contentRect.origin.y);
    CGFloat inset = SWKeyboardPadSpacing / 2.0f;
    rect = CGRectInset(rect, inset, inset);
    return rect;
};

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGRect bounds = (CGRect){
        .size = self.bounds.size
    };
    
    UIEdgeInsets insets = UIEdgeInsetsZero;
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 110000
    if (@available(iOS 11.0, *)) {
        insets = self.safeAreaInsets;
    }
#endif
    
    NSDictionary *buttonDictionary = self.buttonDictionary;
    const CGFloat spacing = SWKeyboardPadBorder;
    const CGFloat rightWidth = bounds.size.width * 2/7;
    
    CGRect rightContentRect = (CGRect){
        .origin.x = CGRectGetWidth(bounds) - rightWidth,
        .origin.y = 0,
        .size.width = rightWidth,
        .size.height = CGRectGetHeight(bounds) - (spacing * 2.0f)
    };
    rightContentRect = UIEdgeInsetsInsetRect(rightContentRect, insets);
    
    // Layout.
    const CGFloat numberColumnWidth = CGRectGetWidth(rightContentRect) / 4.0f;
    const CGFloat numberRowHeight = CGRectGetHeight(rightContentRect) /SWKeyboardRows;
    CGSize numberSize = CGSizeMake(numberColumnWidth, numberRowHeight);
    
    // Layout numbers.
    const NSInteger numberMin = SWKeyboardButtonNumberMin;
    const NSInteger numberMax = SWKeyboardButtonNumberMax;
    const NSInteger numbersPerLine = 3;
    
    for (SWKeyboardButtonKey key = numberMin; key < numberMax; key++) {
        UIButton *button = buttonDictionary[@(key)];
        NSInteger digit = key - numberMin;
        CGRect rect = (CGRect){ .size = numberSize };
        if (digit == 0) {
            rect.origin.y = numberSize.height * 3;
            rect.origin.x = numberSize.width;
        } else {
            NSUInteger idx = (digit - 1);
            NSInteger line = idx / numbersPerLine;
            NSInteger pos = idx % numbersPerLine;
            rect.origin.y = line * numberSize.height;
            rect.origin.x = pos * numberSize.width;
        }
        [button setFrame:MMButtonRectMake(rect, rightContentRect)];
    }
    
    // Layout underlineKey key.
    UIButton *underlineKey = buttonDictionary[@(SWKeyboardButtonUnderline)];
    if (underlineKey) {
        CGRect rect = (CGRect){ .size = numberSize };
        rect.origin.y = numberSize.height * 3;
        [underlineKey setFrame:MMButtonRectMake(rect, rightContentRect)];
    }
    
    // Layout decimal point.
    UIButton *decimalPointKey = buttonDictionary[@(SWKeyboardButtonDecimalPoint)];
    if (decimalPointKey) {
        CGRect rect = (CGRect){ .size = numberSize };
        rect.origin.y = numberSize.height * 3;
        rect.origin.x = numberSize.width * 2;
        [decimalPointKey setFrame:MMButtonRectMake(rect, rightContentRect)];
    }
    
    // Layout utility column.
    const int utilityButtonKeys[2] = { SWKeyboardButtonBackspace, SWKeyboardButtonDone };
    const CGSize utilitySize = CGSizeMake(numberColumnWidth, numberRowHeight * 2.0f);
    for (NSInteger idx = 0; idx < sizeof(utilityButtonKeys) / sizeof(int); idx++) {
        SWKeyboardButtonKey key = utilityButtonKeys[idx];
        UIButton *button = buttonDictionary[@(key)];
        CGRect rect = (CGRect){ .size = utilitySize };
        rect.origin.x = numberColumnWidth * 3.0f;
        rect.origin.y = idx * utilitySize.height;
        [button setFrame:MMButtonRectMake(rect, rightContentRect)];
    }
    
    UIButton *backspaceButton = buttonDictionary[@(SWKeyboardButtonBackspace)];
    if (backspaceButton) {
        CGRect rect = (CGRect){ .size = numberSize };
        rect.origin.x = numberColumnWidth * 3.0f;
        [backspaceButton setFrame:MMButtonRectMake(rect, rightContentRect)];
    }
    
    // Layout special key.
    UIButton *specialKey = buttonDictionary[@(SWKeyboardButtonSpecial)];
    if (specialKey) {
        CGRect rect = (CGRect){ .size = numberSize };
        rect.origin.x = numberColumnWidth * 3.0f;
        rect.origin.y = numberRowHeight * 1.0f;
        [specialKey setFrame:MMButtonRectMake(rect, rightContentRect)];
    }
    
    UIButton *doneButton = buttonDictionary[@(SWKeyboardButtonDone)];
    if (doneButton) {
        CGRect rect = (CGRect){
            .size.width = numberSize.width,
            .size.height = numberSize.height * 2
        };
        rect.origin.x = numberColumnWidth * 3.0f;
        rect.origin.y = numberRowHeight * 2.0f;
        [doneButton setFrame:MMButtonRectMake(rect, rightContentRect)];
    }
    
    CGRect leftContentRect = (CGRect){
        .size.width = rightContentRect.origin.x,
        .size.height = rightContentRect.size.height
    };
    leftContentRect = UIEdgeInsetsInsetRect(leftContentRect, insets);
    
    const CGFloat letterColumnWidth = CGRectGetWidth(leftContentRect) / 10.0f;
    const CGFloat letterRowHeight = CGRectGetHeight(leftContentRect) / 3;
    CGSize letterSize = CGSizeMake(letterColumnWidth, letterRowHeight);
    
    NSArray *total = @[self.firstLineLetters, self.secondLineLetters, self.thirdLineLetters];
    
    for (int x = 0; x < total.count; x ++) {
        NSArray *lines = total[x];
        for (int y = 0; y < lines.count; y ++) {
            NSString *key = lines[y];
            UIButton *button = buttonDictionary[key];
            CGRect rect = (CGRect){ .size = letterSize };
            rect.origin.y = letterSize.height * x;
            rect.origin.x = letterSize.width * y;
            if (x == 1) {
                rect.origin.x += letterSize.width/2;
            } else if ( x == 2) {
                rect.origin.x += letterSize.width*3/2;
            }
            [button setFrame:MMButtonRectMake(rect, leftContentRect)];
        }
    }
    
    // Layout decimal point.
    UIButton *capsLockButton = buttonDictionary[@(SWKeyboardButtonCapsLock)];
    if (capsLockButton) {
        CGRect rect = (CGRect){
            .origin.y = letterSize.height * 2,
            .size.width = letterSize.width * 1.5f,
            .size.height = letterSize.height
        };
        [capsLockButton setFrame:MMButtonRectMake(rect, leftContentRect)];
    }
    
    for (SWKeyboardButton *button in buttonDictionary.allValues) {
        button.usesRoundedCorners = YES;
    }
}

- (CGSize)sizeThatFits:(CGSize)size {
    const CGFloat spacing = SWKeyboardPadBorder;
    size.height = SWKeyboardRowHeight * SWKeyboardRows + (spacing * 2.0f);
    if (size.width == 0.0f) {
        size.width = [UIScreen mainScreen].bounds.size.width;
    }
    return size;
}

#pragma mark - Audio feedback.

- (BOOL)enableInputClicksWhenVisible {
    return YES;
}

#pragma mark - Accessing keyboard images.

+ (UIImage *)_keyboardImageNamed:(NSString *)name {
    NSString *resource = [name stringByDeletingPathExtension];
    NSString *extension = [name pathExtension];
    if (!resource.length) {
        return nil;
    }
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSString *resourcePath = [bundle pathForResource:resource ofType:extension];
    if (resourcePath.length) {
        return [UIImage imageWithContentsOfFile:resourcePath];
    }
    return [UIImage imageNamed:resource];
}

#pragma mark - Matching the system's appearance.

- (BOOL)_systemUsesRoundedRectButtonsOnAllInterfaceIdioms {
    static BOOL usesRoundedRectButtons;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        usesRoundedRectButtons = ([[[UIDevice currentDevice] systemVersion] compare:@"11.0" options:NSNumericSearch] != NSOrderedAscending);
    });
    return usesRoundedRectButtons;
}

@end
