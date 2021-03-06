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
    @IBOutlet weak var labelWithdraw: UILabel!
    @IBOutlet weak var labelDeposit: UILabel!
    
    @IBOutlet weak var labelFail: UILabel!
    @IBOutlet weak var labelPending: UILabel!
    @IBOutlet weak var labelConfirmBlock: PaddingLabel!
    @IBOutlet weak var labelReplaced: PaddingLabel!
    @IBOutlet weak var labelMemo: UILabel!
    @IBOutlet weak var labelDesc: UILabel!
    @IBOutlet weak var btnSpeedUp: UIButton!
    @IBOutlet weak var btnCancel: UIButton!
    @IBOutlet weak var labelReplacedTxid: UILabel!
    var wallet: Wallet?
    @IBOutlet weak var amountTitle: UILabel!
    var transaction: Transaction?
    var historyChangedDelegate: HistoryChangedDelegate?
    // must be at least 10% higher than original transaction, let's just hard-coded a value for now
    let LARGER_TX_FEE: String = "0.0000003"

    func centerHorizontal(uiview: UIView, screenWidth: Int){
        var frm : CGRect = uiview.frame
        uiview.frame = CGRect(x: screenWidth/2 - Int(frm.size.width/2), y: Int(frm.origin.y), width: Int(frm.size.width), height: Int(frm.size.height))
    }

    override func viewDidLoad() {
        var amount = "0"
        var currencySymbol = ""

        self.centerHorizontal(uiview: self.currencyView, screenWidth: Int(self.view.frame.width))

                if let item = transaction{
                    labelFromAddress.text = item.fromAddress
                    labelToAddress.text = item.toAddress
                    if !item.pending {
                        removeView(view: labelPending!)
                    }
                    amount = item.amount
                    if item.success{
                        labelTxId.text = item.txid
                    }else{
                        labelTxId.textColor = UIColor.red
                        labelTxId.text = item.error
                    }
                    if(item.replaced){
                        labelReplaced.isHidden = false
                        labelReplacedTxid.text = item.replaceTxid
                        let attributedText = NSAttributedString(string: item.txid, attributes: [NSAttributedString.Key.strikethroughStyle: 1])
                        labelTxId.attributedText = attributedText
                    }else{
                        labelReplaced.isHidden = true
                    }
                    if(item.replaceable){
                        btnSpeedUp.isHidden = false
                        btnCancel.isHidden = false
                    }else{
                        btnSpeedUp.isHidden = true
                        btnCancel.isHidden = true
                    }
                    self.wrapContent(label: self.labelPending!, text: labelPending.text!)
        //            self.wrapContent(label: self.labelTxId!, text: labelTxId.text!)
                    labelFail.isHidden = item.success
                    labelFee.text = item.transactionFee
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy/MM/dd hh:mm:ss"
                    labelTime.text = dateFormatter.string(from: Date(timeIntervalSince1970: Double(item.timestamp)))
                    if item.direction == .IN {
                        labelWithdraw.isHidden = true
                        labelDeposit.isHidden = false
                    } else{
                        labelWithdraw.isHidden = false
                        labelDeposit.isHidden = true
                    }

                    self.labelMemo.text = item.memo.count == 0 ? "-" : item.memo
                    self.labelDesc.text = item.description.count == 0 ? "-" : item.description
                    fetchTransactionInfo()
                }

                labelAmount.text = "\(amount) \(currencySymbol)"
        
        if let wallet = wallet {
            currencySymbol = wallet.currencySymbol
            currencyView.setSymbol(wallet.currencySymbol)
            currencyView.contentView.backgroundColor = UIColor.white
            currencyView.currencyLabel.textColor = UIColor.black
            CurrencyManager.shared.getAll{ result in
                if let c = CurrencyHelper.findCurrency(currencies: result, wallet: wallet){
                    DispatchQueue.main.async {
                        if(CurrencyHelper.isFungibleToken(currency: c)){
                            self.amountTitle.text = "Token ID"
                            self.labelAmount.text = "\(amount)"
                        }else{
                            self.amountTitle.text = "Amount"
                        }
                    }
                }
            }
            
        }
    }
    func wrapContent(label: UILabel, text: String, xOffset: CGFloat = 0){
        label.text = text
        let width = text.count * 9
        var frm : CGRect = label.frame
        label.frame = CGRect(x: frm.origin.x + xOffset, y: frm.origin.y, width: CGFloat(width), height: frm.size.height)
    }

    func removeView(view: UIView) {
        let constraintH: NSLayoutConstraint = NSLayoutConstraint(item: view as UIView,
                attribute: NSLayoutConstraint.Attribute.height,
                relatedBy: .equal,
                toItem: nil,
                attribute: NSLayoutConstraint.Attribute.notAnAttribute,
                multiplier: 0,
                constant: 0)
        let constraintW = NSLayoutConstraint(item: view as UIView,
                attribute: NSLayoutConstraint.Attribute.width,
                relatedBy: .equal,
                toItem: nil,
                attribute: NSLayoutConstraint.Attribute.notAnAttribute,
                multiplier: 0,
                constant: 0)
        view.addConstraint(constraintH)
        view.addConstraint(constraintW)
    }
    func fetchTransactionInfo(){
        guard transaction!.txid.count > 0 else{return}
        Wallets.shared.getTransactionInfo(currency: wallet!.currency, txid: transaction!.txid, completion: { result in
            switch result {
            case .success(let result):
                self.labelFee.text = result.fee
                self.labelConfirmBlock.isHidden = false
                let text = "\(result.confirmBlocks)  CONFIRMED"
                self.labelConfirmBlock.text = text
//                let xOffset = self.labelPending.isHidden ? 0 : self.labelPending.frame.size.width
                self.wrapContent(label: self.labelConfirmBlock!, text: text)
                break
            case .failure(let error):
                print("getTransactionInfo \(error)")
                break
            }
        })
    }
    @IBAction func onExplore(_ sender: Any) {
        if let w = wallet, let item = transaction {
            let uri = CurrencyHelper.getBlockExplorerUri(currency: w.currency, tokenAddress: w.tokenAddress, txid: item.txid)
            if let url = URL(string: uri){
                UIApplication.shared.open(url, options: [:])
            }
        }
    }
    @IBAction func onSpeedUp(_ sender: Any) {
        if let w = wallet, let item = transaction {
            let pinInput = PinInputViewController(nibName: "PinInputViewController", bundle: nil)
            pinInput.callback = { pinSecret in
                Wallets.shared.increaseTransactionFee(fromWalletId: w.walletId, txid: item.txid, transactionFee: self.LARGER_TX_FEE, pinSecret: pinSecret) { result in
                    switch result {
                    case .success(_):
                        self.historyChangedDelegate?.onChange()
                        let successAlert = UIAlertController(title: "Increase Transaction Fee successed", message: nil, preferredStyle: .alert)
                        successAlert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: {action in
                            self.navigationController?.popViewController(animated: true)
                        }))
                        self.present(successAlert, animated: true)
                        print("increaseTransactionFee onSuccess")
                        break
                    case .failure(let error):
                        let failedAlert = UIAlertController(title: "Increase Transaction Fee failed", message: error.name, preferredStyle: .alert)
                        failedAlert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                        self.present(failedAlert, animated: true)
                        print("increaseTransactionFee onFailed")
                        break
                    }
                }
            }
            present(pinInput, animated: true, completion: nil)
        }
    }
    @IBAction func onCancel(_ sender: Any) {
        if let w = wallet, let item = transaction {
            let pinInput = PinInputViewController(nibName: "PinInputViewController", bundle: nil)
            pinInput.callback = { pinSecret in
                Wallets.shared.cancelTransaction(fromWalletId: w.walletId, txid: item.txid, transactionFee: self.LARGER_TX_FEE, pinSecret: pinSecret) { result in
                    switch result {
                    case .success(_):
                        self.historyChangedDelegate?.onChange()
                        let successAlert = UIAlertController(title: "Cancel Transaction Fee successed", message: nil, preferredStyle: .alert)
                        successAlert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: {action in
                            self.navigationController?.popViewController(animated: true)
                        }))
                        self.present(successAlert, animated: true)
                        print("increaseTransactionFee onSuccess")
                        break
                    case .failure(let error):
                        let failedAlert = UIAlertController(title: "Cancel Transaction Fee failed", message: error.name, preferredStyle: .alert)
                        failedAlert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                        self.present(failedAlert, animated: true)
                        print("increaseTransactionFee onFailed")
                        break
                    }
                }
            }
            present(pinInput, animated: true, completion: nil)
        }
    }
}
