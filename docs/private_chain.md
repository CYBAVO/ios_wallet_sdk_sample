# Private Chain

- Private chain a.k.a. CYBAVO Private Smart Chain (CPSC)
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
  - [Transactions (Deposit to Private Chain, Withdraw to Public Chain, Inner Transfer)](#transactions)
  - [Transaction History](#transaction-history)

## Models

### Wallet

```swift
protocol Wallet : CYBAVOWallet.BalanceAddress, CYBAVOWallet.CurrencyType {

    var walletId: Int64 { get } // Wallet ID

    var isPrivate: Bool { get } // Is private chain (CPSC)

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

    var isPrivate: Bool { get } // Is private chain (CPSC)

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
- call `Auth.registerReferralCode()` to register a referrer.

## Transactions

- There are 3 types of transactions on the private chain.

### 1. Deposit to Private Chain

- Select a private wallet, create a new one if needed.
- Select a deposit address of the private wallet.
- Present the address and memo of the deposit address for deposit.

### 2. Withdraw to Public Chain

#### getTransactionFee

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

- There's no transaction fee for inner transfer.
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
