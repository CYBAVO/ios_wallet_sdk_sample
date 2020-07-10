//Copyright (c) 2019 Cybavo. All rights reserved.

import UIKit
import CYBAVOWallet

class WithdrawController : UIViewController{
    
    @IBOutlet weak var addressTextField: UITextField!
    @IBOutlet weak var amountTextField: UITextField!
    @IBOutlet weak var feePicker: UIPickerView!
    @IBOutlet weak var feeTitle: UITextView!
    @IBOutlet weak var balanceTextView: UITextView!
    @IBOutlet weak var amountUsageTextView: UITextView!
    @IBOutlet weak var amountQuotaTextView: UITextView!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var currencyView: CurrencyView!
    @IBOutlet weak var tokenIdPicker: UIPickerView!
    @IBOutlet weak var amountTitle: UITextView!
    
    var wallet: Wallet?
    var transactionFee = Array<Fee>()
    var tokenIds = Array<String>()
    let feePickerId: String = "feePicker"
    let tokenIdPickerId: String = "tokenIdPicker"
    var historyChangedDelegate: HistoryChangedDelegate?

    private let ABI_JSON = "[{\"constant\":false,\"inputs\":[{\"name\":\"_spender\",\"type\":\"address\"},{\"name\":\"_value\",\"type\":\"uint256\"}],\"name\":\"approve\",\"outputs\":[{\"name\":\"success\",\"type\":\"bool\"}],\"payable\":false,\"stateMutability\":\"nonpayable\",\"type\":\"function\"},{\"constant\":true,\"inputs\":[],\"name\":\"totalSupply\",\"outputs\":[{\"name\":\"\",\"type\":\"uint256\"}],\"payable\":false,\"stateMutability\":\"view\",\"type\":\"function\"},{\"constant\":false,\"inputs\":[{\"name\":\"_from\",\"type\":\"address\"},{\"name\":\"_to\",\"type\":\"address\"},{\"name\":\"_value\",\"type\":\"uint256\"}],\"name\":\"transferFrom\",\"outputs\":[{\"name\":\"success\",\"type\":\"bool\"}],\"payable\":false,\"stateMutability\":\"nonpayable\",\"type\":\"function\"},{\"constant\":true,\"inputs\":[{\"name\":\"_owner\",\"type\":\"address\"},{\"name\":\"_testInt\",\"type\":\"uint256\"},{\"name\":\"_testStr\",\"type\":\"string\"}],\"name\":\"balanceOfCB\",\"outputs\":[{\"name\":\"balance\",\"type\":\"uint256\"}],\"payable\":false,\"stateMutability\":\"view\",\"type\":\"function\"},{\"constant\":false,\"inputs\":[{\"name\":\"to\",\"type\":\"address\"},{\"name\":\"amount\",\"type\":\"uint256\"}],\"name\":\"transferQQQ\",\"outputs\":[{\"name\":\"success\",\"type\":\"bool\"}],\"payable\":false,\"stateMutability\":\"nonpayable\",\"type\":\"function\"},{\"constant\":true,\"inputs\":[{\"name\":\"_owner\",\"type\":\"address\"}],\"name\":\"balanceOf\",\"outputs\":[{\"name\":\"balance\",\"type\":\"uint256\"}],\"payable\":false,\"stateMutability\":\"view\",\"type\":\"function\"},{\"constant\":false,\"inputs\":[{\"name\":\"_to\",\"type\":\"address\"},{\"name\":\"_value\",\"type\":\"uint256\"}],\"name\":\"transfer\",\"outputs\":[{\"name\":\"success\",\"type\":\"bool\"}],\"payable\":false,\"stateMutability\":\"nonpayable\",\"type\":\"function\"},{\"constant\":false,\"inputs\":[],\"name\":\"transferFee\",\"outputs\":[],\"payable\":false,\"stateMutability\":\"nonpayable\",\"type\":\"function\"},{\"constant\":true,\"inputs\":[{\"name\":\"_owner\",\"type\":\"address\"},{\"name\":\"_spender\",\"type\":\"address\"}],\"name\":\"allowance\",\"outputs\":[{\"name\":\"remaining\",\"type\":\"uint256\"}],\"payable\":false,\"stateMutability\":\"view\",\"type\":\"function\"},{\"constant\":false,\"inputs\":[{\"name\":\"_to\",\"type\":\"address\"},{\"name\":\"_value\",\"type\":\"uint256\"},{\"name\":\"_testInt\",\"type\":\"uint256\"},{\"name\":\"_testStr\",\"type\":\"string\"}],\"name\":\"transferCB\",\"outputs\":[{\"name\":\"success\",\"type\":\"bool\"}],\"payable\":false,\"stateMutability\":\"nonpayable\",\"type\":\"function\"},{\"anonymous\":false,\"inputs\":[{\"indexed\":true,\"name\":\"_from\",\"type\":\"address\"},{\"indexed\":true,\"name\":\"_to\",\"type\":\"address\"},{\"indexed\":false,\"name\":\"_value\",\"type\":\"uint256\"}],\"name\":\"Transfer\",\"type\":\"event\"},{\"anonymous\":false,\"inputs\":[{\"indexed\":true,\"name\":\"_owner\",\"type\":\"address\"},{\"indexed\":true,\"name\":\"_spender\",\"type\":\"address\"},{\"indexed\":false,\"name\":\"_value\",\"type\":\"uint256\"}],\"name\":\"Approval\",\"type\":\"event\"}]"
    
    override func viewDidLoad() {
        [addressTextField, amountTextField].forEach{ textField in
            textField?.setBottomBorder()
            textField?.delegate = self
        }
        amountTextField.addDoneCancelToolbar()
        feePicker.accessibilityIdentifier = feePickerId
        feePicker.dataSource = self
        feePicker.delegate = self
        
        tokenIdPicker.accessibilityIdentifier = tokenIdPickerId
        tokenIdPicker.dataSource = self
        tokenIdPicker.delegate = self
//        feePicker.isHidden = wallet.
        sendButton.isUserInteractionEnabled = false
        guard let w = wallet else {
            self.navigationController?.popViewController(animated: true)
            return
        }
        currencyView.setSymbol(w.currencySymbol)

        print("WithdrawController wallet \(w)")
        if(hasTransactionFee()){
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
            feePicker.isHidden = false
            feeTitle.isHidden = false
        }else{
            feePicker.isHidden = true
            feeTitle.isHidden = true
        }
        
        Wallets.shared.getBalances(addresses: [w.walletId: w]) { result in
            switch result {
            case .success(let result):
                print("getBalance \(result)")
                if let balanceItem = result.balance[w.walletId]{
                    self.tokenIds = balanceItem.tokens
                    DispatchQueue.main.async {
                        self.tokenIdPicker.reloadAllComponents()
                    }
                    print("eee_getBalance \(balanceItem.balance) \(w.currencySymbol)")
                    self.balanceTextView.text = "\(balanceItem.balance) \(w.currencySymbol)"
                }
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
        
        CurrencyManager.shared.getAll{ result in
            if let c = CurrencyHelper.findCurrency(currencies: result, wallet: w){
                DispatchQueue.main.async {
                    if(CurrencyHelper.isFungibleToken(currency: c)){
                        self.amountTitle.text = "Token ID"
                        self.tokenIdPicker.isHidden = false
                        self.amountTextField.isHidden = true
                    }else{
                        self.amountTitle.text = "Amount"
                        self.tokenIdPicker.isHidden = true
                        self.amountTextField.isHidden = false
                    }
                }
            }
        }
    }
    @IBAction func onScanQRCode(_ sender: Any) {
        performSegue(withIdentifier: "idQRCodeScan", sender: nil)
    }
    func hasTransactionFee()->Bool{
        if let currency = wallet?.currency {
            return currency != CurrencyHelper.Coin.EOS.rawValue && currency != CurrencyHelper.Coin.TRX.rawValue
        }
        return true
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == "idQRCodeScan" else {
            return
        }
        if let vc = segue.destination as? QRCodeScanController {
            vc.delegate = self
        }
    }
    func getTranscationFeeAsParam()->String?{
        if(hasTransactionFee()){
            return transactionFee[safe: feePicker.selectedRow(inComponent: 0)]?.amount
        }else{
            return ""
        }
    }
    
    /*
     * The smart contract is on test net for testing purpose
     * */
    func callAbiFunctionRead(wallet: Wallet){
        Wallets.shared.callAbiFunctionRead(walletId: wallet.walletId, name: "balanceOfCB", contractAddress: "0xef3aa4115b071a9a7cd43f1896e3129f296c5a5f", abiJson: ABI_JSON, args:["0x281F397c5a5a6E9BE42255b01EfDf8b42F0Cd179", 123, "test"]){ result in
            switch result {
            case .success(let result):
                print("callAbiFunctionRead_\(result.output)_\(result.signedTx)_\(result.txid)")
                break
            case .failure(let error):
                print("callAbiFunctionRead_\(error)")
                break
            }
        }
    }
    
    /*
     * The smart contract is on test net for testing purpose
     * */
    func callAbiFunctionTransaction(wallet: Wallet, fee: String, pinSecret: PinSecret){
        Wallets.shared.callAbiFunctionTransaction(walletId: wallet.walletId, name: "transferCB", contractAddress: "0xef3aa4115b071a9a7cd43f1896e3129f296c5a5f", abiJson: ABI_JSON, args: ["0x490d510c1A8b74749949cFE5cA06D0C6BD7119E2", 1, 100, "unittest"], transactionFee: fee, pinSecret: pinSecret){ result in
                       switch result {
                       case .success(let result):
                            print("callAbiFunctionTransaction_\(result.output)_\(result.signedTx)_\(result.txid)")
                           break
                       case .failure(let error):
                            print("callAbiFunctionTransaction_\(error)")
                           break
                       }
        }
    }
    
    @IBAction func onSend(_ sender: Any) {
        let amountText = tokenIdPicker.isHidden ? amountTextField.text : tokenIds[safe: tokenIdPicker.selectedRow(inComponent: 0)]
        guard let w = wallet, let toAddress = addressTextField.text, let amount = amountText, amountText != "", let fee = getTranscationFeeAsParam() else {
            return
        }
        
        let pinInput = PinInputViewController(nibName: "PinInputViewController", bundle: nil)
        pinInput.callback = { pinSecret in
//            self.callAbiFunctionRead(wallet: w)
//            self.callAbiFunctionTransaction(wallet: w, fee: fee, pinSecret: pinSecret)
            Wallets.shared.createTransaction(fromWalletId: w.walletId, toAddress: toAddress, amount: amount, transactionFee: fee, description: "", pinSecret: pinSecret) { result in
                switch result {
                case .success(_):
                    self.historyChangedDelegate?.onChange()
                    let successAlert = UIAlertController(title: "Withdraw successed", message: nil, preferredStyle: .alert)
                    successAlert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: {action in
                        self.navigationController?.popViewController(animated: true)
                    }))
                    self.present(successAlert, animated: true)
                    print("createTransaction onSuccess")
                    break
                case .failure(let error):
                    let failedAlert = UIAlertController(title: "Withdraw failed", message: error.name, preferredStyle: .alert)
                    failedAlert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: {action in
                        self.navigationController?.popViewController(animated: true)
                    }))
                    self.present(failedAlert, animated: true)
                    print("createTransaction onFailed")
                    break
                }
            }
        }
        present(pinInput, animated: true, completion: nil)
    }
}

extension WithdrawController : UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if(pickerView.accessibilityIdentifier == tokenIdPickerId){
            return tokenIds.count
        }else{
            return transactionFee.count
        }
    }
}

extension WithdrawController : UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        if(pickerView.accessibilityIdentifier == tokenIdPickerId){
            return getTokenIdPickerView(pickerView, viewForRow: row, forComponent: component, reusing: view)
        }else{
            return getFeePickerView(pickerView, viewForRow: row, forComponent: component, reusing: view)
        }
    }
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 32
    }
    
    func getTokenIdPickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView{
        let view = UIView(frame: CGRect(x: 0, y: 0, width: pickerView.frame.width, height: 32))
        if let tokenId = tokenIds[safe: row] {
            let amount = UILabel(frame: CGRect(x: 0, y: 0, width: pickerView.frame.width, height: 32))
            amount.text = tokenId
            amount.numberOfLines = 1
            amount.font = amount.font.withSize(14)
            amount.textColor = .white
            view.addSubview(amount)
        }
        return view
    }
    func getFeePickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView{
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
}

extension WithdrawController : UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard
            let address = addressTextField.text, !address.isEmpty
//            let amount = amountTextField.text, !amount.isEmpty
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
         sendButton.isUserInteractionEnabled = !code.isEmpty
    }
}
