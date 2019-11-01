# CYBABO Wallet APP SDK for iOS - Sample

Sample app for integrating Cybavo Wallet App SDK, https://www.cybavo.com/wallet-app-sdk/

## Institutional-grade security for your customers

Protect your customers’ wallets with the same robust technology we use to protect the most important cryptocurrency exchanges. CYBAVO Wallet App SDK allows you to develop your own cryptocurrency wallet, backed by CYBAVO private key protection technology.

### Mobile SDK
Use CYBAVO Wallet App SDK to easily develop secure wallets for your users without having to code any cryptography on your side. Our SDK allows you to perform the most common operations, such as creating a wallet, querying balances and executing cryptocurrency payments.

### Secure key management system
Key management is the most critical part of cryptocurrency storage. CYBAVO Wallet App SDK makes our robust private key storage system available to all of your users. Our unique encryption scheme and a shared responsibility model offers top notch protection for your customer’s keys.

### CYBAVO Security Cloud
Cryptocurrency transactions performed by wallets developed with CYBAVO Wallet App SDK will be shielded by our Security Cloud, ensuring their integrity.

## Complete solution for cryptocurrency wallets

### Cost saving
Leverage your in-house developing team and develop mobile cryptocurrency apps without compromising on security.

### Fast development
Quickly and easily develop cryptocurrency applications using mobile native languages, without having to worry about cryptographic code.

### Full Node maintenance
Leverage CYBAVO Wallet App SDK infrastructure and avoid maintaining a full node for your application.

Feel free to contact us for product inquiries or mail us: info@cybavo.com

# CYBAVO

A group of cybersecurity experts making crypto-currency wallet secure and usable for your daily business operation.

We provide VAULT, wallet, ledger service for cryptocurrency. Trusted by many exchanges and stable-coin ico teams, please feel free to contact us when your company or business need any help in cryptocurrency operation.

# Run the demo app
1. In ~/.ssh/ create a file called config with contents based on this:
    ```
    Host bitbucket.org
    HostName bitbucket.org
    User git
    IdentityFile ~/.ssh/{{your private key}}
    ```
2. Edit `Podfile`, Replace `source 'https://bitbucket.org/cybavo/Specs.git'` with
  * `https://bitbucket.org/cybavo/Specs_501.git` if using Xcode 10.2.1, Xcode 10.3
  * `https://bitbucket.org/cybavo/Specs_510.git` if using >= Xcode 11
3. Run ```pod install``` to install all dependencies.
4. Open ```CYBAVOWallet.xcworkspace``` in xcode.
5. Edit `Settings.bundle`/`Root.plist` ➜ `SERVICE_ENDPOINT` to your Wallet Service endpoont. (or edit it later in Settings)
6. Edit `Settings.bundle`/`Root.plist` ➜ `SERVICE_API_CODE` to fill in your API Code. (or edit it later in Settings)
7. Edit `AppDelegate.swift` ➜ `MY_GOOGLE_SIGN_IN_WEB_CLI_ID` to your Google sign-in client ID
8. Now you can run it on your device!

# Initialization in your app
Add the following code to your AppDelegate.swift file.
```swift
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
       
        WalletSdk.shared.endPoint = <Your endpoint url>
        WalletSdk.shared.apiCode = <Your API code>

        return true
    }
```    

# Features
- Sign in / Sign up with 3rd-party account system - Google Account
- Wallet Creation / Editing
- Wallet Deposit / Withdrawal
- Transaction History query
- PIN Code configuration: Setup / Change / Recovery
- Secure PIN code input view
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
                            buttonTextFont: nil,//optional, set nil and text size will be calculated according to button size
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
                            backspaceButtonTextFont: nil,//optional, set nil and text size will be calculated according to button size
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
                if(length == pinInputView!.getMaxLength()){
                    let pinSecret = pinInputView.submit()
                }
            }
        }
        ```
    3. Get `PinSecret` by `NumericPinCodeInputView.submit()` and pass it to Wallet and Auth API
        ```swift
         let pinSecret = pinInputView.submit()
         Wallets.shared.createTransaction(fromWalletId: w.walletId, toAddress: toAddress, amount: amount, transactionFee: ""
                            , description: "", pinSecret: pinSecret, extras:  extras) { result in }
        ```
    4. PinSecret will be clear after Wallet and Auth API executed.
         If you want to use the same `PinSecret` with multiple API calls,
         please call `pinSecret.retain()` before call API.
        ```swift
        pinSecret.retain()// Retain for createWallet() after setupPinCode()
        Auth.shared.setupPinCode(pinSecret: pinSecret) { result in
            switch result {
            case .success(_):
                pinSecret.retain()// Retain so that pinSecret can be used after createWallet()
                Wallets.shared.createWallet(currency: 0, tokenAddress: "", parentWalletId: 0, name: "BTC", pinSecret: pinSecret) {result in}
                break
            case .failure(let error):
                break
            }
        }
        ```
    5. You can also use `NumericPinCodeInputView.clear()`to clear current input
        ```swift
        pinInputView.clear()
        ```
