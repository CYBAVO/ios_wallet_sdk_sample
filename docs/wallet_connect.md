# WalletConnect

> WalletConnect is an open protocol which makes Dapps able to interact with wallets on different platforms.  
Wallet SDK provides corresponding APIs which help you get the results to return to Dapp, after establishing a wallet client and being able to receive Dapp's request.   
In later sections, we'll illustrate how to use those APIs to respond to [session request](https://docs.walletconnect.com/tech-spec#session-request) and JSON-RPC call requests which are defined in [JSON-RPC API Methods](https://docs.walletconnect.com/json-rpc-api-methods/ethereum).   
Wallet clients integration on iOS : see [this](https://docs.walletconnect.com/quick-start/wallets/swift)  
WalletConnect Introduction: [WalletConnect v1.0](https://docs.walletconnect.com/)

- Bookmark:
  - [Session Request](#session-request)
  - [JSON-RPC Call Requests](#json-rpc-call-requests)
  - [API History](#api-history)
  - [Cancel a Transaction](#cancel-a-transaction)

## [Session Request](https://docs.walletconnect.com/tech-spec#session-request)

> TODO: flow chart  
(receive session request > call getWalletsByChainIds (pass -1 to get all) > filter !isPrivate && tokenAddress == '' > user select wallet and click approve > call walletconnect's approveSession with wallet address & chainId )

- TODO: explaination of flow chart

- Response parameters:
    1. `chainId = Wallet.chainId`
    2. `accounts = [Wallet.address]`

        ```swift
        protocol Wallet : CYBAVOWallet.BalanceAddress, CYBAVOWallet.CurrencyType {

            var walletId: Int64 { get } // Wallet ID

            override var address: String { get } // Wallet address

            var chainId: Int64 { get } // Currency chain ID

            ...
        }
        ```

## [JSON-RPC Call Requests](https://docs.walletconnect.com/json-rpc-api-methods/ethereum)

- ### [personal_sign](https://docs.walletconnect.com/json-rpc-api-methods/ethereum#personal_sign)

  - Use `walletConnectSignMessage()` to sign a message. ➜ Response to WalletConnect
  - Suggestion: `extras = [“is_hex”: true]` to avoid encode / decode issues which lead to invalid signatures.

    ```swift
    /// Sign message by wallet private key(eth_sign, personal_sign) via WalletConnect
    ///
    /// - This call will be logged as ApiHistoryItem with API name: eth_sign note: Only support ETH & TRX. Result is same as following links:
    /// - ETH: https://github.com/MetaMask/eth-sig-util/blob/v4.0.0/src/personal-sign.ts#L27-L45
    /// - TRX: https://github.com/TRON-US/tronweb/blob/461934e246707bca41529ab82ebe76cf894ab460/src/lib/trx.js#L712-L731
    ///
    /// - Parameters:
    ///   - actionToken: used for Biometrics / SMS transaction
    ///   - signature: used for Biometrics transaction
    ///   - smsCode: used for SMS transaction
    ///   - walletId: ID of wallet
    ///   - message: message to sign
    ///   - pinSecret: PIN secret retrieved via PinCodeInputView
    ///   - extras: Extra attributes for specific currencies, pass null if unspecified.
    ///       - Supported extras:
    ///           - eip155 (Boolean) = true - Use EIP 155 format to sign message
    ///           - is_hex (Boolean) = true - Send Hex as message
    ///           - legacy (Boolean) = true - Use legacy sign and suggest send hex as message(is_hex set true)
    ///   - completion: asynchronous callback of signedMessage
    public func walletConnectSignMessage(actionToken: String = "", signature: String = "", smsCode: String = "", walletId: Int64, message: String, pinSecret: CYBAVOWallet.PinSecret, extras: [String : Any] = [:], completion: @escaping CYBAVOWallet.Callback<CYBAVOWallet.SignedMessageResult>)
    ```

    - Use different functions for biometrics & SMS Verification: see [this](bio_n_sms.md#biometrics--sms-verification-for-transaction-and-sign-operation)

- ### [eth_sign](https://docs.walletconnect.com/json-rpc-api-methods/ethereum#eth_sign)

  - as above, [personal_sign](#personalsign)

- ### [eth_signTypedData](https://docs.walletconnect.com/json-rpc-api-methods/ethereum#eth_signtypeddata)

  - Use `walletConnectSignTypedData()` to sign a typed data. ➜ Response to WalletConnect

    ```swift
    /// Sign typed data(eth_signTypedData) via WalletConnect, this call will be logged as ApiHistoryItem with API
    /// - API eth_signTypedData: https://docs.walletconnect.org/json-rpc-api-methods/ethereum#eth_signtypeddata
    ///
    /// - Parameters:
    ///   - actionToken: used for Biometrics / SMS transaction
    ///   - signature: used for Biometrics transaction
    ///   - smsCode: used for SMS transaction
    ///   - walletId: wallet ID
    ///   - typedData: typed data json string
    ///   - pinSecret: PIN secret retrieved via PinCodeInputView
    ///   - completion: asynchronous callback of SignedRawTxResult
    public func walletConnectSignTypedData(actionToken: String = "", signature: String = "", smsCode: String = "", walletId: Int64, typedData: String, pinSecret: CYBAVOWallet.PinSecret, completion: @escaping CYBAVOWallet.Callback<CYBAVOWallet.SignedRawTxResult>)
    ```

    - Use different functions for biometrics & SMS Verification: see [this](bio_n_sms.md#biometrics--sms-verification-for-transaction-and-sign-operation)
    - Always check and send valid `typedData`. More specification: see [this](https://eips.ethereum.org/EIPS/eip-712#specification-of-the-eth_signtypeddata-json-rpc) 

- ### [eth_signTransaction](https://docs.walletconnect.com/json-rpc-api-methods/ethereum#eth_signtransaction)

    1. Check and adjust the Tx object if necessary, the Tx object must at least contain `gas`, `gasPrice` and `nonce`.   
    You can use `getEstimateGas`, `getTransactionFee` and `getNonce` to get corresponding values and set its hex string to the Tx object.
    2. Use `walletConnectSignTransaction()` to sign a transaction. ➜ Response to WalletConnect 

        ```swift
        /// Signs a transaction(eth_signTransaction) via WalletConnect, this call will be logged as ApiHistoryItem with API name:
        /// - eth_signTransaction - https://docs.walletconnect.org/json-rpc-api-methods/ethereum#eth_signtransaction
        ///
        /// - Parameters:
        ///   - actionToken: used for Biometrics / SMS transaction
        ///   - signature: used for Biometrics transaction
        ///   - smsCode: used for SMS transaction
        ///   - walletId: wallet ID
        ///   - signParams: transaction object json string
        ///   - pinSecret: PIN secret retrieved via PinCodeInputView
        ///   - completion: asynchronous callback of SignedRawTxResult
        public func walletConnectSignTransaction(actionToken: String = "", signature: String = "", smsCode: String = "", walletId: Int64, signParams: String, pinSecret: CYBAVOWallet.PinSecret, completion: @escaping CYBAVOWallet.Callback<CYBAVOWallet.SignedRawTxResult>)
        ```

- ### [eth_sendRawTransaction](https://docs.walletconnect.com/json-rpc-api-methods/ethereum#eth_sendrawtransaction)

    1. use `walletConnectSendSignedTransaction()` to get the `txid`.
    2. During some transactions, you may receive new currencies / tokens which don't exist in the currency list, like swapping a new type of token.
    3. call `Wallets.walletConnectSync` to add currencies and wallets which are created by `walletConnectSendSignedTransaction`.
    4. call `Wallets.getWallets` to get the new wallet list

- ### [eth_sendTransaction](https://docs.walletconnect.com/json-rpc-api-methods/ethereum#eth_sendtransaction)

    1. Use `walletConnectSignTransaction()` in previous section to get the `signedTx`.   
    2. Second, use `walletConnectSendSignedTransaction()` to get the `txid`. ➜ Response to WalletConnect

        ```swift
        /// Create transaction by signed transaction(eth_sendTransaction) via WalletConnect, this call will be logged as ApiHistoryItem with API name: eth_sendRawTransaction
        /// - Parameters:
        ///   - walletId: wallet ID
        ///   - signedTx: signed transaction
        ///   - completion: asynchronous callback of SendSignedTxResult
        public func walletConnectSendSignedTransaction(walletId: Int64, signedTx: String, completion: @escaping CYBAVOWallet.Callback<CYBAVOWallet.SendSignedTxResult>)
        ```

    3. During some transactions, you may receive new currencies / tokens which don't exist in the currency list, like swapping a new type of token.
    4. call `Wallets.walletConnectSync` to add currencies and wallets which are created by `walletConnectSendSignedTransaction`.
    5. call `Wallets.getWallets` to get the new wallet list


## API History

- Call `getWalletConnectApiHistory` to get WalletConnect API history.

    ```swift
    /// Get WalletConnect API history without filter 
    /// 1. walletConnectSignTypedData(long, String, PinSecret, Callback)
    /// 2. walletConnectSignTransaction(long, String, PinSecret, Callback)
    /// 3. walletConnectSignMessage(long, String, PinSecret, Map, Callback)
    /// 4. walletConnectSendSignedTransaction(long, String, Callback)
    ///
    /// - Parameters:
    ///   - walletId: wallet ID
    ///   - start: Query start offset
    ///   - count: Query count returned
    ///   - filters: Filter parameters:
    ///     - api_name (String) - API name
    ///     - start_time (Long) - Start of time period to query, in Unix timestamp
    ///     - end_time (Long) - End of time period to query, in Unix timestamp
    ///   - completion: asynchronous callback of GetApiHistoryResult
    public func getWalletConnectApiHistory(walletId: Int64, start: Int, count: Int, filters: [String : Any] = [:], completion: @escaping CYBAVOWallet.Callback<CYBAVOWallet.GetApiHistoryResult>)
    ```

## Cancel a Transaction

- In list of `ApiHistoryItemInternal`

    ```swift
    protocol ApiHistoryItemInternal {

        var apiName: String { get } // API Name

        var accessId: String { get } // access ID for eth_sendRawTransaction

        var status: Int { get } // Transaction status { WAITING, FAILED, DONE, DROPPED }

        var nonce: Int64? { get } // Nonce

        var gasPrice: String { get } // Gas price

        var gasLimit: String { get } // Gas limit

        ...
    }
    ```

- How to determine if a transaction can be canceled or not?
    1. `apiName == "eth_sendRawTransaction"`
    2. `accessId != ""`
    3. `status == .WAITING`

- How to cancel a transaction?
    1. Decide a new transaction fee.
    2. Call `cancelWalletConnectTransaction` to cancel a WalletConnect Transaction

- How to decide the new transaction fee?
    1. Call `getTransactionFee` to get the current Tx fee.
    2. Decide a new Tx fee
        - if (Tx fee > original Tx fee) ➜ use the new Tx fee
        - if (Tx fee <= original Tx fee) ➜ decide a higher Tx fee by your rules
            - Suggestion: In our experience, (original Tx fee) * 1.1 might be an easy way to calculate a new price for doing this operation.
    3. same as [Transaction_Replacement](transaction.md#transaction-replacement)

- How to see the cancel history?
    1. In list of `ApiHistoryItemInternal`
        - filter `apiName == "eth_sendRawTransaction"` ➜ original Tx operation
        - filter `apiName == "eth_cancelTransaction"` ➜ cancel Tx operation
        - Use `nonce` to map same pair of operations
    2. In same pair of operations:
        - When cancel operation's `status == .DONE` means cancel operation success.
        - When origin Tx operation's `status == .DONE` means cancel operation failed. The original Tx was succeeded.
    3. refer to [Transaction Replacement History](transaction.md#transaction-replacement-history)
