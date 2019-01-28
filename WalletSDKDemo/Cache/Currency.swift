//Copyright (c) 2019 Cybavo. All rights reserved.

import CYBAVOWallet

class CurrencyManager {
    public static let shared = CurrencyManager()
    
    private var currencies: Array<Currency>?
    
    func getAll(_ callback: @escaping (Array<Currency>)->()) {
        if let result = currencies {
            DispatchQueue.global(qos: .background).async {
                callback(result)
            }
        }
        Wallets.shared.getCurrencies() { result in
            switch result {
            case .success(let result):
                    self.currencies = result.currencies
                    if let result = self.currencies {
                        DispatchQueue.global(qos: .background).async {
                            callback(result)
                        }
                    } else {
                        callback(Array<Currency>())
                }
                break
            case .failure(_):
                callback(Array<Currency>())
                break
            }
        }
    }
}
