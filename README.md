# SWKeyboard
自定义 iPad 英文字母键盘

```Objc
// Create and configure the keyboard.
SWKeyboard *keyboard = [[SWKeyboard alloc] initWithFrame:CGRectZero];
keyboard.delegate = self;

// Configure an example UITextField.
UITextField *textField = [[UITextField alloc] initWithFrame:CGRectZero];
textField.inputAccessoryView = [[UIView alloc] init];
textField.inputView = keyboard;
textField.text = @"123456789ABCDEFG";
textField.placeholder = @"TypeSomething…";
textField.font = [UIFont systemFontOfSize:24.0f];
textField.contentVerticalAlignment = UIControlContentVerticalAlignmentTop;

self.textField = textField;
[self.view addSubview:textField];
```
