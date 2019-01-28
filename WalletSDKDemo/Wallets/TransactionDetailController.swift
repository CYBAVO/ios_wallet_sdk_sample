//Copyright (c) 2019 Cybavo. All rights reserved.

import UIKit
import CYBAVOWallet

class TransactionDetailController : UIViewController {
    @IBOutlet weak var labelFromAddress: UILabel!
    @IBOutlet weak var labelToAddress: UILabel!
    @IBOutlet weak var labelAmount: UILabel!
    @IBOutlet weak var labelFee: UILabel!
    @IBOutlet weak var labelTxId: UILabel!
    @IBOutlet weak var labelTime: UILabel!
    @IBOutlet weak var currencyView: CurrencyView!
    @IBOutlet weak var directionLabel: UILabel!
    
    var wallet: Wallet?
    var transaction: Transaction?
    
    override func viewDidLoad() {
        if let item = transaction {
            labelFromAddress.text = item.fromAddress
            labelToAddress.text = item.toAddress
            labelAmount.text = item.amount
            labelFee.text = item.transactionFee
            labelTxId.text = item.txId
          
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy/MM/dd hh:mm:ss"
            labelTime.text = dateFormatter.string(from: Date(timeIntervalSince1970: Double(item.timestamp)))
            
            if item.direction == .IN {
                directionLabel.text = "Deposit"
                directionLabel.backgroundColor = UIColor(red: 153.0/255.0, green: 204.0/255.0, blue: 0.0, alpha: 1.0)
            } else{
                directionLabel.text = "Withdraw"
                directionLabel.backgroundColor = UIColor(red: 1.0, green: 187.0/255.0, blue: 51.0/255.0, alpha: 1.0)
            }
            directionLabel.layer.masksToBounds = true
            directionLabel.layer.cornerRadius = 8
        }
        if let wallet = wallet {
            currencyView.setSymbol(wallet.currencyName)
            currencyView.contentView.backgroundColor = UIColor.white
            currencyView.currencyLabel.textColor = UIColor.black
        }
    }
    @IBAction func onExplore(_ sender: Any) {
        if let w = wallet, let item = transaction {
            let uri = CurrencyHelper.getBlockExplorerUri(currency: w.currency, tokenAddress: w.tokenAddress, txid: item.txId)
            if let url = URL(string: uri){
                UIApplication.shared.open(url, options: [:])
            }
        }
    }
}
