# Transaction

- Bookmarks
  - [Deposit](#deposit)
  - [Withdraw](#withdraw)
  - [Transaction Detail](#transaction-detail)
  - [Transaction Replacement](#transaction-replacement)
  - [Interact with Smart Contract](#interact-with-smart-contract)

## Deposit

- Select a wallet address, create a new one if needed.
- Generate QR code
- Present the QR code for deposit.

## Withdraw

![img](images/sdk_guideline/create-transation.jpg)

### getTransactionFee

- To get transaction fees of the selected currency,  
you will get three levels { high, medium, low } of fees for the user to select.
- `tokenAddress` is for private chain usage. For public chain, `tokenAddress` should always be ""
- For example:
  - ETH transaction use ETH as transaction fee ➜ pass `currency: 60, tokenAddress: ""`
  - ERC20 transaction use ETH as transaction fee ➜ pass `currency: 60, tokenAddress: ""`

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

        var granularity: String { get } // EPI-777: withdraw must be multiples of granularity

        var existentialDeposit: String { get } // The minimum balance after transaction (ALGO, DOT, KSM)

        var minimumAccountBalance: String { get } // The minimum balance after transaction (XLM, FLOW)
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
        /* Estimated total amount to transaction */
        var tranasctionAmout: String { get } 
        /* Estimated platform fee of transaction. */
        var platformFee: String { get } 
        /* Estimated blockchain fee of transaction. */
        var blockchainFee: String { get } 
        /* Minimum transfer amount for private chain. */
        var withdrawMin: String { get } 
    }
    ```

  - Administrators can add `platformFee` on admin panel
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

- This method will create and broadcast a transaction to blockchain.
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
///         1. memo (String) - Memo for XRP, XLM, EOS, BNB
///         2. eos_transaction_type (EosResourceTransactionType) - Resource transaction type for EOS, such as buy RAM, delegate CPU
///         3. num_bytes (Int64) - Bytes of RAM/NET for EOS RAM delegation/undelegation transactions. The minimal amounts are 1024 bytes
///         4. input_data (String) - Hex string of input data. Must also set gas_limit when have this attributes
///         5. gas_limit (Int64) - Must specify this if there were input_data
///         6. skip_email_notification (Bool) - Determined whether or not to skip sending notification mail after create a transaction
///         7. token_id (String) - token ID for ERC-1155
///         8. kind (String) -  kind for private chain, code: private to private; out: private to public
///         9. to_address_tag (Array<String>) - AML tag, get from getAddressesTags() API
///        10. custom_nonce (Int64, Int) - Specific nonce
///        11. custom_gas_limit (Int64, Int) - Specific gas limit
///        12. sol_token_id (String) - token ID of SOL NFT, if get from getSolNftTokens() API, the token ID would be TokenMeta.tokenAddress
///        13. force_send (Bool) - For SOL transaction, true means create ATA account for receiver
///      - Note:
///         - When eos_transaction_type is EosResourceTransactionType.SELL_RAM, EosResourceTransactionType.UNDELEGATE_CPU or EosResourceTransactionType.UNDELEGATE_NET, the receiver should be address of Wallet fromWalletId
///   - completion: asynchronous callback
///
public func createTransaction(actionToken: String = "", signature: String = "", smsCode: String = "", fromWalletId: Int64, toAddress: String, amount: String, transactionFee: String, description: String, pinSecret: CYBAVOWallet.PinSecret, extras: [String : Any] = [:], completion: @escaping CYBAVOWallet.Callback<CYBAVOWallet.CreateTransactionResult>)
```

## Transaction Detail

- There are two APIs for retriving transaction histories: `getHistory()` and `getUserHistory()`.

### getHistory

- You can use `getHistory()` to get transaction histories of a certern wallet.

```swift
/// Get transaction history from
/// - Parameters:
///   - currency: Currency of the address
///   - tokenAddress: Token Contract Address of the address
///   - walletAddress: Wallet address
///   - start: Query start offset
///   - count: Query count returned
///   - crosschain: For private chain transaction history filtering. 0: history for private chain transfer; 1: history for crossing private and public chain
///   - filters: Filter parameters:
///     - direction {Transaction.Direction} - Direction of transaction
///     - pending {Bool} - Pending state of transactions
///     - success {Bool} - Success state of transactions
///     - start_time {Int} - Start of time period to query, in Unix timestamp
///     - end_time {Int} - End of time period to query, in Unix timestamp
///       - ex: ["direction": Direction.OUT, "pending": true, "start_time": 1632387959]
///   - completion: asynchronous callback
public func getHistory(currency: Int, tokenAddress: String, walletAddress: String, start: Int, count: Int, crosschain: Int = 1, filters: [String : Any] = [:], completion: @escaping CYBAVOWallet.Callback<CYBAVOWallet.GetHistoryResult>)
```

- Paging query: you can utilize `start` and `count` to fulfill paging query.  
  - For example:
    - pass `[start: transactions.count, count: 10]` to get 10 more records when it reaches your load more condition until there's no more transactions.
    - Has more: `result.start` + `result.transactions.count` < `result.total`
- Response: list of `Transaction`

    ```swift
    public protocol Transaction {
        /* transaction ID. */
        var txid: String { get }  

        var pending: Bool { get }

        var success: Bool { get }
        /* Is transaction dropped by the blockchain. */
        var dropped: Bool { get } 
        /* Is transaction replaced by another transaction. */
        var replaced: Bool { get } 
    
        ...
    }
    ```

    <img src="images/sdk_guideline/transaction_state.jpg" alt="drawing" width="600"/>

- If the Tx's final state is `Success` or `Pending`, you could call `getTransactionInfo` to check the information about this Tx on the blockchain.

### getUserHistory
- ⚠️ `getUserHistory()` and `TransactionType` are only available on `CYBAVOWallet (1.2.490)` and later.
- You can also use `getUserHistory()` to retrive all transaction histories of the user.
```swift
  /// Get transaction history of the user
  ///
  /// - Parameters:
  ///   - start: Query start offset
  ///   - count: Query count returned
  ///   - filters: Filter parameters:
  ///                 type (TransactionType, [TransactionType]) - Transaction history types
  ///                 pending (Boolean) - Pending state of transactions
  ///                 success (Boolean) - Success state of transactions
  ///                 start_time (Long) - Start of time period to query, in Unix timestamp
  ///                 end_time (Long) - End of time period to query, in Unix timestamp
  ///                 currency (Long, Integer) - Currency of the transaction
  ///                 token_address (String) - Token Contract Address of the transaction
  ///   - completion: Asynchronized callback
  public func getUserHistory(start: Int, count: Int, filters: [String: Any], completion: @escaping Callback<GetHistoryResult>)
```
- Since the result may include transactions from public chain, private chain and different currency. For the returned `Transaction`, there are three fields you can refer to.
```swift
public protocol Transaction {
        /* Currency of the transaction. */
        var currency: Int { get } 
        /* Token contract address of the transaction. */
        var tokenAddress: String { get }
        /**
           Type of the transaction.
           Only available in the result of getUserHistory()
           Please refer to TransactionType for the definition.
        */
        var type: TransactionType { get }
    
        ...
    }
```
### Enumeration - TransactionType

- Enumeration Cases

| Case  | Raw Value | Description |
| ----  | ----  | ---- |
|	Unknown	|	0	| 	Default value when no data available.	|
|	MainDeposit	|	1	| Deposit on public chain.		| 
|	MainWithdraw	|	2	| Withdraw on public chain.		| 
|	PrivDeposit	|	3	| Deposit on private chain, including inner transfer and deposit to private chain (mint).		| 
|	PrivWithdraw	|	4	| Withdraw on private chain, including inner transfer and withdraw to public chain (burn).		| 
|	PrivOuterDeposit	|	5	| When deposit from public chain to private chain, the history of public chain.		| 
|	PrivOuterWithdraw	|	6	| When withdraw from private chain to public chain, the history of private chain.		| 
|	PrivProductDeposit	|	7	| Deposit financial product.		| 
|	PrivProductWithdraw	|	8	| Withdraw, earlyWithdraw financial product.		| 
|	PrivProductReward	|	9	| WithdrawReward financial product.		| 

- Instance Properties

| Property  |  Description |
| ----  | ----  | 
|	var name: String	|	Name of the enum.	|

- Type Methods

| Method | Description |
| ----  | ----  | 
| static func getType(value: Int) -> TransactionType  | Returns the enum of the value,<br>return `Unknown` if cannot find a matched enum.  | 
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

> ⚠️ Warning: Cancel / Accelerate transactions will incur a higher Tx fee for replacing the original Tx.

- If a user wants to Cancel / Accelerate a `Pending` Tx on blockchain.
The user needs to create another Tx with higher Tx fee and the same nonce to replace the original one.
- You can achive Tx replacement by `cancelTransaction` and `increaseTransactionFee` API.
- Condition: `replaceable == true`

  ```swift
  public protocol Transaction {

      var txid: String { get }
      /* Is transaction replaceable. */
      var replaceable: Bool { get } 
      /* Is transaction replaced by another transaction. */
      var replaced: Bool { get } 
      /* TXID of replacement of this transaction if replaced == true */
      var replaceTxid: String { get } 
      /* Nonce of transaction, only valid on ETH, same nonce means replacements */
      var nonce: Int { get } 
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
    4. Call `increaseTransactionFee` for accelerating transactions.

### Transaction Replacement History

- In the result of `getHistory`, you will need to determine different states for a transaction.
- How to determine a transaction is replaced or not:
    1. filter `platformFee == false` ➜ reduce the transactions which are platform fees.
    2. filter `nonce != 0` ➜ reduce normal transactions
    3. mapping transactions with the same nonce
    4. in a set of transactions:
        - the Tx fee lower one ➜ the original order
        - `if Tx1.amount == Tx2.amount` ➜ is Accelerate transaction operation
        - `if Tx.amount == 0` ➜ is Cancel transaction operation
        - `if Tx1.replaced == false && Tx2.replaced == false` ➜ is operating
        - `if Original-Tx.replaced == true` ➜ Cancel / Accelerate success
        - `if Replacement-Tx.replaced == true` ➜ Cancel / Accelerate failed

## Interact with Smart Contract
Wallet SDK provides APIs to call [ABI](https://docs.soliditylang.org/en/develop/abi-spec.html) functions for general read and write operation.   
- For read operation, like `balanceOf`, use `callAbiFunctionRead()`. The parameter is depends on the ABI function required.  

  For example, here's the json of the ABI function we want to call:
    ```javascript
    //Part of ABI_JSON
    {
        "constant": true,
        "inputs": [
          {
            "name": "_owner",
            "type": "address"
          },
          {
            "name": "_testInt",
            "type": "uint256"
          },
          {
            "name": "_testStr",
            "type": "string"
          }
        ],
        "name": "balanceOfCB",
        "outputs": [
          {
            "name": "balance",
            "type": "uint256"
          }
        ],
        "payable": false,
        "stateMutability": "view",
        "type": "function"
      }
    ``` 
    According to its definition, we would compose an API call like this:
    ```swift
    Wallets.shared.callAbiFunctionRead(walletId: walletId,
                                           // name, function name of ABI
                                           name: "balanceOfCB",
                                           // contractAddress, contract address of ABI
                                           contractAddress: "0xef3aa4115b071a9a7cd43f1896e3129f296c5a5f",
                                           // abiJson, ABI contract json
                                           abiJson: ABI_JSON,
                                           // args, argument array of ABI function
                                           args:["0x281F397c5a5a6E9BE42255b01EfDf8b42F0Cd179", 123, "test"]{ result in
                            switch result {
                            case .success(let result):
                                print("callAbiFunctionRead_\(result.output)_\(result.signedTx)_\(result.txid)")
                                break
                            case .failure(let error):
                                print("callAbiFunctionRead_\(error)")
                                break
                            }
        }
    ```
    Aside from `walletId` and  `completion`, all the parameters are varied according to the ABI function.  
    
    See [this](https://github.com/CYBAVO/ios_wallet_sdk_sample/blob/master/WalletSDKDemo/Wallets/WithdrawController.swift#L149-L160) for complete example.  
- For write operaion, like `transferFrom`, use `callAbiFunctionTransaction()`. The parameter is also depends on the ABI function required.  

  For example, here's the json of the ABI function we want to call:
    ```javascript
    //Part of ABI_JSON
    {
        "constant": false,
        "inputs": [
          {
            "name": "_to",
            "type": "address"
          },
          {
            "name": "_value",
            "type": "uint256"
          },
          {
            "name": "_testInt",
            "type": "uint256"
          },
          {
            "name": "_testStr",
            "type": "string"
          }
        ],
        "name": "transferCB",
        "outputs": [
          {
            "name": "success",
            "type": "bool"
          }
        ],
        "payable": false,
        "stateMutability": "nonpayable",
        "type": "function"
      }
    ```
    According to its definition, we would compose an API call like this:
    ```swift
    Wallets.shared.callAbiFunctionTransaction(walletId: wallet.walletId,
                                              // name, function name of ABI
                                              name: "transferCB",
                                              // contractAddress, contract address of ABI
                                              contractAddress: "0xef3aa4115b071a9a7cd43f1896e3129f296c5a5f",
                                              // abiJson, ABI contract json
                                              abiJson: ABI_JSON,
                                              // args, argument array of ABI function
                                              args: ["0x490d510c1A8b74749949cFE5cA06D0C6BD7119E2", 1, 100, "unittest"],
                                              // transactionFee, see getTransactionFee() and amount property of Fee struct
                                              transactionFee: fee,
                                              pinSecret: pinSecret){ result in
                           switch result {
                           case .success(let result):
                                print("callAbiFunctionTransaction_\(result.output)_\(result.signedTx)_\(result.txid)")
                               break
                           case .failure(let error):
                                print("callAbiFunctionTransaction_\(error)")
                               break
                           }
      }
    ```
    Different from `callAbiFunctionRead()`, `callAbiFunctionTransaction()` requires 2 more parameters: `transactionFee` and `PinSecret` for transaction.  
    
    The parameter `name`, `contractAddress`, `abiJson` and `args` are varied according to the ABI function.  
    
    See [this](https://github.com/CYBAVO/ios_wallet_sdk_sample/blob/master/WalletSDKDemo/Wallets/WithdrawController.swift#L165-L176) for complete example.  
    
    See [Withdraw to Public Chain](https://github.com/CYBAVO/ios_wallet_sdk_sample/blob/master/docs/private_chain.md#perform-withdraw) for another specific usage in private chain.