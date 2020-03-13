//Copyright (c) 2019 Cybavo. All rights reserved.

import CYBAVOWallet

class CurrencyHelper {
    struct Key : Hashable {
        var currency: Coin
        var tokenAddress: String
        public var hashValue : Int {
            get {
                return self.currency.hashValue &* 31 &+ self.tokenAddress.hashValue
            }
        }
    }
    
    enum Coin : Int {
        case BTC = 0
        case LTC = 2
        case ETH = 60
        case XRP = 144
        case BCH = 145
        case EOS = 194
        case TRX = 195
    }
    
    static let txExplorers = [
        Key(currency: .BTC, tokenAddress: ""): "https://blockexplorer.com/tx/%@",
        Key(currency: .BTC, tokenAddress: "31"): "https://omniexplorer.info/tx/%@",
        Key(currency: .LTC, tokenAddress: ""): "https://live.blockcypher.com/ltc/tx/%@",
        Key(currency: .ETH, tokenAddress: ""): "https://etherscan.io/tx/%@",
        Key(currency: .XRP, tokenAddress: ""): "https://xrpcharts.ripple.com/#/transactions/%@",
        Key(currency: .BCH, tokenAddress: ""): "https://explorer.bitcoin.com/bch/tx/%@",
        Key(currency: .EOS, tokenAddress: ""): "https://eosflare.io/tx/%@",
        Key(currency: .TRX, tokenAddress: ""): "https://tronscan.org/#/transaction/%@",
    ]
    static func findCurrency(currencies: Array<Currency>, wallet: Wallet)-> Currency?{
        for c in currencies{
            if(c.currency == wallet.currency && c.tokenAddress == wallet.tokenAddress){
                return c
            }
        }
        return nil
    }
    static func isFungibleToken(currency: Currency) -> Bool{
        return currency.tokenVersion == 721
    }
    static func getBlockExplorerUri(currency: Int, tokenAddress: String, txid: String) -> String {
        if let coin = CurrencyHelper.Coin(rawValue: currency), let uri = txExplorers[Key(currency: coin, tokenAddress: tokenAddress)] {
            return String(format: uri, txid)
        }
        return "";
    }
    
}
