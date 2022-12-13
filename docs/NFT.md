# NFT

- Bookmarks
  - [NFT Wallet](#nft-wallet-creation)
  - [NFT Balance](#balance)
  - [Deposit](#deposit)
  - [Withdraw](#withdraw)
  - [Transaction Detail](#transaction-detail)
  - [Specific Usage](#specific-usage)
    - [Solana NFT Tokens](#solana-nft-tokens)
    - [Withdrawing Solana NFT Tokens](#withdrawing-solana-nft-tokens)

## NFT Wallet Creation

- Suppose you'd like to receive some NFT tokens with Wallet SDK, but there's no that kind of `Currency` in the currency list, you can add NFT currency by calling `addContractCurrency`.  
If that kind of `Currency` already exists, there's no need to add it again.

```swift
/// [NFT] Add a new token & create first wallet
/// - Parameters:
///   - currency: Currency of desired new wallet
///   - contractAddress: Token address for tokens, i.e. an ERC-20 token wallet maps to an Ethereum wallet
///   - pinSecret: PIN secret retrieved via PinCodeInputView
///   - completion: asynchronous callback of WalletID
public func addContractCurrency(currency: Int64, contractAddress: String, pinSecret: CYBAVOWallet.PinSecret, completion: @escaping CYBAVOWallet.Callback<CYBAVOWallet.AddContractCurrenciesResult>)

/// Batch version of addContractCurrency
public func addContractCurrencies(currency: [Int64], contractAddress: [String], pinSecret: CYBAVOWallet.PinSecret, completion: @escaping CYBAVOWallet.Callback<CYBAVOWallet.AddContractCurrenciesResult>)
```

- How to get a contract address?  
You can find it on blockchain explorer.  
Take CryptoKitties for example, you can find its contract address on Etherscan:

  ![img](images/sdk_guideline/nft_etherscan_1.png)

## NFT Wallet List

![img](images/sdk_guideline/nft_wallets.jpg)

- Same way as we mentioned in [Wallet Information](wallets.md#wallet-information)
- Conditions:
  - `Wallet.isPrivate == false` ➜ it is on public chain.
  - `tokenAddress != ""` ➜ it is a mapped wallet (NFT wallet is also mapped wallet).
  - `Currency.tokenVersion == 721 || 1155` ➜ it is an NFT wallet.

## Balance

Refer to [Balance](wallets.md#getbalances).

```swift
protocol Balance {

    var tokens: [String] { get } /** Non-Fungible Token IDs for ERC-721*/

    var tokenIdAmounts: [CYBAVOWallet.TokenIdAmount] { get } /** Non-Fungible Token ID and amounts for ERC-1155 */

    ...
}
```

- For ERC-721 (NFT), use `tokens`.
- For ERC-1155 (NFT), use `tokenIdAmounts`.
- For Solana, see [Solana NFT Tokens](#solana-nft-tokens).

- In order to present images, call `getMultipleTokenUri` to get token urls.
  
  ```swift
  /// Get NFT Token URI
  /// - Parameters:
  ///   - currency: Currency of token to query
  ///   - tokenAddresses: Array of token address to query
  ///   - tokenIds: Array of token address to query
  ///   - completion: asynchronous callback of [String : CYBAVOWallet.TokenUriInfo]
  public func getMultipleTokenUri(currency: Int, tokenAddresses: [String], tokenIds: [String], completion: @escaping CYBAVOWallet.Callback<CYBAVOWallet.GetMultipleTokenUriReponse>)
  ```

### Error Handling

- For ERC-1155:

  ```swift
  /// If ERC-1155 token didn't show in wallet's balance, register token ID manually make them in track
  /// - Parameters:
  ///   - walletId: walletId Wallet ID
  ///   - tokenIds: ERC-1155 token IDs for register
  ///   - completion: asynchronous callback
  public func registerTokenIds(walletId: Int64, tokenIds: [String], completion: @escaping CYBAVOWallet.Callback<CYBAVOWallet.RegisterTokenIdsResult>)
  ```

## Deposit

- Select a wallet address, create a new one if needed.
- Generate QR code.
- Present the QR code for deposit.

## Withdraw

- The steps are similar to normal transactions. Refer to [Withdraw](transaction.md#withdraw)
- when `createTransaction()`
  - For [EIP-721](https://eips.ethereum.org/EIPS/eip-721) , set parameter `amount = tokenId`.
  - For [EIP-1155](https://eips.ethereum.org/EIPS/eip-1155) , set parameter `amount = tokenIdAmount` and `extras.put("token_id", tokenId)`.
  - For Solana, see [Withdrawing Solana NFT Tokens](#withdrawing-solana-nft-tokens).

## Transaction Detail

- The steps are similar to normal transactions. Refer to [getHistory](transaction.md#gethistory).

## Specific Usage
- There are specific API usages for some scenarios which related to NFT, you can find them in this section.

### Solana NFT Tokens
- For retriving Solana NFT tokens, please use `getSolNftTokens()`.
```swift
Wallets.shared.getSolNftTokens(walletId: wallet.walletId){ result in
          switch result {
            case .success(let result):
                /**
                  ex. tokenAddress: E3LybqvWfLus2KWyrYKYieLVeT6ENpE4znqkMZ9CTrPH, balance: 17,
                      supply: 100, tokenStandard: Unknown
                */
                for tokenMeta in result.tokens{
                    print("tokenAddress: \(tokenMeta.tokenAddress), balance: \(tokenMeta.balance),")
                    print("supply: \(tokenMeta.supply), tokenStandard: \(tokenMeta.tokenStandard)")
                }
                break
            case .failure(let error):
                print("setSolTokenAccountTransaction failed\(error)")
                break
          }
      }
```
### Withdrawing Solana NFT Tokens
- For withdrawing Solana NFT tokens, put the selected `TokenMeta.tokenAddress` in extras `sol_token_id` then pass to `createTransaction()`.
```swift
let extras: [String:Any] = ["sol_token_id": selectedToken.tokenAddress]
Wallets.shared.createTransaction(fromWalletId: wallet.walletId, 
                                 toAddress: toAddress, amount: amount, transactionFee: fee, 
                                 description: desc, pinSecret: pinSecret, extras:  extras) { result ... }
```
- For Solana NFT transactions, the `Transaction.tokenId` is the token address, for fungible asset transaction, this field will be empty.