//Copyright (c) 2019 Cybavo. All rights reserved.

import UIKit
import CYBAVOWallet


class EosResourceController : UIViewController, SSRadioButtonControllerDelegate{

    @IBOutlet weak var ramProgressView: UIProgressView!
    @IBOutlet weak var ramEos: UILabel!
    @IBOutlet weak var ramValue: UILabel!

    @IBOutlet weak var cpuProgressView: UIProgressView!
    @IBOutlet weak var cpuEos: UILabel!
    @IBOutlet weak var cpuValue: UILabel!
//
//
    @IBOutlet weak var netProgressView: UIProgressView!
    @IBOutlet weak var netEos: UILabel!
    @IBOutlet weak var netValue: UILabel!
    @IBOutlet weak var buyRam: UIButton!
    @IBOutlet weak var sellRam: UIButton!
    @IBOutlet weak var delegateCpu: UIButton!
    @IBOutlet weak var undelegateCpu: UIButton!
    @IBOutlet weak var delegateNet: UIButton!
    @IBOutlet weak var undelegateNet: UIButton!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var amountInput: UITextField!
    @IBOutlet weak var amountEos: UILabel!
    @IBOutlet weak var receiverInput: UITextField!
    var historyChangedDelegate: HistoryChangedDelegate?
    var radioButtonController: SSRadioButtonsController?
    var wallet: Wallet?
    var currentRamPrice = 0.9416
    let regex = try? NSRegularExpression(pattern: "^[a-z1-5]{12}+$", options: .caseInsensitive)
    @IBAction func onAmountChanged(_ sender: Any) {
        if amountEos.isHidden{
            return
        }
        amountEos.text = "≈ \(getNumBytes()) EOS"
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "EOS resources"
        guard let w = wallet else {
            self.dismiss(animated: true)
            return
        }
        [amountInput, receiverInput].forEach{ textField in
            textField?.delegate = self
        }
        amountInput.addDoneCancelToolbar()
        initRatioButton()
        getEosRamPrice()
        getEosResourceState(accountName:w.address)
    }
    /*init & select default item*/
    func initRatioButton(){
        radioButtonController = SSRadioButtonsController(buttons: buyRam, sellRam, delegateCpu, undelegateCpu, delegateNet, undelegateNet)
        radioButtonController!.delegate = self
        radioButtonController!.shouldLetDeSelect = false //true:點第二下取消 false:點第二下仍是選擇
        buyRam.sendActions(for: .touchUpInside)
    }
    
    /*Update intput for num_bytes and receiver*/
    func updateUiInput(index: Int){
//        amountInput.text = ""
//        amountEos.text = "≈ 0 EOS"
        switch index{
            case EosResourceTransactionType.BUY_RAM.rawValue:
                amountInput.placeholder = "Number of bytes"
                receiverInput.isHidden = false
                amountEos.isHidden = false
                break;
            case EosResourceTransactionType.SELL_RAM.rawValue:
                amountInput.placeholder = "Number of bytes"
                receiverInput.isHidden = true
                amountEos.isHidden = false
                break;
            case EosResourceTransactionType.DELEGATE_CPU.rawValue:
                amountInput.placeholder = "Amount"
                receiverInput.isHidden = false
                amountEos.isHidden = true
                break;
            case EosResourceTransactionType.UNDELEGATE_CPU.rawValue:
                amountInput.placeholder = "Amount"
                receiverInput.isHidden = true
                amountEos.isHidden = true
                break;
            case EosResourceTransactionType.DELEGATE_NET.rawValue:
                amountInput.placeholder = "Amount"
                receiverInput.isHidden = false
                amountEos.isHidden = true
                break;
            case EosResourceTransactionType.UNDELEGATE_NET.rawValue:
                amountInput.placeholder = "Amount"
                receiverInput.isHidden = true
                amountEos.isHidden = true
                break;
            default: break

        }
    }
    /**index start from 0, type start from 1*/
    func getTransactionType(index: Int)-> Int{
        return index + 1
    }
    /*getEosRamPrice API call*/
    func getEosRamPrice(){
        Wallets.shared.getEosRamPrice(){ result in
            switch result{
                case .success(let result):
                    self.updateUiRamPrice(ramPrice: result.ramPrice)
                break
            case .failure(_):
                break
            }
        }
    }
    
    /*getEosResourceState API call*/
    func getEosResourceState(accountName:String){
        Wallets.shared.getEosResourceState(accountName: accountName){ result in
            switch result {
            case .success(let result):
                self.updateUiRamProgress(used: result.ramUsage, max: result.ramQuota)
                
                self.updateUiCpuProgress(used: result.cpuUsed, max: result.cpuMax)
                self.updateUiDesc(sAmount: result.cpuAmount, sPrecision: result.cpuAmountPrecision
                    , rAmount: result.cpuRefund, rPrecision: result.cpuRefundPrecision
                    , label: self.cpuEos)
                
                self.updateUiNetProgress(used: result.netUsed, max: result.netMax)
                self.updateUiDesc(sAmount: result.netAmount, sPrecision: result.netAmountPrecision
                    , rAmount: result.netRefund, rPrecision: result.netRefundPrecision
                    , label: self.netEos)
                break
            case .failure(_):
                self.updateUiRamProgress(used: 0, max: 0)
                self.updateUiCpuProgress(used: 0, max: 0)
                self.updateUiNetProgress(used: 0, max: 0)
                self.cpuEos.text = "..."
                self.netEos.text = "..."
                break
            }
        }
    }
    /*call when radio button be selected*/
    func didSelectButton(selectedButton: UIButton?) {
        guard let currentButton = radioButtonController!.selectedButton() else {
            print("點選:nil")
            sendButton.isHidden = true
            return
        }
        sendButton.isHidden = false
        let index = radioButtonController!.selectedButtonIndex()!
        sendButton.setTitle(currentButton.currentTitle, for: .normal)
        updateUiInput(index: getTransactionType(index: index))
        print("點選\(currentButton.currentTitle!)_\(index)")
    }

    /*Update Ram ProgressView and text*/
    func updateUiRamProgress(used: Int64, max: Int64){
        let progress = Progress(totalUnitCount: max)
        progress.completedUnitCount = used
        self.ramProgressView.setProgress(Float(progress.fractionCompleted), animated: true)
        self.ramValue.text = String(format:"%d / %d bytes", arguments:[used, max])
    }
    /*Update Cpu ProgressView and text*/
    func updateUiCpuProgress(used: Int64, max: Int64){
        let progress = Progress(totalUnitCount: max)
        progress.completedUnitCount = used
        self.cpuProgressView.setProgress(Float(progress.fractionCompleted), animated: true)
        self.cpuValue.text = String(format:"%d / %d μs", arguments:[used, max])
    }
    /*Update Net ProgressView and text*/
    func updateUiNetProgress(used: Int64, max: Int64){
        let progress = Progress(totalUnitCount: max)
        progress.completedUnitCount = used
        self.netProgressView.setProgress(Float(progress.fractionCompleted), animated: true)
        self.netValue.text = String(format:"%d / %d bytes", arguments:[used, max])
    }
    func updateUiRamPrice(ramPrice: String){
        self.currentRamPrice = Double(ramPrice)!
        self.ramEos.text = "\(ramPrice) EOS/Kbytes"
    }
    func getNumBytes() -> Double{
        let amount = Double(amountInput.text ?? "0") ?? 0
        return currentRamPrice * Double((amount / 1024))
    }
    /*Update text for how much stacked & refunding*/
    func updateUiDesc(sAmount: Int64?, sPrecision: Int, rAmount: Int64?, rPrecision: Int, label: UILabel){
        if sAmount != nil && rAmount != nil{
            let sValue = self.calWithPrec(amount: sAmount!, precision: sPrecision)
            let rValue = self.calWithPrec(amount: rAmount!, precision: rPrecision)
            label.text = "\(sValue) staked • \(rValue) refunding"
            return
        }
        label.text = String("...")
    }
    /*calculate value for stacked & reunding*/
    func calWithPrec(amount: Int64, precision: Int) -> Decimal{
        let div = pow(10.0,precision)
        return Decimal(amount) / div
    }
//    func postDataFromModel() -> [String:Any] {
//        var dataDictionary: [String: Any] = [:]
//
//        return dataDictionary
//    }
    func getNumBytesAndAmount()-> (Int64?, String){
        let numBytes = Int64(self.amountInput.text ?? "0") ?? 0//self.getNumBytes()
        guard numBytes >= 1024 else{
            return (nil, "0")
        }
        let amount = String(self.getNumBytes())
        return (numBytes, amount)
    }
    @IBAction func onSubmit(_ sender: Any) {
        var extras: [String:Any] = [:]
        let index = self.radioButtonController!.selectedButtonIndex()!

        guard let w = self.wallet, var toAddress = self.receiverInput.text, var amount = self.amountInput.text else {
            let alert = UIAlertController(title: "wallet or receiver or amount is null", message: nil, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            self.present(alert, animated: true)
            return
        }
        if(!self.receiverInput.isHidden){
            let result = self.regex?.matches(in: toAddress, options: .withoutAnchoringBounds, range: NSMakeRange(0, toAddress.count))
            if (result?.count == 0) {
                let alert = UIAlertController(title: "Account Name only allow a-z, 1-5. length 12", message: nil, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                self.present(alert, animated: true)
                return
            }
        }

        let type = self.getTransactionType(index: index)
        extras["eos_transaction_type"] = type
        switch type{
        case EosResourceTransactionType.BUY_RAM.rawValue:
            let result = getNumBytesAndAmount()
            guard result.0 != nil else{
                let alert = UIAlertController(title: "Number of bytes must > 1024 ", message: nil, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                self.present(alert, animated: true)
                return
            }
            extras["num_bytes"] = result.0
            amount = result.1
            break;
        case EosResourceTransactionType.SELL_RAM.rawValue:
            let result = getNumBytesAndAmount()
            guard result.0 != nil else{
                let alert = UIAlertController(title: "Number of bytes must > 1024 ", message: nil, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                self.present(alert, animated: true)
                return
            }
            extras["num_bytes"] = result.0
            amount = result.1
            toAddress = w.address
            break;
        case EosResourceTransactionType.DELEGATE_CPU.rawValue:
            break;
        case EosResourceTransactionType.UNDELEGATE_CPU.rawValue:
            toAddress = w.address
            break;
        case EosResourceTransactionType.DELEGATE_NET.rawValue:
            break;
        case EosResourceTransactionType.UNDELEGATE_NET.rawValue:
            toAddress = w.address
            break;
        default: break
        }

        
        
        let pinInput = PinInputViewController(nibName: "PinInputViewController", bundle: nil)
        pinInput.callback = { pinSecret in
            Wallets.shared.createTransaction(fromWalletId: w.walletId, toAddress: toAddress, amount: amount, transactionFee: ""
                    , description: "", pinSecret: pinSecret, extras:  extras) { result in
                switch result {
                case .success(_):
                    self.historyChangedDelegate?.onChange()
                    let successAlert = UIAlertController(title: "Transaction succeed", message: nil, preferredStyle: .alert)
                    successAlert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: {action in
                        self.getEosResourceState(accountName:w.address)
                    }))
                    self.present(successAlert, animated: true)
                    print("createTransaction onSuccess")
                    break
                case .failure(let error):
                    let failedAlert = UIAlertController(title: "Transaction failed", message: error.name, preferredStyle: .alert)
                    failedAlert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: {action in
                        //                                self.navigationController?.popViewController(animated: true)
                    }))
                    self.present(failedAlert, animated: true)
                    //                        self.requestSecureToken()
                    print("createTransaction onFailed")
                    break
                }
            }
            
        }
        present(pinInput, animated: true, completion: nil)
        
    }

}

extension EosResourceController : UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard
                let receiver = receiverInput.text, !receiver.isEmpty,
                let amount = amountInput.text, !amount.isEmpty
                else {
//            sendButton.isUserInteractionEnabled = false
            return true
        }
//        sendButton.isUserInteractionEnabled = true
        return true
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
extension Double {
    func rounding(toDecimal decimal: Int) -> Double {
        let numberOfDigits = pow(10.0, Double(decimal))
        return (self * numberOfDigits).rounded(.toNearestOrAwayFromZero) / numberOfDigits
    }
}
