//Copyright (c) 2019 Cybavo. All rights reserved.

import UIKit
import CYBAVOWallet

class WithdrawController : UIViewController {
    
    @IBOutlet weak var addressTextField: UITextField!
    @IBOutlet weak var amountTextField: UITextField!
    @IBOutlet weak var feePicker: UIPickerView!
    @IBOutlet weak var balanceTextView: UITextView!
    @IBOutlet weak var amountUsageTextView: UITextView!
    @IBOutlet weak var amountQuotaTextView: UITextView!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var currencyView: CurrencyView!
    
    var wallet: Wallet?
    var transactionFee = Array<Fee>()
    
    override func viewDidLoad() {
        [addressTextField, amountTextField].forEach{ textField in
            textField?.setBottomBorder()
            textField?.delegate = self
        }
        amountTextField.addDoneCancelToolbar()
        feePicker.dataSource = self
        feePicker.delegate = self
        sendButton.isUserInteractionEnabled = false
        guard let w = wallet else {
            self.navigationController?.popViewController(animated: true)
            return
        }
        currencyView.setSymbol(w.currencySymbol)

        print("WithdrawController wallet \(w)")
        
        Wallets.shared.getTransactionFee(currency: w.currency) { result in
            switch result {
            case .success(let result):
                print("getTransactionFee \(result)")
                self.transactionFee = [result.low, result.medium, result.high]
                DispatchQueue.main.async {
                    self.feePicker.reloadAllComponents()
                }
                break
            case .failure(let error):
                print("getTransactionFee failed \(error)")
                break
            }
        }
        
        Wallets.shared.getBalances(addresses: [w.walletId: w]) { result in
            switch result {
            case .success(let result):
                print("getBalance \(result)")
                self.balanceTextView.text = "\(result.balance[w.walletId]?.balance ?? "") \(w.currencySymbol)"
                break
            case .failure(let error):
                print("getBalance \(error)")
                break
            }
        }
        
        Wallets.shared.getWalletUsage(walletId: w.walletId) { result in
            switch result {
            case .success(let result):
                print("getWalletUsage \(result)")
                self.amountUsageTextView.text = "\(result.dailyTransactionAmountUsage) \(w.currencySymbol) Today"
                self.amountQuotaTextView.text = "\(result.dailyTransactionAmountQuota) \(w.currencySymbol) Daily"
                break
            case .failure(let error):
                print("getWalletUsage \(error)")
                break
            }
        }
    }
    @IBAction func onScanQRCode(_ sender: Any) {
        performSegue(withIdentifier: "idQRCodeScan", sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == "idQRCodeScan" else {
            return
        }
        if let vc = segue.destination as? QRCodeScanController {
            vc.delegate = self
        }
    }
    
    @IBAction func onSend(_ sender: Any) {
        createTransactionBySecureToken()
    }
    
    func createTransactionBySecureToken(){
        guard let w = wallet, let toAddress = addressTextField.text, let amount = amountTextField.text, let fee = transactionFee[safe: feePicker.selectedRow(inComponent: 0)]?.amount else {
            return
        }
        
        Wallets.shared.createTransaction(fromWalletId: w.walletId, toAddress: toAddress, amount: amount, transactionFee: fee, description: "") { result in
            switch result {
            case .success(_):
                let successAlert = UIAlertController(title: "Withdraw successed", message: nil, preferredStyle: .alert)
                successAlert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: {action in
                    self.navigationController?.popViewController(animated: true)
                }))
                self.present(successAlert, animated: true)
                print("createTransaction onSuccess")
                break
            case .failure(let error):
                if error == ApiError.ErrDestinationNotInOutgoingAddress {
                    let failedAlert = UIAlertController(title: "Withdraw failed", message: error.name, preferredStyle: .alert)
                    failedAlert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: {action in
                        self.navigationController?.popViewController(animated: true)
                    }))
                    self.present(failedAlert, animated: true)
                }
                self.requestSecureToken()
                print("createTransaction onFailed")
                break
            }
        }
    }
    
    func requestSecureToken(){
        let alert = UIAlertController(title: "Input PIN code", message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addTextField(configurationHandler: { textField in
            textField.keyboardType = .numberPad
            textField.isSecureTextEntry = true
            textField.becomeFirstResponder()
        })
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
            if let pincode = alert.textFields?.first?.text {
                Wallets.shared.requestSecureToken(pinCode: pincode) { result in
                    switch result {
                    case .success(_):
                        print("requestSecureToken onSuccess")
                        self.createTransactionBySecureToken()
                        break
                    case .failure(let error):
                        let failAlert = UIAlertController(title: "Withdraw failed", message: error.name, preferredStyle: .alert)
                        failAlert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                        self.present(failAlert, animated: true)
                        print("requestSecureToken onFailed")
                        break
                    }
                }
            }
        }))
        
        self.present(alert, animated: true)
    }
}

extension WithdrawController : UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return transactionFee.count
    }
}

extension WithdrawController : UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: pickerView.frame.width, height: 32))
        if let fee = transactionFee[safe: row] {
            let amount = UILabel(frame: CGRect(x: 0, y: 0, width: pickerView.frame.width, height: 12))
            amount.text = fee.amount
            amount.numberOfLines = 1
            amount.font = amount.font.withSize(14)
            amount.textColor = .white
            
            let description = UILabel(frame: CGRect(x: 0, y: 18, width: pickerView.frame.width, height: 12))
            description.text = fee.description
            description.numberOfLines = 1
            description.font = amount.font.withSize(10)
            description.textColor = .white
            
            view.addSubview(amount)
            view.addSubview(description)
        }
        return view
    }
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 32
    }
}

extension WithdrawController : UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard
            let address = addressTextField.text, !address.isEmpty,
            let amount = amountTextField.text, !amount.isEmpty
            else {
                sendButton.isUserInteractionEnabled = false
                return true
        }
        sendButton.isUserInteractionEnabled = true
        return true
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

extension WithdrawController : QRCodeContentDelegate {
    func onScan(code: String) {
        addressTextField.text = code
    }
}
