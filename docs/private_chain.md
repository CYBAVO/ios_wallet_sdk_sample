# CYBAVO Private Chain (CPC)

- Scenario for:
  - Financial Products
  - Financial Management Services
  
- Advantages of a private chain:
    1. Free; zero transaction fee for inner transfer
    2. Faster; faster than public chain
    3. Community; referral system is possible

- Easy to implement, sharing APIs with the public chain.

- Bookmarks
  - [Model - Wallet](#wallet)
  - [Model - Currency](#currency)
  - [Model - UserState](#userstate)
  - [Transactions - Deposit to Private Chain](#1-deposit-to-private-chain)
  - [Transactions - Withdraw to Public Chain](#2-withdraw-to-public-chain)
  - [Transactions - Inner Transfer](#3-inner-transfer)
  - [Transaction History](#transaction-history)
  - [CPC Financial Product](#cpc-financial-product)
    - [Financial Product](#financial-product)
    - [Financial History](#financial-history)
    - [Financial Order](#financial-order)
    - [Financial Bonus](#financial-bonus)
    - [Transaction Operations](#transaction-operations)

## Models

### Wallet

```swift
protocol Wallet : CYBAVOWallet.BalanceAddress, CYBAVOWallet.CurrencyType {

    var walletId: Int64 { get } // Wallet ID

    var isPrivate: Bool { get } // Is private chain (CPC)

    var mapToPublicCurrency: Int { get } // Public chain's currency

    var mapToPublicTokenAddress: String { get } // Public chain's tokenAddress

    var mapToPublicName: String { get } // Public chain's currency_name

    var walletCode: String { get } // Address(referral code) for transaction in private chain

    var depositAddresses: [CYBAVOWallet.DepositAddress] { get } // Deposit info, public chain to private chain

    var isPrivateDisabled: Bool { get } // Is disabled private currency
    
    ...
}
```

- `isPrivate` means the wallet is on the private chain
- Thus, it will map to a public currency on the public chain.  
  - related infos: `mapToPublicCurrency`, `mapToPublicTokenAddress`, `mapToPublicName`
- `depositAddresses` provides the addresses on the public chain. When you deposit currencies / tokens to these addresses, you will receive tokens in the related private chain wallet.
  - multiple `depositAddresses` means one private chain wallet might provide multiple addresses for depositing.
  - ex: CPSC-USDT on private chain is mapped to USDT-ERC20 and USDT-TRC20 on the public chains, so you will get multiple addresses in this field.
  - `memo` in model `DepositAddress` is necessary when depositing tokens from public chain to private chain.

### Currency

```swift
protocol Currency : CYBAVOWallet.CurrencyType {

    var isPrivate: Bool { get } // Is private chain (CPC)

    var mapToPublicType: Int { get } // Public chain's currency type

    var mapToPublicTokenAddress: String { get } // Public chain's token address

    var mapToPublicName: String { get } // Public chain's currency name

    var canCreateFinanceWallet: Bool { get } // Can create finance wallet

    ...
}
```

- `isPrivate` means the currency is on the private chain
- Thus, it will map to a public currency on the public chain.  
  - related infos: `mapToPublicType`, `mapToPublicTokenAddress`, `mapToPublicName`, `canCreateFinanceWallet`

- How to create a private chain wallet with the currency?
  - Basically, it's the same way as we mentioned in [createWallet](wallets.md#createwallet), the only difference is the filtering condition of currency and wallet.
  - In the chart below, `Available Currencies` should be `isPrivate == true && (canCreateFinanceWallet == true || tokenAddress == "")`
  ![img](images/sdk_guideline/create_wallet.jpg)

### UserState

```swift
protocol UserState {

    var userReferralCode: String { get } // User referral code

    var linkUserReferralCode: String { get } // Link user referral code (referral by this code, only one per user)

    ...
}
```

- Referral Code has two use cases:
    1. referral system
    2. substitute readable address for making transactions in the private chain
- `userReferralCode` represent the user's referral code
- `linkUserReferralCode` represent the referrer's referral code
- Call `Auth.shared.registerReferralCode()` to register a referrer.
- You can search user by calling `Auth.shared.searchUser()`, the keyword can be `realName` (partial match) or `referralCode` (fully match)
  ```swift
  Auth.shared.searchUser(keyword: "UserX"){ result in
                    switch result {
                        case .success(let result):
                            for i in 0..<result.infos.count {
                                print("#\(i), Name: \(result.infos[i].realName), Code: \(result.infos[i].referralCode)")
                            }
                            break
                        case .failure(let error):
                            //keyword length cannot less then 3,
                            //otherwise the API will receive ErrKeywordForSearchTooShort
                            print("searchUser failed \(error)")
                            break
                    }
                }

  ```
- You can update `realName` by calling `Auth.shared.updateRealName()`
  ```swift
  Auth.shared.updateRealName(realName: "UserY"){ result in
                    switch result {
                    case .success(_):
                            Auth.shared.getUserState(){userStateResult in
                                switch userStateResult {
                                case .success(let userStateResult):
                                    print("newRealName: \(userStateResult.userState.realName)")
                                    break
                                case .failure(let userStateErr):
                                    print("getUserState failed \(userStateErr)")
                                    break
                                }
                            }
                            break
                        case .failure(let error):
                            //realName length cannot less then 3,
                            //otherwise the API will receive ErrKeywordForSearchTooShort
                            print("updateRealName failed \(error)")
                            break
                    }
                    
                }
  ```

## Transactions

- There are 3 types of transactions on the private chain.

### 1. Deposit to Private Chain

- Select a private wallet, create a new one if needed.
- Select a deposit address of the private wallet.
- Present the address and memo of the deposit address for deposit.

### 2. Withdraw to Public Chain

#### Get Transaction Fee

- Withdrawing to public chain will be charged a fixed transaction fee.  
i.e. `getTransactionFee()` will return the same amount of { high, medium, low } level for private chain currency.
- Use `wallet.depositAddress` 's `Currency` and `tokenAddress` as parameters to get the transaction fee for withdraw to public chain.
- The { receive amount = transfer amount - transaction fee }
- The receive amount cannot less than `withdrawMin`

```swift
public protocol GetTransactionFeeResult {
    
    var withdrawMin: String { get } // Minimum transfer amount for private
    
    ...
}
```

#### Perform Withdraw

- Call `callAbiFunctionTransaction()` to perform the transaction with specific parameters:

```swift
let depositAddress = wallet.depositAddress[0] //select a deposit address
let args: [Any] = [toAddress,
                   transferAmount, //ex. "123.123456"
                   memo, // optional, ex. "123456" 
                   "\(depositAddress.mapToPublicCurrency)", //ex. "60"
                   depositAddress.mapToPublicTokenAddress], 

Wallets.shared.callAbiFunctionTransaction(walletId: walletId, 
                    name: "burn", // fixed to "burn"
                    contractAddress: wallet.tokenAddress, 
                    abiJson: "", // fixed to ""
                    args: args, 
                    transactionFee: "0", //our backend will take care of this 
                    pinSecret: pinSecret) {result in ... }
```

### 3. Inner Transfer

#### Private Chain Platform Fee
- On the **admin panel** ➜ **CYBAVO Smart Chain** ➜ **Chain Settings**, choose a currency which supports platform fee, click **Manage** button ➜ **Chain Wallet info**, you can found **Transfer Fee Rate** and **Transfer Fee Min**.  

  <img src="images/sdk_guideline/private_chain_platform_fee.png" alt="drawing" width="600"/>
- All the transfer operation on private chain will be charged platform fee, including inner transfer and transaction for finance product, not including deposit to private chain and withdraw to public chain. 
- Platform fee calculation:
  1. Platform Fee = Transfer Amount * **Transfer Fee Rate**
  2. If the result of step 1 is less then **Transfer Fee Min**, use **Transfer Fee Min**.
  3. If the currency not supported platform fee, the `platformFee` will be "0".
- You can use `estimateTransaction()` to get the platfom fee:
  ```swift
  Wallets.shared.estimateTransaction(
                    currency: wallet.currency,
                    tokenAddress: wallet.tokenAddress,
                    amount: amount, // ex. "100"
                    transactionFee: "0", //fixed to "0"
                    walletId: wallet.walletId){result in
                      switch result {
                          case .success(let result):
                              //check result.platformFee
                              break
                          case .failure(let error):
                              print("estimateTransaction failed: \(error)")
                              break
                      }
                }
  ```
#### Create Transaction
- Call `createTransaction()` to perform the transaction with specific parameters:

```swift
let extras = ["kind": "code"] //means it's a inner transfer transaction

Wallets.shared.createTransaction(fromWalletId: walletId,
                    toAddress: toAddress, //other user's userReferralCode, ex. "8X372G"
                    amount: transferAmount, //ex. "123.123456"
                    transactionFee: "0", // fixed to "0"
                    description: description,
                    pinSecret: pinSecret,
                    extras: extras)  { result in ... }
```

## Transaction History

- Basically, it's the same way as we mentioned in [transaction.md](transaction.md).  
 The only different thing is the parameter `crosschain` of `getHistory()`:
  - Pass `crosschain: 1`, it returns transactions of [Deposit to Private Chain](#deposit-to-private-chain) and [Withdraw to Public Chain](#withdraw-to-public-chain)
  - Pass `crosschain: 0`, it returns transactions of [Inner Transfer](#inner-transfer).

## CPC Financial Product
- ⚠️ Please use `CYBAVOWallet (1.2.446)` and above.
- After deposit to CPC, users can further deposit to financial product for a period of time to get interest, the financial product can be setup on the admin panel.  
- In the following part, we will introduce necessary class and retrive data APIs first, then the operation API.  

### Financial Product  
- The following image and table shows the mapping of product settings on the admin panel and FinancialProduct fields. 

<img src="images/sdk_guideline/private_chain_product_setting.png" alt="drawing" width="700"/> 


|  Product Setting<br>(Admin Panel)   | FinancialProduct Property  | Note  |
|  ----  | ----  | ----  |
|  Contract Address  | `uuid`  | |
|  StartAt  | `startTimestamp`  | |
|  Title:zh-tw <br>Title:zh-cn<br>Title:zh-en | `title.tw`<br>`title.cn`<br>`title.en`  |- Display one of these as product name according to device locale.|
|  Max Users<br>UserWarningCountPrcent  | `maxUsers`<br>`userPercent`  |- `maxUsers` <= `userCount`, means sold out.<br>- `maxUsers` * `userPercent` >= `userCount`, means available<br>- `maxUsers` * `userPercent` < `userCount`, means about full.|
|  Show Rate  | `rate`  |- Display it as annual interest rate<br>-`ratePercent` is `Double` version of annual interest rate.|
|  Campaign  | `GetFinancialProductsResult.campaign`  |- If Campaign is checked, this product will also exist in `GetFinancialProductsResult.campaign`.|
|  MinDeposit<br>MaxDeposit  | `minDeposit`<br>`maxDeposit`  |- Display the deposit amount limit range,<br>ex. Min 0.5 HW-ETH - 1000 HW-ETH. |
|  InverseProfitSharingCurrency  | `kind`  |- enum: `FinancialProductKind`<br>- If InverseProfitSharingCurrency is set to **Disable**, `kind` would be `DemandDeposit`(2) ,<br>otherwise, `kind` would be `FixedDeposit`(1).|

 #### Get Financial Product Lists
- You can get financial product list by `FinancialProductListKind`:
 ```swift
/**
* Refers to FinancialProductListKind:
* All(0), UserDeposit(1), DemandDeposit(2), FixedDeposit(3), Campaign(4)
*/
let kind = FinancialProductListKind.All
// You can also leave parameters blank for get All financial products
Wallets.shared.getFinancialProducts(kinds: [kind.rawValue]){result in
    switch result{
    case .success(let result):
        /**
          Financial product lists are categorized as following:
          result.userDeposits, result.demandDeposits,
          result.fixedDeposits, result.campaign
        */
        for product in result.demandDeposits{
            /**
              ex. Product: Demand Deposits (Hourly Interest), kind: DemandDeposit, Annualized Rate: 7%,
              Amount: 1.000000 HW-XRP, Maturity Interest: 0.000000 HW-XRP,
              Allow withdraw after: 00:02:19, 
              tag:Available
            */
            print("Product: \(product.title.en), kind: \(product.kind), Annualized Rate: \(product.rate)%,")
            print("Amount: \(product.userDeposit) \(product.publicName), Maturity Interest: \(product.userReward) \(product.publicName),")
            print("Allow withdraw after: \(getUserWaitToWithdrawStr(product.userWaitToWithdraw, !product.isCanWithdraw && !product.isCanWithdrawReward)),")
            print("tag: \(getAvailableTag(product))")
        }
        
        for product in result.fixedDeposits{
            /**
              ex. Product: Time deposit (10 days), kind: FixedDeposit, Annualized Rate: 15%,
              Amount: 1.004613 HW-XRP, Maturity Interest: 0.004128 HW-XRP,
              Start date: 2022-09-07 02:48:05, Value date: , Expiry date: 2022-09-17 02:48:05
            */
            print("Product: \(product.title.en), kind: \(product.kind), Annualized Rate: \(product.rate)%,")
            print("Amount: \(product.userDeposit) \(product.publicName), Maturity Interest: \(product.userReward) \(product.publicName),")
            print("Start date: \(getDateStr(product.startTimestamp)), Value date: \(getDateStr(product.rewardTimestamp)), Expiry date: \(getDateStr(product.endTimestamp))")
        }
        break
    case .failure(let error):
        print("getFinancialProducts failed: \(error)")
        break
    }
}
/** Transfer and get userWaitToWithdraw in formatted string */
func getUserWaitToWithdrawStr(_ userWaitToWithdraw: Int, _ isCanWithdraw: Bool) -> String{
    let countdownTime = userWaitToWithdraw - Int(Date().timeIntervalSince1970)
    if countdownTime <= 0 || isCanWithdraw{
        return ""
    }
    
    return timeString(from: TimeInterval(countdownTime))
}
/** Get string in time format */
func timeString(from timeInterval: TimeInterval) -> String {
    let seconds = Int(timeInterval.truncatingRemainder(dividingBy: 60))
    let minutes = Int(timeInterval.truncatingRemainder(dividingBy: 60 * 60) / 60)
    let hours = Int(timeInterval.truncatingRemainder(dividingBy: 60 * 60 * 24) / (60 * 60))
    let days = Int(timeInterval / 86400)
    if days > 0 {
        return String(format: "%.2d:%.2d:%.2d:%.2d", days, hours, minutes, seconds)
    } else {
        return String(format: "%.2d:%.2d:%.2d", hours, minutes, seconds)
    }
}
/** Get available tag for financial product */
func getAvailableTag(_ product: FinancialProduct) -> String{
    if Int(Date().timeIntervalSince1970) < product.startTimestamp {
        return "Not Start"
    }
    if product.userCount >= product.maxUsers {
        return "Sold Out"
    }
    if 1 - Double(product.userCount) / Double(product.maxUsers) <= product.userPercent {
        return "About Full"
    }
    return "Available"
}
/** Get date time string */
func getDateStr(_ timestamp: Int) -> String{
    if timestamp == 0{
        return ""
    }
    
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    return dateFormatter.string(from: Date(timeIntervalSince1970: TimeInterval(timestamp)))
}
 ```
 ### Financial History
- If users have deposited or withdrawn a financial product, related FinancialHistory will be created / removed. 
#### Get Financial History List
- There are 3 kind for FinancialHistory: `Depositing`(1), `Withdraw`(2), `WithdrawReward`(3), the following table shows the change after performed transaction operation.  

|  Transaction Operation   | FinancialProductKind  | Changes in GetFinancialHistoryResult  |
|  ----  | ----  | ----  |
|  deposit  | `FixedDeposit`  | - Add one `Depositing` history. |
|  deposit  | `DemandDeposit`  | - Add one `Depositing` history when there's no one for this product.<br>- Or update the existing `Depositing` history.|
|  withdraw<br>earlyWithdraw  | `FixedDeposit`  | - Remove the `Depositing` history.<br>- Add one `Withdraw` history.<br>- Add one `WithdrawReward` history. |
|  withdraw  | `DemandDeposit`  | - Add one `Withdraw` history.<br>- Remove the `Depositing` history if no `userDeposit` and `userReward` left.<br>- Or update the existing `Depositing` history. |
|  withdrawReward  | `DemandDeposit`  | - Add one `WithdrawReward` history.<br>- Remove the `Depositing` history if no `userDeposit` and `userReward` left.<br>- Or update the existing `Depositing` history. |

- You can get financial history list by `FinancialHistoryListKind` or `FinancialProduct.uuid`. 
 ```swift
/**
  * Refers to FinancialHistoryListKind:
  * Depositing(1), Withdraw(2), WithdrawReward(3)
  */
let kind = FinancialHistoryListKind.Depositing.rawValue

// Flag for paging: pass null for the first page or nextPage, prevPage of GetFinancialHistoryResult
let page: String? = doRefresh ? nil : previousResult.nextPage

 Wallets.shared.getFinancialHistory(kind: kind, page: page){ result in
    switch result{
        case .success(let result):
                for history in result.history{
                    //Get FinancialProduct for this history in result.products
                    guard let product = result.products[history.productUuid] else{
                        continue
                    }
                    /**
                        ex. Currency: HW-ETH, Subscribe item: Demand Deposits (Hourly Interest), Deposit amount: 2.000000000000000000,
                        Start date: 2021-11-03 23:44:00, Value date: ,
                        Expiry date: 2022-12-03 23:44:00
                        Interest amount: 0.143537800000000000, Annual Interest Rate: 10%
                     */
                    print("Currency: \(product.publicName), Subscribe item: \(product.title.en), Deposit amount: \(history.userDeposit),")
                    print("Start date: \(getDateStr(product.startTimestamp)), Value date: \(getDateStr(product.rewardTimestamp)),")
                    // if kind is FinancialHistoryListKind.Withdraw, should display as "Withdraw date"
                    print("Expiry date: \(getDateStr(product.endTimestamp))")
                    print("Interest amount: \(history.userReward), Annual Interest Rate: \(product.rate)%")
                }
            break
        case .failure(let error):
            print("getFinancialHistory by kind failed: \(error)")
            break
    }
}
 ```
- ⚠️ Get financial history list by `FinancialProduct.uuid` will only return `Depositing` history.
```swift
// Flag for paging: pass null for the first page or nextPage, prevPage of GetFinancialHistoryResult
let page: String? = doRefresh ? nil : previousResult.nextPage

Wallets.shared.getFinancialHistory(
        productUuid: financialProduct.uuid,
        page: page){ result in
        switch result{
            case .success(let result):
                    for history in result.history{
                        //Get FinancialProduct for this history in result.products
                        guard let product = result.products[history.productUuid] else{
                            continue
                        }
                        // Use FinancialHistory.isCan || FinancialProduct.isCan
                        let isCanWithdraw = product.isCanWithdraw || history.isCanWithdraw
                        let isCanEarlyWithdraw = product.isCanEarlyWithdraw || history.isCanEarlyWithdraw
                        /**
                          ex. Currency: HW-XRP, Subscribe item: Time deposit (10 days), Deposit amount: 0.521955,
                          Start date: 2022-09-07 19:03:02, Value date: ,
                          Expiry date: 2022-09-17 19:03:02
                          Interest amount: 0.002145, Annual Interest Rate: 15%
                          Allow withdraw after: 00:02:38
                         */
                        print("Currency: \(product.publicName), Subscribe item: \(product.title.en), Deposit amount: \(history.userDeposit),")
                        print("Start date: \(getDateStr(history.startTimestamp)), Value date: \(getDateStr(history.rewardTimestamp)),")
                        print("Expiry date: \(getDateStr(history.endTimestamp))")
                        print("Interest amount: \(history.userReward), Annual Interest Rate: \(product.rate)%")
                        print("Allow withdraw after: \(getUserWaitToWithdrawStr(history.userWaitToWithdraw, !isCanWithdraw && !isCanEarlyWithdraw))")
                    }
                break
            case .failure(let error):
                print("getFinancialHistory by product.uuid failed: \(error)")
                break
        }
    }
```
### Financial Order
- ⚠️ Financial order is only for `FixedDeposit` product.
- Every deposit will create an order.
- The following image and table shows the mapping of order info on the admin panel and GetFinancialOrderResult fields.  

  <img src="images/sdk_guideline/private_chain_order.png" alt="drawing" width="900"/>  

  |  Order Column <br>(Admin Panel)  | GetFinancialOrderResult Field  | Note |
  |  ----  | ----  | ----  |
  |  OrderID  | `uuid`  | |
  |  Amount  | `userDeposit`| |
  |  Reward  | `userReward`  | |
  |  Penalty  | `earlyReward` | `earlyReward` = Reward - Penalty|

```swift
Wallets.shared.getFinancialOrder(productUuid: history.productUuid, orderID: history.uuid){ result in
        switch result{
        case .success(let result):
            // If the order is not exist, result.kind will be FinancialProductKind.Unknown(-1)
            
            /**
              ex. Receivable interest: 0.000000 HW-XRP,
              Origin receivable interest: 0.002145 HW-XRP
            */
            print("Receivable interest: \(result.earlyReward) \(product.publicName),")
            print("Origin receivable interest: \(result.userReward) \(product.publicName)")
            break
        case .failure(let error):
            print("getFinancialOrder failed: \(error)")
            break
        }
    }
```
### Financial Bonus
- CPC financial product also has rebate mechanism, if the user meet the requirement, ex. the user's referrer deposit a finance product, the user will have a `FinancialBonus` in his/her financial list.
- User can perform `withdrawBonus` with `uuid` if `isAlreadyWithdrawn` is false.
```swift
Wallets.shared.getFinancialBonusList(){ result in
        switch result{
        case .success(let result):
            for bonus in result.bonusList{
                var totalPerBonus: Decimal = 0
                for reward in bonus.rewards{
                    totalPerBonus = totalPerBonus + (Decimal(string: reward.amount) ?? 0)
                }
                /**
                  Bonus:SavingRebate, withdraw: false,
                  total: 311.28125 HW-XRP
                 */
                print("Bonus:\(bonus.kind), withdraw: \(bonus.isAlreadyWithdrawn),")
                print("total: \(totalPerBonus) \(bonus.publicName)")
            }
            break
        case .failure(let error):
            print("getFinancialBonusList failed: \(error)")
            break
        }
    }
```

### Transaction Operations 
- There are 6 operations for CPC financial product, they can be achieved by `callAbiFunctionTransaction()` with different `args`, the behavior might be different between different `FinancialProductKind`.
- ⚠️ After performed `callAbiFunctionTransaction()`, it'll take a while to change data, App may need to display a status for transition to prevent users execute the same operation again (press again the same button).
 
|  ABI Method Name<br>`args[0]`   | `kind` /<br>Perform  to  | Note | `args` |
|  :----:  | :----  | :----  | :---- |
|  [approve](#approve-activate)  | `FixedDeposit`<br>`DemandDeposit` / <br>FinancialProduct | - Approve to activate the product.<br>- Required and cannot perform other operations if `FinancialProduct.isNeedApprove` is true | ["approve", product.uuid] |
|  [deposit](#deposit)  | `FixedDeposit`<br>`DemandDeposit` / <br>FinancialProduct  | - Deposit to the product.<br>- Performable when `FinancialProduct.isCanDeposit` is true| ["deposit",<br>product.uuid,<br>amount, <br>""] |
|  [withdraw](#withdraw---fixeddeposit)  | `FixedDeposit` / <br>Order which linked to FinancialHistory| - Withdraw all principal and interest to given financial wallet.<br>- amount is fixed to "0" for all.<br>- Cannot withdraw if current time is earlier then `FinancialHistory.userWaitToWithdraw`.<br>- Performable when `isCanWithdraw` is true<br>- `isCanWithdraw = history.isCanWithdraw \|\| history.isCanWithdraw`| ["withdraw", product.uuid,<br>"0",<br>history.orderId] |
|  [withdraw](#withdraw---demanddeposit)  | `DemandDeposit` / <br>FinancialProduct | - Withdraw a certain amount of principal to given financial wallet.<br>- Cannot withdraw if current time is earlier then `FinancialProduct.userWaitToWithdraw`.<br>- Performable when `FinancialProduct.isCanWithdraw` is true| ["withdraw", product.uuid,<br>amount,<br>""] |
|  [earlyWithdraw](#earlywithdraw)  | `FixedDeposit` / <br>Order which linked to FinancialHistory | - Withdraw all principal and interest to given financial wallet.<br>- Withdraw by product / order.<br>- Interest will be deducted, see [Financial Order](#financial-order).<br>- amount is fixed to "0" for all.<br>- Cannot withdraw if current time is earlier then `FinancialHistory.userWaitToWithdraw`.<br>- Performable when `isCanEarlyWithdraw` is true<br>- `isCanEarlyWithdraw = history.isCanEarlyWithdraw \|\| product.isCanEarlyWithdraw`| ["earlyWithdraw",<br>product.uuid,<br>"0", <br>history.orderId] |
|  [withdrawReward](#withdrawreward)  | `DemandDeposit` / <br>FinancialProduct | - Withdraw all interest to given financial wallet.<br>- amount is fixed to "0" for all.<br>- Cannot withdraw if current time is earlier then `FinancialProduct.userWaitToWithdraw`.<br>- Performable when `FinancialProduct.isCanWithdrawReward` is true| ["withdrawReward", product.uuid,<br>"0",<br>""] |
|  [withdrawBonus](#withdrawbonus)  | - / FinancialBonus | - Withdraw bonus to given financial wallet.<br>- Performable when `FinancialBonus.isAlreadyWithdrawn` is false| ["withdrawBonus", bonus.uuid,<br>"0"] |

Below code snippet shows a pattern to use `callAbiFunctionTransaction()` for those operations.
 ```swift
Wallet wallet = findWallet(privateWallets, product.currency, product.tokenAddress)

var args: [Any] = [
        abiMethodName, // Possible value: "approve", "deposit", "withdraw", "earlyWithdraw", "withdrawReward", "withdrawBonus"
        ...
        ]

let wallet = findWallet(from: privateWallets, currency: product.currency, tokenAddress: product.tokenAddress)
guard let wallet = wallet else{
    return
}
Wallets.shared.callAbiFunctionTransaction(
            walletId: wallet.walletId,
            name: "financial",// fixed to "financial"
            contractAddress: wallet.tokenAddress,
            abiJson: "", // fixed to ""
            args: args,
            transactionFee: "0",// fixed to "0"
            pinSecret: pinSecret){ result in ... }

// Find wallet by currency and tokenAddress in giving list.
func findWallet(from wallets: [Wallet], currency: Int, tokenAddress: String) -> Wallet?{
    for wallet in wallets {
        if wallet.currency == currency, wallet.tokenAddress == tokenAddress {
            return wallet
        }
    }
    return nil
}
 ```
#### Check and Create Wallet
Before performing those operations, you should check if required wallets are created and create for the user if needed.  
Required wallets including:  
1. `currency` is same as `FinancialProduct.currency`, `tokenAddress` is empty.
2. `mapToPublicCurrency` is same as `FinancialProduct.publicCurrency`, `mapToPublicTokenAddress` is empty. 
3. `mapToPublicCurrency` is same as `FinancialProduct.publicCurrency`, `mapToPublicTokenAddress` is same as `FinancialProduct.publicTokenAddress`.  

For example, for a HW-ETH financial product  
(`currency`: 99999999995, `tokenAddress`: "0x123...", `publicCurrency`: 60, `publicTokenAddress`: "")  
required wallets are
1. CPSC wallet (`currency`: 99999999995, `tokenAddress`: "").
2. CPSC-ETH wallet(`mapToPublicCurrency`: 60, `mapToPublicTokenAddress`: "").

For another example, for a HW-USDT financial product  
(`currency`: 99999999995, `tokenAddress`: "0x234...", `publicCurrency`: 60, `publicTokenAddress`: "0x456...")  
required wallets are
1. CPSC wallet (`currency`: 99999999995, `tokenAddress`: "").
2. CPSC-ETH wallet(`mapToPublicCurrency`: 60, `mapToPublicTokenAddress`: "").
3. CPSC-USDT wallet(`mapToPublicCurrency`: 60, `mapToPublicTokenAddress`: "0x456...").

#### Transaction Explain
- Perform those operations may create [Transaction History](#transaction-history) for inner transfer, those transaction will have `explain` field with additional information, you can use `explain` to make the UI more clearer.
```swift
if(item.explain.kind == TransactionExplainKind.Unknown){
    return
}
if(!item.explain.isShowAmount){
    //hide amount for 0 amount operation like approve
}
// ex. kind: WithdrawReward, product: Demand Deposits (Hourly Interest)
print("kind: \(item.explain.kind), product: \(item.explain.name.en)")
```

#### Approve Activate
 ```swift
 if(!product.isNeedApprove){
    return
 }

 // Find wallet by currency and tokenAddress in giving list.
let wallet = findWallet(from: privateWallets, currency: product.currency, tokenAddress: product.tokenAddress)
guard let wallet = wallet else{
    return
}

let args: [Any] = [
            "approve",// ABI method name: fixed to "approve"
            product.uuid]

Wallets.shared.callAbiFunctionTransaction(
            walletId: wallet.walletId,
            name: "financial",// fixed to "financial"
            contractAddress: wallet.tokenAddress,
            abiJson: "",// fixed to ""
            args: args,
            transactionFee: "0",// fixed to "0"
            pinSecret: pinSecret){ result in
                    switch result{
                    case .success(let result):
                        /**
                          Keep product.uuid and display activating, because isNeedApprove will not change immediately.
                          Call getFinancialProducts() to refresh.
                        */
                        break
                    case .failure(let error):
                        print("callAbiFunctionTransaction failed: \(error)")
                        break
                    }
            }
 ```
 [↑ Transaction Operations ↑](#transaction-operations)
#### Deposit
- You can display `minDeposit` and `maxDeposit` as minimum / maximum deposit amount.  
ex.  Min 0.5 HW-ETH - 1000 HW-ETH
- For `FixedDeposit`, you can display estimate reward when editing amount.  
estimate reward = product.ratePercent * amount 
```swift
if(!product.isCanDeposit){
  return
}

 // Find wallet by currency and tokenAddress in giving list.
let wallet = findWallet(from: privateWallets, currency: product.currency, tokenAddress: product.tokenAddress)
guard let wallet = wallet else{
    return
}

let args: [Any] = [
            "deposit",// ABI method name: fixed to "deposit"
            product.uuid,
            amount,
            ""// orderId: fixed to ""
        ]

Wallets.shared.callAbiFunctionTransaction(
            walletId: wallet.walletId,
            name: "financial",// fixed to "financial"
            contractAddress: wallet.tokenAddress,
            abiJson: "", // fixed to ""
            args: args,
            transactionFee: "0",// fixed to "0"
            pinSecret: pinSecret){ result in ... }

```
 [↑ Transaction Operations ↑](#transaction-operations)
#### Withdraw - FixedDeposit
```swift
let isCanWithdraw = history.isCanWithdraw || product.isCanWithdraw
if(!isCanWithdraw){
    return
}
let msInFuture = getMsInFuture(history.userWaitToWithdraw)
if(msInFuture <= 0){
    return
}
let args: [Any] = [
            "withdraw",// ABI method name: fixed to "withdraw"
            product.uuid,
            "0", // amount: fixed to "0"
            history.orderId
        ]

Wallets.shared.callAbiFunctionTransaction(
            walletId: wallet.walletId,
            name: "financial",// fixed to "financial"
            contractAddress: wallet.tokenAddress,
            abiJson: "", // fixed to ""
            args: args,
            transactionFee: "0",// fixed to "0"
            pinSecret: pinSecret){ result in ... }

/** Get remain time in ms */
func getMsInFuture(_ deadline: Int)-> Int{
    return deadline - Int(Date().timeIntervalSince1970)
}
```
 [↑ Transaction Operations ↑](#transaction-operations)
#### Withdraw - DemandDeposit
```swift
if(!product.isCanWithdraw){
    return
}
let msInFuture = getMsInFuture(product.userWaitToWithdraw)
if(msInFuture <= 0){
    return
}
let args: [Any] = [
            "withdraw",// ABI method name: fixed to "withdraw"
            product.uuid,
            amount,
            ""// orderId: fixed to ""
        ]

Wallets.shared.callAbiFunctionTransaction(
            walletId: wallet.walletId,
            name: "financial",// fixed to "financial"
            contractAddress: wallet.tokenAddress,
            abiJson: "", // fixed to ""
            args: args,
            transactionFee: "0",// fixed to "0"
            pinSecret: pinSecret){ result in ... }

```
 [↑ Transaction Operations ↑](#transaction-operations)
#### earlyWithdraw
```swift
let isCanEarlyWithdraw = history.isCanEarlyWithdraw || product.isCanEarlyWithdraw
if(!isCanEarlyWithdraw){
    return
}
let msInFuture = getMsInFuture(history.userWaitToWithdraw)
if(msInFuture <= 0){
    return
}
let args: [Any] = [
            "earlyWithdraw",// ABI method name: fixed to "earlyWithdraw"
            product.uuid,
            "0", // amount: fixed to "0"
            history.orderId
        ]

Wallets.shared.callAbiFunctionTransaction(
            walletId: wallet.walletId,
            name: "financial",// fixed to "financial"
            contractAddress: wallet.tokenAddress,
            abiJson: "", // fixed to ""
            args: args,
            transactionFee: "0",// fixed to "0"
            pinSecret: pinSecret){ result in ... }

```
 [↑ Transaction Operations ↑](#transaction-operations)
#### withdrawReward
```swift
if(!product.isCanWithdrawReward){
    return
}
let msInFuture = getMsInFuture(product.userWaitToWithdraw)
if(msInFuture <= 0){
    return
}
let args: [Any] = [
            "withdrawReward",// ABI method name: fixed to "withdrawReward"
            product.uuid,
            "0", // amount: fixed to "0"
            "" // fixed to "" 
        ]

Wallets.shared.callAbiFunctionTransaction(
            walletId: wallet.walletId,
            name: "financial",// fixed to "financial"
            contractAddress: wallet.tokenAddress,
            abiJson: "", // fixed to ""
            args: args,
            transactionFee: "0",// fixed to "0"
            pinSecret: pinSecret){ result in ... }
```
 [↑ Transaction Operations ↑](#transaction-operations)
#### withdrawBonus
```swift
if(bonus.isAlreadyWithdrawn){
    return
}
let args: [Any] = [
            "withdrawBonus",// ABI method name: fixed to "withdrawBonus"
            bouns.uuid,
            "0", // amount: fixed to "0"
        ]

Wallets.shared.callAbiFunctionTransaction(
            walletId: wallet.walletId,
            name: "financial",// fixed to "financial"
            contractAddress: wallet.tokenAddress,
            abiJson: "", // fixed to ""
            args: args,
            transactionFee: "0",// fixed to "0"
            pinSecret: pinSecret){ result in ... }

```
 [↑ Transaction Operations ↑](#transaction-operations)


