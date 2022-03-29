# Biometrics & SMS Verification

- Bookmarks
  - [UserState](#userstate)
  - [Setup](#biometrics--sms-verification-setup)
  - [Send SMS](#gettransactionsmscode)

## UserState

- Biometrics verification was controlled in the Security Enhancement Section at the Admin panel.  

  <img src="images/sdk_guideline/screenshot_security_enhancement.png" alt="drawing" width="400"/> 

    ```swift
    public protocol UserState {

        var enableBiometrics: Bool { get } // Is enable biometric authentication

        var skipSmsVerify: Bool { get } // Is skip SMS/Biometrics verify

        var accountSkipSmsVerify: Bool { get } // Is skip SMS for specific case, ex. Apple account

        ...
    }
    ```

- `if (enableBiometrics && !skipSmsVerify)` ➜ need Biometrics / SMS verification for every transaction operation

- `if (accountSkipSmsVerify == true)` ➜ cannot use SMS for verification, use Biometrics verification instead.

    e.g. Apple Sign-In can only verify transactions with Biometrics

- There are two versions (Biometrics and SMS) for following transaction APIs:
  - createTransaction
  - requestSecureToken
  - signRawTx
  - increaseTransactionFee
  - callAbiFunction
  - cancelTransaction
  - callAbiFunctionTransaction
  - signMessage
  - walletConnectSignTypedData
  - walletConnectSignTransaction
  - walletConnectSignMessage
  - cancelWalletConnectTransaction

  Example:
  - SMS version has the suffix 'Sms', ex. createTransactionSms
  - Biometrics version has the suffix 'Bio', ex. createTransactionBio

## Biometrics / SMS Verification Setup

![img](images/sdk_guideline/biometric_verification.jpg)

- Must set up before doing any transactions.
- Steps:
    1. call `getBiometricsType` ➜ supported biometric type
    2. call `updateDeviceInfo`, pass nil for default
        - if pass `.NONE` means you are registering for SMS verification
    3. `if (BiometryType != .NONE)` ➜ call `registerPubkey`

```swift
/// Get device's biometrics type
/// - Returns: BiometryType { NONE / FACE / FINGER }
public func getBiometricsType() -> CYBAVOWallet.BiometryType

/// Update device's biometrics type, detect type by sdk
/// - Parameters:
///   - type: BiometricsType's raw value, pass nil for default
///   - completion: asynchronous callback
public func updateDeviceInfo(type: Int?, completion: @escaping CYBAVOWallet.Callback<CYBAVOWallet.UpdateDeviceInfoResult>)

public func registerPubkey(completion: @escaping CYBAVOWallet.Callback<CYBAVOWallet.RegisterPubkeyResult>)
```

## getTransactionSmsCode

- Send a SMS to the user
- `actionToken` + `OTP code` ➜ call SMS series functions

```swift
/// get SMS code for transaction
/// - Parameters:
///   - duration: SMS expire duration (second), ex. 60
///   - completion: asynchronous callback
public func getTransactionSmsCode(duration: Int64, completion: @escaping CYBAVOWallet.Callback<CYBAVOWallet.GetActionTokenResult>)
```
