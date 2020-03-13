//Copyright (c) 2019 Cybavo. All rights reserved.

import UIKit
import CYBAVOWallet

protocol PickerWalletSource {
    var wallets: [Wallet] {get}
    func onSelected(_ wallet:Wallet)
}

class AddWalletController : UIViewController {
    @IBOutlet weak var currenciesPicker: UIPickerView!
    @IBOutlet weak var walletName: UITextField!
    @IBOutlet weak var accountName: UITextField!
    @IBOutlet weak var parentLabel: UITextView!
    @IBOutlet weak var parentPicker: UIPickerView!
    @IBOutlet var noParrentConstraint: NSLayoutConstraint!
    @IBOutlet var hasParentConstraint: NSLayoutConstraint!
    
    var supportedCurrencies: Array<Currency> = Array<Currency>()
    var allWallets: [Wallet]?
    var parentWallets: [Wallet]?
    var parentWallet: Wallet?
    var parentPickerDataSource: ParentPickerDataSource?
    var parentPickerDataDelegate: ParentPickerDataDelegate?
    
    override func viewDidLoad() {
        walletName.delegate = self
        accountName.delegate = self
        parentLabel.isHidden = true
        parentPicker.isHidden = true
        accountName.isHidden = true
        noParrentConstraint.isActive = true
        hasParentConstraint.isActive = false
        parentPickerDataSource = ParentPickerDataSource(source: self)
        parentPickerDataDelegate = ParentPickerDataDelegate(source: self)
    }
    override func viewDidAppear(_ animated: Bool) {
        currenciesPicker.dataSource = self
        currenciesPicker.delegate = self
        parentPicker.dataSource = parentPickerDataSource
        parentPicker.delegate = parentPickerDataDelegate
        
        CurrencyManager.shared.getAll { result in
            self.supportedCurrencies = result
            WalletManager.shared.getWallets{ walletsResult in
                self.allWallets = walletsResult
                self.supportedCurrencies = self.supportedCurrencies.filter{ currency in
                    return !walletsResult.contains{ wallet in
                        return wallet.currency == currency.currency && wallet.tokenAddress == currency.tokenAddress
                    }
                }
                if self.supportedCurrencies.count <= 0 {
                    let alert = UIAlertController(title: "No more wallets", message: nil, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .cancel){ _ in
                        self.navigationController?.popViewController(animated: true)
                    })
                    self.present(alert, animated: true)
                    return
                }
                DispatchQueue.main.async{
                    self.currenciesPicker.reloadAllComponents()
                    if let currency = self.supportedCurrencies[safe: 0] {
                        self.onSelected(currency: currency)
                    }
                }
            }
        }
    }
    private func validateForEos(currency: Currency){
        guard let accountNameStr = accountName.text else {
            return
        }
        if let regex = try? NSRegularExpression(pattern: "^[a-z1-5]{12}+$", options: .caseInsensitive) {
            let result = regex.matches(in: accountNameStr, options: .withoutAnchoringBounds, range: NSMakeRange(0, accountNameStr.count))
            if (result.count == 0) {
                let alert = UIAlertController(title: "Account Name only allow a-z, 1-5. length 12", message: nil, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                self.present(alert, animated: true)
                return
            }
        }

        Wallets.shared.getEosAccountValid(accountName: accountNameStr) {  result in
            switch result {
            case .success(let result):
                print("getEosAccountValid onSuccess")
                guard result.valid else{
                    let successAlert = UIAlertController(title: "EOS account invalid", message: nil, preferredStyle: .alert)
                    successAlert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                    self.present(successAlert, animated: true)
                    return
                }
                guard !result.exist else{
                    let successAlert = UIAlertController(title: "EOS account already exists", message: nil, preferredStyle: .alert)
                    successAlert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                    self.present(successAlert, animated: true)
                    return
                }
                self.inputPinCode(currency: currency)
                break
            case .failure(let error):
                let failAlert = UIAlertController(title: "validateEosAccount failed", message: error.name, preferredStyle: .alert)
                failAlert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                self.present(failAlert, animated: true)
                print("validateEosAccount onFailed")
                break
            }
        }
    }
    func hasAccount(currency: Currency) -> Bool{
        if isToken(currency:currency){
            return false
        }
        return currency.currency == CurrencyHelper.Coin.EOS.rawValue
    }
    func inputPinCode(currency: Currency){
        let pinInput = PinInputViewController(nibName: "PinInputViewController", bundle: nil)
        pinInput.callback = { pinSecret in
            let parentWalletId = self.parentWallet?.walletId ?? Int64(0)
            print("parentWalletId \(parentWalletId)")
            var extras: [String:String] = [:]
            if self.hasAccount(currency: currency){
                extras["account_name"] = self.accountName.text
            }
            Wallets.shared.createWallet(currency: currency.currency, tokenAddress: currency.tokenAddress, parentWalletId: parentWalletId, name: self.walletName.text!, pinSecret: pinSecret, extras: extras) {  result in
                switch result {
                case .success(_):
                    let successAlert = UIAlertController(title: "Create wallet successed", message: nil, preferredStyle: .alert)
                    successAlert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: {action in
                        self.navigationController?.popViewController(animated: true)
                    }))
                    self.present(successAlert, animated: true)
                    print("createWallet onSuccess")
                    break
                case .failure(let error):
                    let failAlert = UIAlertController(title: "Create wallet failed", message: error.name, preferredStyle: .alert)
                    failAlert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                    self.present(failAlert, animated: true)
                    print("createWallet onFailed")
                    break
                }
            }
        }
        present(pinInput, animated: true, completion: nil)
    }
    @IBAction func onSubmit(_ sender: Any) {
        guard let currency = supportedCurrencies[safe: currenciesPicker.selectedRow(inComponent: 0)], let name = walletName.text else {
            print("onsubmit currency or name not ready")
            return
        }
        if hasAccount(currency: currency) {
            validateForEos(currency: currency)
        }else{
            inputPinCode(currency: currency)
        }
    }
}

extension AddWalletController : UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return supportedCurrencies.count
    }
}

extension AddWalletController : UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let label: UILabel
        
        if let view = view {
            label = view as! UILabel
        }
        else {
            label = UILabel(frame: CGRect(x: 0, y: 0, width: pickerView.frame.width, height: 36))
        }
        
        label.text = supportedCurrencies[row].displayName
        label.lineBreakMode = .byWordWrapping
        label.numberOfLines = 0
        label.sizeToFit()
        
        return label
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        onSelected(currency: supportedCurrencies[row])
    }
    func isToken(currency: Currency)->Bool{
        return currency.tokenAddress.count > 0
    }
    func onSelected(currency: Currency){
        if isToken(currency:currency) {
            parentLabel.isHidden = false
            parentPicker.isHidden = false
            noParrentConstraint.isActive = false
            hasParentConstraint.isActive = true
            parentWallets = allWallets?.filter{ $0.currency == currency.currency && $0.tokenAddress.count == 0}
            parentWallet = parentWallets?[safe : 0]
            parentPicker.reloadAllComponents()
        } else {
            parentLabel.isHidden = true
            parentPicker.isHidden = true
            noParrentConstraint.isActive = true
            hasParentConstraint.isActive = false
            parentWallets = nil
            parentWallet = nil
        }
        accountName.isHidden = !self.hasAccount(currency: currency)
    }
}

extension AddWalletController : UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        /**focus next UITextField*/
        if textField == walletName && !accountName.isHidden{
            accountName.becomeFirstResponder()
        }else{
            textField.resignFirstResponder()
        }
        return true
    }
}

extension AddWalletController : PickerWalletSource {
    var wallets: [Wallet] {
        return parentWallets ?? [Wallet]()
    }
    
    
    class ParentPickerDataSource : NSObject, UIPickerViewDataSource {
        var parent: PickerWalletSource
        public init(source: PickerWalletSource){
            parent = source
        }
        func numberOfComponents(in pickerView: UIPickerView) -> Int {
            return 1
        }
        
        func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
            return parent.wallets.count
        }
    }
    
    class ParentPickerDataDelegate : NSObject, UIPickerViewDelegate {
        var parent: PickerWalletSource
        public init(source: PickerWalletSource){
            parent = source
        }
        func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
            let label: UILabel
            
            if let view = view {
                label = view as! UILabel
            }
            else {
                label = UILabel(frame: CGRect(x: 0, y: 0, width: pickerView.frame.width, height: 36))
            }
            
            label.text = parent.wallets[row].name
            label.lineBreakMode = .byWordWrapping
            label.numberOfLines = 0
            label.sizeToFit()
            
            return label
        }
        func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
            if let wallet = parent.wallets[safe: row] {
                parent.onSelected(wallet)
            }
        }
    }
    
    func onSelected(_ wallet: Wallet) {
        parentWallet = wallet
    }
}
