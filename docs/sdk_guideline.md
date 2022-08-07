# CYBAVO Wallet APP SDK (for iOS) - Guideline

> Welcome to CYBAVO Wallet APP SDK (for iOS) - Guideline

The **CYBAVO Wallet APP SDK** provides a thorough solution for building Institutional-grade security wallets.  
It provides both high-level and low-level APIs for nearly all **CYBAVO Wallet APP** features, backed by **CYBAVO** private key protection technology.

- Category
  - [SDK Guideline](#sdk-guideline)
  - [Auth](#auth)
  - [PIN Code](#pin-code)
  - Wallets ➜ [wallets.md](wallets.md)
  - Transaction ➜ [transaction.md](transaction.md)
  - Security Enhancement ➜ [bio_n_sms.md](bio_n_sms.md)
  - [Push Notification](#push-notification)
  - [Others](#others)
  - Advanced
    - NFT ➜ [NFT.md](NFT.md)
    - WalletConnect ➜ [wallet_connect.md](wallet_connect.md)
    - Private Chain ➜ [private_chain.md](private_chain.md)
    - KYC with Sumsub ➜ [kyc_sumsub.md](kyc_sumsub.md)

## SDK Guideline

### Prerequisite

Please contact **CYBAVO** to get your `endPoint` and `apiCode`.

### Installation

- CocoaPods `1.1.0+` is required to build `CYBAVOWallet 1.2.0+`  
- specify in your `Podfile`:

    ```sh
    source 'https://github.com/CocoaPods/Specs.git'
    source 'https://bitbucket.org/cybavo/Specs_512.git'

    platform :ios, '14.0'
    use_frameworks!

    target '<Your Target Name>' do
        pod 'CYBAVOWallet', '~> 1.2.0'
    end
    ```

- Then, run the following command:  

    ```shell
    pod install
    ```

### Setup

- Add the following code in your `AppDelegate.swift`, or your WalletSDK Manager.

  ```swift
  WalletSdk.shared.endPoint = <Your endpoint url>
  WalletSdk.shared.apiCode = <Your API code>
  ```

- See this : [Sandbox Environment](#sandbox-environment)

### APP Flowchart

![ref](images/sdk_guideline/app_flowchart.jpg)

### First-time login tasks

![ref](images/sdk_guideline/first_time_login.jpg)

[↑ go to the top ↑](#cybavo-wallet-app-sdk-for-ios---guideline)

---

# Auth

## Sign-in / Sign-up Flowchart

![ref](images/sdk_guideline/signin_signup.jpg)

## Third-Party Login

  Supported services : Apple / Google / Facebook / LINE / Twitter / WeChat

## Sign-in Flow

- 3rd party login ➡️ `Auth.signIn` ➡️ get success ➡️ wait for `SignInStateDelegate` update
  
- 3rd party login ➡️ `Auth.signIn` ➡️ get `.ErrRegistrationRequired` ➡️ Sign-up flow

```swift
/// sign-in with CYBAVOWallet Auth
///
/// - Parameters:
///   - token: Token String from different 3rd party SDK
///     1. Apple - authorization.credential.identityToken
///     2. Google - user.authentication.idToken
///     3. Facebook - AccessToken.current.tokenString
///     4. LINE - LoginResult.accessToken.value
///     5. Twitter - identity token
///     6. WeChat - identity token
///
///   - identityProvider: String of provider
///     1. Apple - "Apple"
///     2. Google - "Google"
///     3. Facebook - "Facebook"
///     4. LINE - "LINE"
///     5. Twitter - "Twitter"
///     6. WeChat - "WeChat"
///
///   - extras: Extra attributes for specific provider, pass null if unspecified.
///     1. id_token_secret (String) - Secret for Twitter
///
///   - completion: Result<_, ApiError>
///     case success: ➡️ Ready to getUserState()
///     case failure: if ErrorCode == .ErrRegistrationRequired ➡️ go to the Sign-up flow
///
public func signIn(token: String, identityProvider: String, extras: [String : String] = [:], completion: @escaping CYBAVOWallet.Callback<CYBAVOWallet.SignInResult>)
```

## Sign-up Flow

- `Auth.signUp` ➡️ get success ➡️ `Auth.signIn`

```swift
/// sign-up with CYBAVOWallet Auth
/// - Parameters:
///   - token: Refer to func signIn()
///   - identityProvider: Refer to func signIn()
///   - extras: Extra attributes for specific provider, pass null if unspecified.
///     1. id_token_secret (String) - Secret for Twitter
///     2. user_name (String) - User name, required for Apple auth
///
///   - completion: Result<_, ApiError>
///   case success: ➡️ Ready to signIn()
///   case failure: Handle ApiError
///
public func signUp(token: String, identityProvider: String, extras: [String : String] = [:], completion: @escaping CYBAVOWallet.Callback<CYBAVOWallet.SignUpResult>)
```
## Sign-out

```swift
public func signOut()
```

## Model : SignInState

```swift
public enum SignInState {

    case SignedIn // User signed in

    case SignedOut // User signed out

    case needVerifyOtp // User has signed in but need verify otp(sms code)

    case needRegisterPhone // User has signed in but need register phone

    ...
}
```

- monitor `SignInState`

  1. Call `addSignInStateDelegate()` in your auth manager.
  2. Conform `SignInStateDelegate` to handle `onUserStateChanged()` callback.  
  ⚠️ Remember to call `getSignInState()` when you get ready to receive `onUserStateChanged`, because iOS WalletSDK will only trigger delegate's `onUserStateChanged()` after `getSignInState()` has been called.
  3. Call `removeSignInStateDelegate()` if you don’t need monitor anymore.

  ```swift
  public func addSignInStateDelegate(_delegate: CYBAVOWallet.SignInStateDelegate)

  public func removeSignInStateDelegate(_ delegate: CYBAVOWallet.SignInStateDelegate)

  public protocol SignInStateDelegate : AnyObject {
      func onUserStateChanged(state: CYBAVOWallet.SignInState)
  }
  ```
- For Security Enhancement in the [flowchart](#sign-in--sign-up-flowchart), `.needVerifyOtp` and `.needRegisterPhone` SignInState, please see [Security Enhancement](bio_n_sms.md).

- Call `getSignInState()` whenever you need current `CYBAVOWallet.SignInState`.

  ```swift
  public func getSignInState() -> CYBAVOWallet.SignInState
  ```

## Model : UserState

```swift
public protocol UserState {

    var realName: String { get } /* Real name of user */

    var email: String { get } /* Email of user */

    var setPin: Bool { get } /* User has finished PIN setup */

    var setSecurityQuestions: Bool { get } /* User has setup BackupChallenges */

    ...
}
```

- Once you signed in, you should get the current `UserState` to check the variable `setPin`.

  `if (setPin == false)` ➡️ go to **_Setup PIN Code_** in the next section

- Call `Auth.getUserState` to get the current `UserState`

  ```swift
  public func getUserState(completion: @escaping CYBAVOWallet.Callback<CYBAVOWallet.GetUserStateResult>)
  ```

## Account deletion
For account deletion, Wallet SDK provides `revokeUser()` API and the detailed flow is described as below.
1. Check `UserState.setPin` 

    - If it's true, ask user to input PIN and call `revokeUser(pinSecret: PinSecret, completion: callback)`.
    - If it's false, just call `revokeUser(completion: callback)`.

2. (Suggest) Lead user back to sign in page without calling `signOut()` and sign out 3rd party SSO.  
⚠️ After `revokeUser()`, `signOut()` will trigger `onUserStateChanged` with state `.SessionExpired`.  

3. On the admin panel, the user will be mark as disabled with extra info: unregistered by user, then the administrator can remove PII (real name, email and phone) of the user.  

4. This account still can be enabled by administrator if needed. Before being enabled, if the user trying to sign in with revoked account, `signIn()` API will return `.ErrUserRevoked` error.  

[↑ go to the top ↑](#cybavo-wallet-app-sdk-for-ios---guideline)

---

# PIN Code

PIN Code is one of the most important components for user security.  
Ensure your users setPIN right after sign-in success.

## NumericPinCodeInputView

- Use `NumericPinCodeInputView` to input PIN code, see [this](NumericPinCodeInputView.md)
- feel free to customize your own input view.

## Setup PIN Code / Change PIN Code

- Setup PIN code is mandatory for further API calls. Make sure your user setup PIN code successfully before creating wallets.

``` swift
/// setup PIN code
/// - Parameters:
///   - pinSecret: PIN secret retrieved via PinCodeInputView
///   - completion: asynchronous callback
public func setupPinCode(pinSecret: CYBAVOWallet.PinSecret, completion: @escaping CYBAVOWallet.Callback<CYBAVOWallet.SetupPinCodeResult>)

public func changePinCode(newPinSecret: CYBAVOWallet.PinSecret, currentPinSecret: CYBAVOWallet.PinSecret, completion: @escaping CYBAVOWallet.Callback<CYBAVOWallet.ChangePinCodeResult>)
```

## Reset PIN code - with Security Question
- There are 2 ways to reset PIN code, one is by answering security questions

  1. Before that, the user has to set the answers of security questions.  
  ⚠️ Please note that the account must have at least a wallet, otherwise, the API will return `.ErrNoWalletToBackup` error.
  ```swift
  public func setupBackupChallenge(pinSecret: CYBAVOWallet.PinSecret, challenge1: CYBAVOWallet.BackupChallenge, challenge2: CYBAVOWallet.BackupChallenge, challenge3: CYBAVOWallet.BackupChallenge, completion: @escaping CYBAVOWallet.Callback<CYBAVOWallet.SetupPinCodeResult>)
  ```
  2. Get the security question for user to answer
  ```swift
  public func getRestoreQuestions(completion: @escaping CYBAVOWallet.Callback<CYBAVOWallet.GetRestoreQuestionsResult>)
  ```
  3. Verify user input answer (just check if the answers are correct)
  ```swift
  public func verifyRestoreQuestions(challenge1: CYBAVOWallet.BackupChallenge, challenge2: CYBAVOWallet.BackupChallenge, challenge3: CYBAVOWallet.BackupChallenge, completion: @escaping CYBAVOWallet.Callback<CYBAVOWallet.VerifyRestoreQuestionsResult>)
  ```
  4. Reset PIN code by security questions and answers
  ```swift
  public func restorePinCode(pinSecret: CYBAVOWallet.PinSecret, challenge1: CYBAVOWallet.BackupChallenge, challenge2: CYBAVOWallet.BackupChallenge, challenge3: CYBAVOWallet.BackupChallenge, completion: @escaping CYBAVOWallet.Callback<CYBAVOWallet.ChangePinCodeResult>)
  ```

## Reset PIN code - with Admin System

- If the user forgot both the PIN code and the answers which they have set.

  1. First, call API `forgotPinCode` to get the **_Handle Number_**.
  ```swift
  public func forgotPinCode(completion: @escaping Callback<ForgotPinCodeResult>)
  ```

  2. Second, contact the system administrator and get an 8 digits **_Recovery Code_**.
  3. Verify the recovery code  (just check if the recovery code is correct)
  ```swift
  public func verifyRecoveryCode(recoveryCode: String, completion: @escaping Callback<VerifyRecoveryCodeResult>)
  ```
  4. Reset PIN code by the recovery code.

  ```swift
  public func recoverPinCode(pinSecret: PinSecret, recoveryCode: String, completion: @escaping Callback<RecoveryPinCodeResult>)
  ```

## Notice

- Old version `pinCode: String` was deprecated, use `CYBAVOWallet.PinSecret` instead.

  `CYBAVOWallet.PinSecret` advantages:
    1. Much more secure
    2. Compatible with NumericPinCodeInputView
    3. Certainly release the PIN code with API  

- `PinSecret` will be cleared after Wallet and Auth APIs are executed. If you intendly want to keep the `PinSecret`, call `PinSecret.retain()` everytime before APIs are called.

> **⚠️ WARNING** : When creating multiple wallets for the user. If you call APIs constantly.  
> You will receive the error `.ErrInvalidPinSecret` caused by `PinSecret` being cleared.

[↑ go to the top ↑](#cybavo-wallet-app-sdk-for-ios---guideline)

---

# Push Notification

> Wallet SDK support 2 ways to integrate Push Notification: **Amazon Pinpoint** and **Google Firebase**

  <img src="images/sdk_guideline/screenshot_push_notification.png" alt="drawing" width="400"/>  

## Install and configuration

- For admin panel configuration, please refer to "Amazon Pinpoint / Google Firebase" section in CYBAVO Wallet SDK Admin Panel User Manual.
- Registering Your App with APNs, refer [this](https://developer.apple.com/documentation/usernotifications/registering_your_app_with_apns)
- Amazon Pinpoint：could also refer [this](https://github.com/CYBAVO/ios_wallet_sdk_sample/blob/master/docs/PushNotification.md)

## Setup

- Step 1 : decide your `pushDeviceToken` string
  - Amazon Pinpoint

    ```swift
    extension AppDelegate: UNUserNotificationCenterDelegate {
      
      func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
          let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
          let token = tokenParts.joined()
          debugPrint("Device APNs Push Token: \(token)")
          
          UserManager.shared.pushDeviceToken = token
      }

      ...
    }
    ```

  - Google Firebase

    ```swift
    Messaging.messaging().delegate = self

    extension AppDelegate: MessagingDelegate {
    
        func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
            debugPrint("Device FCM Token: \(String(describing: fcmToken))")
            
            UserManager.shared.pushDeviceToken = fcmToken
        }
    }
    ```

- Step 2 : enable the WalletSdk apnsSandbox (for Dev environment)

  ```swift
  #if DEBUG
  WalletSdk.shared.apnsSandbox = true
  #endif
  ```

- Step 3 : After signed in, `setPushDeviceToken`
  
  ```swift
  /// Set Firebase Cloud Messaging (FCM) or Amazon Pinpoint device token
  /// - Parameters:
  ///   - deviceToken: The device token retrieved from FCM SDK or AWS SDK
  ///   - completion: asynchronous callback
  public func setPushDeviceToken(deviceToken: String, completion: @escaping CYBAVOWallet.Callback<CYBAVOWallet.SetPushDeviceTokenResult>)
  ```

  ```swift
  // After user Signed In
  guard Auth.shared.getSignInState() == .SignedIn else { return }

  // Set the push device token
  Auth.shared.setPushDeviceToken(deviceToken: pushDeviceToken) {
      ...
  }
  ```

- Step 4 : Receive and handle the notification

  ```swift
  func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {

      // Demo for 'Transaction' type

      let amount = userInfo["amount"] as? String ?? ""
      let from = userInfo["from_address"] as? String ?? ""
      let to = userInfo["to_address"] as? String ?? ""
      let out = userInfo["out"] as? String ?? ""
      let content = UNMutableNotificationContent()
      
      if (out == "true") {
          content.title = "Transaction Send"
          content.body = "Amount \(amount) from \(from)"
      } else {
          content.title = "Transaction Received"
          content.body = "Amount \(amount) to \(to)"
      }
      content.badge = 1
      content.sound = UNNotificationSound.default
      
      print("didReceiveRemoteNotification \(content.title)_\(content.body)")
      
      let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
      let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
      UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
      
      completionHandler(.newData)
  }
  ```

## Notification Types

There are 2 types of push notification: **Transacion** and **Announcement**.

1. Transaction
  
    ```swift
    {
        "currency": "194",
        "token_address": "",
        "timestamp": "1590376175",
        "fee": "",
        "from_address": "eeeeeeeee111",
        "amount": "0.0010",
        "wallet_id": "2795810471",
        "abi_method": "",
        "to_address": "eeeeeeeee111",
        "type": "1", // 1 means type Transaction
        "txid": "c90e839583f0fda14a1e055065f130883e5d2c597907de223f355b115b410da4",
        "out": "true", // true is Withdraw, false is Deposit
        "description": "d", 
        "abi_arguments": ""
    }
    ```

    - The keys of **Transaction** type are listed below
      Key    | Description  | Type  
      :------------|:------------|:-------
      type    | notification type    |  String
      wallet_id    | Wallet ID    |  String
      currency    | Currency     |  String
      token_address  | Token address | String
      out  | Transaction direction<br>("true": out, "false": in)| String
      amount  | Transaction amount | String
      fee  | Transaction fee | String
      from_address  | Transaction from address | String
      to_address  | Transaction to address | String
      timestamp  | Transaction timestamp | String
      txid  | Transaction TXID | String
      description  | Transaction description | String

    - Sample :

      - Withdraw (currencySymbol was from API getWallets)

        ```String
        Transaction Sent: Amount {{amount}} {{currencySymbol}} to {{fromAddress}}
        ```

      - Deposit (NFT wallet, i.e. wallet mapping to a Currency which tokenVersion is 721 or 1155)

        ```string
        Transaction Received: Token {{amount}}({{currencySymbol}}) received from {{fromAddress}}
        ```

2. Announcement

    ```JSON
    {
        "body": "All CYBAVO Wallet users will be charged 0.1% platform fee for BTC transaction during withdraw since 2021/9/10",
        "sound": "default",
        "title": "Important information",
        "category": "myCategory"
    }
    ```

[↑ go to the top ↑](#cybavo-wallet-app-sdk-for-ios---guideline)

---

# Others

## Error Handling - ApiError

> **⚠️ WARNING** : Please properly handle the ApiError we provided in the API response.

```swift
public struct ApiError : Error {

    public enum ErrorCode : Int { … } // some error codes we defined
    
    public let code: CYBAVOWallet.ApiError.ErrorCode

    public let message: String

    public var name: String { get }

    public init(code: CYBAVOWallet.ApiError.ErrorCode, message: String)
}
```

## Sandbox Environment

- You will only get the `endPoint` & `apiCode` for testing in the beginning.
- We will provide the production `endPoint` & `apiCode` when you are ready.
Feel free to play around with the WalletSDK in the sandbox environment.

[↑ go to the top ↑](#cybavo-wallet-app-sdk-for-ios---guideline)
