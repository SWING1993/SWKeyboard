//
//  SWTextInputDelegateProxy.m
//  SWKeyboard
//
//  Created by 宋国华 on 2019/3/5.
//  Copyright © 2019 songguohua. All rights reserved.
//

#import "SWTextInputDelegateProxy.h"

@implementation SWTextInputDelegateProxy

+ (instancetype)proxyForTextInput:(id<UITextInput>)textInput delegate:(id<UITextInputDelegate>)delegate {
    NSParameterAssert(delegate);
    
    SWTextInputDelegateProxy *proxy = [[SWTextInputDelegateProxy alloc] init];
    proxy->_delegate = delegate;
    proxy->_previousTextInputDelegate = textInput.inputDelegate;
    
    return proxy;
}

#pragma mark - Forwarding.

- (NSArray *)delegates {
    NSMutableArray *delegates = [NSMutableArray array];
    
    id <UITextInputDelegate> previousTextInputDelegate = self.previousTextInputDelegate;
    if (previousTextInputDelegate) {
        [delegates addObject:previousTextInputDelegate];
    }
    
    id <UITextInputDelegate> delegate = self.delegate;
    if (delegate) {
        [delegates addObject:delegate];
    }
    
    return [delegates copy];
}

- (BOOL)respondsToSelector:(SEL)aSelector {
    if ([super respondsToSelector:aSelector]) {
        return YES;
    }
    
    for (id delegate in self.delegates) {
        if ([delegate respondsToSelector:aSelector]) {
            return YES;
        }
    }
    return NO;
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
    NSMethodSignature *signature = [super methodSignatureForSelector:aSelector];
    if (!signature) {
        for (id delegate in self.delegates) {
            if ([delegate respondsToSelector:aSelector]) {
                return [delegate methodSignatureForSelector:aSelector];
            }
        }
    }
    return signature;
}

- (void)forwardInvocation:(NSInvocation *)anInvocation {
    for (id delegate in self.delegates) {
        if ([delegate respondsToSelector:anInvocation.selector]) {
            [anInvocation invokeWithTarget:delegate];
        }
    }
}

@end
