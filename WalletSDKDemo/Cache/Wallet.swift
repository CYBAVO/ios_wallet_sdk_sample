//Copyright (c) 2019 Cybavo. All rights reserved.

import Foundation
import CYBAVOWallet

class WalletManager {
    public static let shared = WalletManager()
    
    private var wallets: Array<Wallet>?
    
    func getWallets(_ callback: @escaping (Array<Wallet>)->()) {
        if let result = wallets {
            DispatchQueue.global(qos: .background).async {
                callback(result)
            }
        }
        Wallets.shared.getWallets { result in
            switch result {
            case .success(let result):
                    self.wallets = result.wallets
                    if let result = self.wallets {
                        DispatchQueue.global(qos: .background).async {
                            callback(result)
                        }
                    } else {
                        callback(Array<Wallet>())
                    }
                break
            case .failure(_):
                callback(Array<Wallet>())
                break
            }
        }
    }
}
