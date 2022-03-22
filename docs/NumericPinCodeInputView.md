# NumericPinCodeInputView

## NumericPinCodeInputView Introduction

1. Create a `NumericPinCodeInputView` simply

    ```swift
    pinInputView = NumericPinCodeInputView(frame: CGRect(x: 0, y: 0, width: 250, height: 400))
                pinInputView.setMaxLength(length: 6)
                pinInputView.styleAttr = CYBAVOWallet.StyleAttr(
                        fixedOrder: false,
                        disabled: false,
                        buttonWidth: 70,
                        buttonHeight: 70,
                        horizontalSpacing: 5,
                        buttonTextFont: nil, // optional, set nil and text size will be calculated according to button size
                        verticalSpacing: 7,
                        buttonTextColor: UIColor.darkGray,
                        buttonTextColorPressed: UIColor.lightGray,
                        buttonTextColorDisabled: UIColor.red,
                        buttonBackgroundColor: UIColor.lightGray,
                        buttonBackgroundColorPressed: UIColor.darkGray,
                        buttonBackgroundColorDisabled: UIColor.yellow,
                        buttonBorderRadius: 33,
                        buttonBorderWidth: 0,
                        buttonBorderColor: UIColor.green,
                        buttonBorderColorPressed: UIColor.blue,
                        buttonBorderColorDisabled: UIColor.orange,
                        backspaceButtonWidth: 70,
                        backspaceButtonHeight: 70,
                        backspaceButtonTextFont: nil, // optional, set nil and text size will be calculated according to button size
                        backspaceButtonTextColor: UIColor.darkGray,
                        backspaceButtonTextColorPressed: UIColor.lightGray,
                        backspaceButtonTextColorDisabled: UIColor.yellow,
                        backspaceButtonBackgroundColor: UIColor.lightGray,
                        backspaceButtonBackgroundColorPressed: UIColor.darkGray,
                        backspaceButtonBackgroundColorDisabled: UIColor.red,
                        backspaceButtonBorderRadius: 33,
                        backspaceButtonBorderWidth: 0,
                        backspaceButtonBorderColor: UIColor.blue,
                        backspaceButtonBorderColorPressed: UIColor.red,
                        backspaceButtonBorderColorDisabled: UIColor.black,
                        backspaceButtonText: "⌫")
    ```

2. Set `OnPinInputListener` for `onChanged` callback

    ```swift
    extension ViewController: CYBAVOWallet.OnPinInputListener {
        func onChanged(length: Int) {
            if(length == pinInputView!.getMaxLength()) {
                let pinSecret = pinInputView.submit()
            }
        }
    }
    ```

3. Get `PinSecret` by `NumericPinCodeInputView.submit()` and pass it to Wallet and Auth API

    ``` swift
    let pinSecret = pinInputView.submit()
    Wallets.shared.createTransaction(fromWalletId: w.walletId, toAddress: toAddress, amount: amount, transactionFee: ""
                    , description: "", pinSecret: pinSecret, extras:  extras) { result in }
    ```

4. PinSecret will be clear after the Wallet and Auth API are executed.
        If you want to use the same `PinSecret` with multiple API calls,
        Please call `pinSecret.retain()` before calling the API.

    ```swift
    pinSecret.retain() // Retain for createWallet() after setupPinCode()
    Auth.shared.setupPinCode(pinSecret: pinSecret) { result in
        switch result {
        case .success(_):
            pinSecret.retain() // Retain so that pinSecret can be used after createWallet()
            Wallets.shared.createWallet(currency: 0, tokenAddress: "", parentWalletId: 0, name: "BTC", pinSecret: pinSecret) { result in }
            break
        case .failure(let error):
            break
        }
    }
    ```

5. You can also use `NumericPinCodeInputView.clear()` to clear current input

    ```swift
    pinInputView.clear()
    ```
