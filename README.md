# CYBAVO Wallet APP SDK for iOS - Sample

> Sample app for integrating Cybavo Wallet App SDK, <https://www.cybavo.com/wallet-app-sdk/>

## Institutional-grade security for your customers

Protect your customers' wallets with the same robust technology we use to protect the most important cryptocurrency exchanges. CYBAVO Wallet App SDK allows you to develop your own cryptocurrency wallet, backed by CYBAVO private key protection technology.

- Mobile SDK

    Use CYBAVO Wallet App SDK to easily develop secure wallets for your users without having to code any cryptography on your side. Our SDK allows you to perform the most common operations, such as creating a wallet, querying balances and executing cryptocurrency payments.

- Secure key management system

    Key management is the most critical part of cryptocurrency storage. CYBAVO Wallet App SDK makes our robust private key storage system available to all of your users. Our unique encryption scheme and a shared responsibility model offers top notch protection for your customer's keys.

- CYBAVO Security Cloud

    Cryptocurrency transactions performed by wallets developed with CYBAVO Wallet App SDK will be shielded by our Security Cloud, ensuring their integrity.

## Complete solution for cryptocurrency wallets

- Cost saving

    Leverage your in-house developing team and develop mobile cryptocurrency apps without compromising on security.

- Fast development

    Quickly and easily develop cryptocurrency applications using mobile native languages, without having to worry about cryptographic code.

- Full Node maintenance

    Leverage CYBAVO Wallet App SDK infrastructure and avoid maintaining a full node for your application.

---

# CYBAVO

A group of cybersecurity experts making crypto-currency wallets secure and usable for your daily business operation.

We provide VAULT, wallet, ledger service for cryptocurrency. Trusted by many exchanges and stable-coin ico teams, please feel free to contact us when your company or business needs any help in cryptocurrency operation.

# SDK Features

- Sign in / Sign up with 3rd-party account services
- Wallet Creation / Editing
- Wallet Deposit / Withdrawal
- Transaction History query
- PIN Code configuration: Setup / Change / Recovery
- Secure PIN code input view - NumericPinCodeInputView
- Push Notification - receive push notification of deposit / withdrawal
- Private chain, NFT and WalletConnect supported

# Run the demo app

1. In ~/.ssh/ create a file called config with contents based on this:

    ```default
    Host bitbucket.org
    HostName bitbucket.org
    User git
    IdentityFile ~/.ssh/{{your private SSH key}}
    ```

    > How to setup an SSH key? : see [this](https://support.atlassian.com/bitbucket-cloud/docs/set-up-an-ssh-key/)

2. Run ```pod install``` to install all dependencies.
3. Run ```pod update``` to update all dependencies. **(Optional)**
4. Open ```CYBAVOWallet.xcworkspace``` in xcode.
5. Change the `Bundle Identifier` to yours and update signing settings.
6. Edit `Settings.bundle`/`Root.plist` ➜ `SERVICE_ENDPOINT` to your Wallet Service endpoint.
7. Edit `Settings.bundle`/`Root.plist` ➜ `SERVICE_API_CODE` to fill in your API Code.
8. Edit `AppDelegate.swift` ➜ `MY_GOOGLE_SIGN_IN_WEB_CLI_ID` to your Google sign-in client ID **(Optional)**
9. Now you can run it on your device!

# More Details

see this : [**SDK Guideline**](docs/sdk_guideline.md)