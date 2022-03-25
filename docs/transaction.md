# Transaction

- Bookmarks
  - [Deposit](#deposit)
  - [Withdraw](#withdraw)
  - [Transaction Detail](#transaction-detail)
  - [Transaction Replacement](#transaction-replacement)

## Deposit

- Select a wallet address, create a new one if needed.
- Generate QRCode
- Present the QRCode for deposit.

## Withdraw

![img](images/sdk_guideline/create-transation.jpg)

### getTransactionFee

- To get transaction fees of the selected currency,  
you will get three levels { high, medium, low } of fees for the user to select.
- `tokenAddress` is for private chain usage.
- ETH (currency = 60) ➜ Tx fee should use ETH
- ERC20 (currency = 60, tokenAddress = "") ➜ Tx fee should use ETH, too

```swift
/// Get transaction transactionFee of specified currency
/// - Parameters:
///   - currency: Currency to query
///   - tokenAddress: fee of private to public transaction
///   - completion: asynchronous callback
public func getTransactionFee(currency: Int, tokenAddress: String = "", completion: @escaping CYBAVOWallet.Callback<CYBAVOWallet.GetTransactionFeeResult>)
```

### getCurrencyTraits

- To get currency traits when you are ready to withdraw.

```swift
/// Get currency traits for withdraw restriction
/// - Parameters:
///   - currency: query currency
///   - tokenAddress: query tokenAddress
///   - tokenVersion: query tokenVersion
///   - walletAddress: query walletAddress
///   - completion: asynchronous callback of GetCurrencyTraitsResult
public func getCurrencyTraits(currency: Int, tokenAddress: String, tokenVersion: Int, walletAddress: String, completion: @escaping CYBAVOWallet.Callback<CYBAVOWallet.GetCurrencyTraitsResult>) {}
```

- Response: `GetCurrencyTraitsResult`

    ```swift
    public protocol GetCurrencyTraitsResult {

        var granularity: String { get }

        var existentialDeposit: String { get }

        var minimumAccountBalance: String { get }
    }
    ```

  - about `granularity`, see [EIP-777](https://eips.ethereum.org/EIPS/eip-777) ➜ search for granularity section
  - about `existentialDeposit`, see [this](https://support.polkadot.network/support/solutions/articles/65000168651-what-is-the-existential-deposit-)

  - about `minimumAccountBalance`, see [this](https://developers.stellar.org/docs/glossary/minimum-balance/)

### estimateTransaction

- Estimate the transaction fees to present for the user.

```swift
/// Estimate platform fee / chain fee for given transaction information
/// - Parameters:
///   - currency: Currency of desired new wallet
///   - tokenAddress: Token address for tokens, i.e. an ERC-20 token wallet maps to an Ethereum wallet
///   - amount: Amount to transfer
///   - transactionFee: Transaction transactionFee to pay
///   - walletId: Wallet ID to estimated transaction
///   - toAddress: To Address
///   - completion: asynchronous callback
public func estimateTransaction(currency: Int, tokenAddress: String, amount: String, transactionFee: String, walletId: Int64? = nil, toAddress: String? = nil, completion: @escaping CYBAVOWallet.Callback<CYBAVOWallet.EstimateTransactionResult>)
```

- Response: `EstimateTransactionResult`

    ```swift
    public protocol EstimateTransactionResult {

        var tranasctionAmout: String { get } // Estimated total amount to transaction

        var platformFee: String { get } // Estimated platform fee of transaction

        var blockchainFee: String { get } // Estimated blockchain fee of transaction

        var withdrawMin: String { get } // Minimum transfer amount for private
    }
    ```

  - `platformFee` was set on admin panel
  ![screenshot](images/sdk_guideline/screenshot_platform_fee_management.png)

### getAddressesTags

- To get an AML tag for the address.
- Be sure to provide warnings for the user if the address is in the blacklist.

```swift
/// Get AML tag for address
/// - Parameters:
///   - currency: query currency
///   - addresses: query address
///   - completion: asynchronous callback
public func getAddressesTags(currency: Int, addresses: [String], completion: @escaping CYBAVOWallet.Callback<CYBAVOWallet.GetAddressesTagsReponse>)
```

### createTransaction

- This method will try to send the transaction onto the blockchain.
- Fulfill the requirement of different types of currencies in the extras field.
- Please use the function with `PinSecret` version, the others are planning to deprecate.
- If you are making SMS transaction, refer to `createTransactionSms`
- If you are making Biometrics transaction, refer to `createTransactionBio`

```swift
/// Create a transaction from specified wallet to specified address
/// - Parameters:
///   - actionToken: used for Biometrics / SMS transaction
///   - signature: used for Biometrics transaction
///   - smsCode: used for SMS transaction
///   - fromWalletId: ID of wallet to withdraw from
///   - toAddress: Target address to send
///   - amount: Amount to transfer, token ID for ERC-721, BSC-721
///   - transactionFee: Transaction transactionFee to pay
///   - description: Description of the transaction
///   - pinSecret: PIN secret retrieved via {PinCodeInputView}
///   - extras: Extra attributes for specific currencies, pass null if unspecified.
///      - Supported extras:
///         1. memo (String) - Memo for XRP, XML, EOS, BNB
///         2. eos_transaction_type (EosResourceTransactionType) - Resource transaction type for EOS, such as buy RAM, delegate CPU
///         3. num_bytes (Long) - Bytes of RAM/NET for EOS RAM delegation/undelegation transactions. The minimal amounts are 1024 bytes
///         4. input_data (String) - Hex string of input data. Must also set gas_limit when have this attributes
///         5. gas_limit (Long) - Must specify this if there were input_data
///         6. skip_email_notification (Boolean) -Determined whether or not to skip sending notification mail after create a transaction
///         7. token_id (String) -token ID for ERC-1155
///         8. kind (String) -kind for private chain, code: private to private; out: private to public
///         9. to_address_tag (String[]) -AML tag, get from getAddressesTags() API
///      - Note:
///         - When eos_transaction_type is EosResourceTransactionType.SELL_RAM, EosResourceTransactionType.UNDELEGATE_CPU or EosResourceTransactionType.UNDELEGATE_NET, the receiver should be address of Wallet fromWalletId
///         - ex: ["memo": "abcd", "eos_transaction_type": EosResourceTransactionType.SELL_RAM.rawValue, "skip_email_notification": false, "kind": "code"]
///   - completion: asynchronous callback
///
public func createTransaction(actionToken: String = "", signature: String = "", smsCode: String = "", fromWalletId: Int64, toAddress: String, amount: String, transactionFee: String, description: String, pinSecret: CYBAVOWallet.PinSecret, extras: [String : Any] = [:], completion: @escaping CYBAVOWallet.Callback<CYBAVOWallet.CreateTransactionResult>)
```

## Transaction Detail

### getHistory

- Call this API to get the transaction history.

```swift
/// Get transaction history from
/// - Parameters:
///   - currency: Currency of the address
///   - tokenAddress: Token Contract Address of the address
///   - walletAddress: Wallet address
///   - start: Query start offset
///   - count: Query count returned
///   - crosschain: 0: history for private chain transfer; 1: history for crossing private and public chain
///                 (private chain currency is 99999999995, tokenAddress not null)
///   - filters: Filter parameters:
///     -  direction {Transaction.Direction} - Direction of transaction
///     - pending {Bool} - Pending state of transactions
///     - success {Bool} - Success state of transactions
///     - start_time {Int} - Start of time period to query, in Unix timestamp
///     - end_time {Int} - End of time period to query, in Unix timestamp
///       - ex: ["direction": Direction.OUT, "pending": true, "start_time": 1632387959]
///   - completion: asynchronous callback
public func getHistory(currency: Int, tokenAddress: String, walletAddress: String, start: Int, count: Int, crosschain: Int = 1, filters: [String : Any] = [:], completion: @escaping CYBAVOWallet.Callback<CYBAVOWallet.GetAddressHistoryResult>)
```

- Response: list of `Transaction`

    ```swift
    public protocol Transaction {

        var txid: String { get } // transaction ID

        var pending: Bool { get }

        var success: Bool { get }

        var dropped: Bool { get } // Is transaction dropped by the blockchain

        var replaced: Bool { get } // Is transaction replaced by another transaction
    
        ...
    }
    ```

    <img src="images/sdk_guideline/transaction_state.jpg" alt="drawing" width="600"/>

- If the Tx's final state is `Success` or `Pending`, you could call `getTransactionInfo` to check the information about this Tx on the blockchain.

### getTransactionInfo

- Check the information about the Tx on the blockchain.

```swift
/// Get transaction result for given txid.
/// - Parameters:
///   - currency: currency to get transaction result
///   - txid: txid of transaction
///   - completion: asynchronous callback
public func getTransactionInfo(currency: Int, txid: String, completion: @escaping CYBAVOWallet.Callback<CYBAVOWallet.GetTransactionInfoResult>)

/// the batch version of getTransactionInfo
public func getTransactionsInfo(currency: Int64, txids: [String], completion: @escaping CYBAVOWallet.Callback<CYBAVOWallet.GetTransactionsInfoResult>)
```

## Transaction Replacement

> ⚠️ Warning: Cancel / Speed-up transactions will incur a higher Tx fee for replacing the original orders.

- When user want to Cancel / Speed-up a `Pending` Tx they have made. You cannot just cancel the original order, because the order information is already on the blockchain.
- You need to do is to provide a higher Tx fee with the same Tx-id onto the blockchain, therefore you could replace the original order.
- Condition: `replaceable == true`

  ```swift
  public protocol Transaction {

      var txid: String { get }
      
      var replaceable: Bool { get } // Is transaction replaceable

      var replaced: Bool { get } // Is transaction replaced by another transaction

      var replaceTxid: String { get } // TXID of replacement of this transaction if {@link #replaced} == true

      var nonce: Int { get } // Nonce of transaction, only valid on ETH, same nonce means replacements
      
      ...
  }
  ```
  
  - Steps:
    1. Call `getTransactionFee` to get the current Tx fee.
    2. Decide a new Tx fee
        - if (Tx fee > original Tx fee) ➜ use the new Tx fee
        - if (Tx fee <= original Tx fee) ➜ decide a higher Tx fee by your rules
            - Suggestion: In our experience, (original Tx fee) * 1.1 might be a easy way to calculate a new price for doing this operation.
    3. Call `cancelTransaction` for canceling transactions.
    4. Call `increaseTransactionFee` for speeding-up transactions.

### Transaction Replacement History

- In the result of `getHistory`, you will need to determine different states for a transaction.
- How to determine a transaction is replaced or not:
    1. filter `platformFee == false` ➜ reduce the transactions which are platform fees.
    2. filter `nonce != 0` ➜ reduce normal transactions
    3. mapping transactions with the same nonce
    4. in a set of transactions:
        - the Tx fee lower one ➜ the original order
        - `if Tx1.amount == Tx2.amount` ➜ is Speed-up transaction operation
        - `if Tx.amount == 0` ➜ is Cancel transaction operation
        - `if Tx1.replaced == false && Tx2.replaced == false` ➜ is operating
        - `if Original-Tx.replaced == true` ➜ Cancel / Speed-up success
        - `if Replacement-Tx.replaced == true` ➜ Cancel / Speed-up failed
